from __future__ import annotations

import math
import wave
from pathlib import Path
from random import Random

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "assets" / "art"
AUDIO = ROOT / "assets" / "audio"
STEAM = ROOT / "assets" / "steam_store"
RNG = Random(42)

INK = (18, 18, 16, 255)
DIRT = (43, 38, 29, 255)
METAL = (80, 82, 78, 255)
RUST = (116, 72, 42, 255)
SICK = (111, 137, 89, 255)
WARNING = (202, 88, 50, 255)
LAB = (112, 164, 150, 255)


def ensure_dirs() -> None:
    for folder in ["tiles", "objects", "characters", "ui"]:
        (ART / folder).mkdir(parents=True, exist_ok=True)
    for folder in ["ui", "sfx", "ambience"]:
        (AUDIO / folder).mkdir(parents=True, exist_ok=True)
    STEAM.mkdir(parents=True, exist_ok=True)


def save(path: Path, image: Image.Image) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)


def font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/Library/Fonts/Arial Unicode.ttf",
    ]
    for candidate in candidates:
        try:
            return ImageFont.truetype(candidate, size)
        except OSError:
            pass
    return ImageFont.load_default()


def outlined(size: tuple[int, int], fill=(0, 0, 0, 0)) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", size, fill)
    return img, ImageDraw.Draw(img)


def px(draw: ImageDraw.ImageDraw, box, fill, outline=INK, width=2) -> None:
    draw.rectangle(box, fill=outline)
    x0, y0, x1, y1 = box
    draw.rectangle((x0 + width, y0 + width, x1 - width, y1 - width), fill=fill)


def tile(name: str, base: tuple[int, int, int], specks: list[tuple[int, int, int]]) -> None:
    img = Image.new("RGBA", (64, 64), base + (255,))
    draw = ImageDraw.Draw(img)
    for _ in range(95):
        x = RNG.randrange(0, 64)
        y = RNG.randrange(0, 64)
        color = RNG.choice(specks)
        draw.rectangle((x, y, x + RNG.randrange(1, 5), y + RNG.randrange(1, 3)), fill=color + (255,))
    for _ in range(6):
        y = RNG.randrange(0, 64)
        draw.line((0, y, 64, y + RNG.randrange(-3, 4)), fill=(base[0] - 8, base[1] - 8, base[2] - 8, 255), width=1)
    save(ART / "tiles" / f"{name}.png", img)


def make_tiles() -> None:
    tile("dirt", (42, 38, 29), [(55, 48, 34), (30, 29, 24), (82, 67, 38), (67, 45, 33)])
    tile("bunker_floor", (55, 56, 50), [(72, 70, 62), (38, 39, 36), (91, 83, 65), (44, 48, 49)])
    tile("field", (56, 47, 31), [(49, 88, 43), (75, 64, 35), (85, 100, 50), (36, 61, 35)])
    tile("cracked_road", (40, 42, 42), [(24, 25, 27), (65, 64, 59), (88, 76, 62), (52, 45, 44)])
    tile("dark_ground", (27, 32, 31), [(19, 23, 23), (45, 50, 44), (54, 43, 38), (34, 37, 31)])
    tile("night_ground", (16, 22, 32), [(24, 33, 48), (10, 14, 21), (44, 40, 45), (21, 28, 36)])


