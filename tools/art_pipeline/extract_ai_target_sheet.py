from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets" / "art" / "source" / "generated_raw" / "ai_target_sprite_sheet.png"
MANIFEST = ROOT / "data" / "art_asset_manifest.json"
CHAR_DIR = ROOT / "assets" / "art" / "characters" / "sheets"
OBJECT_DIR = ROOT / "assets" / "art" / "objects" / "generated"
CUTOUT_DIR = ROOT / "assets" / "art" / "source" / "cutouts"
FRAME = 64
COLUMNS = 4

ANIMATIONS = {
    "idle_down": {"row": 0, "frames": 2, "fps": 2},
    "idle_side": {"row": 1, "frames": 2, "fps": 2},
    "idle_up": {"row": 2, "frames": 2, "fps": 2},
    "walk_down": {"row": 3, "frames": 4, "fps": 7},
    "walk_side": {"row": 4, "frames": 4, "fps": 8},
    "walk_up": {"row": 5, "frames": 4, "fps": 7},
    "attack_down": {"row": 6, "frames": 3, "fps": 10},
    "attack_side": {"row": 7, "frames": 3, "fps": 10},
    "attack_up": {"row": 8, "frames": 3, "fps": 10},
    "hit_down": {"row": 9, "frames": 2, "fps": 8},
    "death_down": {"row": 10, "frames": 4, "fps": 6},
}

BOXES = {
    "scientist_front": [(48, 21, 82, 95), (117, 20, 154, 95), (187, 19, 224, 95), (258, 19, 294, 95), (327, 19, 364, 95), (404, 20, 452, 95), (483, 22, 530, 95), (557, 22, 611, 95), (641, 23, 702, 95)],
    "scientist_side": [(49, 107, 82, 184), (118, 107, 150, 184), (186, 107, 223, 184), (257, 107, 295, 184), (327, 107, 362, 184), (400, 107, 451, 184), (479, 107, 540, 184), (561, 115, 610, 183), (627, 156, 705, 184)],
    "walker": [(38, 213, 79, 288), (107, 215, 151, 288), (180, 213, 221, 288), (246, 213, 288, 288), (322, 213, 360, 288), (402, 213, 442, 288), (473, 213, 514, 288), (545, 213, 588, 288), (617, 213, 661, 288)],
    "runner": [(35, 312, 93, 387), (107, 315, 159, 387), (179, 312, 234, 386), (260, 313, 302, 386), (335, 312, 380, 387), (404, 313, 447, 386), (470, 312, 529, 386)],
    "brute": [(32, 410, 91, 495), (116, 410, 167, 495), (194, 407, 243, 495), (269, 407, 317, 496), (344, 409, 401, 495), (422, 410, 483, 495), (500, 410, 575, 495)],
    "crusher": [(32, 517, 92, 609), (119, 519, 176, 609), (199, 519, 252, 608), (277, 519, 329, 608), (357, 518, 407, 608), (432, 518, 483, 608), (506, 520, 577, 609)],
    "armored": [(35, 632, 93, 725), (122, 632, 174, 726), (195, 632, 245, 726), (270, 632, 320, 725), (342, 632, 398, 726), (424, 632, 495, 726)],
}

OBJECT_BOXES = {
    "bunker_core": (748, 16, 1016, 195),
    "lab_station": (1056, 36, 1250, 174),
    "workbench": (1296, 39, 1502, 187),
    "furnace": (739, 222, 966, 384),
    "farm_plot": (1000, 222, 1223, 385),
    "animal_pen": (1256, 217, 1507, 385),
    "barricade": (702, 410, 888, 526),
    "scrap_wall": (920, 409, 1098, 522),
    "gate": (1124, 406, 1289, 522),
    "wire_fence": (1318, 409, 1503, 522),
    "spike_trap": (664, 567, 794, 655),
    "flame_trap": (842, 548, 973, 660),
    "basic_turret": (1007, 553, 1142, 653),
    "shotgun_turret": (1195, 545, 1311, 655),
    "spotlight": (1377, 548, 1451, 660),
    "generator": (650, 676, 844, 804),
    "battery": (897, 688, 1039, 801),
    "power_pole": (1117, 657, 1248, 820),
    "container": (1312, 684, 1453, 809),
    "crash_plane": (51, 747, 395, 991),
    "ruined_building": (411, 766, 771, 990),
    "rubble": (808, 838, 1129, 993),
    "wrecked_car": (1181, 841, 1462, 993),
}


