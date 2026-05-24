from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def remove_key(image: Image.Image, key: tuple[int, int, int], tolerance: int) -> Image.Image:
    src = image.convert("RGBA")
    pixels = src.load()
    for y in range(src.height):
        for x in range(src.width):
            r, g, b, a = pixels[x, y]
            if abs(r - key[0]) <= tolerance and abs(g - key[1]) <= tolerance and abs(b - key[2]) <= tolerance:
                pixels[x, y] = (r, g, b, 0)
            else:
                pixels[x, y] = (r, g, b, a)
    return src


def trim(image: Image.Image, pad: int) -> Image.Image:
    bbox = image.getbbox()
    if bbox is None:
        return image
    x0, y0, x1, y1 = bbox
    return image.crop((max(0, x0 - pad), max(0, y0 - pad), min(image.width, x1 + pad), min(image.height, y1 + pad)))


def split_grid(image: Image.Image, frame: tuple[int, int], output_dir: Path, prefix: str, trim_pad: int) -> int:
    output_dir.mkdir(parents=True, exist_ok=True)
    count = 0
    cols = image.width // frame[0]
    rows = image.height // frame[1]
    for row in range(rows):
        for col in range(cols):
            cell = image.crop((col * frame[0], row * frame[1], (col + 1) * frame[0], (row + 1) * frame[1]))
            if cell.getbbox() is None:
                continue
            save_img = trim(cell, trim_pad) if trim_pad >= 0 else cell
            save_img.save(output_dir / f"{prefix}_r{row:02d}_c{col:02d}.png")
            count += 1
    return count


def main() -> int:
    parser = argparse.ArgumentParser(description="Remove chroma key and optionally split a source sheet into transparent frames.")
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--key", default="0,255,0")
    parser.add_argument("--tolerance", default=8, type=int)
    parser.add_argument("--frame-size", default="")
    parser.add_argument("--prefix", default="frame")
    parser.add_argument("--trim-pad", default=2, type=int)
    args = parser.parse_args()
    key = tuple(int(part) for part in args.key.split(","))
    image = remove_key(Image.open(args.input), key, args.tolerance)
    if args.frame_size:
        w, h = (int(part) for part in args.frame_size.lower().split("x"))
        count = split_grid(image, (w, h), args.out, args.prefix, args.trim_pad)
        print(f"wrote {count} frames to {args.out}")
    else:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        trim(image, args.trim_pad).save(args.out)
        print(args.out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
