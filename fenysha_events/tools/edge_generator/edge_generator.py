import argparse
import os
import re
import struct
import sys
import zlib
from io import BytesIO

from PIL import Image, ImageChops


# ============================================================================
# Configuration
# ============================================================================

SUPPORTED_IMAGE_EXTENSIONS = {
    ".png",
    ".jpg",
    ".jpeg",
    ".webp",
}

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
TEMPLATE_NAME = "template.dmi"


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

        length = struct.unpack(">I", data[pos:pos + 4])[0]
        chunk_type = data[pos + 4:pos + 8]
        chunk_end = pos + 12 + length

        if chunk_end > len(data):
            raise ValueError("Corrupted PNG chunk.")

        payload = data[pos + 8:pos + 8 + length]

        yield chunk_type, payload

        pos = chunk_end

        if chunk_type == b"IEND":
            break


def extract_dmi_description(input_path: str) -> str | None:
    """
    Extract BYOND DMI Description from a zTXt chunk.
    """

    with open(input_path, "rb") as file:
        data = file.read()

    for chunk_type, payload in read_png_chunks(data):
        if chunk_type != b"zTXt":
            continue

        separator = payload.find(b"\0")

        if separator == -1:
            continue

        if payload[:separator] != b"Description":
            continue

        method_pos = separator + 1

        if method_pos >= len(payload):
            continue

        if payload[method_pos] != 0:
            raise ValueError(
                "Unsupported zTXt compression method."
            )

        return zlib.decompress(
            payload[method_pos + 1:]
        ).decode("utf-8")

    return None


def make_ztxt_chunk(keyword: str, text: str) -> bytes:
    """Create a PNG zTXt chunk."""

    keyword_data = keyword.encode("ascii")

    if not keyword_data or len(keyword_data) > 79:
        raise ValueError("Invalid PNG text keyword.")

    if b"\0" in keyword_data:
        raise ValueError("PNG keyword cannot contain NUL.")

    payload = (
        keyword_data
        + b"\0"
        + b"\0"
        + zlib.compress(text.encode("utf-8"), level=9)
    )

    chunk_type = b"zTXt"

    return (
        struct.pack(">I", len(payload))
        + chunk_type
        + payload
        + struct.pack(
            ">I",
            zlib.crc32(chunk_type + payload) & 0xFFFFFFFF,
        )
    )


