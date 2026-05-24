from pathlib import Path
from random import Random

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "assets" / "art"
RNG = Random(42)


def ensure_dirs() -> None:
    for folder in ["tiles", "objects", "characters", "ui"]:
        (ART / folder).mkdir(parents=True, exist_ok=True)


def save(path: Path, image: Image.Image) -> None:
    image.save(path)


def tile(name: str, base: tuple[int, int, int], specks: list[tuple[int, int, int]]) -> None:
    img = Image.new("RGBA", (64, 64), base + (255,))
    draw = ImageDraw.Draw(img)
    for _ in range(70):
        x = RNG.randrange(0, 64)
        y = RNG.randrange(0, 64)
        color = RNG.choice(specks)
        draw.rectangle((x, y, x + RNG.randrange(1, 4), y + RNG.randrange(1, 3)), fill=color + (255,))
    save(ART / "tiles" / f"{name}.png", img)


def outlined(size: tuple[int, int], fill=(0, 0, 0, 0)) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", size, fill)
    return img, ImageDraw.Draw(img)


def draw_outline_rect(draw: ImageDraw.ImageDraw, box, fill, outline=(25, 22, 18, 255), width=2) -> None:
    draw.rectangle(box, fill=outline)
    x0, y0, x1, y1 = box
    draw.rectangle((x0 + width, y0 + width, x1 - width, y1 - width), fill=fill)


def make_objects() -> None:
    img, draw = outlined((96, 80))
    draw.polygon([(10, 42), (48, 14), (88, 42), (78, 68), (18, 68)], fill=(42, 37, 30, 255))
    draw.polygon([(10, 42), (48, 14), (88, 42), (48, 52)], fill=(70, 58, 42, 255), outline=(22, 20, 18, 255))
    draw_outline_rect(draw, (34, 42, 62, 70), (34, 57, 67, 255))
    draw.rectangle((42, 52, 54, 70), fill=(19, 25, 30, 255))
    save(ART / "objects" / "bunker.png", img)

    img, draw = outlined((80, 72))
    draw_outline_rect(draw, (10, 20, 70, 62), (52, 59, 54, 255))
    draw.rectangle((20, 30, 34, 44), fill=(80, 130, 122, 255))
    draw.rectangle((46, 30, 60, 44), fill=(74, 112, 142, 255))
    draw.line((16, 18, 64, 18), fill=(126, 144, 110, 255), width=3)
    draw.rectangle((28, 8, 52, 18), fill=(87, 99, 88, 255))
    save(ART / "objects" / "lab.png", img)

    img, draw = outlined((64, 64))
    draw_outline_rect(draw, (12, 22, 52, 54), (70, 62, 46, 255))
    draw.rectangle((20, 14, 44, 24), fill=(100, 92, 68, 255))
    draw.rectangle((22, 30, 42, 38), fill=(228, 178, 52, 255))
    draw.line((14, 54, 50, 54), fill=(30, 28, 24, 255), width=4)
    save(ART / "objects" / "generator.png", img)

    img, draw = outlined((80, 64))
    for x in range(8, 76, 14):
        draw.rectangle((x, 18, x + 4, 54), fill=(85, 59, 36, 255))
    draw.rectangle((8, 24, 74, 28), fill=(112, 76, 42, 255))
    draw.rectangle((8, 46, 74, 50), fill=(112, 76, 42, 255))
    draw.ellipse((28, 30, 42, 44), fill=(190, 180, 150, 255), outline=(28, 24, 20, 255))
    draw.rectangle((43, 36, 54, 47), fill=(155, 125, 90, 255), outline=(28, 24, 20, 255))
    save(ART / "objects" / "animal_pen.png", img)

    img, draw = outlined((64, 64))
    draw.rectangle((18, 10, 46, 56), fill=(75, 55, 38, 255), outline=(25, 20, 16, 255), width=3)
    draw.rectangle((24, 18, 40, 50), fill=(25, 22, 18, 255))
    draw.rectangle((16, 8, 48, 16), fill=(95, 77, 54, 255))
    save(ART / "objects" / "city_gate.png", img)

    img, draw = outlined((64, 48))
    draw.rectangle((4, 18, 60, 42), fill=(80, 74, 66, 255), outline=(25, 22, 20, 255), width=3)
    for x in range(8, 60, 12):
        draw.line((x, 20, x + 8, 40), fill=(111, 104, 92, 255), width=2)
    save(ART / "objects" / "wall_segment.png", img)

    img, draw = outlined((48, 48))
    draw.rectangle((16, 30, 32, 42), fill=(54, 49, 44, 255), outline=(20, 18, 16, 255))
    draw.ellipse((10, 10, 38, 38), fill=(63, 69, 63, 255), outline=(22, 22, 20, 255), width=3)
    draw.rectangle((23, 0, 28, 18), fill=(92, 86, 70, 255), outline=(22, 22, 20, 255))
    draw.rectangle((19, 19, 30, 30), fill=(126, 110, 70, 255))
    save(ART / "objects" / "turret.png", img)

    img, draw = outlined((48, 48))
    draw.rectangle((6, 8, 42, 42), fill=(82, 63, 38, 255), outline=(28, 24, 18, 255), width=2)
    for x in [14, 24, 34]:
        draw.line((x, 12, x - 2, 38), fill=(70, 130, 64, 255), width=3)
    draw.rectangle((8, 34, 40, 39), fill=(46, 92, 44, 255))
    save(ART / "objects" / "farm_plot.png", img)

    img, draw = outlined((96, 96))
    draw.rectangle((14, 22, 82, 84), fill=(50, 51, 47, 255), outline=(18, 17, 15, 255), width=4)
    draw.polygon([(14, 22), (48, 8), (82, 22), (74, 34), (22, 34)], fill=(69, 63, 56, 255), outline=(18, 17, 15, 255))
    for x in [24, 48, 66]:
        draw.rectangle((x, 42, x + 12, 58), fill=(22, 25, 26, 255), outline=(92, 82, 62, 255))
    draw.line((22, 82, 76, 30), fill=(96, 80, 55, 255), width=4)
    save(ART / "objects" / "ruined_building.png", img)

    img, draw = outlined((120, 64))
    draw.polygon([(8, 36), (76, 20), (112, 30), (80, 46), (18, 48)], fill=(93, 97, 95, 255), outline=(22, 24, 24, 255))
    draw.polygon([(48, 26), (32, 4), (64, 24)], fill=(64, 74, 78, 255), outline=(22, 24, 24, 255))
    draw.polygon([(64, 42), (42, 62), (76, 48)], fill=(64, 74, 78, 255), outline=(22, 24, 24, 255))
    draw.rectangle((80, 24, 96, 34), fill=(45, 67, 78, 255))
    save(ART / "objects" / "crash_plane.png", img)

    img, draw = outlined((64, 64))
    for box in [(8, 36, 24, 50), (20, 26, 42, 50), (36, 34, 56, 52), (28, 18, 46, 34)]:
        draw.rectangle(box, fill=(72, 68, 62, 255), outline=(22, 20, 18, 255), width=2)
    save(ART / "objects" / "rubble.png", img)

    img, draw = outlined((80, 48))
    draw.polygon([(8, 30), (18, 16), (58, 12), (72, 26), (68, 38), (12, 40)], fill=(58, 66, 70, 255), outline=(20, 20, 20, 255))
    draw.rectangle((26, 16, 46, 27), fill=(28, 35, 40, 255))
    draw.ellipse((14, 34, 28, 46), fill=(18, 18, 18, 255))
    draw.ellipse((54, 32, 68, 44), fill=(18, 18, 18, 255))
    save(ART / "objects" / "wrecked_car.png", img)

    img, draw = outlined((48, 48))
    draw.rectangle((8, 14, 40, 38), fill=(83, 62, 42, 255), outline=(22, 18, 14, 255), width=3)
    draw.line((10, 22, 38, 22), fill=(127, 95, 58, 255), width=2)
    draw.rectangle((18, 8, 32, 14), fill=(96, 82, 62, 255), outline=(22, 18, 14, 255))
    save(ART / "objects" / "container.png", img)


