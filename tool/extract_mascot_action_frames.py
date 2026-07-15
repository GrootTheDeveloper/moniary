"""Extract one mascot pose per PNG from the generated action sheet.

The source sheet is not a regular grid. Poses are detected from their main
connected component, then cropped from a fixed-width slot around that pose so
neighboring poses can never leak into the exported frame.
"""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw


ACTION_FRAME_COUNTS = {
    "look": 9,
    "wave": 9,
    "sleep": 10,
    "startled": 10,
    "celebrate": 10,
}
CANVAS_SIZE = 160
SLOT_HALF_WIDTH = 70
BOTTOM_PADDING = 4
MAIN_COMPONENT_MIN_AREA = 1_000


def _alpha_row_bands(alpha: Image.Image) -> list[tuple[int, int]]:
    bands: list[tuple[int, int]] = []
    start: int | None = None

    for y in range(alpha.height):
        occupied = alpha.crop((0, y, alpha.width, y + 1)).getbbox() is not None
        if occupied and start is None:
            start = y
        elif not occupied and start is not None:
            bands.append((start, y))
            start = None

    if start is not None:
        bands.append((start, alpha.height))
    return bands


def _main_component_centers(
    alpha: Image.Image,
    y_start: int,
    y_end: int,
) -> list[int]:
    pixels = alpha.load()
    visited: set[tuple[int, int]] = set()
    centers: list[int] = []

    for y in range(y_start, y_end):
        for x in range(alpha.width):
            if pixels[x, y] == 0 or (x, y) in visited:
                continue

            queue = deque([(x, y)])
            visited.add((x, y))
            component_x: list[int] = []

            while queue:
                current_x, current_y = queue.pop()
                component_x.append(current_x)
                for next_x, next_y in (
                    (current_x - 1, current_y),
                    (current_x + 1, current_y),
                    (current_x, current_y - 1),
                    (current_x, current_y + 1),
                ):
                    if not (
                        0 <= next_x < alpha.width
                        and y_start <= next_y < y_end
                    ):
                        continue
                    if pixels[next_x, next_y] == 0:
                        continue
                    if (next_x, next_y) in visited:
                        continue
                    visited.add((next_x, next_y))
                    queue.append((next_x, next_y))

            if len(component_x) >= MAIN_COMPONENT_MIN_AREA:
                centers.append(round(sum(component_x) / len(component_x)))

    return sorted(centers)


def _component_areas(alpha: Image.Image) -> list[int]:
    pixels = alpha.load()
    visited: set[tuple[int, int]] = set()
    areas: list[int] = []

    for y in range(alpha.height):
        for x in range(alpha.width):
            if pixels[x, y] == 0 or (x, y) in visited:
                continue

            queue = deque([(x, y)])
            visited.add((x, y))
            area = 0
            while queue:
                current_x, current_y = queue.pop()
                area += 1
                for next_x, next_y in (
                    (current_x - 1, current_y),
                    (current_x + 1, current_y),
                    (current_x, current_y - 1),
                    (current_x, current_y + 1),
                ):
                    if not (
                        0 <= next_x < alpha.width
                        and 0 <= next_y < alpha.height
                    ):
                        continue
                    if pixels[next_x, next_y] == 0:
                        continue
                    if (next_x, next_y) in visited:
                        continue
                    visited.add((next_x, next_y))
                    queue.append((next_x, next_y))
            areas.append(area)

    return sorted(areas, reverse=True)


def _slot_bounds(
    centers: list[int],
    index: int,
    sheet_width: int,
) -> tuple[int, int]:
    center = centers[index]
    left = (
        max(0, center - SLOT_HALF_WIDTH)
        if index == 0
        else (centers[index - 1] + center) // 2
    )
    right = (
        min(sheet_width, center + SLOT_HALF_WIDTH)
        if index == len(centers) - 1
        else (center + centers[index + 1]) // 2
    )
    return left, right


def _assert_slots_cover_row(
    alpha: Image.Image,
    y_start: int,
    y_end: int,
    centers: list[int],
) -> None:
    first_left, _ = _slot_bounds(centers, 0, alpha.width)
    _, last_right = _slot_bounds(centers, len(centers) - 1, alpha.width)
    pixels = alpha.load()
    for y in range(y_start, y_end):
        for x in range(alpha.width):
            if pixels[x, y] == 0:
                continue
            if not first_left <= x < last_right:
                raise ValueError(
                    f"Pixel ({x}, {y}) falls outside every detected pose slot"
                )


