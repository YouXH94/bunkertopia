from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data"
ART = ROOT / "assets" / "art"
RAW = ART / "source" / "generated_raw"
TILES = ART / "tiles" / "generated"
MANIFEST = DATA / "art_asset_manifest.json"

TILE = 64

ATLASES = {
    "stone_road_atlas": {
        "source": RAW / "imagegen_stone_road_atlas_source.png",
        "output": TILES / "stone_road_atlas.png",
        "columns": 4,
        "rows": 4,
        "tiles": [
            "road_end_up",
            "road_end_down",
            "road_end_left",
            "road_end_right",
            "road_corner_up_right",
            "road_corner_right_down",
            "road_corner_down_left",
            "road_corner_left_up",
            "road_straight_horizontal",
            "road_straight_vertical",
            "road_t_up",
            "road_t_right",
            "road_t_down",
            "road_t_left",
            "road_cross",
            "road_broken_plaza",
        ],
    },
    "mountain_atlas": {
        "source": RAW / "imagegen_mountain_connectable_atlas_source.png",
        "output": TILES / "mountain_atlas.png",
        "columns": 4,
        "rows": 4,
        "tiles": [
            "mountain_isolated",
            "mountain_end_north",
            "mountain_end_east",
            "mountain_end_south",
            "mountain_end_west",
            "mountain_straight_ns",
            "mountain_straight_ew",
            "mountain_corner_ne",
            "mountain_corner_es",
            "mountain_corner_sw",
            "mountain_corner_wn",
            "mountain_t_nes",
            "mountain_t_esw",
            "mountain_t_swn",
            "mountain_t_wne",
            "mountain_cross",
        ],
    },
    "nature_atlas": {
        "source": RAW / "imagegen_nature_atlas_source.png",
        "output": TILES / "nature_atlas.png",
        "columns": 5,
        "rows": 4,
        "tiles": [
            "dead_tree",
            "pine_tree",
            "bent_tree",
            "tree_stump",
            "fallen_log",
            "large_bush",
            "small_bush",
            "dry_grass",
            "wild_grass",
            "dead_flowers",
            "rock_cluster",
            "mossy_rock",
            "mud_pit",
            "cracked_soil",
            "root_cluster",
            "grass_variant_a",
            "grass_variant_b",
            "flower_variant",
            "sapling",
            "scrub_patch",
        ],
    },
}


def res(path: Path) -> str:
    return "res://" + str(path.relative_to(ROOT)).replace("\\", "/")


def dark_runs(image: Image.Image, axis: str, threshold: int = 32, ratio: float = 0.70) -> list[tuple[int, int]]:
    rgb = image.convert("RGB")
    pixels = rgb.load()
    width, height = rgb.size
    values: list[bool] = []
    if axis == "x":
        for x in range(width):
            dark = sum(1 for y in range(height) if sum(pixels[x, y]) / 3 < threshold)
            values.append(dark / height >= ratio)
    else:
        for y in range(height):
            dark = sum(1 for x in range(width) if sum(pixels[x, y]) / 3 < threshold)
            values.append(dark / width >= ratio)

    runs: list[tuple[int, int]] = []
    start: int | None = None
    for index, active in enumerate(values):
        if active and start is None:
            start = index
        if (not active or index == len(values) - 1) and start is not None:
            end = index - 1 if not active else index
            if end - start + 1 >= 3:
                runs.append((start, end))
            start = None
    return runs


def choose_grid_runs(image: Image.Image, columns: int, rows: int) -> tuple[list[tuple[int, int]], list[tuple[int, int]]]:
    vertical = dark_runs(image, "x")
    horizontal = dark_runs(image, "y")
    if len(vertical) < columns + 1 or len(horizontal) < rows + 1:
        raise RuntimeError(
            f"Could not detect atlas gutters in {image.size}: "
            f"vertical={vertical}, horizontal={horizontal}"
        )
    vertical = vertical[: columns + 1]
    horizontal = horizontal[: rows + 1]
    return vertical, horizontal


def extract_cells(source_path: Path, columns: int, rows: int) -> list[Image.Image]:
    source = Image.open(source_path).convert("RGBA")
    vertical, horizontal = choose_grid_runs(source, columns, rows)
    cells: list[Image.Image] = []
    for row in range(rows):
        for column in range(columns):
            left = vertical[column][1] + 1
            right = vertical[column + 1][0]
            top = horizontal[row][1] + 1
            bottom = horizontal[row + 1][0]
            cell = source.crop((left, top, right, bottom)).resize((TILE, TILE), Image.Resampling.LANCZOS)
            cells.append(cell.convert("RGBA"))
    return cells