def character(path: Path, coat: tuple[int, int, int], skin: tuple[int, int, int], pants: tuple[int, int, int], infected=False) -> None:
    img, draw = outlined((32, 48))
    draw.rectangle((12, 20, 20, 38), fill=coat + (255,), outline=(18, 18, 16, 255))
    draw.rectangle((9, 22, 13, 36), fill=coat + (255,), outline=(18, 18, 16, 255))
    draw.rectangle((19, 22, 23, 36), fill=coat + (255,), outline=(18, 18, 16, 255))
    draw.rectangle((12, 38, 15, 46), fill=pants + (255,))
    draw.rectangle((17, 38, 20, 46), fill=pants + (255,))
    draw.rectangle((10, 8, 22, 20), fill=skin + (255,), outline=(18, 18, 16, 255))
    draw.rectangle((12, 5, 20, 10), fill=(48, 34, 26, 255))
    eye = (215, 70, 55, 255) if infected else (24, 28, 30, 255)
    draw.point((14, 14), fill=eye)
    draw.point((19, 14), fill=eye)
    if infected:
        draw.line((8, 28, 24, 34), fill=(80, 110, 70, 255), width=2)
    save(path, img)


def make_characters() -> None:
    character(ART / "characters" / "scientist.png", (218, 218, 198), (172, 118, 78), (48, 55, 62), False)
    character(ART / "characters" / "zombie_walker.png", (92, 88, 62), (116, 138, 94), (58, 52, 46), True)
    character(ART / "characters" / "zombie_runner.png", (82, 70, 74), (126, 150, 92), (48, 42, 42), True)
    character(ART / "characters" / "zombie_brute.png", (115, 90, 62), (142, 155, 102), (63, 55, 48), True)


def make_icon() -> None:
    img, draw = outlined((64, 64), (30, 36, 32, 255))
    draw.rectangle((14, 22, 50, 48), fill=(82, 98, 86, 255), outline=(12, 14, 12, 255), width=3)
    draw.polygon([(14, 22), (32, 10), (50, 22)], fill=(116, 96, 62, 255), outline=(12, 14, 12, 255))
    draw.ellipse((24, 28, 40, 44), fill=(85, 145, 102, 255), outline=(10, 12, 10, 255))
    save(ART / "ui" / "icon.png", img)


def main() -> None:
    ensure_dirs()
    tile("dirt", (44, 39, 27), [(58, 50, 32), (35, 32, 25), (76, 65, 38)])
    tile("bunker_floor", (57, 55, 48), [(70, 68, 60), (42, 41, 36), (88, 82, 66)])
    tile("field", (62, 52, 30), [(46, 92, 44), (78, 65, 35), (83, 109, 50)])
    tile("cracked_road", (42, 43, 42), [(26, 27, 28), (66, 65, 60), (85, 78, 64)])
    tile("dark_ground", (30, 34, 32), [(22, 25, 24), (48, 52, 45), (55, 45, 40)])
    tile("night_ground", (18, 24, 34), [(26, 34, 48), (12, 16, 23), (44, 42, 46)])
    make_objects()
    make_characters()
    make_icon()


if __name__ == "__main__":
    main()
