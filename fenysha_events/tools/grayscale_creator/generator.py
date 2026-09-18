import argparse
import os
import struct
import sys
import zlib
from io import BytesIO

from PIL import Image, ImageOps


# ============================================================================
# Supported files
# ============================================================================

SUPPORTED_IMAGE_EXTENSIONS = {
    ".png",
    ".jpg",
    ".jpeg",
    ".webp",
}

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


# ============================================================================
# Grayscale
# ============================================================================

def to_grayscale(image: Image.Image) -> Image.Image:
    """
    Convert RGB channels to grayscale while preserving alpha.
    """

    image = image.convert("RGBA")

    gray = ImageOps.grayscale(
        image.convert("RGB")
    )

    alpha = image.getchannel("A")

    return Image.merge(
        "RGBA",
        (
            gray,
            gray,
            gray,
            alpha,
        ),
    )


# ============================================================================
# PNG chunks / DMI Description
# ============================================================================

def read_png_chunks(data: bytes):
    """
    Iterate over PNG chunks.

    Yields:
        (chunk_type, payload)
    """

    if not data.startswith(PNG_SIGNATURE):
        raise ValueError("Invalid PNG signature.")

    pos = len(PNG_SIGNATURE)

    while pos < len(data):
        if pos + 12 > len(data):
            raise ValueError("Corrupted PNG.")

        length = struct.unpack(
            ">I",
            data[pos:pos + 4],
        )[0]

        chunk_type = data[
            pos + 4:
            pos + 8
        ]

        chunk_end = pos + 12 + length

        if chunk_end > len(data):
            raise ValueError("Corrupted PNG chunk.")

        payload = data[
            pos + 8:
            pos + 8 + length
        ]

        yield chunk_type, payload

        pos = chunk_end

        if chunk_type == b"IEND":
            break


def extract_dmi_description(
    input_path: str,
) -> str | None:
    """
    Extract BYOND DMI Description from the zTXt chunk.
    """

    with open(input_path, "rb") as file:
        data = file.read()

    for chunk_type, payload in read_png_chunks(data):
        if chunk_type != b"zTXt":
            continue

        separator = payload.find(b"\0")

        if separator == -1:
            continue

        keyword = payload[:separator]

        if keyword != b"Description":
            continue

        method_pos = separator + 1

        if method_pos >= len(payload):
            continue

        compression_method = payload[method_pos]

        if compression_method != 0:
            raise ValueError(
                "Unsupported zTXt compression method."
            )

        compressed = payload[method_pos + 1:]

        return zlib.decompress(
            compressed
        ).decode("utf-8")

    return None


def make_ztxt_chunk(
    keyword: str,
    text: str,
) -> bytes:
    """
    Create a PNG zTXt chunk.
    """

    keyword_data = keyword.encode("ascii")

    if not keyword_data or len(keyword_data) > 79:
        raise ValueError("Invalid PNG text keyword.")

    if b"\0" in keyword_data:
        raise ValueError("PNG keyword cannot contain NUL.")

    payload = (
        keyword_data
        + b"\0"
        + b"\0"
        + zlib.compress(
            text.encode("utf-8"),
            level=9,
        )
    )

    chunk_type = b"zTXt"

    return (
        struct.pack(">I", len(payload))
        + chunk_type
        + payload
        + struct.pack(
            ">I",
            zlib.crc32(
                chunk_type + payload
            ) & 0xFFFFFFFF,
        )
    )


