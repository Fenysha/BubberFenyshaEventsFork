import ctypes
import json
import random
import subprocess
import time
import tkinter as tk
from tkinter import filedialog, messagebox, ttk
from pathlib import Path

import numpy as np


# ============================================================================
# Elevation Constants
# ============================================================================

ELEV_TYPES = [
    (0, "0: Ocean"),
    (1, "1: Coast"),
    (2, "2: Lowland"),
    (3, "3: Highland"),
    (4, "4: Mountain"),
    (5, "5: Snow"),
]

ELEV_LABELS = [label for _, label in ELEV_TYPES]

BIOMES = [
    "ocean", "beach", "coasts", "sea_ice",
    "tundra", "taiga", "temperate_forest", "grassland",
    "savanna", "desert", "tropical_forest", "rainforest",
    "mountains", "snow", "river", "lake",
]

SUB_BIOMES = [
    "deep_ocean", "frozen_ocean", "shore",
    "plains", "hills", "rocky_hills",
    "forest", "forest_hills",
    "tundra_plains", "snowfields", "marsh",
]


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
                f"В DLL '{dll_path.name}' не найдена функция '{GeneratorClient.FUNC_NAME}'."
            )

        func = getattr(dll, GeneratorClient.FUNC_NAME)
        func.argtypes = [ctypes.c_size_t, ctypes.POINTER(ctypes.c_char_p)]
        func.restype = ctypes.c_char_p

        arg = ctypes.c_char_p(config_json.encode("utf-8"))
        argv = (ctypes.c_char_p * 1)(arg)

        result_ptr = func(1, argv)
        if not result_ptr:
            raise RuntimeError("Rust-функция вернула NULL.")

        return ctypes.string_at(result_ptr)

    @staticmethod
    def _call_cli(exe_path: Path, config_json: str) -> bytes:
        process = subprocess.run(
            [str(exe_path), config_json],
            capture_output=True,
            check=False,
        )

        if process.returncode != 0:
            stderr = process.stderr.decode("utf-8", errors="replace")
            raise RuntimeError(
                f"Rust EXE завершился с кодом {process.returncode}:\n{stderr}"
            )

        return process.stdout

    @staticmethod
    def run(generator_path: str, config: dict):
        path = Path(generator_path)
        if not path.exists():
            raise FileNotFoundError(f"Файл не найден:\n{path}")

        config_json = json.dumps(config, separators=(",", ":"))
        start = time.perf_counter()

        if path.suffix.lower() in (".dll", ".so", ".dylib"):
            stdout_bytes = GeneratorClient._call_dll(path, config_json)
        else:
            stdout_bytes = GeneratorClient._call_cli(path, config_json)

        elapsed_ms = (time.perf_counter() - start) * 1000.0
        raw_text = stdout_bytes.decode("utf-8", errors="replace").strip()

        try:
            result = json.loads(raw_text)
        except json.JSONDecodeError as error:
            raise RuntimeError(
                "Rust вернул некорректный JSON:\n\n" + raw_text[:2000]
            ) from error

        if isinstance(result, str):
            if result.startswith("ERROR:"):
                raise RuntimeError(result)
            raise RuntimeError("Rust вернул строку вместо объекта:\n" + result)

        if not isinstance(result, dict):
            raise RuntimeError("Неожиданный формат ответа Rust.")

        if result.get("status") != "ok":
            raise RuntimeError(
                "Генератор Rust сообщил об ошибке:\n"
                + json.dumps(result, ensure_ascii=False, indent=2)
            )

        width = int(result["width"])
        height = int(result["height"])
        expected_size = width * height

        height_data = result.get("heights")
        if height_data is None:
            raise RuntimeError("В ответе Rust отсутствует 'heights'.")

        if len(height_data) != expected_size:
            raise RuntimeError(
                f"Неверный размер heights: {len(height_data)}, ожидалось {expected_size}."
            )

        heights = np.asarray(height_data, dtype=np.float32).reshape((height, width))

        cave_data = result.get("cave_mask")
        if cave_data is None:
            cave_mask = np.zeros((height, width), dtype=np.uint8)
        else:
            if len(cave_data) != expected_size:
                raise RuntimeError(
                    f"Неверный размер cave_mask: {len(cave_data)}, ожидалось {expected_size}."
                )
            cave_mask = np.asarray(cave_data, dtype=np.uint8).reshape((height, width))

        meta = result.get("meta", {})
        return heights, cave_mask, elapsed_ms, meta


# ============================================================================
# Heightmap renderer
# ============================================================================


