from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]


def project_path(path: str) -> Path:
    if path.startswith("res://"):
        return ROOT / path.replace("res://", "", 1)
    return Path(path)


def validate_image(path: Path, key: tuple[int, int, int]) -> list[str]:
    errors: list[str] = []
    if not path.exists():
        return [f"missing: {path}"]
    image = Image.open(path).convert("RGBA")
    if image.width <= 0 or image.height <= 0:
        errors.append(f"invalid size: {path}")
    alpha = image.getchannel("A")
    if alpha.getbbox() is None:
        errors.append(f"blank alpha: {path}")
    pixels = image.getdata()
    opaque = 0
    key_leaks = 0
    for r, g, b, a in pixels:
        if a > 12:
            opaque += 1
            if abs(r - key[0]) <= 4 and abs(g - key[1]) <= 4 and abs(b - key[2]) <= 4:
                key_leaks += 1
    if opaque == 0:
        errors.append(f"no visible pixels: {path}")
    if key_leaks > 0:
        errors.append(f"chroma key leak: {path} ({key_leaks}px)")
    return errors


def collect_paths(manifest: dict) -> list[str]:
    paths: list[str] = []
    for section in ["objects", "tiles", "ui_icons"]:
        for value in manifest.get(section, {}).values():
            if isinstance(value, dict) and value.get("path"):
                paths.append(str(value["path"]))
    for value in manifest.get("characters", {}).values():
        if isinstance(value, dict) and value.get("sheet"):
            paths.append(str(value["sheet"]))
    return paths


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate Bunkertopia target-style art manifest outputs.")
    parser.add_argument("--manifest", default=ROOT / "data" / "art_asset_manifest.json", type=Path)
    parser.add_argument("--key", default="0,255,0")
    args = parser.parse_args()
    if not args.manifest.exists():
        print(f"missing manifest: {args.manifest}")
        return 2
    key = tuple(int(part) for part in args.key.split(","))
    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    errors: list[str] = []
    for raw_path in collect_paths(manifest):
        errors.extend(validate_image(project_path(raw_path), key))
    if errors:
        for error in errors:
            print(error)
        return 1
    print(f"validated {len(collect_paths(manifest))} art assets")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