def save_dmi(
    image: Image.Image,
    description: str,
    output_path: str,
):
    """
    Save an image as PNG and attach a BYOND DMI Description.

    The resulting file is a valid PNG container with a .dmi extension,
    which is the native DMI format used by BYOND.
    """

    buffer = BytesIO()

    image.save(
        buffer,
        format="PNG",
        optimize=True,
    )

    png_data = buffer.getvalue()

    if not png_data.startswith(PNG_SIGNATURE):
        raise ValueError("Failed to create PNG data.")

    description_chunk = make_ztxt_chunk(
        "Description",
        description,
    )

    result = bytearray()
    result.extend(PNG_SIGNATURE)

    pos = len(PNG_SIGNATURE)
    description_inserted = False

    while pos < len(png_data):
        if pos + 12 > len(png_data):
            raise ValueError("Generated PNG is corrupted.")

        length = struct.unpack(
            ">I",
            png_data[pos:pos + 4],
        )[0]

        chunk_type = png_data[
            pos + 4:
            pos + 8
        ]

        chunk_end = pos + 12 + length

        if chunk_end > len(png_data):
            raise ValueError(
                "Generated PNG chunk is corrupted."
            )

        payload = png_data[
            pos + 8:
            pos + 8 + length
        ]

        # Remove an existing BYOND Description if any.
        if chunk_type == b"zTXt":
            separator = payload.find(b"\0")

            if (
                separator != -1
                and payload[:separator] == b"Description"
            ):
                pos = chunk_end
                continue

        result.extend(
            png_data[pos:chunk_end]
        )

        # Keep the same placement used by the original generator:
        # Description immediately after IHDR.
        if (
            chunk_type == b"IHDR"
            and not description_inserted
        ):
            result.extend(description_chunk)
            description_inserted = True

        pos = chunk_end

        if chunk_type == b"IEND":
            break

    if not description_inserted:
        raise ValueError("IHDR chunk not found.")

    os.makedirs(
        os.path.dirname(
            os.path.abspath(output_path)
        ),
        exist_ok=True,
    )

    with open(output_path, "wb") as file:
        file.write(result)


# ============================================================================
# DMI description helpers
# ============================================================================

def get_dmi_icon_size(
    description: str,
) -> tuple[int, int]:
    """
    Read icon width/height from DMI Description.
    """

    width = None
    height = None

    for raw_line in description.splitlines():
        line = raw_line.strip()

        if line.startswith("width = "):
            width = int(
                line.split("=", 1)[1].strip()
            )

        elif line.startswith("height = "):
            height = int(
                line.split("=", 1)[1].strip()
            )

    if width is None or height is None:
        raise ValueError(
            "DMI Description does not contain width/height."
        )

    return width, height


# ============================================================================
# Existing DMI -> grayscale DMI
# ============================================================================

def process_dmi(
    input_path: str,
    output_path: str,
):
    """
    Convert an existing DMI to grayscale.

    The DMI Description is preserved exactly.
    States, dirs, frames, delays and atlas layout remain unchanged.
    Only RGB pixels are modified.
    """

    print(f"Loading DMI: {input_path}")

    description = extract_dmi_description(
        input_path
    )

    if description is None:
        raise ValueError(
            "The input file has no BYOND DMI Description."
        )

    image = Image.open(
        input_path
    ).convert("RGBA")

    icon_width, icon_height = get_dmi_icon_size(
        description
    )

    if icon_width <= 0 or icon_height <= 0:
        raise ValueError(
            "Invalid DMI icon dimensions."
        )

    if image.width % icon_width != 0:
        raise ValueError(
            f"Atlas width {image.width} is not divisible "
            f"by icon width {icon_width}."
        )

    if image.height % icon_height != 0:
        raise ValueError(
            f"Atlas height {image.height} is not divisible "
            f"by icon height {icon_height}."
        )

    grayscale = to_grayscale(image)

    save_dmi(
        grayscale,
        description,
        output_path,
    )

    print(f"DMI created: {output_path}")


# ============================================================================
# PNG files -> DMI with states
# ============================================================================

def create_png_dmi_description(
    state_names: list[str],
    width: int,
    height: int,
) -> str:
    """
    Create DMI Description for a set of static PNG states.
    """

    description = (
        "# BEGIN DMI\n"
        "version = 4.0\n"
        f"width = {width}\n"
        f"height = {height}\n"
    )

    for state_name in state_names:
        description += (
            f'state = "{state_name}"\n'
            "\tdirs = 1\n"
            "\tframes = 1\n"
        )

    description += "# END DMI\n"

    return description


