from __future__ import annotations

import json
import math
from pathlib import Path
from random import Random

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data"
ART = ROOT / "assets" / "art"
SOURCE = ART / "source"
RAW = SOURCE / "generated_raw"
CUTOUTS = SOURCE / "cutouts"
CHAR_SHEETS = ART / "characters" / "sheets"
OBJECTS = ART / "objects" / "generated"
TILES = ART / "tiles" / "generated"
UI = ART / "ui" / "generated"

RNG = Random(143)
FRAME = 64
SHEET_COLS = 4
KEY = (0, 255, 0, 255)

INK = (12, 13, 12, 255)
DEEP = (21, 24, 22, 255)
DIRT = (47, 41, 31, 255)
DUST = (89, 78, 55, 255)
RUST = (121, 67, 39, 255)
RUST_DARK = (72, 43, 34, 255)
METAL = (86, 91, 87, 255)
METAL_DARK = (47, 51, 50, 255)
CONCRETE = (74, 77, 70, 255)
LAB = (83, 134, 125, 255)
LAB_GLOW = (111, 184, 169, 255)
SICK = (111, 134, 83, 255)
BLOOD = (118, 36, 31, 255)
LIGHT = (213, 166, 70, 255)
GREEN = (74, 100, 62, 255)


def ensure_dirs() -> None:
    for folder in [DATA, RAW, CUTOUTS, CHAR_SHEETS, OBJECTS, TILES, UI]:
        folder.mkdir(parents=True, exist_ok=True)


def save(path: Path, image: Image.Image) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)


def new(size: tuple[int, int], fill=(0, 0, 0, 0)) -> Image.Image:
    return Image.new("RGBA", size, fill)


def draw_shadow(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], alpha: int = 96) -> None:
    draw.ellipse(box, fill=(0, 0, 0, alpha))


def rect(draw: ImageDraw.ImageDraw, box, fill, outline=INK, width=2) -> None:
    draw.rectangle(box, fill=outline)
    x0, y0, x1, y1 = box
    draw.rectangle((x0 + width, y0 + width, x1 - width, y1 - width), fill=fill)


def line_noise(draw: ImageDraw.ImageDraw, box, count: int = 26, palette=None) -> None:
    palette = palette or [RUST, RUST_DARK, (32, 35, 32, 255), (118, 106, 74, 255)]
    x0, y0, x1, y1 = box
    for _ in range(count):
        x = RNG.randint(x0, max(x0, x1 - 2))
        y = RNG.randint(y0, max(y0, y1 - 2))
        length = RNG.randint(2, 9)
        draw.line((x, y, min(x1, x + length), y + RNG.randint(-1, 1)), fill=RNG.choice(palette), width=1)