def make_objects() -> None:
    img, draw = outlined((96, 80))
    draw.polygon([(10, 42), (48, 12), (88, 42), (78, 68), (18, 68)], fill=(37, 35, 30, 255), outline=INK)
    draw.polygon([(10, 42), (48, 12), (88, 42), (48, 54)], fill=(78, 66, 46, 255), outline=INK)
    px(draw, (33, 42, 63, 70), (35, 61, 66, 255))
    draw.rectangle((42, 52, 54, 70), fill=(15, 19, 22, 255))
    draw.rectangle((18, 50, 30, 58), fill=RUST)
    save(ART / "objects" / "bunker.png", img)

    img, draw = outlined((88, 76))
    px(draw, (9, 20, 76, 64), (52, 58, 53, 255))
    draw.rectangle((20, 31, 34, 45), fill=(64, 126, 116, 255), outline=INK)
    draw.rectangle((48, 30, 65, 46), fill=(68, 112, 138, 255), outline=INK)
    draw.line((14, 18, 68, 18), fill=(126, 144, 110, 255), width=3)
    draw.rectangle((29, 8, 55, 18), fill=(86, 96, 85, 255), outline=INK)
    draw.line((42, 20, 38, 64), fill=(124, 86, 55, 255), width=2)
    save(ART / "objects" / "lab.png", img)

    img, draw = outlined((64, 64))
    px(draw, (12, 22, 52, 54), (67, 62, 47, 255))
    draw.rectangle((20, 14, 44, 24), fill=(100, 92, 68, 255), outline=INK)
    draw.rectangle((22, 30, 42, 38), fill=(216, 164, 46, 255), outline=INK)
    draw.line((14, 54, 50, 54), fill=(30, 28, 24, 255), width=4)
    save(ART / "objects" / "generator.png", img)

    img, draw = outlined((80, 64))
    for x in range(8, 76, 14):
        draw.rectangle((x, 18, x + 4, 54), fill=(85, 59, 36, 255), outline=INK)
    draw.rectangle((8, 24, 74, 28), fill=(112, 76, 42, 255))
    draw.rectangle((8, 46, 74, 50), fill=(112, 76, 42, 255))
    draw.ellipse((28, 30, 42, 44), fill=(175, 166, 138, 255), outline=INK)
    draw.rectangle((43, 36, 54, 47), fill=(142, 113, 84, 255), outline=INK)
    save(ART / "objects" / "animal_pen.png", img)

    img, draw = outlined((64, 64))
    draw.rectangle((18, 10, 46, 56), fill=(72, 52, 38, 255), outline=INK, width=3)
    draw.rectangle((24, 18, 40, 50), fill=(18, 17, 15, 255))
    draw.rectangle((16, 8, 48, 16), fill=(95, 77, 54, 255), outline=INK)
    draw.rectangle((37, 30, 42, 36), fill=WARNING)
    save(ART / "objects" / "city_gate.png", img)

    img, draw = outlined((64, 48))
    draw.rectangle((4, 18, 60, 42), fill=(76, 72, 66, 255), outline=INK, width=3)
    for x in range(8, 60, 12):
        draw.line((x, 20, x + 8, 40), fill=(111, 104, 92, 255), width=2)
    draw.rectangle((6, 36, 58, 42), fill=(74, 45, 36, 255))
    save(ART / "objects" / "wall_segment.png", img)

    img, draw = outlined((48, 48))
    draw.rectangle((16, 30, 32, 42), fill=(50, 47, 42, 255), outline=INK)
    draw.ellipse((10, 10, 38, 38), fill=(61, 68, 62, 255), outline=INK, width=3)
    draw.rectangle((23, 0, 28, 18), fill=(92, 86, 70, 255), outline=INK)
    draw.rectangle((19, 19, 30, 30), fill=(126, 110, 70, 255))
    draw.point((35, 14), fill=WARNING)
    save(ART / "objects" / "turret.png", img)

    img, draw = outlined((48, 48))
    draw.rectangle((6, 8, 42, 42), fill=(78, 60, 40, 255), outline=INK, width=2)
    for x in [14, 24, 34]:
        draw.line((x, 12, x - 2, 38), fill=(63, 118, 58, 255), width=3)
    draw.rectangle((8, 34, 40, 39), fill=(41, 82, 41, 255))
    save(ART / "objects" / "farm_plot.png", img)

    img, draw = outlined((96, 96))
    draw.rectangle((14, 22, 82, 84), fill=(48, 49, 47, 255), outline=INK, width=4)
    draw.polygon([(14, 22), (48, 8), (82, 22), (74, 34), (22, 34)], fill=(70, 62, 54, 255), outline=INK)
    for x in [24, 48, 66]:
        draw.rectangle((x, 42, x + 12, 58), fill=(18, 22, 23, 255), outline=(92, 82, 62, 255))
    draw.line((22, 82, 76, 30), fill=(96, 80, 55, 255), width=4)
    draw.rectangle((17, 66, 38, 80), fill=(86, 48, 38, 255))
    save(ART / "objects" / "ruined_building.png", img)

    img, draw = outlined((120, 64))
    draw.polygon([(8, 36), (76, 20), (112, 30), (80, 46), (18, 48)], fill=(90, 94, 92, 255), outline=INK)
    draw.polygon([(48, 26), (32, 4), (64, 24)], fill=(60, 72, 78, 255), outline=INK)
    draw.polygon([(64, 42), (42, 62), (76, 48)], fill=(60, 72, 78, 255), outline=INK)
    draw.rectangle((80, 24, 96, 34), fill=(42, 63, 73, 255), outline=INK)
    draw.rectangle((18, 43, 48, 49), fill=RUST)
    save(ART / "objects" / "crash_plane.png", img)

    img, draw = outlined((64, 64))
    for box in [(8, 36, 24, 50), (20, 26, 42, 50), (36, 34, 56, 52), (28, 18, 46, 34)]:
        draw.rectangle(box, fill=(70, 66, 62, 255), outline=INK, width=2)
    draw.line((10, 52, 54, 32), fill=RUST, width=2)
    save(ART / "objects" / "rubble.png", img)

    img, draw = outlined((80, 48))
    draw.polygon([(8, 30), (18, 16), (58, 12), (72, 26), (68, 38), (12, 40)], fill=(55, 64, 68, 255), outline=INK)
    draw.rectangle((26, 16, 46, 27), fill=(25, 32, 37, 255), outline=INK)
    draw.ellipse((14, 34, 28, 46), fill=(18, 18, 18, 255))
    draw.ellipse((54, 32, 68, 44), fill=(18, 18, 18, 255))
    draw.line((10, 24, 68, 34), fill=(88, 48, 38, 255), width=2)
    save(ART / "objects" / "wrecked_car.png", img)

    img, draw = outlined((48, 48))
    draw.rectangle((8, 14, 40, 38), fill=(80, 59, 40, 255), outline=INK, width=3)
    draw.line((10, 22, 38, 22), fill=(126, 94, 58, 255), width=2)
    draw.rectangle((18, 8, 32, 14), fill=(94, 80, 61, 255), outline=INK)
    save(ART / "objects" / "container.png", img)