class HeightmapRenderer:
    # Dark ocean -> coast -> vegetation -> highlands -> rock -> snow.
    PALETTE = np.array(
        [
            [9, 20, 34],       # deep water
            [18, 54, 81],      # water
            [43, 111, 126],    # shallow / coast
            [92, 143, 96],     # lowland
            [139, 153, 82],    # dry lowland
            [158, 132, 76],    # highland
            [120, 91, 72],     # mountain
            [174, 168, 158],   # high mountain
            [231, 236, 233],   # snow
        ],
        dtype=np.float32,
    )

    @staticmethod
    def _interpolate_palette(values: np.ndarray) -> np.ndarray:
        values = np.clip(values, 0.0, 1.0)
        scaled = values * (len(HeightmapRenderer.PALETTE) - 1)
        index0 = np.floor(scaled).astype(np.int32)
        index1 = np.minimum(index0 + 1, len(HeightmapRenderer.PALETTE) - 1)
        blend = (scaled - index0)[..., None]

        rgb = (
            HeightmapRenderer.PALETTE[index0] * (1.0 - blend)
            + HeightmapRenderer.PALETTE[index1] * blend
        )
        return np.clip(rgb, 0, 255).astype(np.uint8)

    @staticmethod
    def height_to_rgb(heights: np.ndarray) -> np.ndarray:
        minimum = float(np.min(heights))
        maximum = float(np.max(heights))

        if maximum - minimum < 1e-6:
            normalized = np.zeros_like(heights, dtype=np.float32)
        else:
            normalized = (heights - minimum) / (maximum - minimum)

        return HeightmapRenderer._interpolate_palette(normalized)

    @staticmethod
    def apply_caves(rgb: np.ndarray, cave_mask: np.ndarray) -> np.ndarray:
        caves = cave_mask != 0
        if not np.any(caves):
            return rgb

        result = rgb.copy().astype(np.float32)
        result[caves] *= 0.38

        # Add a subtle blue-violet tint instead of making caves simply black.
        result[caves, 2] = np.minimum(result[caves, 2] + 10.0, 255.0)
        return result.astype(np.uint8)

    @staticmethod
    def threshold_mask(heights: np.ndarray, threshold: float) -> np.ndarray:
        mask = heights >= threshold
        rgb = np.zeros((*heights.shape, 3), dtype=np.uint8)
        rgb[~mask] = (10, 18, 29)

        if np.any(mask):
            above = heights[mask]
            if above.max() > above.min():
                norm = (above - above.min()) / (above.max() - above.min() + 1e-8)
            else:
                norm = np.ones_like(above)

            rgb[mask, 0] = (34 + norm * 45).astype(np.uint8)
            rgb[mask, 1] = (126 + norm * 105).astype(np.uint8)
            rgb[mask, 2] = (137 + norm * 80).astype(np.uint8)

        return rgb


# ============================================================================
# Main Application
# ============================================================================


