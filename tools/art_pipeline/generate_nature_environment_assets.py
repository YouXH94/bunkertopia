from __future__ import annotations

import json
from pathlib import Path
from random import Random

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data"
ART = ROOT / "assets" / "art"
TILES = ART / "tiles" / "generated"
RAW = ART / "source" / "generated_raw"
MANIFEST = DATA / "art_asset_manifest.json"

RNG = Random(904)

TILE = 64
INK = (12, 13, 12, 255)
DIRT = (43, 38, 29, 255)
DIRT_DARK = (28, 27, 23, 255)
STONE = (76, 76, 68, 255)
STONE_DARK = (44, 47, 45, 255)
STONE_LIGHT = (104, 100, 84, 255)
RUST = (112, 66, 39, 255)
RUST_DARK = (70, 42, 33, 255)
MOSS = (63, 90, 57, 255)
GRASS = (69, 91, 48, 255)
GRASS_DARK = (39, 58, 36, 255)
WOOD = (81, 58, 39, 255)
WOOD_DARK = (47, 36, 28, 255)
LEAF = (54, 77, 47, 255)
LEAF_DARK = (31, 48, 36, 255)
DEAD_LEAF = (91, 82, 52, 255)
FLOWER = (142, 112, 71, 255)
SHADOW = (0, 0, 0, 72)
MOUNTAIN = (74, 76, 72, 255)
MOUNTAIN_DARK = (39, 42, 42, 255)
MOUNTAIN_LIGHT = (101, 100, 88, 255)

ROAD_TILES = [
    ("road_end_up", {"up"}),
    ("road_end_down", {"down"}),
    ("road_end_left", {"left"}),
    ("road_end_right", {"right"}),
    ("road_corner_up_right", {"up", "right"}),
    ("road_corner_right_down", {"right", "down"}),
    ("road_corner_down_left", {"down", "left"}),
    ("road_corner_left_up", {"left", "up"}),
    ("road_straight_horizontal", {"left", "right"}),
    ("road_straight_vertical", {"up", "down"}),
    ("road_t_up", {"left", "up", "right"}),
    ("road_t_right", {"up", "right", "down"}),
    ("road_t_down", {"left", "down", "right"}),
    ("road_t_left", {"up", "left", "down"}),
    ("road_cross", {"up", "right", "down", "left"}),
    ("road_broken_plaza", {"up", "right", "down", "left", "plaza"}),
]

MOUNTAIN_TILES = [
    "mountain_center",
    "mountain_edge_top",
    "mountain_edge_right",
    "mountain_edge_bottom",
    "mountain_edge_left",
    "mountain_corner_top_right",
    "mountain_corner_bottom_right",
    "mountain_corner_bottom_left",
    "mountain_corner_top_left",
    "gravel_slope",
    "cave_mouth",
    "boulder_field",
]

NATURE_TILES = [
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
]


def ensure_dirs() -> None:
    TILES.mkdir(parents=True, exist_ok=True)
    RAW.mkdir(parents=True, exist_ok=True)


def res(path: Path) -> str:
    return "res://" + str(path.relative_to(ROOT)).replace("\\", "/")


def new(size: tuple[int, int], fill=(0, 0, 0, 0)) -> Image.Image:
    return Image.new("RGBA", size, fill)


def save(path: Path, image: Image.Image) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)


def noise(draw: ImageDraw.ImageDraw, box, count: int, palette) -> None:
    x0, y0, x1, y1 = box
    for _ in range(count):
        x = RNG.randint(x0, x1)
        y = RNG.randint(y0, y1)
        length = RNG.randint(1, 6)
        draw.line((x, y, min(x1, x + length), y + RNG.randint(-1, 1)), fill=RNG.choice(palette), width=1)


def shadow(draw: ImageDraw.ImageDraw, box, alpha: int = 70) -> None:
    draw.ellipse(box, fill=(0, 0, 0, alpha))


def base_ground(draw: ImageDraw.ImageDraw) -> None:
    draw.rectangle((0, 0, TILE, TILE), fill=DIRT)
    noise(draw, (0, 0, 63, 63), 90, [(55, 48, 34, 255), DIRT_DARK, RUST, (64, 58, 42, 255)])