def save_dmi(image: Image.Image, description: str, output_path: str):
    """
    Save an RGBA image as a valid BYOND DMI PNG container.
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

    result = bytearray(PNG_SIGNATURE)
    pos = len(PNG_SIGNATURE)
    description_inserted = False

    while pos < len(png_data):
        if pos + 12 > len(png_data):
            raise ValueError("Generated PNG is corrupted.")

        length = struct.unpack(
            ">I",
            png_data[pos:pos + 4],
        )[0]

        chunk_type = png_data[pos + 4:pos + 8]
        chunk_end = pos + 12 + length

        if chunk_end > len(png_data):
            raise ValueError("Generated PNG chunk is corrupted.")

        payload = png_data[pos + 8:pos + 8 + length]

        # Remove an existing BYOND Description chunk.
        if chunk_type == b"zTXt":
            separator = payload.find(b"\0")

            if (
                separator != -1
                and payload[:separator] == b"Description"
            ):
                pos = chunk_end
                continue

        result.extend(png_data[pos:chunk_end])

        if chunk_type == b"IHDR" and not description_inserted:
            result.extend(description_chunk)
            description_inserted = True

        pos = chunk_end

        if chunk_type == b"IEND":
            break

    if not description_inserted:
        raise ValueError("IHDR chunk not found.")

    os.makedirs(
        os.path.dirname(os.path.abspath(output_path)),
        exist_ok=True,
    )

    with open(output_path, "wb") as file:
        file.write(result)


# ============================================================================
# DMI Description parser
# ============================================================================

STATE_RE = re.compile(r'^state = "(.*)"$')
DIRS_RE = re.compile(r'^\s*dirs = (\d+)$')
FRAMES_RE = re.compile(r'^\s*frames = (\d+)$')
WIDTH_RE = re.compile(r'^\s*width = (\d+)$')
HEIGHT_RE = re.compile(r'^\s*height = (\d+)$')


def parse_dmi_description(description: str):
    """
    Parse width, height and states from a DMI Description.
    """

    width = None
    height = None
    states = []
    current = None

    for raw_line in description.splitlines():
        line = raw_line.rstrip()

        match = WIDTH_RE.match(line)
        if match:
            width = int(match.group(1))
            continue

        match = HEIGHT_RE.match(line)
        if match:
            height = int(match.group(1))
            continue

        match = STATE_RE.match(line)
        if match:
            if current is not None:
                states.append(current)

            current = {
                "name": match.group(1),
                "dirs": 1,
                "frames": 1,
            }
            continue

        if current is None:
            continue

        match = DIRS_RE.match(line)
        if match:
            current["dirs"] = int(match.group(1))
            continue

        match = FRAMES_RE.match(line)
        if match:
            current["frames"] = int(match.group(1))

    if current is not None:
        states.append(current)

    if width is None or height is None:
        raise ValueError(
            "DMI Description does not contain width/height."
        )

    if not states:
        raise ValueError(
            "DMI Description contains no states."
        )

    return width, height, states


# ============================================================================
# DMI atlas
# ============================================================================

def get_static_state_tiles(
    image: Image.Image,
    states: list[dict],
    width: int,
    height: int,
):
    """
    Extract DMI states that consist of exactly one direction and one frame.

    The generator intentionally uses static states because every source DMI
    is reduced to its first state.
    """

    if image.width % width != 0:
        raise ValueError(
            f"Atlas width {image.width} is not divisible by icon width {width}."
        )

    if image.height % height != 0:
        raise ValueError(
            f"Atlas height {image.height} is not divisible by icon height {height}."
        )

    columns = image.width // width
    rows = image.height // height
    capacity = columns * rows

    required = 0

    for state in states:
        dirs = state["dirs"]
        frames = state["frames"]

        if dirs != 1 or frames != 1:
            raise ValueError(
                f'State "{state["name"]}" has dirs={dirs}, frames={frames}. '
                "Only static dirs=1, frames=1 states are supported."
            )

        required += 1

    if required > capacity:
        raise ValueError(
            f"DMI Description requires {required} atlas slots, "
            f"but the image only contains {capacity}."
        )

    tiles = []

    for index in range(len(states)):
        x = (index % columns) * width
        y = (index // columns) * height

        tiles.append(
            image.crop((x, y, x + width, y + height))
        )

    return tiles


# ============================================================================
# Template edges
# ============================================================================

def load_edge_template(template_path: str):
    """
    Load edge_* states from template.dmi.

    Only alpha channels are used as edge masks. State names and ordering are
    preserved exactly in the generated DMI.
    """

    description = extract_dmi_description(template_path)

    if description is None:
        raise ValueError(
            "Template DMI has no BYOND DMI Description."
        )

    width, height, states = parse_dmi_description(description)
    image = Image.open(template_path).convert("RGBA")
    tiles = get_static_state_tiles(
        image,
        states,
        width,
        height,
    )

    edges = []

    for state, tile in zip(states, tiles):
        name = state["name"]

        if not name.startswith("edge_"):
            continue

        alpha = tile.getchannel("A")

        if alpha.getbbox() is None:
            raise ValueError(
                f'Edge state "{name}" contains an empty alpha mask.'
            )

        edges.append((name, alpha))

    if not edges:
        raise ValueError(
            'Template DMI contains no states beginning with "edge_".'
        )

    return width, height, edges


# ============================================================================
# Source texture
# ============================================================================

def load_source_texture(input_path: str):
    """
    Load a source texture.

    PNG/JPG/WEBP:
        the complete image is used.

    DMI:
        only the first state is used.
    """

    extension = os.path.splitext(input_path)[1].lower()

    if extension in SUPPORTED_IMAGE_EXTENSIONS:
        image = Image.open(input_path).convert("RGBA")

        return (
            os.path.splitext(os.path.basename(input_path))[0],
            image,
        )

    if extension != ".dmi":
        raise ValueError(
            f"Unsupported source type: {extension}"
        )

    description = extract_dmi_description(input_path)

    if description is None:
        raise ValueError(
            "Source DMI has no BYOND DMI Description."
        )

    width, height, states = parse_dmi_description(description)
    image = Image.open(input_path).convert("RGBA")
    tiles = get_static_state_tiles(
        image,
        states,
        width,
        height,
    )

    # First state only.
    first_state = states[0]

    return (
        first_state["name"],
        tiles[0],
    )


# ============================================================================
# Generation
# ============================================================================

def generate_edge_tiles(
    source_texture: Image.Image,
    edge_masks: list[tuple[str, Image.Image]],
):
    """
    Apply each template edge mask to the source texture.

    RGB is taken directly from the source texture.
    Alpha is multiplied by the template edge alpha.
    """

    source = source_texture.convert("RGBA")
    source_alpha = source.getchannel("A")

    result = []

    for edge_name, edge_mask in edge_masks:
        combined_alpha = ImageChops.multiply(
            source_alpha,
            edge_mask,
        )

        tile = source.copy()
        tile.putalpha(combined_alpha)

        result.append((edge_name, tile))

    return result


def create_description(
    state_names: list[str],
    width: int,
    height: int,
):
    """Create a static one-frame DMI Description."""

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


def create_edge_dmi(
    source_texture: Image.Image,
    edge_masks: list[tuple[str, Image.Image]],
    output_path: str,
):
    """
    Generate one complete edge DMI from one source texture.
    """

    width = source_texture.width
    height = source_texture.height

    for edge_name, mask in edge_masks:
        if mask.size != (width, height):
            raise ValueError(
                f'{edge_name}: template is {mask.width}x{mask.height}, '
                f"source is {width}x{height}."
            )

    edge_tiles = generate_edge_tiles(
        source_texture,
        edge_masks,
    )

    atlas = Image.new(
        "RGBA",
        (width, height * len(edge_tiles)),
        (0, 0, 0, 0),
    )

    state_names = []

    for index, (edge_name, tile) in enumerate(edge_tiles):
        atlas.paste(
            tile,
            (0, index * height),
        )
        state_names.append(edge_name)

    description = create_description(
        state_names,
        width,
        height,
    )

    save_dmi(
        atlas,
        description,
        output_path,
    )

    return len(edge_tiles), atlas.size


# ============================================================================
# Automatic folder mode
# ============================================================================

def find_sources(input_dir: str):
    """
    Find all source DMI/image files except template.dmi.
    """

    files = []

    for name in os.listdir(input_dir):
        path = os.path.join(input_dir, name)

        if not os.path.isfile(path):
            continue

        if name.lower() == TEMPLATE_NAME:
            continue

        extension = os.path.splitext(name)[1].lower()

        if (
            extension == ".dmi"
            or extension in SUPPORTED_IMAGE_EXTENSIONS
        ):
            files.append(path)

    return sorted(files)


def auto_mode():
    """
    Automatic mode:

        script_folder/
            edge_generator.py
            input/
                template.dmi
                sand.dmi
                grass.dmi
                dirt.png
                snow.png
            output/

    template.dmi:
        contains edge_* states and acts as the edge shape template.

    Source DMI:
        first state is used as the source texture.

    Source PNG/JPG/WEBP:
        entire image is used as the source texture.

    Each source receives its own complete DMI:
        sand_edges.dmi
        grass_edges.dmi
        dirt_edges.dmi
        snow_edges.dmi
    """

    script_dir = os.path.dirname(os.path.abspath(__file__))
    input_dir = os.path.join(script_dir, "input")
    output_dir = os.path.join(script_dir, "output")
    template_path = os.path.join(input_dir, TEMPLATE_NAME)

    print("=" * 60)
    print("EDGE TILE GENERATOR")
    print("=" * 60)
    print(f"Input:    {input_dir}")
    print(f"Template: {template_path}")
    print(f"Output:   {output_dir}")
    print()

    if not os.path.isdir(input_dir):
        raise ValueError(
            f"Input folder not found:\n{input_dir}"
        )

    if not os.path.isfile(template_path):
        raise ValueError(
            f'"{TEMPLATE_NAME}" not found in:\n{input_dir}'
        )

    os.makedirs(output_dir, exist_ok=True)

    template_width, template_height, edge_masks = load_edge_template(
        template_path
    )

    print(
        f"Template edges: {len(edge_masks)}"
    )
    print(
        f"Template size:  {template_width}x{template_height}"
    )
    print()

    sources = find_sources(input_dir)

    if not sources:
        raise ValueError(
            "No source DMI or image files found in input."
        )

    print(
        f"Found {len(sources)} source file(s).\n"
    )

    for index, source_path in enumerate(sources, start=1):
        filename = os.path.basename(source_path)
        base_name = os.path.splitext(filename)[0]
        output_path = os.path.join(
            output_dir,
            f"{base_name}_edges.dmi",
        )

        if os.path.exists(output_path):
            extension = os.path.splitext(filename)[1].lower().lstrip(".")
            output_path = os.path.join(
                output_dir,
                f"{base_name}_{extension}_edges.dmi",
            )

        print(
            f"[{index}/{len(sources)}] {filename}"
        )

        state_name, source_texture = load_source_texture(
            source_path
        )

        width = source_texture.width
        height = source_texture.height

        if width != height:
            raise ValueError(
                f"{filename}: source texture must be square, "
                f"got {width}x{height}."
            )

        if width != template_width or height != template_height:
            raise ValueError(
                f"{filename}: source is {width}x{height}, "
                f"but template is {template_width}x{template_height}."
            )

        print(
            f"  State: {state_name}"
        )

        edge_count, atlas_size = create_edge_dmi(
            source_texture,
            edge_masks,
            output_path,
        )

        print(
            f"  Created: {output_path}"
        )
        print(
            f"  Edges:   {edge_count}"
        )
        print(
            f"  Atlas:   {atlas_size[0]}x{atlas_size[1]}"
        )
        print()

    print(
        f"Done. Processed {len(sources)} source file(s)."
    )


# ============================================================================
# Manual CLI mode
# ============================================================================

def cli_mode():
    """
    Manual mode:

        python edge_generator.py SOURCE --template template.dmi

    DMI source:
        first state is used.

    Image source:
        complete image is used.
    """

    parser = argparse.ArgumentParser(
        description=(
            "Generate BYOND edge-tile DMIs from a template DMI."
        )
    )

    parser.add_argument(
        "input",
        help="Source PNG/image or DMI.",
    )

    parser.add_argument(
        "-t",
        "--template",
        default=None,
        help="Edge template DMI. Default: template.dmi next to the source.",
    )

    parser.add_argument(
        "-o",
        "--output",
        default=None,
        help="Output .dmi path.",
    )

    args = parser.parse_args()

    input_path = os.path.abspath(args.input)

    if not os.path.isfile(input_path):
        raise FileNotFoundError(
            f"Source does not exist: {input_path}"
        )

    if args.template is None:
        template_path = os.path.join(
            os.path.dirname(input_path),
            TEMPLATE_NAME,
        )
    else:
        template_path = os.path.abspath(args.template)

    if not os.path.isfile(template_path):
        raise FileNotFoundError(
            f"Template does not exist: {template_path}"
        )

    template_width, template_height, edge_masks = load_edge_template(
        template_path
    )

    state_name, source_texture = load_source_texture(input_path)

    width = source_texture.width
    height = source_texture.height

    if width != height:
        raise ValueError(
            f"Source texture must be square, got {width}x{height}."
        )

    if width != template_width or height != template_height:
        raise ValueError(
            f"Source is {width}x{height}, but template is "
            f"{template_width}x{template_height}."
        )

    if args.output is None:
        base_name = os.path.splitext(
            os.path.basename(input_path)
        )[0]

        output_path = os.path.join(
            os.path.dirname(input_path),
            f"{base_name}_edges.dmi",
        )
    else:
        output_path = os.path.abspath(args.output)

    if not output_path.lower().endswith(".dmi"):
        output_path += ".dmi"

    print(f"Source state: {state_name}")
    create_edge_dmi(
        source_texture,
        edge_masks,
        output_path,
    )
    print(f"DMI created: {output_path}")


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
        if len(sys.argv) == 1:
            try:
                input("\nPress Enter to close...")
            except EOFError:
                pass