def iso_block(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, depth: int, top, left, right) -> None:
    top_poly = [(x, y + depth), (x + w // 2, y), (x + w, y + depth), (x + w // 2, y + depth * 2)]
    left_poly = [(x, y + depth), (x + w // 2, y + depth * 2), (x + w // 2, y + depth * 2 + h), (x, y + depth + h)]
    right_poly = [(x + w, y + depth), (x + w // 2, y + depth * 2), (x + w // 2, y + depth * 2 + h), (x + w, y + depth + h)]
    draw.polygon(left_poly, fill=left, outline=INK)
    draw.polygon(right_poly, fill=right, outline=INK)
    draw.polygon(top_poly, fill=top, outline=INK)
    line_noise(draw, (x + 3, y + depth + 3, x + w - 3, y + depth * 2 + h - 3), 18)


def crop_alpha(img: Image.Image, pad: int = 4) -> Image.Image:
    bbox = img.getbbox()
    if bbox is None:
        return img
    x0, y0, x1, y1 = bbox
    x0 = max(0, x0 - pad)
    y0 = max(0, y0 - pad)
    x1 = min(img.width, x1 + pad)
    y1 = min(img.height, y1 + pad)
    return img.crop((x0, y0, x1, y1))


def make_tile(name: str, base: tuple[int, int, int], accents: list[tuple[int, int, int]]) -> dict:
    img = new((64, 64), base + (255,))
    draw = ImageDraw.Draw(img)
    for _ in range(155):
        x = RNG.randrange(64)
        y = RNG.randrange(64)
        color = RNG.choice(accents) + (255,)
        draw.rectangle((x, y, min(63, x + RNG.randrange(1, 6)), min(63, y + RNG.randrange(1, 3))), fill=color)
    for _ in range(7):
        x0 = RNG.randrange(-16, 64)
        y0 = RNG.randrange(0, 64)
        draw.line((x0, y0, x0 + RNG.randrange(22, 76), y0 + RNG.randrange(-5, 6)), fill=(max(0, base[0] - 17), max(0, base[1] - 17), max(0, base[2] - 17), 255), width=1)
    if name in ["cracked_road", "dark_ground", "night_ground"]:
        for _ in range(5):
            x = RNG.randrange(4, 62)
            y = RNG.randrange(4, 62)
            draw.line((x, y, x + RNG.randrange(-20, 20), y + RNG.randrange(8, 24)), fill=(18, 18, 18, 255), width=1)
    path = TILES / f"{name}.png"
    save(path, img)
    return {"path": res(path), "size": [64, 64]}


def draw_bunker() -> Image.Image:
    img = new((170, 132))
    draw = ImageDraw.Draw(img)
    draw_shadow(draw, (18, 96, 152, 126), 100)
    iso_block(draw, 22, 34, 126, 46, 36, (78, 66, 48, 255), (45, 46, 41, 255), (34, 38, 37, 255))
    rect(draw, (72, 82, 102, 118), (24, 31, 33, 255))
    draw.rectangle((79, 90, 95, 117), fill=(11, 13, 14, 255))
    draw.rectangle((33, 76, 55, 88), fill=LAB, outline=INK)
    draw.rectangle((117, 70, 137, 82), fill=RUST, outline=INK)
    draw.rectangle((52, 30, 92, 42), fill=(52, 57, 54, 255), outline=INK)
    draw.line((30, 66, 144, 96), fill=RUST, width=3)
    return crop_alpha(img)


def draw_lab() -> Image.Image:
    img = new((136, 116))
    draw = ImageDraw.Draw(img)
    draw_shadow(draw, (16, 86, 124, 108), 82)
    iso_block(draw, 22, 30, 92, 42, 24, (83, 86, 75, 255), (50, 57, 53, 255), (37, 44, 43, 255))
    draw.rectangle((45, 62, 66, 86), fill=LAB, outline=INK)
    draw.rectangle((80, 54, 102, 81), fill=(52, 83, 96, 255), outline=INK)
    draw.line((30, 52, 108, 52), fill=LAB_GLOW, width=2)
    draw.rectangle((56, 17, 84, 34), fill=(76, 82, 74, 255), outline=INK)
    draw.line((98, 27, 104, 15), fill=(111, 113, 90, 255), width=2)
    return crop_alpha(img)


def draw_workbench() -> Image.Image:
    img = new((112, 88))
    draw = ImageDraw.Draw(img)
    draw_shadow(draw, (14, 66, 100, 82), 78)
    iso_block(draw, 18, 26, 78, 22, 18, (92, 70, 45, 255), (64, 47, 34, 255), (51, 39, 32, 255))
    for x in [34, 54, 74]:
        draw.rectangle((x, 50, x + 4, 78), fill=(50, 38, 29, 255), outline=INK)
    draw.rectangle((34, 22, 54, 34), fill=METAL, outline=INK)
    draw.line((68, 27, 91, 24), fill=LIGHT, width=2)
    return crop_alpha(img)


def draw_furnace() -> Image.Image:
    img = new((112, 102))
    draw = ImageDraw.Draw(img)
    draw_shadow(draw, (18, 78, 100, 96), 90)
    iso_block(draw, 25, 26, 64, 34, 22, (77, 72, 61, 255), (48, 46, 42, 255), (36, 38, 36, 255))
    draw.rectangle((44, 56, 72, 80), fill=(20, 18, 16, 255), outline=INK)
    draw.rectangle((49, 60, 68, 76), fill=(198, 84, 42, 255))
    draw.rectangle((57, 10, 72, 32), fill=METAL_DARK, outline=INK)
    for y in [18, 23, 28]:
        draw.line((58, y, 71, y - 3), fill=(84, 88, 82, 180), width=1)
    return crop_alpha(img)


def draw_farm() -> Image.Image:
    img = new((76, 68))
    draw = ImageDraw.Draw(img)
    draw_shadow(draw, (8, 50, 68, 64), 58)
    draw.polygon([(8, 28), (38, 12), (68, 28), (38, 52)], fill=(61, 46, 29, 255), outline=INK)
    for offset in [-18, -6, 6, 18]:
        draw.line((38 + offset, 18, 38 + offset - 22, 39), fill=(35, 32, 23, 255), width=1)
        draw.line((38 + offset, 18, 38 + offset + 20, 39), fill=(84, 67, 37, 255), width=1)
    for x, y in [(28, 31), (38, 27), (48, 33), (34, 40), (52, 41)]:
        draw.line((x, y, x - 2, y - 8), fill=GREEN, width=2)
        draw.line((x, y, x + 2, y - 7), fill=(92, 126, 65, 255), width=2)
    return crop_alpha(img)


def draw_animal_pen() -> Image.Image:
    img = new((132, 94))
    draw = ImageDraw.Draw(img)
    draw_shadow(draw, (16, 72, 118, 90), 72)
    draw.polygon([(18, 44), (62, 20), (116, 42), (70, 73)], fill=(50, 38, 27, 255), outline=INK)
    for x, y in [(25, 40), (44, 30), (64, 22), (84, 29), (106, 38)]:
        draw.rectangle((x, y, x + 5, y + 38), fill=(86, 57, 34, 255), outline=INK)
    draw.line((22, 50, 111, 48), fill=(112, 73, 43, 255), width=3)
    draw.line((28, 65, 100, 63), fill=(112, 73, 43, 255), width=3)
    draw.ellipse((57, 46, 78, 62), fill=(164, 155, 127, 255), outline=INK)
    draw.rectangle((76, 52, 92, 67), fill=(119, 92, 69, 255), outline=INK)
    return crop_alpha(img)


def draw_wall(kind: str) -> Image.Image:
    img = new((78, 58))
    draw = ImageDraw.Draw(img)
    draw_shadow(draw, (5, 42, 72, 55), 66)
    if kind == "barricade":
        for x in range(10, 64, 13):
            draw.polygon([(x, 18), (x + 8, 13), (x + 11, 42), (x + 2, 45)], fill=(92, 61, 36, 255), outline=INK)
        draw.line((8, 28, 69, 22), fill=(125, 82, 43, 255), width=5)
        draw.line((9, 39, 68, 34), fill=(75, 50, 34, 255), width=5)
    else:
        iso_block(draw, 8, 18, 62, 12, 12, (98, 95, 85, 255), (66, 67, 63, 255), (48, 52, 51, 255))
        for x in [18, 32, 48]:
            draw.rectangle((x, 28, x + 8, 44), fill=(75, 80, 78, 255), outline=INK)
        line_noise(draw, (10, 22, 68, 45), 18, [RUST, (42, 43, 41, 255), (118, 111, 95, 255)])
    return crop_alpha(img)


def draw_gate() -> Image.Image:
    img = new((76, 86))
    draw = ImageDraw.Draw(img)
    draw_shadow(draw, (11, 64, 66, 80), 68)
    draw.rectangle((18, 16, 58, 70), fill=(69, 47, 34, 255), outline=INK, width=3)
    for x in [26, 37, 48]:
        draw.rectangle((x, 20, x + 5, 68), fill=(92, 61, 37, 255), outline=INK)
    draw.line((20, 30, 56, 58), fill=METAL, width=4)
    draw.rectangle((48, 41, 56, 49), fill=RUST, outline=INK)
    return crop_alpha(img)


def draw_wire() -> Image.Image:
    img = new((84, 62))
    draw = ImageDraw.Draw(img)
    draw_shadow(draw, (10, 47, 76, 59), 56)
    for x in [14, 33, 52, 71]:
        draw.rectangle((x, 14, x + 4, 50), fill=METAL_DARK, outline=INK)
    for y in [22, 32, 42]:
        points = []
        for x in range(12, 74, 6):
            points.append((x, y + (3 if (x // 6) % 2 == 0 else -3)))
        draw.line(points, fill=(150, 150, 133, 255), width=2)
    for x in [28, 58]:
        draw.line((x, 22, x + 9, 16), fill=LIGHT, width=1)
    return crop_alpha(img)


def draw_spikes() -> Image.Image:
    img = new((76, 58))
    draw = ImageDraw.Draw(img)
    draw_shadow(draw, (8, 43, 68, 55), 56)
    draw.polygon([(8, 38), (39, 22), (68, 38), (39, 51)], fill=(46, 36, 27, 255), outline=INK)
    for x in [20, 31, 42, 53]:
        draw.polygon([(x, 39), (x + 6, 18), (x + 12, 39)], fill=(116, 114, 100, 255), outline=INK)
        draw.line((x + 7, 26, x + 11, 38), fill=RUST, width=1)
    return crop_alpha(img)


def draw_flame_trap() -> Image.Image:
    img = new((76, 62))
    draw = ImageDraw.Draw(img)
    draw_shadow(draw, (9, 45, 68, 58), 62)
    draw.polygon([(12, 36), (38, 22), (66, 36), (38, 50)], fill=METAL_DARK, outline=INK)
    draw.rectangle((28, 24, 50, 43), fill=(71, 59, 45, 255), outline=INK)
    draw.polygon([(36, 26), (31, 14), (39, 20), (44, 8), (49, 25)], fill=(214, 78, 39, 255))
    draw.polygon([(39, 25), (36, 17), (43, 14), (45, 24)], fill=(236, 170, 69, 255))
    return crop_alpha(img)


def draw_turret(kind: str) -> Image.Image:
    img = new((86, 84))
    draw = ImageDraw.Draw(img)
    draw_shadow(draw, (15, 63, 72, 78), 78)
    draw.polygon([(22, 55), (43, 42), (65, 54), (43, 68)], fill=METAL_DARK, outline=INK)
    draw.ellipse((24, 22, 64, 60), fill=(63, 70, 66, 255), outline=INK, width=3)
    if kind == "shotgun":
        draw.rectangle((42, 18, 70, 25), fill=METAL, outline=INK)
        draw.rectangle((42, 30, 72, 37), fill=METAL, outline=INK)
    else:
        draw.rectangle((42, 21, 76, 30), fill=METAL, outline=INK)
    draw.rectangle((37, 33, 51, 47), fill=(105, 92, 60, 255), outline=INK)
    draw.point((30, 31), fill=LIGHT)
    line_noise(draw, (21, 24, 66, 59), 12)
    return crop_alpha(img)


def draw_spotlight() -> Image.Image:
    img = new((82, 92))
    draw = ImageDraw.Draw(img)
    draw_shadow(draw, (16, 70, 68, 86), 66)
    draw.rectangle((37, 50, 45, 74), fill=METAL_DARK, outline=INK)
    draw.polygon([(26, 73), (56, 73), (67, 82), (16, 82)], fill=METAL_DARK, outline=INK)
    draw.ellipse((20, 18, 62, 54), fill=(65, 69, 64, 255), outline=INK, width=3)
    draw.polygon([(39, 25), (76, 11), (76, 39), (39, 48)], fill=(238, 199, 94, 76))
    draw.ellipse((30, 27, 52, 47), fill=LIGHT, outline=INK)
    return crop_alpha(img)


def draw_generator() -> Image.Image:
    img = new((86, 78))
    draw = ImageDraw.Draw(img)
    draw_shadow(draw, (11, 58, 76, 73), 72)
    iso_block(draw, 16, 22, 56, 23, 15, (93, 81, 57, 255), (59, 56, 47, 255), (42, 46, 44, 255))
    draw.rectangle((35, 37, 55, 49), fill=LIGHT, outline=INK)
    draw.line((61, 25, 75, 14), fill=METAL, width=2)
    draw.line((61, 31, 78, 28), fill=METAL, width=2)
    return crop_alpha(img)


def draw_battery() -> Image.Image:
    img = new((74, 72))
    draw = ImageDraw.Draw(img)
    draw_shadow(draw, (10, 55, 64, 68), 62)
    iso_block(draw, 17, 19, 42, 28, 14, (66, 75, 71, 255), (39, 49, 48, 255), (31, 39, 41, 255))
    draw.rectangle((30, 18, 45, 24), fill=METAL, outline=INK)
    draw.line((27, 44, 49, 44), fill=LAB_GLOW, width=2)
    draw.line((36, 35, 42, 35), fill=LIGHT, width=2)
    return crop_alpha(img)


def draw_power_pole() -> Image.Image:
    img = new((74, 104))
    draw = ImageDraw.Draw(img)
    draw_shadow(draw, (16, 82, 58, 99), 52)
    draw.rectangle((34, 18, 42, 90), fill=(88, 62, 38, 255), outline=INK)
    draw.rectangle((16, 28, 60, 35), fill=(84, 57, 36, 255), outline=INK)
    draw.line((17, 32, 3, 19), fill=(38, 40, 38, 255), width=2)
    draw.line((58, 32, 72, 18), fill=(38, 40, 38, 255), width=2)
    draw.line((39, 35, 23, 79), fill=(115, 83, 48, 255), width=2)
    return crop_alpha(img)


def draw_container() -> Image.Image:
    img = new((84, 70))
    draw = ImageDraw.Draw(img)
    draw_shadow(draw, (12, 52, 74, 66), 64)
    iso_block(draw, 13, 22, 58, 19, 16, (98, 71, 45, 255), (62, 48, 36, 255), (46, 38, 33, 255))
    draw.line((22, 38, 66, 35), fill=(126, 89, 50, 255), width=2)
    draw.rectangle((35, 20, 51, 27), fill=METAL, outline=INK)
    return crop_alpha(img)


def draw_ruin() -> Image.Image:
    img = new((144, 132))
    draw = ImageDraw.Draw(img)
    draw_shadow(draw, (18, 104, 126, 125), 84)
    iso_block(draw, 22, 30, 94, 42, 24, (77, 72, 61, 255), (47, 51, 48, 255), (34, 39, 39, 255))
    draw.rectangle((30, 58, 53, 82), fill=(17, 19, 18, 255), outline=(93, 81, 58, 255))
    draw.rectangle((76, 52, 101, 80), fill=(17, 19, 18, 255), outline=(93, 81, 58, 255))
    draw.line((29, 104, 110, 45), fill=RUST, width=4)
    draw.rectangle((22, 87, 56, 104), fill=(79, 44, 36, 255), outline=INK)
    draw.polygon([(89, 29), (116, 20), (105, 48)], fill=(45, 47, 45, 255), outline=INK)
    return crop_alpha(img)


def draw_rubble() -> Image.Image:
    img = new((84, 70))
    draw = ImageDraw.Draw(img)
    draw_shadow(draw, (9, 52, 75, 66), 52)
    for box in [(12, 40, 30, 53), (25, 29, 51, 52), (45, 37, 69, 55), (36, 20, 58, 38)]:
        draw.rectangle(box, fill=(65, 63, 58, 255), outline=INK, width=2)
    draw.line((14, 58, 72, 32), fill=RUST, width=2)
    draw.line((26, 24, 62, 54), fill=(93, 82, 60, 255), width=2)
    return crop_alpha(img)


def draw_plane() -> Image.Image:
    img = new((176, 100))
    draw = ImageDraw.Draw(img)
    draw_shadow(draw, (18, 71, 160, 92), 76)
    draw.polygon([(12, 58), (92, 30), (164, 42), (111, 68), (30, 72)], fill=(86, 91, 88, 255), outline=INK)
    draw.polygon([(66, 38), (45, 8), (92, 35)], fill=(53, 68, 73, 255), outline=INK)
    draw.polygon([(88, 63), (58, 94), (113, 72)], fill=(51, 64, 70, 255), outline=INK)
    draw.rectangle((113, 38, 139, 49), fill=(31, 49, 56, 255), outline=INK)
    draw.rectangle((27, 68, 70, 75), fill=RUST, outline=INK)
    draw.line((87, 36, 132, 66), fill=BLOOD, width=2)
    line_noise(draw, (18, 37, 155, 73), 24, [RUST, METAL_DARK, (122, 123, 113, 255)])
    return crop_alpha(img)


def draw_car() -> Image.Image:
    img = new((108, 70))
    draw = ImageDraw.Draw(img)
    draw_shadow(draw, (12, 52, 96, 66), 70)
    draw.polygon([(11, 42), (27, 22), (76, 18), (97, 38), (88, 53), (18, 55)], fill=(53, 63, 66, 255), outline=INK)
    draw.rectangle((36, 23, 61, 36), fill=(22, 31, 36, 255), outline=INK)
    draw.ellipse((21, 48, 39, 66), fill=(12, 12, 12, 255))
    draw.ellipse((68, 47, 86, 65), fill=(12, 12, 12, 255))
    draw.line((17, 35, 91, 47), fill=BLOOD, width=2)
    return crop_alpha(img)


OBJECT_DRAWERS = {
    "bunker_core": draw_bunker,
    "lab_station": draw_lab,
    "workbench": draw_workbench,
    "furnace": draw_furnace,
    "farm_plot": draw_farm,
    "animal_pen": draw_animal_pen,
    "barricade": lambda: draw_wall("barricade"),
    "scrap_wall": lambda: draw_wall("scrap"),
    "gate": draw_gate,
    "wire_fence": draw_wire,
    "spike_trap": draw_spikes,
    "flame_trap": draw_flame_trap,
    "basic_turret": lambda: draw_turret("basic"),
    "shotgun_turret": lambda: draw_turret("shotgun"),
    "spotlight": draw_spotlight,
    "generator": draw_generator,
    "battery": draw_battery,
    "power_pole": draw_power_pole,
    "container": draw_container,
    "ruined_building": draw_ruin,
    "rubble": draw_rubble,
    "crash_plane": draw_plane,
    "wrecked_car": draw_car,
}


CHARACTER_VARIANTS = {
    "scientist": {"coat": (189, 191, 171, 255), "skin": (160, 111, 76, 255), "pants": (43, 50, 55, 255), "hair": (45, 34, 27, 255), "infected": False, "scale": 1.0},
    "walker": {"coat": (83, 82, 60, 255), "skin": (103, 131, 87, 255), "pants": (53, 49, 45, 255), "hair": (45, 38, 32, 255), "infected": True, "scale": 1.0},
    "runner": {"coat": (79, 66, 69, 255), "skin": (121, 146, 88, 255), "pants": (43, 39, 39, 255), "hair": (42, 33, 28, 255), "infected": True, "scale": 0.92},
    "brute": {"coat": (112, 83, 57, 255), "skin": (140, 154, 98, 255), "pants": (59, 52, 47, 255), "hair": (48, 38, 28, 255), "infected": True, "scale": 1.22},
    "crusher": {"coat": (93, 87, 73, 255), "skin": (132, 139, 94, 255), "pants": (55, 50, 45, 255), "hair": (30, 31, 31, 255), "infected": True, "scale": 1.28, "armor": True},
    "crawler": {"coat": (76, 70, 55, 255), "skin": (120, 142, 86, 255), "pants": (44, 39, 35, 255), "hair": (38, 29, 26, 255), "infected": True, "scale": 0.72, "crawler": True},
    "fire_weak_infected": {"coat": (84, 79, 49, 255), "skin": (147, 128, 72, 255), "pants": (54, 42, 34, 255), "hair": (53, 32, 25, 255), "infected": True, "scale": 1.0, "fire": True},
    "armored": {"coat": (78, 84, 84, 255), "skin": (112, 126, 91, 255), "pants": (48, 51, 49, 255), "hair": (36, 35, 33, 255), "infected": True, "scale": 1.08, "armor": True},
}


ANIM_ROWS = {
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


def draw_character_frame(draw: ImageDraw.ImageDraw, ox: int, oy: int, variant: dict, direction: str, frame: int, state: str) -> None:
    scale = float(variant.get("scale", 1.0))
    crawler = bool(variant.get("crawler", False))
    cx = ox + FRAME // 2
    base_y = oy + (53 if not crawler else 48)
    bob = 0 if state.startswith("idle") else (-1 if frame % 2 == 0 else 1)
    if state.startswith("hit"):
        bob = -2
    body_w = int(12 * scale)
    body_h = int((22 if not crawler else 11) * scale)
    head_w = int(13 * scale)
    skin = variant["skin"]
    coat = variant["coat"]
    pants = variant["pants"]
    hair = variant["hair"]
    infected = bool(variant.get("infected", False))

    shadow_w = int(23 * scale)
    draw.ellipse((cx - shadow_w, base_y - 5, cx + shadow_w, base_y + 5), fill=(0, 0, 0, 88))

    if crawler:
        draw.rectangle((cx - 17, base_y - 21 + bob, cx + 17, base_y - 10 + bob), fill=coat, outline=INK)
        draw.rectangle((cx - 12, base_y - 33 + bob, cx + 1, base_y - 20 + bob), fill=skin, outline=INK)
        for x in [-20, -7, 8, 20]:
            draw.line((cx, base_y - 13 + bob, cx + x, base_y - 3), fill=pants, width=4)
        draw.point((cx - 8, base_y - 27 + bob), fill=(229, 52, 43, 255))
        return

    leg_shift = [-2, 1, 2, -1][frame % 4] if state.startswith("walk") else 0
    if state.startswith("death"):
        draw.rectangle((cx - 20, base_y - 15, cx + 19, base_y - 4), fill=coat, outline=INK)
        draw.rectangle((cx - 27, base_y - 14, cx - 14, base_y - 2), fill=skin, outline=INK)
        draw.line((cx - 12, base_y - 12, cx + 22, base_y - 22), fill=BLOOD, width=2)
        return

    if direction == "side":
        face = 1
        if state.startswith("attack"):
            draw.line((cx + 9, base_y - 27 + bob, cx + 31, base_y - 30 + bob), fill=(122, 111, 82, 255), width=4)
        draw.rectangle((cx - 6, base_y - body_h - 10 + bob, cx + 8, base_y - 10 + bob), fill=coat, outline=INK)
        draw.rectangle((cx + 6, base_y - 26 + bob, cx + 14, base_y - 12 + bob), fill=coat, outline=INK)
        draw.rectangle((cx - 7, base_y - 10, cx - 3, base_y - 1 + leg_shift), fill=pants)
        draw.rectangle((cx + 4, base_y - 10, cx + 8, base_y - 1 - leg_shift), fill=pants)
        draw.rectangle((cx - 7, base_y - body_h - head_w - 8 + bob, cx + 6, base_y - body_h - 9 + bob), fill=skin, outline=INK)
        draw.rectangle((cx - 6, base_y - body_h - head_w - 11 + bob, cx + 7, base_y - body_h - head_w - 6 + bob), fill=hair)
        eye = (224, 45, 39, 255) if infected else (19, 23, 25, 255)
        draw.point((cx + 4 * face, base_y - body_h - 16 + bob), fill=eye)
    else:
        head_y = base_y - body_h - head_w - 8 + bob
        if state.startswith("attack"):
            draw.line((cx + 10, base_y - 27 + bob, cx + (22 if direction == "down" else -18), base_y - (15 if direction == "down" else 44) + bob), fill=(122, 111, 82, 255), width=4)
        draw.rectangle((cx - body_w // 2, base_y - body_h - 8 + bob, cx + body_w // 2, base_y - 9 + bob), fill=coat, outline=INK)
        draw.rectangle((cx - body_w // 2 - 6, base_y - body_h - 4 + bob, cx - body_w // 2, base_y - 12 + bob), fill=coat, outline=INK)
        draw.rectangle((cx + body_w // 2, base_y - body_h - 4 + bob, cx + body_w // 2 + 6, base_y - 12 + bob), fill=coat, outline=INK)
        draw.rectangle((cx - 6, base_y - 10, cx - 2, base_y - 1 + leg_shift), fill=pants)
        draw.rectangle((cx + 2, base_y - 10, cx + 6, base_y - 1 - leg_shift), fill=pants)
        draw.rectangle((cx - head_w // 2, head_y, cx + head_w // 2, head_y + head_w), fill=skin, outline=INK)
        draw.rectangle((cx - head_w // 2, head_y - 4, cx + head_w // 2, head_y + 2), fill=hair)
        eye = (224, 45, 39, 255) if infected else (19, 23, 25, 255)
        if direction == "down":
            draw.point((cx - 4, head_y + 7), fill=eye)
            draw.point((cx + 4, head_y + 7), fill=eye)
        else:
            draw.line((cx - 5, head_y + 5, cx + 5, head_y + 5), fill=hair, width=1)

    if not infected:
        draw.rectangle((cx - 13, base_y - 35 + bob, cx + 13, base_y - 31 + bob), fill=(205, 203, 181, 255), outline=INK)
        draw.rectangle((cx + 9, base_y - 25 + bob, cx + 13, base_y - 14 + bob), fill=LAB, outline=INK)
    if bool(variant.get("armor", False)):
        draw.rectangle((cx - 11, base_y - 35 + bob, cx + 11, base_y - 18 + bob), outline=(124, 130, 119, 255), width=2)
    if bool(variant.get("fire", False)):
        draw.line((cx - 12, base_y - 18, cx + 14, base_y - 31), fill=(200, 88, 38, 255), width=2)


def make_character_sheet(character_id: str, variant: dict) -> dict:
    rows = max(item["row"] for item in ANIM_ROWS.values()) + 1
    sheet = new((FRAME * SHEET_COLS, FRAME * rows))
    draw = ImageDraw.Draw(sheet)
    directions = {
        "down": "down",
        "side": "side",
        "up": "up",
    }
    for anim, meta in ANIM_ROWS.items():
        parts = anim.split("_")
        state = parts[0]
        direction = directions.get(parts[1], "down")
        row = meta["row"]
        for frame in range(SHEET_COLS):
            draw_character_frame(draw, frame * FRAME, row * FRAME, variant, direction, frame, state)
    path = CHAR_SHEETS / f"{character_id}_sheet.png"
    save(path, sheet)
    return {
        "sheet": res(path),
        "frame_size": [FRAME, FRAME],
        "animations": ANIM_ROWS,
        "offset": [0, -11],
        "scale": 1.0,
    }


def make_objects() -> dict:
    manifest = {}
    for object_id, drawer in OBJECT_DRAWERS.items():
        img = drawer()
        path = OBJECTS / f"{object_id}.png"
        save(path, img)
        save(CUTOUTS / f"{object_id}.png", img)
        manifest[object_id] = {
            "path": res(path),
            "size": [img.width, img.height],
            "scale": 1.0,
            "offset": [0, -6],
        }
    return manifest


def make_tiles() -> dict:
    return {
        "dirt": make_tile("dirt", (43, 38, 29), [(58, 50, 34), (28, 29, 24), (82, 68, 38), (67, 44, 33)]),
        "bunker_floor": make_tile("bunker_floor", (54, 56, 51), [(76, 75, 67), (37, 39, 37), (92, 83, 65), (44, 48, 48)]),
        "field": make_tile("field", (56, 45, 30), [(49, 88, 43), (75, 64, 35), (88, 100, 50), (34, 59, 34)]),
        "cracked_road": make_tile("cracked_road", (39, 41, 41), [(23, 24, 26), (65, 64, 59), (88, 75, 61), (52, 45, 43)]),
        "dark_ground": make_tile("dark_ground", (27, 31, 30), [(18, 22, 22), (45, 50, 44), (55, 43, 38), (34, 37, 31)]),
        "night_ground": make_tile("night_ground", (15, 20, 29), [(23, 32, 47), (10, 14, 21), (44, 40, 45), (21, 28, 36)]),
    }


def icon_shape(draw: ImageDraw.ImageDraw, key: str) -> None:
    if key in ["food", "raw_food"]:
        draw.ellipse((9, 9, 23, 23), fill=(111, 133, 70, 255), outline=INK)
        draw.line((16, 9, 20, 5), fill=GREEN, width=2)
    elif key == "water":
        draw.polygon([(16, 5), (24, 20), (16, 28), (8, 20)], fill=(70, 119, 145, 255), outline=INK)
    elif key == "power":
        draw.polygon([(18, 4), (9, 18), (16, 18), (13, 29), (24, 14), (17, 14)], fill=LIGHT, outline=INK)
    elif key in ["ammo", "fuel"]:
        draw.rectangle((11, 6, 21, 26), fill=(142, 95, 53, 255), outline=INK)
        draw.rectangle((13, 9, 19, 14), fill=RUST, outline=INK)
    elif key in ["samples", "chemicals", "medicine"]:
        draw.rectangle((11, 5, 21, 27), fill=(42, 68, 63, 255), outline=INK)
        draw.rectangle((13, 14, 19, 25), fill=LAB_GLOW)
    elif key in ["parts", "scrap", "iron_ingot", "screws"]:
        draw.polygon([(7, 13), (17, 6), (26, 14), (18, 25), (8, 22)], fill=METAL, outline=INK)
        draw.line((10, 21, 24, 12), fill=RUST, width=2)
    elif key in ["wood", "cloth"]:
        draw.rectangle((8, 12, 25, 22), fill=(101, 68, 39, 255), outline=INK)
        draw.line((10, 17, 23, 14), fill=(132, 88, 47, 255), width=1)
    elif key in ["wire", "electronics", "circuit_board", "battery_cell"]:
        draw.rectangle((7, 9, 25, 24), fill=(44, 75, 65, 255), outline=INK)
        draw.line((9, 14, 22, 14), fill=LAB_GLOW, width=1)
        draw.line((12, 20, 21, 12), fill=LIGHT, width=1)
    elif key in ["seeds", "fertilizer", "animal_feed"]:
        draw.polygon([(8, 23), (16, 8), (25, 23)], fill=(73, 102, 56, 255), outline=INK)
        draw.ellipse((13, 17, 20, 24), fill=(126, 103, 57, 255), outline=INK)
    elif key == "books":
        draw.polygon([(8, 8), (17, 11), (24, 8), (24, 25), (17, 28), (8, 25)], fill=(99, 65, 52, 255), outline=INK)
        draw.line((17, 11, 17, 28), fill=(41, 33, 29, 255), width=1)
    elif key in ["build", "threat", "skills", "crafting", "research", "base"]:
        draw.rectangle((7, 8, 25, 24), fill=(72, 79, 67, 255), outline=INK)
        draw.line((10, 21, 23, 11), fill=LIGHT if key == "threat" else LAB_GLOW, width=2)
    else:
        draw.rectangle((8, 8, 24, 24), fill=METAL, outline=INK)


def make_icons() -> dict:
    keys = [
        "food", "water", "power", "ammo", "fuel", "samples", "parts", "base",
        "scrap", "wood", "cloth", "wire", "electronics", "chemicals", "seeds",
        "raw_food", "medicine", "books", "iron_ingot", "screws", "circuit_board",
        "battery_cell", "fertilizer", "animal_feed", "build", "threat", "skills",
        "crafting", "research",
    ]
    manifest = {}
    for key in keys:
        img = new((32, 32))
        draw = ImageDraw.Draw(img)
        draw.rectangle((3, 4, 29, 28), fill=(34, 37, 33, 235), outline=INK, width=2)
        icon_shape(draw, key)
        path = UI / f"icon_{key}.png"
        save(path, img)
        manifest[key] = {"path": res(path), "size": [32, 32]}
    app_icon = new((64, 64), (28, 33, 30, 255))
    draw = ImageDraw.Draw(app_icon)
    draw.polygon([(11, 32), (32, 14), (54, 32), (43, 51), (20, 51)], fill=(79, 75, 56, 255), outline=INK)
    draw.rectangle((25, 36, 39, 51), fill=(14, 18, 20, 255))
    draw.ellipse((26, 23, 38, 35), fill=(91, 141, 108, 255), outline=INK)
    save(UI / "icon.png", app_icon)
    manifest["app"] = {"path": res(UI / "icon.png"), "size": [64, 64]}
    return manifest


def make_contact_sheets(characters: dict, objects: dict, icons: dict) -> list[str]:
    paths = []

    char_sheet = new((FRAME * 4, FRAME * len(characters)), KEY)
    for row, char_id in enumerate(characters.keys()):
        src = Image.open(ROOT / characters[char_id]["sheet"].replace("res://", "")).convert("RGBA")
        char_sheet.alpha_composite(src.crop((0, 3 * FRAME, FRAME * 4, 4 * FRAME)), (0, row * FRAME))
    path = RAW / "characters_walk_contact_sheet.png"
    save(path, char_sheet)
    paths.append(res(path))

    obj_sheet = new((512, 512), KEY)
    x = y = 10
    row_h = 0
    for object_id in objects.keys():
        img = Image.open(ROOT / objects[object_id]["path"].replace("res://", "")).convert("RGBA")
        if x + img.width > obj_sheet.width - 10:
            x = 10
            y += row_h + 14
            row_h = 0
        if y + img.height > obj_sheet.height - 10:
            break
        obj_sheet.alpha_composite(img, (x, y))
        x += img.width + 14
        row_h = max(row_h, img.height)
    path = RAW / "core_objects_contact_sheet.png"
    save(path, obj_sheet)
    paths.append(res(path))

    icon_sheet = new((256, 128), KEY)
    for index, key in enumerate(icons.keys()):
        img = Image.open(ROOT / icons[key]["path"].replace("res://", "")).convert("RGBA")
        icon_sheet.alpha_composite(img, ((index % 8) * 32, (index // 8) * 32))
    path = RAW / "ui_icons_contact_sheet.png"
    save(path, icon_sheet)
    paths.append(res(path))
    return paths


def res(path: Path) -> str:
    return "res://" + str(path.relative_to(ROOT))


def main() -> None:
    ensure_dirs()
    characters = {key: make_character_sheet(key, value) for key, value in CHARACTER_VARIANTS.items()}
    objects = make_objects()
    tiles = make_tiles()
    icons = make_icons()
    raw_sources = make_contact_sheets(characters, objects, icons)
    manifest = {
        "style": {
            "name": "dirty_low_saturation_oblique_pixel",
            "reference": "root preview right-side gameplay target",
            "notes": "Hard post-apocalyptic survival management, grimy low saturation, not cute/cartoon.",
            "comfyui": "http://192.168.50.143:8000",
            "chroma_key": "#00ff00",
        },
        "characters": characters,
        "objects": objects,
        "tiles": tiles,
        "ui_icons": icons,
        "raw_sources": raw_sources,
    }
    (DATA / "art_asset_manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