class GeneratorTester(tk.Tk):
    # UI palette.
    BG = "#0B1018"
    PANEL = "#111923"
    PANEL_ALT = "#0F161F"
    PANEL_HOVER = "#172231"
    MAP_BG = "#070C12"
    INPUT_BG = "#0A111A"
    BORDER = "#253342"
    BORDER_SOFT = "#1B2734"
    FG = "#E7EEF5"
    FG_SECONDARY = "#8998A8"
    FG_DIM = "#627183"
    ACCENT = "#46B7D8"
    ACCENT_HOVER = "#5BC9E8"
    ACCENT_DARK = "#173642"
    SUCCESS = "#65C18C"
    WARNING = "#D7A85F"
    ERROR = "#D87272"

    FONT = "Segoe UI"
    MONO = "Consolas"

    def __init__(self):
        super().__init__()

        self.title("Tartarus Planet Generator — Tester")
        self.geometry("1440x920")
        self.minsize(1180, 760)
        self.configure(background=self.BG)

        self.generator_path = None
        self.last_heights = None
        self.last_caves = None
        self.last_meta = {}

        self.photo = None
        self.display_photo = None
        self.display_width = 0
        self.display_height = 0
        self.map_origin_x = 0
        self.map_origin_y = 0
        self.map_scale_mode = "fit"

        self._create_variables()
        self._create_styles()
        self._build_layout()
        self._draw_empty_map()

    # ------------------------------------------------------------------------
    # Variables
    # ------------------------------------------------------------------------

    def _create_variables(self):
        self.seed_var = tk.IntVar(value=random.randint(0, 2_147_483_647))
        self.x_var = tk.IntVar(value=0)
        self.y_var = tk.IntVar(value=0)
        self.local_seed_var = tk.IntVar(value=0)
        self.size_var = tk.IntVar(value=128)
        self.bias_var = tk.DoubleVar(value=0.0)
        self.smooth_var = tk.IntVar(value=1)
        self.caves_var = tk.BooleanVar(value=True)

        self.biome_var = tk.StringVar(value="grassland")
        self.sub_biome_var = tk.StringVar(value="plains")

        self.threshold_mode_var = tk.BooleanVar(value=False)
        self.threshold_var = tk.DoubleVar(value=0.40)

        self.neighbourhood_vars = []
        for y in range(3):
            row = []
            for x in range(3):
                default_val = 4 if (x == 1 and y == 1) else 2
                row.append(tk.IntVar(value=default_val))
            self.neighbourhood_vars.append(row)

    # ------------------------------------------------------------------------
    # ttk styles
    # ------------------------------------------------------------------------

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
            font=(self.FONT, 9),
        )

        style.configure(
            "Dark.TCombobox",
            fieldbackground=self.INPUT_BG,
            background=self.PANEL,
            foreground=self.FG,
            bordercolor=self.BORDER,
            lightcolor=self.BORDER,
            darkcolor=self.BORDER,
            arrowcolor=self.FG_SECONDARY,
            padding=4,
        )
        style.map(
            "Dark.TCombobox",
            fieldbackground=[("readonly", self.INPUT_BG)],
            foreground=[("readonly", self.FG)],
            selectbackground=[("readonly", self.ACCENT_DARK)],
            selectforeground=[("readonly", self.FG)],
            arrowcolor=[("active", self.ACCENT), ("readonly", self.FG_SECONDARY)],
        )

        style.configure(
            "Dark.TSpinbox",
            fieldbackground=self.INPUT_BG,
            background=self.PANEL,
            foreground=self.FG,
            bordercolor=self.BORDER,
            lightcolor=self.BORDER,
            darkcolor=self.BORDER,
            arrowcolor=self.FG_SECONDARY,
            padding=3,
        )

        style.configure(
            "Dark.Horizontal.TScale",
            troughcolor=self.INPUT_BG,
            background=self.PANEL,
            sliderlength=16,
        )

        style.configure(
            "Vertical.TScrollbar",
            background=self.PANEL_ALT,
            troughcolor=self.PANEL,
            bordercolor=self.PANEL,
            arrowcolor=self.FG_DIM,
        )
        style.map(
            "Vertical.TScrollbar",
            background=[("active", self.PANEL_HOVER)],
        )

    # ------------------------------------------------------------------------
    # Small UI helpers
    # ------------------------------------------------------------------------

    def _card(self, parent, title, subtitle=None):
        frame = tk.Frame(
            parent,
            bg=self.PANEL,
            highlightthickness=1,
            highlightbackground=self.BORDER_SOFT,
            highlightcolor=self.BORDER,
        )

        header = tk.Frame(frame, bg=self.PANEL)
        header.pack(fill=tk.X, padx=12, pady=(10, 7))

        tk.Label(
            header,
            text=title.upper(),
            bg=self.PANEL,
            fg=self.FG,
            font=(self.FONT, 9, "bold"),
        ).pack(anchor="w")

        if subtitle:
            tk.Label(
                header,
                text=subtitle,
                bg=self.PANEL,
                fg=self.FG_DIM,
                font=(self.FONT, 8),
            ).pack(anchor="w", pady=(2, 0))

        body = tk.Frame(frame, bg=self.PANEL)
        body.pack(fill=tk.X, padx=12, pady=(0, 11))
        return frame, body

    def _label(self, parent, text, dim=False):
        return tk.Label(
            parent,
            text=text,
            bg=self.PANEL,
            fg=self.FG_DIM if dim else self.FG_SECONDARY,
            font=(self.FONT, 8),
        )

    def _entry(self, parent, variable, width=12):
        entry = tk.Entry(
            parent,
            textvariable=variable,
            width=width,
            bg=self.INPUT_BG,
            fg=self.FG,
            insertbackground=self.ACCENT,
            selectbackground=self.ACCENT_DARK,
            selectforeground=self.FG,
            relief=tk.FLAT,
            highlightthickness=1,
            highlightbackground=self.BORDER,
            highlightcolor=self.ACCENT,
            font=(self.MONO, 9),
        )
        return entry

    def _button(self, parent, text, command, accent=False, compact=False):
        bg = self.ACCENT_DARK if accent else self.PANEL_ALT
        hover = self.ACCENT if accent else self.PANEL_HOVER
        fg = self.FG

        button = tk.Button(
            parent,
            text=text,
            command=command,
            bg=bg,
            fg=fg,
            activebackground=hover,
            activeforeground=self.FG,
            relief=tk.FLAT,
            bd=0,
            cursor="hand2",
            padx=10 if not compact else 7,
            pady=6 if not compact else 4,
            font=(self.FONT, 8, "bold" if accent else "normal"),
            highlightthickness=1,
            highlightbackground=self.BORDER,
            highlightcolor=self.ACCENT if accent else self.BORDER,
        )

        button.bind("<Enter>", lambda _: button.configure(bg=hover))
        button.bind("<Leave>", lambda _: button.configure(bg=bg))
        return button

    # ------------------------------------------------------------------------
    # Layout
    # ------------------------------------------------------------------------

    def _build_layout(self):
        root = tk.Frame(self, bg=self.BG)
        root.pack(fill=tk.BOTH, expand=True, padx=12, pady=12)

        self._build_header(root)

        content = tk.Frame(root, bg=self.BG)
        content.pack(fill=tk.BOTH, expand=True, pady=(10, 0))

        self._build_sidebar(content)
        self._build_map_area(content)

    def _build_header(self, parent):
        header = tk.Frame(parent, bg=self.BG, height=54)
        header.pack(fill=tk.X)
        header.pack_propagate(False)

        left = tk.Frame(header, bg=self.BG)
        left.pack(side=tk.LEFT, fill=tk.Y)

        tk.Label(
            left,
            text="TARTARUS",
            bg=self.BG,
            fg=self.ACCENT,
            font=(self.MONO, 9, "bold"),
        ).pack(anchor="w")
        tk.Label(
            left,
            text="PLANET GENERATOR",
            bg=self.BG,
            fg=self.FG,
            font=(self.FONT, 16, "bold"),
        ).pack(anchor="w", pady=(1, 0))

        right = tk.Frame(header, bg=self.BG)
        right.pack(side=tk.RIGHT, fill=tk.Y)

        status = tk.Frame(right, bg=self.PANEL, padx=10, pady=7)
        status.pack(anchor="e", pady=3)

        self.status_dot = tk.Label(
            status,
            text="●",
            bg=self.PANEL,
            fg=self.FG_DIM,
            font=(self.MONO, 9),
        )
        self.status_dot.pack(side=tk.LEFT, padx=(0, 7))

        self.header_status = tk.Label(
            status,
            text="IDLE",
            bg=self.PANEL,
            fg=self.FG_SECONDARY,
            font=(self.MONO, 8, "bold"),
        )
        self.header_status.pack(side=tk.LEFT)

    def _build_sidebar(self, parent):
        sidebar_outer = tk.Frame(parent, bg=self.PANEL, width=324)
        sidebar_outer.pack(side=tk.LEFT, fill=tk.Y, padx=(0, 10))
        sidebar_outer.pack_propagate(False)

        canvas = tk.Canvas(
            sidebar_outer,
            bg=self.PANEL,
            highlightthickness=0,
            bd=0,
        )
        scrollbar = ttk.Scrollbar(sidebar_outer, orient="vertical", command=canvas.yview)
        canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        self.sidebar = tk.Frame(canvas, bg=self.PANEL)
        window_id = canvas.create_window((0, 0), window=self.sidebar, anchor="nw")

        def _update_scroll(_=None):
            canvas.configure(scrollregion=canvas.bbox("all"))
            canvas.itemconfigure(window_id, width=canvas.winfo_width())

        self.sidebar.bind("<Configure>", _update_scroll)
        canvas.bind("<Configure>", _update_scroll)
        canvas.configure(yscrollcommand=scrollbar.set)

        def _wheel(event):
            canvas.yview_scroll(int(-1 * (event.delta / 120)), "units")

        canvas.bind("<Enter>", lambda _: canvas.bind_all("<MouseWheel>", _wheel))
        canvas.bind("<Leave>", lambda _: canvas.unbind_all("<MouseWheel>"))

        body = tk.Frame(self.sidebar, bg=self.PANEL)
        body.pack(fill=tk.X, padx=12, pady=12)
        self._build_sidebar_controls(body)

    def _build_sidebar_controls(self, parent):
        self._build_generator_card(parent)
        self._build_seed_card(parent)
        self._build_biome_card(parent)
        self._build_generation_card(parent)
        self._build_neighbourhood_card(parent)
        self._build_threshold_card(parent)
        self._build_generate_block(parent)

    def _build_generator_card(self, parent):
        card, body = self._card(
            parent,
            "Generator binary",
            "Rust dynamic library or standalone executable",
        )
        card.pack(fill=tk.X, pady=(0, 8))

        self._button(
            body,
            "SELECT DLL / EXE",
            self.select_generator,
            accent=True,
        ).pack(fill=tk.X)

        path_row = tk.Frame(body, bg=self.PANEL)
        path_row.pack(fill=tk.X, pady=(8, 0))

        self.generator_dot = tk.Label(
            path_row,
            text="●",
            bg=self.PANEL,
            fg=self.FG_DIM,
            font=(self.MONO, 8),
        )
        self.generator_dot.pack(side=tk.LEFT, padx=(0, 6))

        self.generator_label = tk.Label(
            path_row,
            text="No generator selected",
            bg=self.PANEL,
            fg=self.FG_DIM,
            anchor="w",
            font=(self.MONO, 8),
        )
        self.generator_label.pack(side=tk.LEFT, fill=tk.X, expand=True)

    def _build_seed_card(self, parent):
        card, body = self._card(
            parent,
            "Seeds & coordinates",
            "Planet-level and local generation context",
        )
        card.pack(fill=tk.X, pady=(0, 8))

        grid = tk.Frame(body, bg=self.PANEL)
        grid.pack(fill=tk.X)
        grid.columnconfigure(1, weight=1)

        labels = [
            ("Planet seed", self.seed_var, self.random_seed),
            ("Local seed", self.local_seed_var, self.random_local_seed),
        ]

        for row, (text, var, random_cmd) in enumerate(labels):
            self._label(grid, text).grid(row=row, column=0, sticky="w", pady=3)
            self._entry(grid, var, width=14).grid(
                row=row, column=1, sticky="ew", padx=(10, 6), pady=3
            )
            self._button(grid, "R", random_cmd, compact=True).grid(
                row=row, column=2, pady=3
            )

        self._label(grid, "Coordinate").grid(row=2, column=0, sticky="w", pady=3)
        coords = tk.Frame(grid, bg=self.PANEL)
        coords.grid(row=2, column=1, columnspan=2, sticky="ew", padx=(10, 0), pady=3)
        coords.columnconfigure(0, weight=1)
        coords.columnconfigure(2, weight=1)

        self._entry(coords, self.x_var, width=6).grid(row=0, column=0, sticky="ew")
        tk.Label(coords, text="×", bg=self.PANEL, fg=self.FG_DIM, font=(self.MONO, 9)).grid(
            row=0, column=1, padx=6
        )
        self._entry(coords, self.y_var, width=6).grid(row=0, column=2, sticky="ew")

    def _build_biome_card(self, parent):
        card, body = self._card(
            parent,
            "Biome context",
            "Passed unchanged to the Rust generator",
        )
        card.pack(fill=tk.X, pady=(0, 8))

        self._label(body, "Biome").pack(anchor="w")
        ttk.Combobox(
            body,
            textvariable=self.biome_var,
            values=BIOMES,
            state="readonly",
            style="Dark.TCombobox",
        ).pack(fill=tk.X, pady=(4, 9))

        self._label(body, "Sub-biome").pack(anchor="w")
        ttk.Combobox(
            body,
            textvariable=self.sub_biome_var,
            values=SUB_BIOMES,
            state="readonly",
            style="Dark.TCombobox",
        ).pack(fill=tk.X, pady=(4, 0))

    def _build_generation_card(self, parent):
        card, body = self._card(
            parent,
            "Generation parameters",
            "Local heightmap controls",
        )
        card.pack(fill=tk.X, pady=(0, 8))

        row = tk.Frame(body, bg=self.PANEL)
        row.pack(fill=tk.X, pady=3)
        row.columnconfigure(1, weight=1)
        self._label(row, "Map size").grid(row=0, column=0, sticky="w")
        ttk.Combobox(
            row,
            textvariable=self.size_var,
            values=(32, 64, 128, 256, 512),
            state="readonly",
            width=8,
            style="Dark.TCombobox",
        ).grid(row=0, column=1, sticky="e")

        row2 = tk.Frame(body, bg=self.PANEL)
        row2.pack(fill=tk.X, pady=3)
        row2.columnconfigure(1, weight=1)
        self._label(row2, "Smooth passes").grid(row=0, column=0, sticky="w")
        ttk.Spinbox(
            row2,
            from_=0,
            to=3,
            textvariable=self.smooth_var,
            width=8,
            style="Dark.TSpinbox",
        ).grid(row=0, column=1, sticky="e")

        bias_title = tk.Frame(body, bg=self.PANEL)
        bias_title.pack(fill=tk.X, pady=(7, 2))
        self._label(bias_title, "Density bias").pack(side=tk.LEFT)
        self.bias_value_label = tk.Label(
            bias_title,
            text="+0.000",
            bg=self.PANEL,
            fg=self.FG,
            font=(self.MONO, 8),
        )
        self.bias_value_label.pack(side=tk.RIGHT)

        ttk.Scale(
            body,
            from_=-0.5,
            to=0.5,
            variable=self.bias_var,
            orient=tk.HORIZONTAL,
            style="Dark.Horizontal.TScale",
            command=self._on_bias_changed,
        ).pack(fill=tk.X, pady=(0, 7))

        caves_row = tk.Frame(body, bg=self.PANEL)
        caves_row.pack(fill=tk.X, pady=(2, 0))

        self.caves_check = tk.Checkbutton(
            caves_row,
            text="Generate caves",
            variable=self.caves_var,
            bg=self.PANEL,
            fg=self.FG_SECONDARY,
            activebackground=self.PANEL,
            activeforeground=self.FG,
            selectcolor=self.INPUT_BG,
            highlightthickness=0,
            bd=0,
            font=(self.FONT, 8),
        )
        self.caves_check.pack(anchor="w")

    def _build_neighbourhood_card(self, parent):
        card, body = self._card(
            parent,
            "3×3 elevation neighbourhood",
            "Centre cell is the active sub-level",
        )
        card.pack(fill=tk.X, pady=(0, 8))

        self.combo_grid = []
        n_grid = tk.Frame(body, bg=self.PANEL)
        n_grid.pack(fill=tk.X, pady=(2, 6))

        for y in range(3):
            row_combos = []
            for x in range(3):
                cell = tk.Frame(
                    n_grid,
                    bg=self.ACCENT_DARK if (x == 1 and y == 1) else self.INPUT_BG,
                    padx=2,
                    pady=2,
                    highlightthickness=1,
                    highlightbackground=self.ACCENT if (x == 1 and y == 1) else self.BORDER,
                )
                cell.grid(row=y, column=x, padx=2, pady=2, sticky="nsew")
                n_grid.columnconfigure(x, weight=1)

                cb = ttk.Combobox(
                    cell,
                    values=ELEV_LABELS,
                    width=9,
                    state="readonly",
                    style="Dark.TCombobox",
                )
                cb.current(self.neighbourhood_vars[y][x].get())
                cb.pack(fill=tk.X)
                cb.bind(
                    "<<ComboboxSelected>>",
                    lambda e, rx=x, ry=y, widget=cb: self._on_neigh_change(rx, ry, widget),
                )
                row_combos.append(cb)
            self.combo_grid.append(row_combos)

        presets = tk.Frame(body, bg=self.PANEL)
        presets.pack(fill=tk.X)

        for text, command in (
            ("Mountain", lambda: self._apply_preset(4, 2)),
            ("Island", lambda: self._apply_preset(2, 0)),
            ("Plain", lambda: self._apply_preset(2, 2)),
            ("Basin", lambda: self._apply_preset(2, 4)),
        ):
            self._button(presets, text, command, compact=True).pack(
                side=tk.LEFT, fill=tk.X, expand=True, padx=2
            )

    def _build_threshold_card(self, parent):
        card, body = self._card(
            parent,
            "Threshold viewer",
            "Visualize the height coverage above a threshold",
        )
        card.pack(fill=tk.X, pady=(0, 8))

        mode_row = tk.Frame(body, bg=self.PANEL)
        mode_row.pack(fill=tk.X)

        self.threshold_check = tk.Checkbutton(
            mode_row,
            text="Enable threshold mode",
            variable=self.threshold_mode_var,
            command=self._on_threshold_changed,
            bg=self.PANEL,
            fg=self.FG,
            activebackground=self.PANEL,
            activeforeground=self.FG,
            selectcolor=self.INPUT_BG,
            highlightthickness=0,
            bd=0,
            font=(self.FONT, 8, "bold"),
        )
        self.threshold_check.pack(side=tk.LEFT)

        self.threshold_label = tk.Label(
            mode_row,
            text="0.40",
            bg=self.PANEL,
            fg=self.ACCENT,
            font=(self.MONO, 9, "bold"),
        )
        self.threshold_label.pack(side=tk.RIGHT)

        ttk.Scale(
            body,
            from_=0.0,
            to=1.0,
            variable=self.threshold_var,
            orient=tk.HORIZONTAL,
            style="Dark.Horizontal.TScale",
            command=self._on_threshold_changed,
        ).pack(fill=tk.X, pady=(7, 0))

    def _build_generate_block(self, parent):
        action = tk.Frame(parent, bg=self.PANEL)
        action.pack(fill=tk.X, pady=(2, 0))

        self.generate_button = self._button(
            action,
            "GENERATE HEIGHTMAP",
            self.generate,
            accent=True,
        )
        self.generate_button.pack(fill=tk.X)

        self.status_label = tk.Label(
            action,
            text="Select a generator and run a test generation.",
            bg=self.PANEL,
            fg=self.FG_DIM,
            justify="left",
            anchor="w",
            font=(self.FONT, 8),
        )
        self.status_label.pack(fill=tk.X, pady=(9, 4))

    def _build_map_area(self, parent):
        map_outer = tk.Frame(parent, bg=self.BG)
        map_outer.pack(side=tk.RIGHT, fill=tk.BOTH, expand=True)

        toolbar = tk.Frame(map_outer, bg=self.PANEL, height=42)
        toolbar.pack(fill=tk.X)
        toolbar.pack_propagate(False)

        left = tk.Frame(toolbar, bg=self.PANEL)
        left.pack(side=tk.LEFT, fill=tk.Y, padx=12)
        tk.Label(
            left,
            text="HEIGHTMAP VIEWPORT",
            bg=self.PANEL,
            fg=self.FG,
            font=(self.FONT, 9, "bold"),
        ).pack(side=tk.LEFT, pady=11)
        self.map_mode_label = tk.Label(
            left,
            text="FIT",
            bg=self.PANEL,
            fg=self.ACCENT,
            font=(self.MONO, 8, "bold"),
        )
        self.map_mode_label.pack(side=tk.LEFT, padx=(9, 0))

        right = tk.Frame(toolbar, bg=self.PANEL)
        right.pack(side=tk.RIGHT, fill=tk.Y, padx=8)
        self._button(right, "FIT", self.fit_map, compact=True).pack(side=tk.LEFT, padx=2, pady=6)
        self._button(right, "1:1", self.actual_size_map, compact=True).pack(side=tk.LEFT, padx=2, pady=6)

        viewport = tk.Frame(
            map_outer,
            bg=self.MAP_BG,
            highlightthickness=1,
            highlightbackground=self.BORDER,
        )
        viewport.pack(fill=tk.BOTH, expand=True, pady=(8, 0))

        self.map_canvas = tk.Canvas(
            viewport,
            background=self.MAP_BG,
            highlightthickness=0,
            bd=0,
        )
        self.map_canvas.pack(fill=tk.BOTH, expand=True)

        footer = tk.Frame(map_outer, bg=self.PANEL, height=66)
        footer.pack(fill=tk.X, pady=(8, 0))
        footer.pack_propagate(False)

        info_left = tk.Frame(footer, bg=self.PANEL)
        info_left.pack(side=tk.LEFT, fill=tk.Y, padx=12)

        self.map_info = tk.Label(
            info_left,
            text="X: —    Y: —    HEIGHT: —    CAVE: —",
            bg=self.PANEL,
            fg=self.FG,
            font=(self.MONO, 9, "bold"),
        )
        self.map_info.pack(anchor="w", pady=(11, 0))

        self.map_meta_info = tk.Label(
            info_left,
            text="No generated map",
            bg=self.PANEL,
            fg=self.FG_DIM,
            font=(self.FONT, 8),
        )
        self.map_meta_info.pack(anchor="w", pady=(3, 0))

        legend = tk.Frame(footer, bg=self.PANEL)
        legend.pack(side=tk.RIGHT, fill=tk.Y, padx=12)

        tk.Label(
            legend,
            text="LOW",
            bg=self.PANEL,
            fg=self.FG_DIM,
            font=(self.MONO, 7),
        ).pack(anchor="w")

        self.legend_canvas = tk.Canvas(
            legend,
            width=220,
            height=14,
            bg=self.PANEL,
            highlightthickness=0,
            bd=0,
        )
        self.legend_canvas.pack(anchor="w")
        self._draw_legend()

        self.map_canvas.bind("<Motion>", self.on_map_mouse)
        self.map_canvas.bind("<Configure>", self.on_canvas_resize)
        self.map_canvas.bind("<Leave>", self._on_map_leave)

    # ------------------------------------------------------------------------
    # Legend / empty viewport
    # ------------------------------------------------------------------------

    def _draw_legend(self):
        self.legend_canvas.delete("all")
        colors = HeightmapRenderer.PALETTE.astype(np.uint8)
        width = 220
        steps = 100
        for i in range(steps):
            position = i / max(1, steps - 1)
            index = int(position * (len(colors) - 1))
            x0 = i * width / steps
            x1 = (i + 1) * width / steps + 1
            color = "#%02X%02X%02X" % tuple(colors[index])
            self.legend_canvas.create_rectangle(
                x0, 1, x1, 13, fill=color, outline=color
            )
        self.legend_canvas.create_rectangle(0, 1, width, 13, outline=self.BORDER)

        labels = tk.Frame(self.legend_canvas.master, bg=self.PANEL)
        labels.place(relx=0, rely=1.0, y=-1, anchor="sw", width=220, height=1)

    def _draw_empty_map(self):
        self.map_canvas.delete("all")
        canvas_w = max(1, self.map_canvas.winfo_width())
        canvas_h = max(1, self.map_canvas.winfo_height())
        cx = canvas_w / 2
        cy = canvas_h / 2

        self.map_canvas.create_oval(
            cx - 52,
            cy - 52,
            cx + 52,
            cy + 52,
            outline=self.BORDER,
            width=1,
        )
        self.map_canvas.create_text(
            cx,
            cy - 7,
            text="NO HEIGHTMAP",
            fill=self.FG_SECONDARY,
            font=(self.MONO, 10, "bold"),
        )
        self.map_canvas.create_text(
            cx,
            cy + 16,
            text="generate a map to inspect terrain",
            fill=self.FG_DIM,
            font=(self.FONT, 8),
        )

    # ------------------------------------------------------------------------
    # Helpers / interaction
    # ------------------------------------------------------------------------

    def _on_bias_changed(self, value):
        self.bias_value_label.config(text=f"{float(value):+.3f}")

    def _on_neigh_change(self, x, y, widget):
        self.neighbourhood_vars[y][x].set(widget.current())

    def _apply_preset(self, center: int, outer: int):
        for y in range(3):
            for x in range(3):
                val = center if (x == 1 and y == 1) else outer
                self.neighbourhood_vars[y][x].set(val)
                self.combo_grid[y][x].current(val)

    def random_seed(self):
        self.seed_var.set(random.randint(0, 2_147_483_647))

    def random_local_seed(self):
        self.local_seed_var.set(random.randint(0, 2_147_483_647))

    def select_generator(self):
        path = filedialog.askopenfilename(
            title="Choose Rust generator",
            filetypes=[
                ("Rust generator", "*.dll *.exe *.so *.dylib"),
                ("All files", "*.*"),
            ],
        )
        if not path:
            return

        self.generator_path = path
        p = Path(path)
        self.generator_label.config(text=p.name, fg=self.FG)
        self.generator_dot.config(fg=self.SUCCESS)
        self.header_status.config(text="READY", fg=self.SUCCESS)
        self.status_dot.config(fg=self.SUCCESS)
        self.status_label.config(text=f"Generator selected:\n{p.name}", fg=self.FG_SECONDARY)

    def get_config(self) -> dict:
        neighbourhood = [
            int(self.neighbourhood_vars[y][x].get())
            for y in range(3)
            for x in range(3)
        ]

        return {
            "planet_seed": int(self.seed_var.get()),
            "planet_x": int(self.x_var.get()),
            "planet_y": int(self.y_var.get()),
            "local_seed": int(self.local_seed_var.get()),
            "width": int(self.size_var.get()),
            "height": int(self.size_var.get()),
            "neighbourhood": neighbourhood,
            "biome": self.biome_var.get(),
            "sub_biome": self.sub_biome_var.get(),
            "density_bias": round(float(self.bias_var.get()), 3),
            "smooth_passes": int(self.smooth_var.get()),
            "caves": "caves_true" if self.caves_var.get() else "caves_false",
        }

    def _on_threshold_changed(self, *_):
        value = float(self.threshold_var.get())
        self.threshold_label.config(text=f"{value:.2f}")

        if self.last_heights is not None:
            self.render_map(self.last_heights, self.last_caves)

    def generate(self):
        if not self.generator_path:
            messagebox.showerror("Ошибка", "Сначала выберите DLL или EXE генератора.")
            return

        try:
            self._set_running_state(True)
            self.update_idletasks()

            config = self.get_config()
            heights, caves, elapsed, meta = GeneratorClient.run(
                self.generator_path,
                config,
            )

            self.last_heights = heights
            self.last_caves = caves
            self.last_meta = meta

            self.render_map(heights, caves)

            minimum = float(np.min(heights))
            maximum = float(np.max(heights))
            cave_count = int(np.count_nonzero(caves))
            cave_pct = (cave_count / caves.size) * 100.0 if caves.size else 0.0
            water_count = int(np.sum(heights <= 0.18))
            water_pct = (water_count / heights.size) * 100.0

            status_lines = [
                f"Generation complete · {elapsed:.1f} ms",
                f"Height range {minimum:.3f} .. {maximum:.3f}",
                f"Water {water_pct:.1f}% · Caves {cave_pct:.1f}%",
            ]

            if self.threshold_mode_var.get():
                thr = float(self.threshold_var.get())
                above = int(np.sum(heights >= thr))
                above_pct = (above / heights.size) * 100.0
                status_lines.append(f"Threshold ≥ {thr:.2f}: {above_pct:.1f}%")

            self.status_label.config(text="\n".join(status_lines), fg=self.FG_SECONDARY)
            self.header_status.config(text="READY", fg=self.SUCCESS)
            self.status_dot.config(fg=self.SUCCESS)

            meta_suffix = self._format_meta(meta)
            self.map_meta_info.config(
                text=f"{heights.shape[1]} × {heights.shape[0]} · {self.map_scale_mode.upper()}" + meta_suffix
            )

        except Exception as error:
            self.header_status.config(text="ERROR", fg=self.ERROR)
            self.status_dot.config(fg=self.ERROR)
            self.status_label.config(text="Generation failed.", fg=self.ERROR)
            messagebox.showerror("Rust Generator Error", str(error))
        finally:
            self._set_running_state(False)

    def _set_running_state(self, running):
        if running:
            self.generate_button.config(state=tk.DISABLED, text="GENERATING…")
            self.header_status.config(text="RUNNING", fg=self.WARNING)
            self.status_dot.config(fg=self.WARNING)
            self.status_label.config(text="Calling Rust generator…", fg=self.WARNING)
        else:
            self.generate_button.config(state=tk.NORMAL, text="GENERATE HEIGHTMAP")

    def _format_meta(self, meta):
        if not isinstance(meta, dict) or not meta:
            return ""

        version = meta.get("version")
        if version is not None:
            return f" · generator v{version}"
        return ""

    # ------------------------------------------------------------------------
    # Map rendering
    # ------------------------------------------------------------------------

    def render_map(self, heights, caves):
        if self.threshold_mode_var.get():
            rgb = HeightmapRenderer.threshold_mask(
                heights,
                float(self.threshold_var.get()),
            )
        else:
            rgb = HeightmapRenderer.height_to_rgb(heights)
            rgb = HeightmapRenderer.apply_caves(rgb, caves)

        height, width, _ = rgb.shape
        header = f"P6\n{width} {height}\n255\n".encode("ascii")
        image_data = header + rgb.tobytes()

        self.photo = tk.PhotoImage(data=image_data, format="PPM")
        self.map_scale_mode = "fit"
        self.map_mode_label.config(text="FIT")
        self._fit_map_to_canvas()

    def _fit_map_to_canvas(self):
        if self.photo is None:
            self._draw_empty_map()
            return

        canvas_w = max(1, self.map_canvas.winfo_width() - 18)
        canvas_h = max(1, self.map_canvas.winfo_height() - 18)
        img_w, img_h = self.photo.width(), self.photo.height()

        scale = min(canvas_w / img_w, canvas_h / img_h)

        if scale >= 2.0:
            zoom = max(1, int(scale))
            self.display_photo = self.photo.zoom(zoom, zoom)
        elif scale < 1.0:
            sub = max(1, int(round(1.0 / scale)))
            self.display_photo = self.photo.subsample(sub, sub)
        else:
            self.display_photo = self.photo

        self.display_width = self.display_photo.width()
        self.display_height = self.display_photo.height()

        canvas_full_w = max(1, self.map_canvas.winfo_width())
        canvas_full_h = max(1, self.map_canvas.winfo_height())
        self.map_origin_x = (canvas_full_w - self.display_width) / 2
        self.map_origin_y = (canvas_full_h - self.display_height) / 2

        self.map_canvas.delete("all")
        self.map_canvas.create_rectangle(
            self.map_origin_x - 1,
            self.map_origin_y - 1,
            self.map_origin_x + self.display_width + 1,
            self.map_origin_y + self.display_height + 1,
            outline=self.BORDER_SOFT,
        )
        self.map_canvas.create_image(
            canvas_full_w / 2,
            canvas_full_h / 2,
            image=self.display_photo,
            anchor=tk.CENTER,
        )

    def fit_map(self):
        self.map_scale_mode = "fit"
        self.map_mode_label.config(text="FIT")
        self._fit_map_to_canvas()

    def actual_size_map(self):
        if self.photo is None:
            return

        self.map_scale_mode = "1:1"
        self.map_mode_label.config(text="1:1")
        self.display_photo = self.photo
        self.display_width = self.display_photo.width()
        self.display_height = self.display_photo.height()

        canvas_w = max(1, self.map_canvas.winfo_width())
        canvas_h = max(1, self.map_canvas.winfo_height())
        self.map_origin_x = (canvas_w - self.display_width) / 2
        self.map_origin_y = (canvas_h - self.display_height) / 2

        self.map_canvas.delete("all")
        self.map_canvas.create_rectangle(
            self.map_origin_x - 1,
            self.map_origin_y - 1,
            self.map_origin_x + self.display_width + 1,
            self.map_origin_y + self.display_height + 1,
            outline=self.BORDER_SOFT,
        )
        self.map_canvas.create_image(
            canvas_w / 2,
            canvas_h / 2,
            image=self.display_photo,
            anchor=tk.CENTER,
        )

    def on_canvas_resize(self, _event):
        if self.map_scale_mode == "fit":
            self._fit_map_to_canvas()
        elif self.photo is None:
            self._draw_empty_map()

    def on_map_mouse(self, event):
        if self.last_heights is None or self.display_photo is None:
            return

        height, width = self.last_heights.shape
        px = event.x - self.map_origin_x
        py = event.y - self.map_origin_y

        if px < 0 or py < 0 or px >= self.display_width or py >= self.display_height:
            self.map_info.config(text="X: —    Y: —    HEIGHT: —    CAVE: —")
            return

        x = int(px * width / self.display_width)
        y = int(py * height / self.display_height)
        x = max(0, min(width - 1, x))
        y = max(0, min(height - 1, y))

        val = float(self.last_heights[y, x])
        is_cave = bool(self.last_caves[y, x])

        self.map_info.config(
            text=f"X: {x:<4}  Y: {y:<4}  HEIGHT: {val:.5f}  CAVE: {'YES' if is_cave else 'NO'}"
        )

    def _on_map_leave(self, _event):
        if self.last_heights is not None:
            h, w = self.last_heights.shape
            self.map_info.config(
                text=f"MAP {w}×{h}    MOVE CURSOR OVER MAP FOR CELL DATA"
            )


if __name__ == "__main__":
    app = GeneratorTester()
    app.mainloop()
