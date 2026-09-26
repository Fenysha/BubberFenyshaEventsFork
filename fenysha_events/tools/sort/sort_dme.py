#!/usr/bin/env python3
import argparse
import re
from pathlib import Path

BEGIN_INCLUDE = "BEGIN_INCLUDE"
END_INCLUDE = "END_INCLUDE"
MOD_INCLUDE_BEGIN = "MOD_INCLUDE_BEGIN"
MOD_INCLUDE_END = "MOD_INCLUDE_END"
BLOCK_BEGIN_MARKERS = {BEGIN_INCLUDE, MOD_INCLUDE_BEGIN}
BLOCK_END_MARKERS = {END_INCLUDE, MOD_INCLUDE_END}
INCLUDE_RE = re.compile(r'^\s*#include\s+"([^"]+)"\s*$')


def normalize_block_marker(line: str):
    stripped = line.strip()
    if not stripped:
        return None

    marker = stripped.lstrip('/').strip()
    return marker if marker in BLOCK_BEGIN_MARKERS | BLOCK_END_MARKERS else None


def sort_include_lines(lines):
    include_lines = []
    non_include_lines = []

    for line in lines:
        stripped = line.rstrip('\r\n')
        match = INCLUDE_RE.match(stripped)
        if match:
            include_lines.append((match.group(1), line))
        else:
            non_include_lines.append(line)

    def cmp_paths(a, b):
        a0 = a.replace('/', '\\').lower()
        b0 = b.replace('/', '\\').lower()

        a_suffix = ''
        if '.' in a0:
            a_suffix = a0.split('.')[-1]
        b_suffix = ''
        if '.' in b0:
            b_suffix = b0.split('.')[-1]

        a_segments = a0.split('\\')
        b_segments = b0.split('\\')

        for a_seg, b_seg in zip(a_segments, b_segments):
            a_is_file = a_seg.endswith(('dm', 'dmf'))
            b_is_file = b_seg.endswith(('dm', 'dmf'))

            if a_is_file and not b_is_file:
                return -1
            if b_is_file and not a_is_file:
                return 1

            if a_seg != b_seg:
                if a_suffix != b_suffix:
                    return (a_suffix > b_suffix) - (a_suffix < b_suffix)
                return (a_seg > b_seg) - (a_seg < b_seg)

        return 0

    from functools import cmp_to_key
    sorted_includes = [line for _, line in sorted(include_lines, key=cmp_to_key(lambda x, y: cmp_paths(x[0], y[0])))]
    return sorted_includes + non_include_lines


def sort_dme_file(path: Path) -> bool:
    text = path.read_text(encoding='utf-8')
    original_lines = text.splitlines(keepends=True)

    output = []
    in_block = False
    current_block_lines = []
    found_begin = False
    found_end = False

    for line in original_lines:
        marker = normalize_block_marker(line)

        if marker in BLOCK_BEGIN_MARKERS:
            in_block = True
            found_begin = True
            output.append(line)
            current_block_lines = []
            continue

        if marker in BLOCK_END_MARKERS:
            if not in_block:
                output.append(line)
                continue
            in_block = False
            found_end = True
            output.extend(sort_include_lines(current_block_lines))
            output.append(line)
            current_block_lines = []
            continue

        if in_block:
            current_block_lines.append(line)
        else:
            output.append(line)

    if not found_begin:
        return False

    if not found_end:
        raise ValueError(f"No closing block marker was found for the sortable include block in {path}")

    new_text = ''.join(output)
    if new_text != text:
        path.write_text(new_text, encoding='utf-8')
        return True

    return False


def parse_args():
    base_dir = Path(__file__).resolve().parents[2]
    default_file = base_dir / '_fenysha_events.dme'

    parser = argparse.ArgumentParser(description='Sorts #include blocks in the project DME files.')
    parser.add_argument(
        'file',
        nargs='?',
        default=str(default_file),
        help='Path to the .dme file. Default: _fenysha_events.dme'
    )
    parser.add_argument('--all', action='store_true', help='Sort both: _fenysha_events.dme and _fenysha_events_premodular.dme')
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    if args.all:
        base = Path(__file__).resolve().parents[2]
        files = [base / '_fenysha_events.dme', base / '_fenysha_events_premodular.dme']
        any_changed = False
        for f in files:
            if not f.exists():
                print(f'Skipping missing file: {f}')
                continue
            changed = sort_dme_file(f)
            any_changed = any_changed or changed
            print(f'Sorted: {f}' if changed else f'Already sorted: {f}')
        raise SystemExit(0)

    file_path = Path(args.file).resolve()

    if not file_path.exists():
        raise FileNotFoundError(f'File not found: {file_path}')

    changed = sort_dme_file(file_path)
    if changed:
        print(f'Sorted: {file_path}')
    else:
        print(f'Already sorted or no sortable include block found: {file_path}')