def is_green(pixel: tuple[int, int, int, int]) -> bool:
    r, g, b, _a = pixel
    return g > 135 and r < 115 and b < 115 and g > r * 1.45 and g > b * 1.45


def key_alpha(img: Image.Image) -> Image.Image:
    src = img.convert("RGBA")
    data = []
    for pixel in src.getdata():
        r, g, b, a = pixel
        bright_key = g > 140 and r < 95 and b < 95 and g > r * 1.35 and g > b * 1.35
        edge_key = g > 95 and r < 80 and b < 80 and g > r * 1.25 and g > b * 1.25 and a < 160
        dark_key = g > 82 and r < 48 and b < 48 and g > r * 1.45 and g > b * 1.45
        if bright_key or edge_key or dark_key or a < 32:
            data.append((r, g, b, 0))
        else:
            if g > 100 and g > r * 1.25 and g > b * 1.25 and g - max(r, b) > 22:
                g = max(r, b) + 18
            data.append((r, g, b, a))
    src.putdata(data)
    return src


def clean_transparency(img: Image.Image) -> Image.Image:
    src = img.convert("RGBA")
    data = []
    for r, g, b, a in src.getdata():
        greenish = g > max(r, b) + 12 and r < 115 and b < 115
        halo = greenish and r < 72 and b < 72 and a < 230
        if a < 64 or halo:
            data.append((r, g, b, 0))
        else:
            if greenish:
                g = max(r, b) + 8
            data.append((r, g, b, a))
    src.putdata(data)
    return src


def crop(source: Image.Image, box: tuple[int, int, int, int], pad: int = 3) -> Image.Image:
    x0, y0, x1, y1 = box
    piece = key_alpha(source.crop((max(0, x0 - pad), max(0, y0 - pad), min(source.width, x1 + pad), min(source.height, y1 + pad))))
    bbox = piece.getbbox()
    if bbox is not None:
        px0, py0, px1, py1 = bbox
        piece = piece.crop((max(0, px0 - 2), max(0, py0 - 2), min(piece.width, px1 + 2), min(piece.height, py1 + 2)))
    return piece


def paste_center(sheet: Image.Image, piece: Image.Image, col: int, row: int, y_bias: int = 0) -> None:
    max_w = FRAME - 4
    max_h = FRAME - 4
    if piece.width > max_w or piece.height > max_h:
        scale = min(max_w / piece.width, max_h / piece.height)
        piece = piece.resize((max(1, int(piece.width * scale)), max(1, int(piece.height * scale))), Image.Resampling.LANCZOS)
    x = col * FRAME + (FRAME - piece.width) // 2
    y = row * FRAME + FRAME - piece.height - 3 + y_bias
    sheet.alpha_composite(piece, (x, y))


def build_character(source: Image.Image, character_id: str, front_key: str, side_key: str | None = None) -> dict:
    side_key = side_key or front_key
    front = [crop(source, box) for box in BOXES[front_key]]
    side = [crop(source, box) for box in BOXES[side_key]]
    rows = max(meta["row"] for meta in ANIMATIONS.values()) + 1
    sheet = Image.new("RGBA", (FRAME * COLUMNS, FRAME * rows), (0, 0, 0, 0))

    for col, piece in enumerate(front[:2]):
        paste_center(sheet, piece, col, ANIMATIONS["idle_down"]["row"])
        paste_center(sheet, piece, col, ANIMATIONS["idle_up"]["row"])
    for col, piece in enumerate(side[:2]):
        paste_center(sheet, piece, col, ANIMATIONS["idle_side"]["row"])
    for col, piece in enumerate(front[:4]):
        paste_center(sheet, piece, col, ANIMATIONS["walk_down"]["row"])
        paste_center(sheet, piece, col, ANIMATIONS["walk_up"]["row"])
    for col, piece in enumerate(side[:4]):
        paste_center(sheet, piece, col, ANIMATIONS["walk_side"]["row"])
    for col, piece in enumerate(front[4:7]):
        paste_center(sheet, piece, col, ANIMATIONS["attack_down"]["row"])
        paste_center(sheet, piece, col, ANIMATIONS["attack_up"]["row"])
    for col, piece in enumerate(side[4:7]):
        paste_center(sheet, piece, col, ANIMATIONS["attack_side"]["row"])
    for col, piece in enumerate(front[1:3]):
        paste_center(sheet, piece, col, ANIMATIONS["hit_down"]["row"])
    death_source = side[-1] if character_id == "scientist" else front[-1]
    for col in range(4):
        paste_center(sheet, death_source, col, ANIMATIONS["death_down"]["row"])

    CHAR_DIR.mkdir(parents=True, exist_ok=True)
    path = CHAR_DIR / f"{character_id}_sheet.png"
    sheet = clean_transparency(sheet)
    sheet.save(path)
    return {
        "sheet": res(path),
        "frame_size": [FRAME, FRAME],
        "animations": ANIMATIONS,
        "offset": [0, -12],
        "source": res(SOURCE),
        "style": "ai_target_preview",
    }