def character(path: Path, coat: tuple[int, int, int], skin: tuple[int, int, int], pants: tuple[int, int, int], infected=False, brute=False) -> None:
    width = 40 if brute else 32
    img, draw = outlined((width, 52))
    cx = width // 2
    draw.rectangle((cx - 5, 20, cx + 5, 40), fill=coat + (255,), outline=INK)
    draw.rectangle((cx - 9, 23, cx - 5, 38), fill=coat + (255,), outline=INK)
    draw.rectangle((cx + 5, 23, cx + 9, 38), fill=coat + (255,), outline=INK)
    if brute:
        draw.rectangle((cx - 12, 24, cx + 12, 36), fill=coat + (255,), outline=INK)
    draw.rectangle((cx - 5, 40, cx - 2, 49), fill=pants + (255,))
    draw.rectangle((cx + 2, 40, cx + 5, 49), fill=pants + (255,))
    draw.rectangle((cx - 6, 8, cx + 6, 20), fill=skin + (255,), outline=INK)
    draw.rectangle((cx - 5, 5, cx + 5, 10), fill=(46, 34, 27, 255))
    eye = (220, 55, 45, 255) if infected else (22, 27, 30, 255)
    draw.point((cx - 3, 14), fill=eye)
    draw.point((cx + 4, 14), fill=eye)
    if infected:
        draw.line((cx - 10, 29, cx + 10, 35), fill=(65, 112, 67, 255), width=2)
        draw.rectangle((cx + 7, 16, cx + 11, 20), fill=(78, 105, 63, 255))
    else:
        draw.rectangle((cx - 10, 18, cx + 10, 22), fill=(206, 206, 185, 255), outline=INK)
        draw.rectangle((cx + 7, 26, cx + 10, 34), fill=(74, 126, 134, 255))
    save(path, img)


def make_characters() -> None:
    character(ART / "characters" / "scientist.png", (201, 204, 184), (166, 116, 78), (46, 54, 60), False)
    character(ART / "characters" / "zombie_walker.png", (86, 84, 62), (110, 133, 92), (55, 51, 46), True)
    character(ART / "characters" / "zombie_runner.png", (78, 68, 72), (121, 146, 88), (46, 41, 41), True)
    character(ART / "characters" / "zombie_brute.png", (112, 86, 60), (139, 154, 98), (60, 53, 47), True, True)