def road_tile(connections: set[str]) -> Image.Image:
    image = new((TILE, TILE), DIRT)
    draw = ImageDraw.Draw(image)
    base_ground(draw)
    center = (32, 32)
    width = 26 if "plaza" not in connections else 36
    half = width // 2
    road = (62, 61, 55, 255)
    edge = (29, 31, 30, 255)
    if "plaza" in connections:
        draw.rectangle((12, 12, 52, 52), fill=edge)
        draw.rectangle((15, 15, 49, 49), fill=road)
    for direction in connections:
        if direction == "up":
            draw.rectangle((center[0] - half - 2, 0, center[0] + half + 2, center[1] + half), fill=edge)
            draw.rectangle((center[0] - half, 0, center[0] + half, center[1] + half), fill=road)
        elif direction == "down":
            draw.rectangle((center[0] - half - 2, center[1] - half, center[0] + half + 2, 64), fill=edge)
            draw.rectangle((center[0] - half, center[1] - half, center[0] + half, 64), fill=road)
        elif direction == "left":
            draw.rectangle((0, center[1] - half - 2, center[0] + half, center[1] + half + 2), fill=edge)
            draw.rectangle((0, center[1] - half, center[0] + half, center[1] + half), fill=road)
        elif direction == "right":
            draw.rectangle((center[0] - half, center[1] - half - 2, 64, center[1] + half + 2), fill=edge)
            draw.rectangle((center[0] - half, center[1] - half, 64, center[1] + half), fill=road)
    draw.rectangle((center[0] - half, center[1] - half, center[0] + half, center[1] + half), fill=road)
    for _ in range(45):
        x = RNG.randint(4, 59)
        y = RNG.randint(4, 59)
        if image.getpixel((x, y))[:3] == road[:3]:
            color = RNG.choice([STONE, STONE_DARK, STONE_LIGHT, (84, 74, 58, 255)])
            draw.rectangle((x, y, min(63, x + RNG.randint(2, 6)), min(63, y + RNG.randint(1, 4))), fill=color)
    for _ in range(9):
        x = RNG.randint(8, 56)
        y = RNG.randint(8, 56)
        draw.line((x, y, x + RNG.randint(-12, 12), y + RNG.randint(5, 17)), fill=(25, 27, 26, 255), width=1)
    return image