def build_crawler(source: Image.Image) -> dict:
    base = [crop(source, box) for box in BOXES["walker"][:4]]
    rows = max(meta["row"] for meta in ANIMATIONS.values()) + 1
    sheet = Image.new("RGBA", (FRAME * COLUMNS, FRAME * rows), (0, 0, 0, 0))
    for row_name in ANIMATIONS.keys():
        row = ANIMATIONS[row_name]["row"]
        for col in range(4):
            piece = base[col % len(base)].resize((max(1, base[col % len(base)].width * 3 // 4), max(1, base[col % len(base)].height * 3 // 4)), Image.Resampling.LANCZOS)
            paste_center(sheet, piece, col, row, 8)
    path = CHAR_DIR / "crawler_sheet.png"
    sheet = clean_transparency(sheet)
    sheet.save(path)
    return {"sheet": res(path), "frame_size": [FRAME, FRAME], "animations": ANIMATIONS, "offset": [0, -8], "source": res(SOURCE), "style": "ai_target_preview"}


def build_objects(source: Image.Image) -> dict:
    OBJECT_DIR.mkdir(parents=True, exist_ok=True)
    CUTOUT_DIR.mkdir(parents=True, exist_ok=True)
    objects = {}
    for object_id, box in OBJECT_BOXES.items():
        piece = crop(source, box, 5)
        path = OBJECT_DIR / f"{object_id}.png"
        cutout = CUTOUT_DIR / f"{object_id}.png"
        piece = clean_transparency(piece)
        piece.save(path)
        piece.save(cutout)
        objects[object_id] = {
            "path": res(path),
            "size": [piece.width, piece.height],
            "scale": object_scale(object_id),
            "offset": [0, -8],
            "source": res(SOURCE),
            "style": "ai_target_preview",
        }
    return objects


def object_scale(object_id: str) -> float:
    if object_id in ["crash_plane", "ruined_building", "rubble", "wrecked_car"]:
        return 0.72
    if object_id in ["bunker_core", "furnace", "farm_plot", "animal_pen", "barricade", "scrap_wall", "gate", "wire_fence"]:
        return 0.58
    if object_id in ["lab_station", "workbench", "generator"]:
        return 0.64
    if object_id in ["power_pole"]:
        return 0.55
    if object_id in ["spotlight", "spike_trap", "flame_trap", "basic_turret", "shotgun_turret", "battery", "container"]:
        return 0.72
    return 0.65


def res(path: Path) -> str:
    return "res://" + str(path.relative_to(ROOT))


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract the AI-generated target-style source sheet into Godot-ready assets.")
    parser.add_argument("--source", default=SOURCE, type=Path)
    parser.add_argument("--manifest", default=MANIFEST, type=Path)
    args = parser.parse_args()
    if not args.source.exists():
        print(f"missing source sheet: {args.source}")
        return 2
    source = Image.open(args.source).convert("RGBA")
    if args.manifest.exists():
        manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    else:
        manifest = {}
    manifest.setdefault("style", {})
    manifest["style"].update({
        "name": "preview_matched_dirty_pixel_art",
        "reference": "165B0C2C-FF86-4F68-B4E7-34CFD2DD5120.PNG right-side gameplay panels",
        "source_sheet": res(args.source),
        "chroma_key": "#00ff00",
    })
    manifest["characters"] = {
        "scientist": build_character(source, "scientist", "scientist_front", "scientist_side"),
        "walker": build_character(source, "walker", "walker"),
        "runner": build_character(source, "runner", "runner"),
        "brute": build_character(source, "brute", "brute"),
        "crusher": build_character(source, "crusher", "crusher"),
        "crawler": build_crawler(source),
        "fire_weak_infected": build_character(source, "fire_weak_infected", "brute"),
        "armored": build_character(source, "armored", "armored"),
    }
    manifest["objects"] = build_objects(source)
    args.manifest.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"updated {args.manifest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