def make_icons() -> None:
    icon_defs = {
        "food": ((104, 128, 66, 255), "F"),
        "water": ((65, 116, 145, 255), "W"),
        "power": ((211, 166, 55, 255), "P"),
        "ammo": ((141, 104, 68, 255), "A"),
        "fuel": ((154, 92, 48, 255), "G"),
        "samples": ((92, 158, 123, 255), "S"),
        "parts": ((119, 121, 112, 255), "R"),
        "research": ((115, 166, 154, 255), "+"),
        "wall": ((122, 112, 95, 255), "#"),
        "base": ((84, 101, 87, 255), "B"),
    }
    for name, (color, letter) in icon_defs.items():
        img, draw = outlined((32, 32), (0, 0, 0, 0))
        draw.rectangle((4, 6, 28, 26), fill=color, outline=INK, width=2)
        draw.text((12, 8), letter, fill=(20, 22, 18, 255), font=font(14))
        draw.rectangle((7, 21, 25, 24), fill=(255, 255, 255, 38))
        save(ART / "ui" / f"icon_{name}.png", img)

    img, draw = outlined((64, 64), (30, 36, 32, 255))
    draw.rectangle((14, 22, 50, 48), fill=(82, 98, 86, 255), outline=INK, width=3)
    draw.polygon([(14, 22), (32, 10), (50, 22)], fill=(116, 96, 62, 255), outline=INK)
    draw.ellipse((24, 28, 40, 44), fill=(85, 145, 102, 255), outline=INK)
    save(ART / "ui" / "icon.png", img)


def draw_key_scene(size: tuple[int, int], include_logo: bool, hero_only: bool = False) -> Image.Image:
    low = Image.new("RGBA", (480, 270), (18, 23, 25, 255))
    draw = ImageDraw.Draw(low)
    for y in range(270):
        shade = int(18 + y * 0.08)
        draw.line((0, y, 480, y), fill=(shade, shade + 4, shade + 2, 255))
    draw.rectangle((0, 188, 480, 270), fill=(37, 34, 27, 255))
    for x in range(0, 480, 14):
        draw.line((x, 188, x - 44, 270), fill=(54, 47, 34, 255), width=1)
    draw.rectangle((38, 132, 188, 220), fill=(49, 52, 45, 255), outline=INK, width=3)
    draw.polygon([(38, 132), (112, 84), (188, 132), (112, 155)], fill=(83, 68, 45, 255), outline=INK)
    draw.rectangle((75, 166, 122, 221), fill=(23, 29, 31, 255), outline=INK)
    draw.rectangle((300, 70, 450, 208), fill=(36, 38, 38, 255), outline=INK, width=2)
    for wx in [322, 365, 410]:
        draw.rectangle((wx, 96, wx + 24, 124), fill=(18, 22, 22, 255), outline=(91, 83, 62, 255))
    draw.line((315, 205, 444, 88), fill=RUST, width=4)
    draw.polygon([(212, 168), (340, 145), (435, 165), (342, 194), (216, 194)], fill=(82, 88, 86, 255), outline=INK)
    draw.polygon([(282, 150), (246, 98), (314, 148)], fill=(55, 68, 74, 255), outline=INK)
    for x, y in [(265, 172), (285, 176), (306, 171), (332, 178), (358, 174), (390, 180)]:
        draw.ellipse((x, y, x + 4, y + 3), fill=(222, 56, 42, 255))
    for tx, ty in [(165, 154), (196, 175)]:
        draw.ellipse((tx, ty, tx + 28, ty + 28), fill=(58, 64, 58, 255), outline=INK)
        draw.rectangle((tx + 13, ty - 16, tx + 17, ty + 8), fill=(116, 105, 72, 255), outline=INK)
        draw.line((tx + 14, ty + 3, tx + 64, ty - 8), fill=(235, 188, 74, 255), width=2)
    draw.rectangle((106, 174, 118, 216), fill=(200, 203, 184, 255), outline=INK)
    draw.rectangle((102, 184, 122, 198), fill=(200, 203, 184, 255), outline=INK)
    draw.rectangle((108, 162, 118, 174), fill=(166, 116, 78, 255), outline=INK)
    if include_logo and not hero_only:
        draw.rectangle((24, 24, 282, 80), fill=(0, 0, 0, 120))
    img = low.resize(size, Image.Resampling.NEAREST)
    if include_logo and not hero_only:
        d2 = ImageDraw.Draw(img)
        scale = size[0] / 480
        logo_font = font(max(24, int(31 * scale)))
        d2.text((int(30 * scale), int(28 * scale)), "BUNKERTOPIA", fill=(224, 232, 198, 255), font=logo_font)
    return img


