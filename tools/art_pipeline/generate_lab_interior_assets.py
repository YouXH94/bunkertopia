from __future__ import annotations

import json
from pathlib import Path
from random import Random

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data"
ART = ROOT / "assets" / "art"
OBJECTS = ART / "objects" / "generated"
TILES = ART / "tiles" / "generated"
ANIMATIONS = ART / "objects" / "animations"
MANIFEST = DATA / "art_asset_manifest.json"

RNG = Random(731)

INK = (11, 12, 11, 255)
SHADOW = (0, 0, 0, 86)
CONCRETE = (62, 65, 60, 255)
CONCRETE_DARK = (37, 40, 38, 255)
CONCRETE_LIGHT = (91, 91, 78, 255)
METAL = (82, 88, 84, 255)
METAL_DARK = (43, 48, 48, 255)
RUST = (114, 67, 38, 255)
RUST_DARK = (71, 42, 32, 255)
LAB_GLOW = (88, 167, 154, 255)
LAB_GLOW_DARK = (38, 83, 86, 255)
WARNING = (186, 83, 47, 255)
DIRT = (44, 38, 30, 255)
FABRIC = (94, 86, 67, 255)
WOOD = (89, 61, 39, 255)


def ensure_dirs() -> None:
    for path in [OBJECTS, TILES, ANIMATIONS]:
        path.mkdir(parents=True, exist_ok=True)


def res(path: Path) -> str:
    return "res://" + str(path.relative_to(ROOT)).replace("\\", "/")


def save(path: Path, image: Image.Image) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)


def new(size: tuple[int, int], fill=(0, 0, 0, 0)) -> Image.Image:
    return Image.new("RGBA", size, fill)


def rect(draw: ImageDraw.ImageDraw, box, fill, outline=INK, width: int = 2) -> None:
    draw.rectangle(box, fill=outline)
    x0, y0, x1, y1 = box
    draw.rectangle((x0 + width, y0 + width, x1 - width, y1 - width), fill=fill)


def shadow(draw: ImageDraw.ImageDraw, box, alpha: int = 86) -> None:
    draw.ellipse(box, fill=(0, 0, 0, alpha))


def noise(draw: ImageDraw.ImageDraw, box, count: int, palette) -> None:
    x0, y0, x1, y1 = box
    for _ in range(count):
        x = RNG.randint(x0, max(x0, x1 - 1))
        y = RNG.randint(y0, max(y0, y1 - 1))
        length = RNG.randint(2, 10)
        color = RNG.choice(palette)
        draw.line((x, y, min(x1, x + length), y + RNG.randint(-1, 1)), fill=color, width=1)


def crop_alpha(image: Image.Image, pad: int = 4) -> Image.Image:
    bbox = image.getbbox()
    if bbox is None:
        return image
    x0, y0, x1, y1 = bbox
    return image.crop((max(0, x0 - pad), max(0, y0 - pad), min(image.width, x1 + pad), min(image.height, y1 + pad)))


