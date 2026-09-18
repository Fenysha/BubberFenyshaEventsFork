import ctypes
import json
import subprocess
import time
from pathlib import Path
import random

import numpy as np
import tkinter as tk
from tkinter import ttk, filedialog, messagebox


# ============================================================================
# Rust generator client
# ============================================================================

class GeneratorClient:

    FUNC_NAME = "tp_sublevel_generate"

    @staticmethod
    def _call_dll(dll_path: Path, config_json: str) -> bytes:
        dll = ctypes.CDLL(str(dll_path))

        if not hasattr(dll, GeneratorClient.FUNC_NAME):
            raise AttributeError(
                f"В DLL '{dll_path.name}' не найдена функция "
                f"'{GeneratorClient.FUNC_NAME}'."
            )

        func = getattr(dll, GeneratorClient.FUNC_NAME)

        func.argtypes = [
            ctypes.c_size_t,
            ctypes.POINTER(ctypes.c_char_p),
        ]

        func.restype = ctypes.c_char_p

        arg = ctypes.c_char_p(
            config_json.encode("utf-8")
        )

        argv = (ctypes.c_char_p * 1)(arg)

        result_ptr = func(1, argv)

        if not result_ptr:
            raise RuntimeError(
                "Rust-функция вернула NULL."
            )

        return ctypes.string_at(result_ptr)

    @staticmethod
    def _call_cli(exe_path: Path, config_json: str) -> bytes:
        process = subprocess.run(
            [str(exe_path), config_json],
            capture_output=True,
            check=False,
        )

        if process.returncode != 0:
            stderr = process.stderr.decode(
                "utf-8",
                errors="replace",
            )

            raise RuntimeError(
                f"Rust EXE завершился с кодом "
                f"{process.returncode}:\n{stderr}"
            )

        return process.stdout

    @staticmethod
    def run(
        generator_path: str,
        config: dict,
    ):
        path = Path(generator_path)

        if not path.exists():
            raise FileNotFoundError(
                f"Файл не найден:\n{path}"
            )

        config_json = json.dumps(
            config,
            separators=(",", ":"),
        )

        start = time.perf_counter()

        if path.suffix.lower() in (
            ".dll",
            ".so",
            ".dylib",
        ):
            stdout_bytes = GeneratorClient._call_dll(
                path,
                config_json,
            )
        else:
            stdout_bytes = GeneratorClient._call_cli(
                path,
                config_json,
            )

        elapsed_ms = (
            time.perf_counter() - start
        ) * 1000.0

        raw_text = stdout_bytes.decode(
            "utf-8",
            errors="replace",
        ).strip()

        try:
            result = json.loads(raw_text)

        except json.JSONDecodeError as error:
            raise RuntimeError(
                "Rust вернул некорректный JSON:\n\n"
                + raw_text[:2000]
            ) from error

        if isinstance(result, str):

            if result.startswith("ERROR:"):
                raise RuntimeError(result)

            raise RuntimeError(
                "Rust вернул строку вместо объекта:\n"
                + result
            )

        if not isinstance(result, dict):
            raise RuntimeError(
                "Неожиданный формат ответа Rust."
            )

        if result.get("status") != "ok":
            raise RuntimeError(
                "Генератор Rust сообщил об ошибке:\n"
                + json.dumps(
                    result,
                    ensure_ascii=False,
                    indent=2,
                )
            )

        width = int(result["width"])
        height = int(result["height"])

        expected_size = width * height

        height_data = result.get("heights")

        if height_data is None:
            raise RuntimeError(
                "В ответе Rust отсутствует 'heights'."
            )

        if len(height_data) != expected_size:
            raise RuntimeError(
                f"Неверный размер heights: "
                f"{len(height_data)}, "
                f"ожидалось {expected_size}."
            )

        heights = np.asarray(
            height_data,
            dtype=np.float32,
        ).reshape(
            height,
            width,
        )

        cave_data = result.get("cave_mask")

        if cave_data is None:
            cave_mask = np.zeros(
                (height, width),
                dtype=np.uint8,
            )
        else:
            if len(cave_data) != expected_size:
                raise RuntimeError(
                    f"Неверный размер cave_mask: "
                    f"{len(cave_data)}, "
                    f"ожидалось {expected_size}."
                )

            cave_mask = np.asarray(
                cave_data,
                dtype=np.uint8,
            ).reshape(
                height,
                width,
            )

        return (
            heights,
            cave_mask,
            elapsed_ms,
        )