def process_png_files(
    input_files: list[str],
    output_path: str,
):
    """
    Convert PNG/image files into one DMI.

    Each input image becomes one DMI state.

    Example:
        wall.png  -> state "wall"
        floor.png -> state "floor"
        grass.png -> state "grass"

    Every state has one frame and one direction.
    """

    if not input_files:
        raise ValueError("No image files to process.")

    images: list[Image.Image] = []
    state_names: list[str] = []

    first_width = None
    first_height = None

    for input_path in input_files:
        file_name = os.path.basename(input_path)
        state_name = os.path.splitext(file_name)[0]

        print(f"Loading texture: {file_name}")

        image = Image.open(
            input_path
        ).convert("RGBA")

        if image.width != image.height:
            raise ValueError(
                f"{file_name}: texture must be square, "
                f"got {image.width}x{image.height}."
            )

        if first_width is None:
            first_width = image.width
            first_height = image.height
        else:
            if image.width != first_width:
                raise ValueError(
                    f"{file_name}: width {image.width} does not match "
                    f"{first_width}."
                )

            if image.height != first_height:
                raise ValueError(
                    f"{file_name}: height {image.height} does not match "
                    f"{first_height}."
                )

        images.append(
            to_grayscale(image)
        )

        state_names.append(
            state_name
        )

    assert first_width is not None
    assert first_height is not None

    # Same vertical frame atlas layout as the original create_dmi().
    atlas = Image.new(
        "RGBA",
        (
            first_width,
            first_height * len(images),
        ),
        (0, 0, 0, 0),
    )

    y = 0

    for image in images:
        atlas.paste(
            image,
            (0, y),
        )
        y += first_height

    description = create_png_dmi_description(
        state_names,
        first_width,
        first_height,
    )

    save_dmi(
        atlas,
        description,
        output_path,
    )

    print()
    print(f"DMI created: {output_path}")
    print(f"States:      {len(images)}")
    print(
        f"Icon size:   {first_width}x{first_height}"
    )
    print(
        f"Atlas size:  {atlas.width}x{atlas.height}"
    )


# ============================================================================
# File discovery
# ============================================================================

def find_input_files(
    input_dir: str,
) -> list[str]:
    """
    Find supported DMI/image files in a folder.
    """

    files = []

    for name in os.listdir(input_dir):
        path = os.path.join(
            input_dir,
            name,
        )

        if not os.path.isfile(path):
            continue

        extension = os.path.splitext(name)[1].lower()

        if (
            extension == ".dmi"
            or extension in SUPPORTED_IMAGE_EXTENSIONS
        ):
            files.append(path)

    return sorted(files)


# ============================================================================
# Automatic mode
# ============================================================================

def auto_mode():
    """
    Automatic mode:

        script_folder/input -> script_folder/output

    Rules:

        One or more DMIs:
            preserve each DMI structure and convert its pixels.
            Each file is processed sequentially.

        PNG/images:
            combine all images into one DMI,
            with every image becoming a state.

    DMI files and standalone images cannot be mixed.
    """

    script_dir = os.path.dirname(
        os.path.abspath(__file__)
    )

    input_dir = os.path.join(
        script_dir,
        "input",
    )

    output_dir = os.path.join(
        script_dir,
        "output",
    )

    print("=" * 60)
    print("GRAYSCALE DMI GENERATOR")
    print("=" * 60)
    print(f"Input:  {input_dir}")
    print(f"Output: {output_dir}")
    print()

    if not os.path.isdir(input_dir):
        raise ValueError(
            f"Input folder not found:\n{input_dir}"
        )

    os.makedirs(
        output_dir,
        exist_ok=True,
    )

    files = find_input_files(
        input_dir
    )

    if not files:
        raise ValueError(
            "No supported DMI or image files found in input."
        )

    dmi_files = [
        path
        for path in files
        if os.path.splitext(path)[1].lower() == ".dmi"
    ]

    image_files = [
        path
        for path in files
        if os.path.splitext(path)[1].lower() != ".dmi"
    ]

    # ------------------------------------------------------------------------
    # Existing DMI(s)
    # ------------------------------------------------------------------------

    if dmi_files:
        if image_files:
            raise ValueError(
                "Do not mix DMI and image files in input."
            )

        total = len(dmi_files)
        print(f"Found {total} DMI file(s). Processing one by one...\n")

        for index, input_path in enumerate(dmi_files, start=1):
            base_name = os.path.splitext(
                os.path.basename(input_path)
            )[0]

            output_path = os.path.join(
                output_dir,
                f"{base_name}_grayscale.dmi",
            )

            print(f"[{index}/{total}] ", end="")
            process_dmi(
                input_path,
                output_path,
            )
            print()

        print(f"Done. Processed {total} DMI file(s).")
        return

    # ------------------------------------------------------------------------
    # PNG/images -> DMI
    # ------------------------------------------------------------------------

    output_path = os.path.join(
        output_dir,
        "grayscale.dmi",
    )

    process_png_files(
        image_files,
        output_path,
    )


# ============================================================================
# Manual CLI mode
# ============================================================================