def _export_frames(
    sheet: Image.Image,
    output_dir: Path,
) -> list[tuple[str, Path]]:
    alpha = sheet.getchannel("A")
    row_bands = _alpha_row_bands(alpha)
    action_rows = list(ACTION_FRAME_COUNTS.items())

    if len(row_bands) < len(action_rows):
        raise ValueError(
            f"Expected at least {len(action_rows)} populated rows, found {len(row_bands)}"
        )

    output_dir.mkdir(parents=True, exist_ok=True)
    exported: list[tuple[str, Path]] = []

    for row_index, (action, expected_count) in enumerate(action_rows):
        y_start, y_end = row_bands[row_index]
        centers = _main_component_centers(alpha, y_start, y_end)
        if len(centers) != expected_count:
            raise ValueError(
                f"{action}: expected {expected_count} poses, found {len(centers)}"
            )
        _assert_slots_cover_row(alpha, y_start, y_end, centers)

        row_height = y_end - y_start
        target_y = CANVAS_SIZE - BOTTOM_PADDING - row_height
        if target_y < 0:
            raise ValueError(f"{action}: row height {row_height} exceeds canvas")

        for frame_index, center in enumerate(centers):
            left, right = _slot_bounds(centers, frame_index, sheet.width)
            slot = sheet.crop((left, y_start, right, y_end))
            frame = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
            target_x = CANVAS_SIZE // 2 - (center - left)
            if target_x < 0 or target_x + slot.width > CANVAS_SIZE:
                raise ValueError(f"{action}_{frame_index:02}: slot exceeds canvas")
            frame.alpha_composite(slot, (target_x, target_y))

            frame_alpha = frame.getchannel("A")
            bbox = frame_alpha.getbbox()
            if bbox is None:
                raise ValueError(f"{action}_{frame_index:02}: exported frame is empty")
            if bbox[0] == 0 or bbox[2] == CANVAS_SIZE:
                raise ValueError(f"{action}_{frame_index:02}: touches a horizontal edge")
            if bbox[1] == 0 or bbox[3] == CANVAS_SIZE:
                raise ValueError(f"{action}_{frame_index:02}: touches a vertical edge")
            large_components = [
                area
                for area in _component_areas(frame_alpha)
                if area >= MAIN_COMPONENT_MIN_AREA
            ]
            if len(large_components) != 1:
                raise ValueError(
                    f"{action}_{frame_index:02}: expected one mascot component, "
                    f"found {len(large_components)}"
                )

            output_path = output_dir / f"mascot_{action}_{frame_index:02}.png"
            frame.save(output_path, optimize=True)
            exported.append((f"{action}_{frame_index:02}", output_path))

    return exported


def _write_contact_sheet(
    exported: list[tuple[str, Path]],
    output_path: Path,
) -> None:
    columns = 8
    cell_width = 130
    cell_height = 120
    rows = (len(exported) + columns - 1) // columns
    contact = Image.new(
        "RGBA",
        (columns * cell_width, rows * cell_height),
        (246, 246, 246, 255),
    )
    draw = ImageDraw.Draw(contact)

    for index, (label, frame_path) in enumerate(exported):
        column = index % columns
        row = index // columns
        x = column * cell_width
        y = row * cell_height
        frame = Image.open(frame_path).convert("RGBA")
        frame.thumbnail((100, 94), Image.Resampling.NEAREST)
        contact.alpha_composite(frame, (x + (cell_width - frame.width) // 2, y + 2))
        draw.rectangle(
            (x, y, x + cell_width - 1, y + cell_height - 1),
            outline=(70, 70, 70, 255),
            width=1,
        )
        draw.text((x + 4, y + 101), label, fill=(20, 20, 20, 255))

    output_path.parent.mkdir(parents=True, exist_ok=True)
    contact.convert("RGB").save(output_path, optimize=True)


def _write_previews(
    exported: list[tuple[str, Path]],
    output_dir: Path,
) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    for action in ACTION_FRAME_COUNTS:
        paths = [path for label, path in exported if label.startswith(f"{action}_")]
        frames = [Image.open(path).convert("RGBA") for path in paths]
        frames[0].save(
            output_dir / f"{action}.gif",
            save_all=True,
            append_images=frames[1:],
            duration=120,
            loop=0,
            disposal=2,
        )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("sheet", type=Path)
    parser.add_argument("output_dir", type=Path)
    parser.add_argument("contact_sheet", type=Path)
    parser.add_argument("preview_dir", type=Path)
    args = parser.parse_args()

    sheet = Image.open(args.sheet).convert("RGBA")
    exported = _export_frames(sheet, args.output_dir)
    _write_contact_sheet(exported, args.contact_sheet)
    _write_previews(exported, args.preview_dir)
    print(f"Exported {len(exported)} isolated mascot frames")


if __name__ == "__main__":
    main()