# ============================================================================
# Heightmap renderer
# ============================================================================

class HeightmapRenderer:

    @staticmethod
    def height_to_rgb(heights: np.ndarray):
        minimum = float(np.min(heights))
        maximum = float(np.max(heights))

        if maximum - minimum < 0.000001:
            normalized = np.zeros_like(
                heights,
                dtype=np.float32,
            )
        else:
            normalized = (
                heights - minimum
            ) / (
                maximum - minimum
            )

        # Blue -> Cyan -> Purple -> Red
        #
        # Низкая высота:
        #     синий
        #
        # Высокая:
        #     красный
        #
        # Никаких специальных цветов Tkinter здесь
        # не требуется — создаём RGB напрямую.

        red = (
            normalized * 255.0
        ).astype(np.uint8)

        blue = (
            (1.0 - normalized) * 255.0
        ).astype(np.uint8)

        # Небольшая зелёная составляющая в середине
        # делает карту визуально более читаемой.
        green = (
            np.sin(
                normalized * np.pi
            ) * 90.0
        ).astype(np.uint8)

        rgb = np.stack(
            (
                red,
                green,
                blue,
            ),
            axis=-1,
        )

        return rgb

    @staticmethod
    def apply_caves(
        rgb: np.ndarray,
        cave_mask: np.ndarray,
    ):
        caves = cave_mask != 0

        if np.any(caves):

            # Пещеры затемняются, но сохраняют
            # информацию о высоте.
            rgb[caves] = (
                rgb[caves].astype(np.float32)
                * 0.25
            ).astype(np.uint8)

        return rgb


# ============================================================================
# Main application
# ============================================================================