def cli_mode():
    """
    Manual mode.

    DMI file:
        preserve structure -> grayscale DMI

    Image file:
        one-state DMI

    Folder of images:
        multi-state DMI

    Folder of DMIs:
        process each DMI sequentially
    """

    parser = argparse.ArgumentParser(
        description=(
            "Convert DMI/textures to grayscale BYOND .dmi files."
        )
    )

    parser.add_argument(
        "input",
        help=(
            "Path to a .dmi/image file or a folder."
        ),
    )

    parser.add_argument(
        "-o",
        "--output",
        default=None,
        help="Output .dmi path (or directory when processing multiple DMIs).",
    )

    args = parser.parse_args()

    input_path = os.path.abspath(
        args.input
    )

    if not os.path.exists(input_path):
        raise FileNotFoundError(
            f"Input does not exist: {input_path}"
        )

    # ------------------------------------------------------------------------
    # Single file
    # ------------------------------------------------------------------------

    if os.path.isfile(input_path):
        extension = os.path.splitext(
            input_path
        )[1].lower()

        if args.output is None:
            base_name = os.path.splitext(
                os.path.basename(input_path)
            )[0]

            output_path = os.path.join(
                os.path.dirname(input_path),
                f"{base_name}_grayscale.dmi",
            )
        else:
            output_path = args.output

        if not output_path.lower().endswith(".dmi"):
            output_path += ".dmi"

        if extension == ".dmi":
            process_dmi(
                input_path,
                output_path,
            )

        elif extension in SUPPORTED_IMAGE_EXTENSIONS:
            process_png_files(
                [input_path],
                output_path,
            )

        else:
            raise ValueError(
                f"Unsupported file type: {extension}"
            )

        return

    # ------------------------------------------------------------------------
    # Folder
    # ------------------------------------------------------------------------

    if os.path.isdir(input_path):
        files = find_input_files(
            input_path
        )

        if not files:
            raise ValueError(
                "No supported DMI or image files found."
            )

        dmi_files = [
            path
            for path in files
            if os.path.splitext(path)[1].lower() == ".dmi"
        ]

        image_files = [
            path
            for path in files
            if os.path.splitext(path)[1].lower() != ".dmi"
        ]

        if dmi_files and image_files:
            raise ValueError(
                "Do not mix DMI and image files in one folder."
            )

        # Multiple (or single) DMIs — process each one by one
        if dmi_files:
            total = len(dmi_files)
            print(f"Found {total} DMI file(s). Processing one by one...\n")

            # Determine output directory
            if args.output is None:
                output_dir = input_path
            else:
                # If user passed a path ending with .dmi and there's only one file,
                # treat it as a specific file path. Otherwise treat as directory.
                if (
                    total == 1
                    and args.output.lower().endswith(".dmi")
                ):
                    output_dir = None
                    single_output = args.output
                else:
                    output_dir = args.output
                    os.makedirs(output_dir, exist_ok=True)
                    single_output = None

            for index, dmi_path in enumerate(dmi_files, start=1):
                base_name = os.path.splitext(
                    os.path.basename(dmi_path)
                )[0]

                if total == 1 and single_output is not None:
                    output_path = single_output
                else:
                    output_path = os.path.join(
                        output_dir if output_dir is not None else input_path,
                        f"{base_name}_grayscale.dmi",
                    )

                if not output_path.lower().endswith(".dmi"):
                    output_path += ".dmi"

                print(f"[{index}/{total}] ", end="")
                process_dmi(
                    dmi_path,
                    output_path,
                )
                print()

            print(f"Done. Processed {total} DMI file(s).")
            return

        # Only images
        if args.output is None:
            output_path = os.path.join(
                input_path,
                "grayscale.dmi",
            )
        else:
            output_path = args.output

        if not output_path.lower().endswith(".dmi"):
            output_path += ".dmi"

        process_png_files(
            image_files,
            output_path,
        )

        return

    raise ValueError(
        "Input must be a file or directory."
    )


# ============================================================================
# Entry point
# ============================================================================

def main():
    if len(sys.argv) == 1:
        auto_mode()
    else:
        cli_mode()


if __name__ == "__main__":
    try:
        main()

    except KeyboardInterrupt:
        print("\nCancelled.")

    except Exception as exc:
        print(f"\nERROR: {exc}")

    finally:
        # Keep the console visible when launched by double-click.
        if len(sys.argv) == 1:
            try:
                input("\nPress Enter to close...")
            except EOFError:
                pass