def extract_atlas(source_path: Path, output_path: Path, columns: int, rows: int) -> None:
    cells = extract_cells(source_path, columns, rows)
    atlas = Image.new("RGBA", (columns * TILE, rows * TILE), (0, 0, 0, 0))
    for index, cell in enumerate(cells):
        column = index % columns
        row = index // columns
        atlas.alpha_composite(cell, (column * TILE, row * TILE))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(output_path)


def build_preview(outputs: list[Path]) -> Path:
    images = [(path.name, Image.open(path).convert("RGBA")) for path in outputs]
    width = max(image.width for _, image in images) + 24
    height = sum(image.height + 34 for _, image in images) + 12
    preview = Image.new("RGBA", (width, height), (24, 25, 23, 255))
    draw = ImageDraw.Draw(preview)
    y = 12
    for name, image in images:
        draw.text((12, y), name, fill=(214, 208, 178, 255))
        y += 18
        draw.rectangle((12, y, 12 + image.width + 1, y + image.height + 1), outline=(75, 77, 67, 255))
        preview.alpha_composite(image, (13, y + 1))
        y += image.height + 16
    path = RAW / "nature_environment_preview.png"
    preview.save(path)
    return path


def build_mountain_connectivity_preview(mountain_atlas_path: Path) -> Path:
    atlas = Image.open(mountain_atlas_path).convert("RGBA")
    tile_names = {
        "iso": 0,
        "n": 1,
        "e": 2,
        "s": 3,
        "w": 4,
        "ns": 5,
        "ew": 6,
        "ne": 7,
        "es": 8,
        "sw": 9,
        "wn": 10,
        "nes": 11,
        "esw": 12,
        "swn": 13,
        "wne": 14,
        "cross": 15,
    }
    layout = [
        ["iso", "n", "n", "iso", "iso", "iso"],
        ["e", "cross", "cross", "ew", "es", "iso"],
        ["iso", "ns", "iso", "iso", "ns", "iso"],
        ["e", "wne", "ew", "ew", "swn", "w"],
        ["iso", "s", "iso", "iso", "s", "iso"],
    ]
    preview = Image.new("RGBA", (len(layout[0]) * TILE, len(layout) * TILE), (30, 29, 24, 255))
    for row_index, row in enumerate(layout):
        for column_index, tile_name in enumerate(row):
            tile_index = tile_names[tile_name]
            tile = atlas.crop((
                (tile_index % 4) * TILE,
                (tile_index // 4) * TILE,
                (tile_index % 4 + 1) * TILE,
                (tile_index // 4 + 1) * TILE,
            ))
            preview.alpha_composite(tile, (column_index * TILE, row_index * TILE))
    path = RAW / "mountain_connectivity_preview.png"
    preview.save(path)
    return path


def update_manifest(preview: Path, mountain_connectivity_preview: Path) -> None:
    if not MANIFEST.exists():
        return
    data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    atlases = data.setdefault("atlases", {})
    for atlas_id, atlas in ATLASES.items():
        output = atlas["output"]
        with Image.open(output) as image:
            atlases[atlas_id] = {
                "path": res(output),
                "source": res(atlas["source"]),
                "size": [image.width, image.height],
                "tile_size": [TILE, TILE],
                "columns": atlas["columns"],
                "rows": atlas["rows"],
                "tiles": atlas["tiles"],
                "style": "imagegen_target_reference",
            }
    data.setdefault("previews", {})["nature_environment"] = res(preview)
    data.setdefault("previews", {})["mountain_connectivity"] = res(mountain_connectivity_preview)
    MANIFEST.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    outputs: list[Path] = []
    for atlas_id, atlas in ATLASES.items():
        source = atlas["source"]
        if not source.exists():
            raise FileNotFoundError(f"Missing imagegen source for {atlas_id}: {source}")
        extract_atlas(source, atlas["output"], atlas["columns"], atlas["rows"])
        outputs.append(atlas["output"])
    preview = build_preview(outputs)
    mountain_preview = build_mountain_connectivity_preview(ATLASES["mountain_atlas"]["output"])
    update_manifest(preview, mountain_preview)
    print("Extracted imagegen nature atlases: " + ", ".join(path.name for path in outputs))


if __name__ == "__main__":
    main()