class GeneratorTester(tk.Tk):

    BG = "#151515"
    PANEL = "#202020"
    PANEL2 = "#252525"
    FG = "#dddddd"
    FG_SECONDARY = "#999999"
    ENTRY_BG = "#111111"
    BORDER = "#3a3a3a"
    BUTTON_BG = "#303030"
    BUTTON_ACTIVE = "#404040"

    def __init__(self):
        super().__init__()

        self.title(
            "Tartarus Planet Generator"
        )

        self.geometry(
            "1200x850"
        )

        self.minsize(
            900,
            650,
        )

        self.configure(
            background=self.BG
        )

        self.generator_path = None

        self.last_heights = None
        self.last_caves = None

        self.photo = None
        self.display_photo = None

        self.display_width = 0
        self.display_height = 0

        self.map_origin_x = 0
        self.map_origin_y = 0

        self._create_variables()
        self._create_styles()
        self._create_controls()
        self._create_map()

    # ========================================================================
    # Variables
    # ========================================================================

    def _create_variables(self):

        self.seed_var = tk.IntVar(
            value=random.randint(
                0,
                2_147_483_647,
            )
        )

        self.x_var = tk.IntVar(
            value=0
        )

        self.y_var = tk.IntVar(
            value=0
        )

        self.local_seed_var = tk.IntVar(
            value=random.randint(
                0,
                2_147_483_647,
            )
        )

        self.size_var = tk.IntVar(
            value=128
        )

        self.bias_var = tk.DoubleVar(
            value=0.0
        )

        self.smooth_var = tk.IntVar(
            value=2
        )

        self.caves_var = tk.BooleanVar(
            value=True
        )

        # --------------------------------------------------------------------
        # 3x3 neighbourhood.
        #
        # Центр всегда обозначает текущую планету.
        #
        # 0 = сосед отсутствует
        # 1 = сосед существует
        # --------------------------------------------------------------------

        self.neighbourhood_vars = []

        for y in range(3):

            row = []

            for x in range(3):

                # По умолчанию центр активен.
                value = (
                    1
                    if x == 1 and y == 1
                    else 0
                )

                var = tk.IntVar(
                    value=value
                )

                row.append(var)

            self.neighbourhood_vars.append(
                row
            )

    # ========================================================================
    # Styles
    # ========================================================================

    def _create_styles(self):

        style = ttk.Style(self)

        try:
            style.theme_use("clam")
        except tk.TclError:
            pass

        style.configure(
            ".",
            background=self.BG,
            foreground=self.FG,
        )

        style.configure(
            "TFrame",
            background=self.BG,
        )

        style.configure(
            "Panel.TFrame",
            background=self.PANEL,
        )

        style.configure(
            "TLabel",
            background=self.BG,
            foreground=self.FG,
        )

        style.configure(
            "Secondary.TLabel",
            background=self.BG,
            foreground=self.FG_SECONDARY,
        )

        style.configure(
            "TButton",
            background=self.BUTTON_BG,
            foreground=self.FG,
            bordercolor=self.BORDER,
            padding=6,
        )

        style.map(
            "TButton",
            background=[
                (
                    "active",
                    self.BUTTON_ACTIVE,
                )
            ],
        )

        style.configure(
            "TCheckbutton",
            background=self.BG,
            foreground=self.FG,
        )

        style.configure(
            "TSpinbox",
            fieldbackground=self.ENTRY_BG,
            background=self.PANEL,
            foreground=self.FG,
        )

        style.configure(
            "TCombobox",
            fieldbackground=self.ENTRY_BG,
            background=self.PANEL,
            foreground=self.FG,
        )

    # ========================================================================
    # Controls
    # ========================================================================

    def _create_controls(self):

        controls = ttk.Frame(
            self,
            padding=10,
        )

        controls.pack(
            side=tk.TOP,
            fill=tk.X,
        )

        # --------------------------------------------------------------------
        # Generator
        # --------------------------------------------------------------------

        ttk.Button(
            controls,
            text="Выбрать Rust DLL / EXE",
            command=self.select_generator,
        ).grid(
            row=0,
            column=0,
            padx=4,
            pady=4,
        )

        self.generator_label = ttk.Label(
            controls,
            text="Генератор не выбран",
            style="Secondary.TLabel",
        )

        self.generator_label.grid(
            row=0,
            column=1,
            columnspan=7,
            sticky="w",
            padx=8,
        )

        # --------------------------------------------------------------------
        # Planet seed
        # --------------------------------------------------------------------

        ttk.Label(
            controls,
            text="Planet seed:",
        ).grid(
            row=1,
            column=0,
            sticky="e",
        )

        ttk.Entry(
            controls,
            textvariable=self.seed_var,
            width=14,
        ).grid(
            row=1,
            column=1,
            padx=4,
        )

        ttk.Button(
            controls,
            text="Random Seed",
            command=self.random_seed,
        ).grid(
            row=1,
            column=2,
            padx=4,
        )

        # --------------------------------------------------------------------
        # Planet coordinates
        # --------------------------------------------------------------------

        ttk.Label(
            controls,
            text="Planet X:",
        ).grid(
            row=1,
            column=3,
            sticky="e",
        )

        ttk.Entry(
            controls,
            textvariable=self.x_var,
            width=8,
        ).grid(
            row=1,
            column=4,
            padx=4,
        )

        ttk.Label(
            controls,
            text="Planet Y:",
        ).grid(
            row=1,
            column=5,
            sticky="e",
        )

        ttk.Entry(
            controls,
            textvariable=self.y_var,
            width=8,
        ).grid(
            row=1,
            column=6,
            padx=4,
        )

        # --------------------------------------------------------------------
        # Local seed
        # --------------------------------------------------------------------

        ttk.Label(
            controls,
            text="Local seed:",
        ).grid(
            row=2,
            column=0,
            sticky="e",
        )

        ttk.Entry(
            controls,
            textvariable=self.local_seed_var,
            width=14,
        ).grid(
            row=2,
            column=1,
            padx=4,
        )

        ttk.Button(
            controls,
            text="Random Local",
            command=self.random_local_seed,
        ).grid(
            row=2,
            column=2,
            padx=4,
        )

        # --------------------------------------------------------------------
        # Size
        # --------------------------------------------------------------------

        ttk.Label(
            controls,
            text="Размер:",
        ).grid(
            row=2,
            column=3,
            sticky="e",
        )

        ttk.Combobox(
            controls,
            textvariable=self.size_var,
            values=(
                32,
                64,
                128,
                256,
                512,
            ),
            width=8,
            state="readonly",
        ).grid(
            row=2,
            column=4,
            padx=4,
        )

        # --------------------------------------------------------------------
        # Density bias
        # --------------------------------------------------------------------

        ttk.Label(
            controls,
            text="Density bias:",
        ).grid(
            row=3,
            column=0,
            sticky="e",
        )

        ttk.Entry(
            controls,
            textvariable=self.bias_var,
            width=14,
        ).grid(
            row=3,
            column=1,
            padx=4,
        )

        # --------------------------------------------------------------------
        # Smooth
        # --------------------------------------------------------------------

        ttk.Label(
            controls,
            text="Smooth passes:",
        ).grid(
            row=3,
            column=3,
            sticky="e",
        )

        ttk.Spinbox(
            controls,
            from_=0,
            to=20,
            textvariable=self.smooth_var,
            width=8,
        ).grid(
            row=3,
            column=4,
            padx=4,
        )

        # --------------------------------------------------------------------
        # Caves
        # --------------------------------------------------------------------

        ttk.Checkbutton(
            controls,
            text="Generate caves",
            variable=self.caves_var,
        ).grid(
            row=3,
            column=5,
            columnspan=2,
            sticky="w",
        )

        # --------------------------------------------------------------------
        # Neighbourhood
        # --------------------------------------------------------------------

        neighbourhood_frame = ttk.Frame(
            controls,
        )

        neighbourhood_frame.grid(
            row=1,
            column=7,
            rowspan=4,
            padx=(20, 5),
        )

        ttk.Label(
            neighbourhood_frame,
            text="Neighbourhood",
        ).grid(
            row=0,
            column=0,
            columnspan=3,
            pady=(0, 3),
        )

        for y in range(3):

            for x in range(3):

                check = ttk.Checkbutton(
                    neighbourhood_frame,
                    variable=self.neighbourhood_vars[y][x],
                    width=2,
                )

                check.grid(
                    row=y + 1,
                    column=x,
                    padx=1,
                    pady=1,
                )

        # --------------------------------------------------------------------
        # Generate
        # --------------------------------------------------------------------

        ttk.Button(
            controls,
            text="GENERATE",
            command=self.generate,
        ).grid(
            row=4,
            column=0,
            columnspan=8,
            sticky="ew",
            padx=4,
            pady=(10, 4),
        )

        # --------------------------------------------------------------------
        # Status
        # --------------------------------------------------------------------

        self.status_label = ttk.Label(
            controls,
            text="Готов.",
            style="Secondary.TLabel",
        )

        self.status_label.grid(
            row=5,
            column=0,
            columnspan=8,
            sticky="w",
            padx=4,
            pady=4,
        )

    # ========================================================================
    # Map
    # ========================================================================

    def _create_map(self):

        frame = tk.Frame(
            self,
            background=self.BG,
        )

        frame.pack(
            fill=tk.BOTH,
            expand=True,
            padx=10,
            pady=(0, 10),
        )

        self.map_canvas = tk.Canvas(
            frame,
            background="#080808",
            highlightthickness=1,
            highlightbackground=self.BORDER,
        )

        self.map_canvas.pack(
            fill=tk.BOTH,
            expand=True,
        )

        self.map_canvas.bind(
            "<Motion>",
            self.on_map_mouse,
        )

        self.map_canvas.bind(
            "<Configure>",
            self.on_canvas_resize,
        )

        self.map_info = ttk.Label(
            frame,
            text="X: -   Y: -   Height: -",
            style="Secondary.TLabel",
        )

        self.map_info.pack(
            side=tk.BOTTOM,
            anchor="w",
            pady=(5, 0),
        )

    # ========================================================================
    # Random seeds
    # ========================================================================

    def random_seed(self):

        self.seed_var.set(
            random.randint(
                0,
                2_147_483_647,
            )
        )

        # Заодно меняем local seed.
        self.local_seed_var.set(
            random.randint(
                0,
                2_147_483_647,
            )
        )

    def random_local_seed(self):

        self.local_seed_var.set(
            random.randint(
                0,
                2_147_483_647,
            )
        )

    # ========================================================================
    # Generator selection
    # ========================================================================

    def select_generator(self):

        path = filedialog.askopenfilename(
            title="Выберите Rust generator",
            filetypes=[
                (
                    "Rust generator",
                    "*.dll *.exe *.so *.dylib",
                ),
                (
                    "All files",
                    "*.*",
                ),
            ],
        )

        if not path:
            return

        self.generator_path = path

        self.generator_label.config(
            text=path
        )

        self.status_label.config(
            text="Генератор выбран."
        )

    # ========================================================================
    # Configuration
    # ========================================================================

    def get_config(self):

        # --------------------------------------------------------------------
        # Собираем neighbourhood 3x3 в плоский [u8; 9].
        #
        # Порядок:
        #
        # [0] [1] [2]
        # [3] [4] [5]
        # [6] [7] [8]
        #
        # Центр [4] — текущая планета.
        # --------------------------------------------------------------------

        neighbourhood = [
            int(
                self.neighbourhood_vars[y][x].get()
            )
            for y in range(3)
            for x in range(3)
        ]

        return {
            "planet_seed": int(
                self.seed_var.get()
            ),

            "planet_x": int(
                self.x_var.get()
            ),

            "planet_y": int(
                self.y_var.get()
            ),

            "local_seed": int(
                self.local_seed_var.get()
            ),

            "width": int(
                self.size_var.get()
            ),

            "height": int(
                self.size_var.get()
            ),

            "neighbourhood": neighbourhood,

            "density_bias": float(
                self.bias_var.get()
            ),

            "smooth_passes": int(
                self.smooth_var.get()
            ),

            # Rust ожидает String.
            "caves": (
                "caves_true"
                if self.caves_var.get()
                else "caves_false"
            ),
        }

    # ========================================================================
    # Generate
    # ========================================================================

    def generate(self):

        if not self.generator_path:

            messagebox.showerror(
                "Ошибка",
                "Сначала выбери Rust DLL или EXE.",
            )

            return

        try:

            self.status_label.config(
                text="Генерация..."
            )

            self.update_idletasks()

            config = self.get_config()

            heights, caves, elapsed = (
                GeneratorClient.run(
                    self.generator_path,
                    config,
                )
            )

            self.last_heights = heights
            self.last_caves = caves

            self.render_map(
                heights,
                caves,
            )

            minimum = float(
                np.min(heights)
            )

            maximum = float(
                np.max(heights)
            )

            average = float(
                np.mean(heights)
            )

            cave_count = int(
                np.count_nonzero(caves)
            )

            total = caves.size

            cave_percent = (
                cave_count / total * 100.0
                if total
                else 0.0
            )

            self.status_label.config(
                text=(
                    f"Generated in {elapsed:.2f} ms | "
                    f"Height: "
                    f"{minimum:.4f} .. {maximum:.4f} | "
                    f"Average: {average:.4f} | "
                    f"Caves: {cave_percent:.2f}%"
                )
            )

        except Exception as error:

            self.status_label.config(
                text="Ошибка генерации."
            )

            messagebox.showerror(
                "Rust Generator Error",
                str(error),
            )

    # ========================================================================
    # Render map
    # ========================================================================

    def render_map(
        self,
        heights,
        caves,
    ):

        rgb = HeightmapRenderer.height_to_rgb(
            heights
        )

        rgb = HeightmapRenderer.apply_caves(
            rgb,
            caves,
        )

        height, width, _ = rgb.shape

        # --------------------------------------------------------------------
        # PPM — позволяет Tkinter отображать NumPy RGB
        # без обязательной зависимости от Pillow.
        # --------------------------------------------------------------------

        header = (
            f"P6\n"
            f"{width} {height}\n"
            f"255\n"
        ).encode("ascii")

        image_data = (
            header
            + rgb.tobytes()
        )

        self.photo = tk.PhotoImage(
            data=image_data,
            format="PPM",
        )

        self.map_canvas.delete(
            "all"
        )

        self._fit_map_to_canvas()

    # ========================================================================
    # Fit map
    # ========================================================================

    def _fit_map_to_canvas(self):

        if self.photo is None:
            return

        canvas_width = max(
            1,
            self.map_canvas.winfo_width(),
        )

        canvas_height = max(
            1,
            self.map_canvas.winfo_height(),
        )

        image_width = self.photo.width()
        image_height = self.photo.height()

        scale_x = (
            canvas_width / image_width
        )

        scale_y = (
            canvas_height / image_height
        )

        scale = min(
            scale_x,
            scale_y,
        )

        if scale >= 2.0:

            zoom = max(
                1,
                int(scale),
            )

            self.display_photo = (
                self.photo.zoom(
                    zoom,
                    zoom,
                )
            )

        elif scale < 1.0:

            factor = max(
                1,
                int(
                    1.0 / scale
                ),
            )

            self.display_photo = (
                self.photo.subsample(
                    factor,
                    factor,
                )
            )

        else:

            self.display_photo = self.photo

        self.display_width = (
            self.display_photo.width()
        )

        self.display_height = (
            self.display_photo.height()
        )

        self.map_origin_x = (
            canvas_width
            - self.display_width
        ) / 2

        self.map_origin_y = (
            canvas_height
            - self.display_height
        ) / 2

        self.map_canvas.delete(
            "all"
        )

        self.map_canvas.create_image(
            canvas_width / 2,
            canvas_height / 2,
            image=self.display_photo,
            anchor=tk.CENTER,
        )

    # ========================================================================
    # Canvas resize
    # ========================================================================

    def on_canvas_resize(self, event):

        if self.photo is not None:
            self._fit_map_to_canvas()

    # ========================================================================
    # Mouse
    # ========================================================================

    def on_map_mouse(self, event):

        if self.last_heights is None:
            return

        if self.display_photo is None:
            return

        height, width = (
            self.last_heights.shape
        )

        px = (
            event.x
            - self.map_origin_x
        )

        py = (
            event.y
            - self.map_origin_y
        )

        if px < 0 or py < 0:
            return

        if px >= self.display_width:
            return

        if py >= self.display_height:
            return

        x = int(
            px
            * width
            / self.display_width
        )

        y = int(
            py
            * height
            / self.display_height
        )

        x = max(
            0,
            min(
                width - 1,
                x,
            ),
        )

        y = max(
            0,
            min(
                height - 1,
                y,
            ),
        )

        value = float(
            self.last_heights[y, x]
        )

        cave = bool(
            self.last_caves[y, x]
        )

        self.map_info.config(
            text=(
                f"X: {x}   "
                f"Y: {y}   "
                f"Height: {value:.6f}   "
                f"Cave: {'YES' if cave else 'NO'}"
            )
        )


# ============================================================================
# Main
# ============================================================================

if __name__ == "__main__":

    app = GeneratorTester()

    app.mainloop()
