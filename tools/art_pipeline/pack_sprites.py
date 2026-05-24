from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


def pack_folder(input_dir: Path, output: Path, cell: tuple[int, int], columns: int) -> int:
    files = sorted(path for path in input_dir.glob("*.png") if path.is_file())
    if not files:
        return 0
    rows = (len(files) + columns - 1) // columns
    atlas = Image.new("RGBA", (columns * cell[0], rows * cell[1]), (0, 0, 0, 0))
    index = {}
    for i, path in enumerate(files):
        img = Image.open(path).convert("RGBA")
        x = (i % columns) * cell[0] + max(0, (cell[0] - img.width) // 2)
        y = (i // columns) * cell[1] + max(0, (cell[1] - img.height) // 2)
        atlas.alpha_composite(img, (x, y))
        index[path.stem] = {"cell": [i % columns, i // columns], "path": str(path)}
    output.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(output)
    output.with_suffix(".json").write_text(json.dumps(index, ensure_ascii=False, indent=2), encoding="utf-8")
    return len(files)


def main() -> int:
    parser = argparse.ArgumentParser(description="Pack transparent PNG frames or icons into a Godot-friendly atlas.")
    parser.add_argument("--input-dir", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--cell-size", default="64x64")
    parser.add_argument("--columns", default=8, type=int)
    args = parser.parse_args()
    cell = tuple(int(part) for part in args.cell_size.lower().split("x"))
    count = pack_folder(args.input_dir, args.output, cell, args.columns)
    print(f"packed {count} images into {args.output}")
    return 0 if count > 0 else 2


if __name__ == "__main__":
    raise SystemExit(main())