def make_steam_art() -> None:
    master = draw_key_scene((1920, 1080), True)
    save(STEAM / "source_art.png", master)
    save(STEAM / "menu_background.png", master.crop((0, 120, 1920, 960)).resize((1280, 720), Image.Resampling.LANCZOS))
    sizes = {
        "header_capsule_920x430.png": (920, 430, True, False),
        "small_capsule_462x174.png": (462, 174, True, False),
        "main_capsule_1232x706.png": (1232, 706, True, False),
        "vertical_capsule_748x896.png": (748, 896, True, False),
        "library_capsule_600x900.png": (600, 900, True, False),
        "library_hero_3840x1240.png": (3840, 1240, False, True),
        "library_header_920x430.png": (920, 430, True, False),
    }
    for name, (w, h, logo, hero_only) in sizes.items():
        save(STEAM / name, draw_key_scene((w, h), logo, hero_only))
    logo = Image.new("RGBA", (1280, 720), (0, 0, 0, 0))
    d = ImageDraw.Draw(logo)
    d.text((102, 280), "BUNKERTOPIA", fill=(224, 232, 198, 255), font=font(128))
    d.rectangle((96, 420, 940, 438), fill=(181, 84, 48, 255))
    save(STEAM / "library_logo_1280x720.png", logo)


def tone(path: Path, freq: float, duration: float, volume: float = 0.25, noise: float = 0.0) -> None:
    sample_rate = 44100
    count = int(sample_rate * duration)
    with wave.open(str(path), "w") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(sample_rate)
        frames = bytearray()
        for i in range(count):
            t = i / sample_rate
            env = min(1.0, i / max(1, int(sample_rate * 0.015))) * max(0.0, 1.0 - i / count)
            value = math.sin(t * freq * math.tau)
            if noise > 0:
                value = value * (1.0 - noise) + RNG.uniform(-1.0, 1.0) * noise
            sample = int(max(-1.0, min(1.0, value * volume * env)) * 32767)
            frames.extend(sample.to_bytes(2, "little", signed=True))
        wav.writeframes(bytes(frames))


def make_audio() -> None:
    tone(AUDIO / "ui" / "button_click.wav", 620, 0.07, 0.20, 0.05)
    tone(AUDIO / "sfx" / "pickup.wav", 880, 0.16, 0.24, 0.04)
    tone(AUDIO / "sfx" / "door_open.wav", 140, 0.35, 0.23, 0.30)
    tone(AUDIO / "sfx" / "player_fire.wav", 90, 0.11, 0.55, 0.45)
    tone(AUDIO / "sfx" / "turret_fire.wav", 120, 0.08, 0.45, 0.40)
    tone(AUDIO / "sfx" / "hit_flesh.wav", 70, 0.12, 0.30, 0.65)
    tone(AUDIO / "sfx" / "zombie_moan.wav", 48, 0.55, 0.28, 0.35)
    tone(AUDIO / "sfx" / "alarm.wav", 720, 0.42, 0.26, 0.03)
    tone(AUDIO / "sfx" / "generator_pulse.wav", 58, 0.50, 0.25, 0.20)
    tone(AUDIO / "sfx" / "research_success.wav", 1040, 0.35, 0.24, 0.02)
    tone(AUDIO / "sfx" / "research_fail.wav", 110, 0.28, 0.32, 0.22)
    tone(AUDIO / "sfx" / "base_damage.wav", 55, 0.25, 0.48, 0.50)
    tone(AUDIO / "ambience" / "night_wind.wav", 32, 2.0, 0.13, 0.70)


def main() -> None:
    ensure_dirs()
    make_tiles()
    make_objects()
    make_characters()
    make_icons()
    make_steam_art()
    make_audio()


if __name__ == "__main__":
    main()