def iso_block(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, depth: int, top, left, right) -> None:
    top_poly = [(x, y + depth), (x + w // 2, y), (x + w, y + depth), (x + w // 2, y + depth * 2)]
    left_poly = [(x, y + depth), (x + w // 2, y + depth * 2), (x + w // 2, y + depth * 2 + h), (x, y + depth + h)]
    right_poly = [(x + w, y + depth), (x + w // 2, y + depth * 2), (x + w // 2, y + depth * 2 + h), (x + w, y + depth + h)]
    draw.polygon(left_poly, fill=left, outline=INK)
    draw.polygon(right_poly, fill=right, outline=INK)
    draw.polygon(top_poly, fill=top, outline=INK)
    noise(draw, (x + 3, y + depth + 3, x + w - 3, y + depth * 2 + h - 3), 18, [RUST, RUST_DARK, METAL_DARK])


def make_lab_floor(name: str, accent: str) -> Path:
    image = new((64, 64), CONCRETE)
    draw = ImageDraw.Draw(image)
    for x in range(0, 65, 16):
        draw.line((x, 0, x, 64), fill=CONCRETE_DARK, width=1)
    for y in range(0, 65, 16):
        draw.line((0, y, 64, y), fill=CONCRETE_DARK, width=1)
    noise(draw, (0, 0, 63, 63), 90, [CONCRETE_LIGHT, CONCRETE_DARK, DIRT, RUST_DARK])
    if accent == "grate":
        rect(draw, (12, 18, 52, 46), (39, 43, 42, 255), METAL_DARK, 2)
        for x in range(18, 50, 7):
            draw.line((x, 20, x, 44), fill=(102, 106, 95, 255), width=2)
    elif accent == "cable":
        draw.line((4, 52, 28, 40, 42, 42, 63, 29), fill=(28, 31, 31, 255), width=4)
        draw.line((3, 52, 28, 40, 42, 42, 62, 29), fill=(114, 53, 40, 255), width=1)
        draw.rectangle((44, 10, 54, 20), fill=LAB_GLOW_DARK, outline=INK)
    path = TILES / f"{name}.png"
    save(path, image)
    return path


def make_lab_wall(name: str, variant: str) -> Path:
    image = new((96, 96))
    draw = ImageDraw.Draw(image)
    shadow(draw, (12, 76, 84, 92), 60)
    rect(draw, (10, 14, 86, 74), (50, 55, 53, 255), INK, 3)
    draw.rectangle((14, 18, 82, 31), fill=(72, 76, 69, 255), outline=INK)
    draw.rectangle((14, 58, 82, 70), fill=(31, 35, 35, 255), outline=INK)
    for x in range(22, 80, 17):
        draw.line((x, 18, x, 70), fill=(33, 36, 35, 255), width=1)
    if variant == "pipes":
        for y in [39, 48]:
            draw.line((14, y, 82, y - 6), fill=METAL, width=4)
            draw.line((14, y + 1, 82, y - 5), fill=INK, width=1)
        draw.rectangle((58, 34, 74, 54), fill=RUST_DARK, outline=INK)
    elif variant == "warning":
        draw.rectangle((32, 36, 64, 56), fill=(35, 37, 34, 255), outline=INK)
        for x in range(34, 64, 8):
            draw.line((x, 55, x + 12, 37), fill=WARNING, width=3)
    else:
        draw.rectangle((28, 36, 68, 54), fill=LAB_GLOW_DARK, outline=INK)
        draw.line((32, 46, 64, 46), fill=LAB_GLOW, width=2)
    noise(draw, (12, 16, 84, 72), 24, [RUST, RUST_DARK, CONCRETE_DARK])
    path = OBJECTS / f"{name}.png"
    save(path, crop_alpha(image))
    return path


def make_bunker_entrance() -> Path:
    image = new((196, 150))
    draw = ImageDraw.Draw(image)
    shadow(draw, (22, 112, 176, 142), 98)
    draw.polygon([(16, 88), (98, 28), (180, 88), (146, 126), (48, 126)], fill=(37, 39, 36, 255), outline=INK)
    draw.polygon([(34, 82), (98, 42), (162, 82), (130, 106), (66, 106)], fill=(72, 70, 59, 255), outline=INK)
    draw.rectangle((74, 72, 122, 128), fill=INK)
    draw.rectangle((82, 78, 114, 128), fill=(14, 17, 18, 255))
    draw.rectangle((68, 62, 128, 76), fill=METAL_DARK, outline=INK)
    draw.line((42, 94, 71, 78), fill=RUST, width=4)
    draw.line((126, 78, 156, 96), fill=RUST, width=4)
    draw.rectangle((42, 102, 62, 116), fill=(66, 48, 36, 255), outline=INK)
    draw.rectangle((134, 99, 154, 113), fill=(66, 48, 36, 255), outline=INK)
    for x in [88, 98, 108]:
        draw.line((x, 80, x, 126), fill=(31, 33, 32, 255), width=2)
    noise(draw, (22, 48, 174, 128), 40, [RUST, RUST_DARK, CONCRETE_DARK, DIRT])
    path = OBJECTS / "bunker_entrance.png"
    save(path, crop_alpha(image))
    return path


def make_supercomputer() -> Path:
    image = new((210, 154))
    draw = ImageDraw.Draw(image)
    shadow(draw, (20, 124, 190, 148), 92)
    iso_block(draw, 22, 50, 72, 46, 28, (62, 66, 64, 255), (36, 42, 43, 255), (28, 35, 36, 255))
    iso_block(draw, 76, 36, 88, 54, 30, (69, 74, 71, 255), (41, 48, 49, 255), (31, 39, 41, 255))
    iso_block(draw, 142, 56, 44, 38, 22, (57, 63, 61, 255), (34, 39, 40, 255), (27, 34, 35, 255))
    draw.rectangle((90, 51, 150, 84), fill=(13, 20, 22, 255), outline=INK, width=3)
    draw.rectangle((96, 57, 144, 78), fill=LAB_GLOW_DARK)
    draw.line((100, 64, 116, 64, 118, 70, 139, 70), fill=LAB_GLOW, width=2)
    for x in [38, 50, 62, 158, 171]:
        draw.rectangle((x, 82, x + 6, 94), fill=(111, 79, 45, 255), outline=INK)
    for y in [100, 108, 116]:
        draw.line((32, y, 180, y + RNG.randint(-2, 2)), fill=(24, 30, 31, 255), width=3)
    draw.line((74, 108, 52, 133, 106, 132, 128, 116), fill=(33, 34, 32, 255), width=4)
    draw.line((74, 109, 52, 134, 106, 133, 128, 117), fill=RUST, width=1)
    path = OBJECTS / "supercomputer.png"
    save(path, crop_alpha(image))
    return path


def make_screen_frames() -> list[Path]:
    paths: list[Path] = []
    frames: list[Image.Image] = []
    for frame in range(8):
        image = new((64, 48))
        draw = ImageDraw.Draw(image)
        rect(draw, (2, 2, 61, 45), (10, 18, 20, 255), INK, 2)
        draw.rectangle((7, 7, 56, 38), fill=(18, 48, 48, 255))
        for row in range(4):
            y = 11 + row * 6
            start = 10 + ((frame + row * 3) % 15)
            draw.line((start, y, min(55, start + 15 + row * 3), y), fill=LAB_GLOW, width=1)
        for col in range(5):
            x = 11 + col * 9
            height = 4 + ((frame * 3 + col * 5) % 18)
            draw.line((x, 35, x, 35 - height), fill=(80, 170, 151, 255), width=2)
        draw.rectangle((8 + frame * 3 % 40, 30, 12 + frame * 3 % 40, 34), fill=(210, 146, 62, 255))
        path = OBJECTS / f"supercomputer_screen_frame_{frame:02d}.png"
        save(path, image)
        save(ANIMATIONS / f"supercomputer_screen_frame_{frame:02d}.png", image)
        paths.append(path)
        frames.append(image)
    sheet = new((64 * len(frames), 48))
    for index, frame in enumerate(frames):
        sheet.alpha_composite(frame, (index * 64, 0))
    save(ANIMATIONS / "supercomputer_screen_sheet.png", sheet)
    return paths


def make_bed() -> Path:
    image = new((126, 84))
    draw = ImageDraw.Draw(image)
    shadow(draw, (13, 60, 115, 78), 70)
    draw.polygon([(16, 34), (62, 14), (112, 35), (64, 62)], fill=(55, 44, 35, 255), outline=INK)
    draw.polygon([(20, 34), (62, 18), (105, 36), (64, 56)], fill=FABRIC, outline=INK)
    draw.polygon([(22, 35), (40, 27), (62, 36), (43, 45)], fill=(126, 117, 91, 255), outline=INK)
    draw.line((43, 47, 85, 28), fill=(72, 65, 51, 255), width=2)
    for x, y in [(22, 41), (104, 40), (62, 58)]:
        draw.rectangle((x, y, x + 5, y + 14), fill=METAL_DARK, outline=INK)
    path = OBJECTS / "bunker_bed.png"
    save(path, crop_alpha(image))
    return path


def make_table(name: str, lab: bool = False) -> Path:
    image = new((116, 82))
    draw = ImageDraw.Draw(image)
    shadow(draw, (14, 59, 104, 76), 68)
    top = (83, 74, 55, 255) if not lab else (72, 79, 75, 255)
    left = (61, 48, 35, 255) if not lab else (46, 54, 53, 255)
    right = (45, 36, 29, 255) if not lab else (35, 43, 44, 255)
    iso_block(draw, 20, 22, 76, 18, 16, top, left, right)
    for x, y in [(32, 43), (76, 43), (43, 56), (88, 52)]:
        draw.rectangle((x, y, x + 5, y + 18), fill=right, outline=INK)
    if lab:
        draw.rectangle((38, 23, 58, 34), fill=LAB_GLOW_DARK, outline=INK)
        draw.line((42, 29, 54, 29), fill=LAB_GLOW, width=2)
        draw.rectangle((68, 24, 83, 34), fill=RUST_DARK, outline=INK)
    else:
        draw.rectangle((44, 20, 60, 27), fill=(122, 104, 75, 255), outline=INK)
        draw.line((68, 22, 82, 31), fill=RUST, width=2)
    path = OBJECTS / f"{name}.png"
    save(path, crop_alpha(image))
    return path


def make_locker() -> Path:
    image = new((76, 112))
    draw = ImageDraw.Draw(image)
    shadow(draw, (12, 88, 68, 105), 72)
    rect(draw, (18, 12, 58, 94), (54, 65, 65, 255), INK, 3)
    draw.line((38, 16, 38, 90), fill=INK, width=2)
    for x in [24, 44]:
        for y in [24, 31, 38]:
            draw.line((x, y, x + 8, y), fill=(104, 111, 102, 255), width=1)
    draw.rectangle((31, 58, 35, 64), fill=RUST, outline=INK)
    draw.rectangle((42, 58, 46, 64), fill=RUST, outline=INK)
    noise(draw, (20, 16, 56, 92), 14, [RUST, RUST_DARK, METAL_DARK])
    path = OBJECTS / "rusty_locker.png"
    save(path, crop_alpha(image))
    return path


def make_shelf() -> Path:
    image = new((108, 100))
    draw = ImageDraw.Draw(image)
    shadow(draw, (14, 78, 96, 94), 65)
    rect(draw, (18, 16, 88, 78), (42, 47, 45, 255), INK, 3)
    for y in [32, 50, 68]:
        draw.line((21, y, 85, y), fill=(91, 81, 59, 255), width=4)
    for x, y, c in [(27, 22, RUST), (43, 21, METAL), (63, 22, LAB_GLOW_DARK), (34, 40, WOOD), (58, 39, RUST_DARK), (73, 57, METAL)]:
        draw.rectangle((x, y, x + 10, y + 10), fill=c, outline=INK)
    path = OBJECTS / "metal_shelf.png"
    save(path, crop_alpha(image))
    return path


def make_chair() -> Path:
    image = new((64, 72))
    draw = ImageDraw.Draw(image)
    shadow(draw, (10, 51, 55, 66), 58)
    draw.polygon([(18, 33), (34, 24), (51, 32), (34, 43)], fill=(66, 54, 42, 255), outline=INK)
    draw.rectangle((19, 13, 44, 31), fill=(51, 55, 52, 255), outline=INK)
    for x, y in [(22, 39), (45, 37), (31, 45), (52, 42)]:
        draw.line((x, y, x - 3, y + 18), fill=METAL_DARK, width=3)
    path = OBJECTS / "metal_chair.png"
    save(path, crop_alpha(image))
    return path


def update_manifest(object_paths: dict[str, Path], tile_paths: dict[str, Path], animation_frames: list[Path]) -> None:
    if not MANIFEST.exists():
        return
    data = json.loads(MANIFEST.read_text())
    objects = data.setdefault("objects", {})
    for asset_id, path in object_paths.items():
        with Image.open(path) as image:
            objects[asset_id] = {
                "path": res(path),
                "size": [image.width, image.height],
                "scale": 1.0,
                "offset": [0, 0],
                "style": "procedural_lab_interior",
            }
    tiles = data.setdefault("tiles", {})
    for asset_id, path in tile_paths.items():
        tiles[asset_id] = {"path": res(path), "size": [64, 64], "style": "procedural_lab_interior"}
    data.setdefault("animations", {})["supercomputer_screen"] = {
        "frames": [res(path) for path in animation_frames],
        "sheet": res(ANIMATIONS / "supercomputer_screen_sheet.png"),
        "frame_size": [64, 48],
        "fps": 6,
        "style": "procedural_lab_interior",
    }
    MANIFEST.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


def main() -> None:
    ensure_dirs()
    tile_paths = {
        "lab_floor": make_lab_floor("lab_floor", "plain"),
        "lab_floor_grate": make_lab_floor("lab_floor_grate", "grate"),
        "lab_floor_cable": make_lab_floor("lab_floor_cable", "cable"),
    }
    object_paths = {
        "bunker_entrance": make_bunker_entrance(),
        "lab_wall_panel": make_lab_wall("lab_wall_panel", "panel"),
        "lab_wall_pipes": make_lab_wall("lab_wall_pipes", "pipes"),
        "lab_wall_warning": make_lab_wall("lab_wall_warning", "warning"),
        "supercomputer": make_supercomputer(),
        "bunker_bed": make_bed(),
        "rusty_table": make_table("rusty_table"),
        "lab_desk": make_table("lab_desk", lab=True),
        "rusty_locker": make_locker(),
        "metal_shelf": make_shelf(),
        "metal_chair": make_chair(),
    }
    screen_frames = make_screen_frames()
    for index, path in enumerate(screen_frames):
        object_paths[f"supercomputer_screen_frame_{index:02d}"] = path
    update_manifest(object_paths, tile_paths, screen_frames)
    print(f"Generated {len(tile_paths)} lab tiles, {len(object_paths)} lab objects, {len(screen_frames)} screen frames.")


if __name__ == "__main__":
    main()