def build_road_atlas() -> Path:
    atlas = new((4 * TILE, 4 * TILE))
    for index, (_, connections) in enumerate(ROAD_TILES):
        atlas.alpha_composite(road_tile(set(connections)), ((index % 4) * TILE, (index // 4) * TILE))
    path = TILES / "stone_road_atlas.png"
    save(path, atlas)
    return path


def rock_facets(draw: ImageDraw.ImageDraw, points, light_offset=(0, -7)) -> None:
    draw.polygon(points, fill=MOUNTAIN, outline=INK)
    cx = sum(p[0] for p in points) // len(points)
    cy = sum(p[1] for p in points) // len(points)
    for p in points[::2]:
        draw.line((p[0], p[1], cx + light_offset[0], cy + light_offset[1]), fill=MOUNTAIN_LIGHT, width=1)
    for p in points[1::2]:
        draw.line((p[0], p[1], cx, cy + 8), fill=MOUNTAIN_DARK, width=2)


def mountain_tile(kind: str) -> Image.Image:
    image = new((TILE, TILE))
    draw = ImageDraw.Draw(image)
    shadow(draw, (6, 47, 58, 61), 60)
    if kind == "cave_mouth":
        rock_facets(draw, [(8, 48), (17, 20), (36, 7), (57, 31), (55, 55), (21, 57)])
        draw.ellipse((20, 32, 45, 58), fill=(8, 10, 10, 255), outline=INK)
        draw.rectangle((27, 45, 39, 58), fill=(5, 7, 7, 255))
    elif kind == "boulder_field":
        for _ in range(7):
            x = RNG.randint(8, 46)
            y = RNG.randint(20, 48)
            draw.polygon([(x, y + 12), (x + 9, y), (x + 22, y + 9), (x + 18, y + 23), (x + 3, y + 21)], fill=MOUNTAIN, outline=INK)
            draw.line((x + 9, y, x + 10, y + 18), fill=MOUNTAIN_LIGHT, width=1)
    elif kind == "gravel_slope":
        draw.polygon([(0, 54), (64, 20), (64, 64), (0, 64)], fill=(55, 54, 48, 255), outline=INK)
        for _ in range(28):
            x = RNG.randint(0, 62)
            y = RNG.randint(24, 62)
            draw.rectangle((x, y, x + RNG.randint(1, 4), y + RNG.randint(1, 3)), fill=RNG.choice([STONE, STONE_DARK, MOUNTAIN_LIGHT]))
    else:
        coords = {
            "mountain_center": [(0, 52), (15, 19), (34, 5), (63, 31), (63, 64), (4, 64)],
            "mountain_edge_top": [(0, 42), (18, 12), (44, 8), (64, 40), (64, 64), (0, 64)],
            "mountain_edge_right": [(2, 58), (28, 15), (64, 0), (64, 64)],
            "mountain_edge_bottom": [(0, 50), (22, 31), (44, 27), (64, 48), (64, 64), (0, 64)],
            "mountain_edge_left": [(0, 0), (38, 16), (62, 56), (0, 64)],
            "mountain_corner_top_right": [(8, 55), (22, 18), (64, 0), (64, 64), (12, 64)],
            "mountain_corner_bottom_right": [(6, 61), (32, 21), (64, 28), (64, 64)],
            "mountain_corner_bottom_left": [(0, 28), (34, 22), (58, 62), (0, 64)],
            "mountain_corner_top_left": [(0, 0), (48, 13), (58, 55), (0, 64)],
        }.get(kind, [(8, 52), (28, 16), (50, 24), (58, 58), (18, 62)])
        rock_facets(draw, coords)
    noise(draw, (5, 9, 58, 61), 22, [MOUNTAIN_DARK, MOUNTAIN_LIGHT, RUST_DARK])
    return image


def build_mountain_atlas() -> Path:
    atlas = new((4 * TILE, 3 * TILE))
    for index, name in enumerate(MOUNTAIN_TILES):
        atlas.alpha_composite(mountain_tile(name), ((index % 4) * TILE, (index // 4) * TILE))
    path = TILES / "mountain_atlas.png"
    save(path, atlas)
    return path


def draw_trunk(draw: ImageDraw.ImageDraw, x: int, y: int, h: int = 34) -> None:
    draw.line((x, y, x - 2, y + h), fill=INK, width=7)
    draw.line((x, y, x - 2, y + h), fill=WOOD, width=4)
    draw.line((x + 1, y + 7, x + 12, y - 3), fill=WOOD_DARK, width=3)
    draw.line((x - 1, y + 17, x - 14, y + 10), fill=WOOD_DARK, width=3)


def foliage(draw: ImageDraw.ImageDraw, cx: int, cy: int, color=LEAF) -> None:
    for dx, dy, r in [(-12, 4, 13), (0, -6, 16), (13, 5, 12), (-2, 10, 15)]:
        draw.ellipse((cx + dx - r, cy + dy - r, cx + dx + r, cy + dy + r), fill=INK)
        draw.ellipse((cx + dx - r + 2, cy + dy - r + 2, cx + dx + r - 2, cy + dy + r - 2), fill=color)
    noise(draw, (cx - 25, cy - 22, cx + 25, cy + 23), 14, [LEAF_DARK, DEAD_LEAF, MOSS])


def nature_tile(kind: str) -> Image.Image:
    image = new((TILE, TILE))
    draw = ImageDraw.Draw(image)
    shadow(draw, (8, 50, 58, 62), 52)
    if kind == "dead_tree":
        draw_trunk(draw, 34, 16, 39)
        draw.line((29, 28, 12, 18), fill=WOOD_DARK, width=3)
        draw.line((37, 23, 52, 13), fill=WOOD_DARK, width=3)
    elif kind == "pine_tree":
        draw.rectangle((29, 34, 35, 58), fill=WOOD_DARK, outline=INK)
        for y, w in [(14, 22), (25, 30), (36, 38)]:
            draw.polygon([(32, y), (32 - w, y + 20), (32 + w, y + 20)], fill=INK)
            draw.polygon([(32, y + 3), (32 - w + 4, y + 18), (32 + w - 4, y + 18)], fill=LEAF_DARK)
    elif kind == "bent_tree":
        draw.line((35, 58, 28, 34, 40, 14), fill=INK, width=8)
        draw.line((35, 58, 28, 34, 40, 14), fill=WOOD, width=5)
        foliage(draw, 38, 18, DEAD_LEAF)
    elif kind == "tree_stump":
        draw.ellipse((20, 38, 46, 58), fill=INK)
        draw.rectangle((22, 26, 44, 49), fill=WOOD, outline=INK)
        draw.ellipse((22, 21, 44, 34), fill=(113, 84, 54, 255), outline=INK)
        draw.ellipse((29, 25, 38, 31), outline=WOOD_DARK)
    elif kind == "fallen_log":
        draw.line((10, 43, 54, 30), fill=INK, width=14)
        draw.line((10, 43, 54, 30), fill=WOOD, width=10)
        draw.ellipse((47, 24, 61, 36), fill=(112, 78, 50, 255), outline=INK)
        draw.line((18, 40, 41, 33), fill=WOOD_DARK, width=1)
    elif "bush" in kind or "scrub" in kind:
        count = 5 if "large" in kind else 3
        for _ in range(count):
            x = RNG.randint(16, 46)
            y = RNG.randint(28, 48)
            r = RNG.randint(9, 15)
            draw.ellipse((x - r, y - r, x + r, y + r), fill=INK)
            draw.ellipse((x - r + 2, y - r + 2, x + r - 2, y + r - 2), fill=RNG.choice([LEAF, LEAF_DARK, MOSS, DEAD_LEAF]))
    elif "grass" in kind or "flower" in kind:
        for _ in range(22):
            x = RNG.randint(8, 56)
            y = RNG.randint(32, 58)
            color = RNG.choice([GRASS, GRASS_DARK, DEAD_LEAF])
            draw.line((x, y, x + RNG.randint(-4, 4), y - RNG.randint(6, 18)), fill=color, width=2)
            if "flower" in kind and RNG.random() < 0.25:
                draw.rectangle((x - 1, y - 14, x + 2, y - 11), fill=FLOWER)
    elif "rock" in kind:
        for _ in range(4 if kind == "rock_cluster" else 3):
            x = RNG.randint(11, 43)
            y = RNG.randint(31, 48)
            draw.polygon([(x, y + 10), (x + 8, y), (x + 20, y + 5), (x + 16, y + 18), (x + 3, y + 18)], fill=STONE, outline=INK)
            if kind == "mossy_rock":
                draw.arc((x + 2, y + 3, x + 15, y + 15), 180, 340, fill=MOSS, width=2)
    elif kind == "mud_pit":
        draw.ellipse((10, 30, 56, 55), fill=INK)
        draw.ellipse((13, 32, 53, 52), fill=(39, 34, 27, 255))
        draw.arc((21, 36, 43, 48), 0, 180, fill=(74, 61, 42, 255), width=2)
    elif kind == "cracked_soil":
        draw.ellipse((9, 28, 56, 58), fill=(47, 38, 29, 220))
        for _ in range(8):
            x = RNG.randint(15, 52)
            y = RNG.randint(32, 55)
            draw.line((x, y, x + RNG.randint(-12, 12), y + RNG.randint(-8, 8)), fill=DIRT_DARK, width=1)
    elif kind == "root_cluster":
        for _ in range(8):
            x = RNG.randint(20, 43)
            y = RNG.randint(28, 49)
            draw.line((31, 36, x, y), fill=INK, width=4)
            draw.line((31, 36, x, y), fill=WOOD_DARK, width=2)
    elif kind == "sapling":
        draw.line((32, 55, 31, 36), fill=WOOD_DARK, width=3)
        foliage(draw, 32, 31, LEAF)
    return image


def build_nature_atlas() -> Path:
    atlas = new((5 * TILE, 4 * TILE))
    for index, name in enumerate(NATURE_TILES):
        atlas.alpha_composite(nature_tile(name), ((index % 5) * TILE, (index // 5) * TILE))
    path = TILES / "nature_atlas.png"
    save(path, atlas)
    return path


def build_preview(paths: list[Path]) -> Path:
    images = [(path.name, Image.open(path).convert("RGBA")) for path in paths]
    width = max(image.width for _, image in images) + 24
    height = sum(image.height + 34 for _, image in images) + 12
    preview = new((width, height), (24, 25, 23, 255))
    draw = ImageDraw.Draw(preview)
    y = 12
    for name, image in images:
        draw.text((12, y), name, fill=(214, 208, 178, 255))
        y += 18
        draw.rectangle((12, y, 12 + image.width + 1, y + image.height + 1), outline=(75, 77, 67, 255))
        preview.alpha_composite(image, (13, y + 1))
        y += image.height + 16
    path = RAW / "nature_environment_preview.png"
    save(path, preview)
    return path


def update_manifest(paths: dict[str, Path], preview: Path) -> None:
    if not MANIFEST.exists():
        return
    data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    atlases = data.setdefault("atlases", {})
    atlas_defs = {
        "stone_road_atlas": {"columns": 4, "rows": 4, "tiles": [name for name, _ in ROAD_TILES]},
        "mountain_atlas": {"columns": 4, "rows": 3, "tiles": MOUNTAIN_TILES},
        "nature_atlas": {"columns": 5, "rows": 4, "tiles": NATURE_TILES},
    }
    for atlas_id, path in paths.items():
        with Image.open(path) as image:
            entry = atlas_defs[atlas_id]
            entry.update({
                "path": res(path),
                "size": [image.width, image.height],
                "tile_size": [TILE, TILE],
                "style": "procedural_wasteland_nature",
            })
            atlases[atlas_id] = entry
    data.setdefault("previews", {})["nature_environment"] = res(preview)
    MANIFEST.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    ensure_dirs()
    paths = {
        "stone_road_atlas": build_road_atlas(),
        "mountain_atlas": build_mountain_atlas(),
        "nature_atlas": build_nature_atlas(),
    }
    preview = build_preview(list(paths.values()))
    update_manifest(paths, preview)
    print("Generated nature atlases: " + ", ".join(path.name for path in paths.values()))


if __name__ == "__main__":
    main()
