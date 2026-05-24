from __future__ import annotations

import argparse
import json
import time
import urllib.parse
import urllib.request
import uuid
from pathlib import Path


DEFAULT_SERVER = "http://192.168.50.143:8000"


def get_json(url: str, timeout: float = 8.0) -> dict:
    with urllib.request.urlopen(url, timeout=timeout) as response:
        return json.loads(response.read().decode("utf-8"))


def post_json(url: str, payload: dict, timeout: float = 12.0) -> dict:
    data = json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return json.loads(response.read().decode("utf-8"))


def health(server: str) -> int:
    stats = get_json(f"{server.rstrip('/')}/system_stats")
    print(json.dumps({
        "server": server,
        "system": stats.get("system", {}),
        "devices": stats.get("devices", []),
    }, ensure_ascii=False, indent=2))
    return 0


def submit(server: str, workflow_path: Path, output_dir: Path, poll: bool) -> int:
    if not workflow_path.exists():
        print(f"workflow not found: {workflow_path}")
        return 2
    workflow = json.loads(workflow_path.read_text(encoding="utf-8"))
    client_id = str(uuid.uuid4())
    result = post_json(f"{server.rstrip('/')}/prompt", {"prompt": workflow, "client_id": client_id})
    prompt_id = result.get("prompt_id")
    print(json.dumps(result, ensure_ascii=False, indent=2))
    if not poll or prompt_id == "":
        return 0
    output_dir.mkdir(parents=True, exist_ok=True)
    for _ in range(240):
        history = get_json(f"{server.rstrip('/')}/history/{prompt_id}", timeout=12.0)
        if prompt_id in history:
            return download_outputs(server, history[prompt_id], output_dir)
        time.sleep(1.0)
    print("timed out waiting for ComfyUI history")
    return 3


def download_outputs(server: str, entry: dict, output_dir: Path) -> int:
    saved = 0
    for node in entry.get("outputs", {}).values():
        for image in node.get("images", []):
            query = urllib.parse.urlencode({
                "filename": image.get("filename", ""),
                "subfolder": image.get("subfolder", ""),
                "type": image.get("type", "output"),
            })
            url = f"{server.rstrip('/')}/view?{query}"
            target = output_dir / image.get("filename", f"comfy_{saved}.png")
            with urllib.request.urlopen(url, timeout=30.0) as response:
                target.write_bytes(response.read())
            print(target)
            saved += 1
    return 0 if saved > 0 else 4


def main() -> int:
    parser = argparse.ArgumentParser(description="Optional ComfyUI bridge for Bunkertopia source-sheet generation.")
    parser.add_argument("--server", default=DEFAULT_SERVER)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("health")
    submit_parser = sub.add_parser("submit")
    submit_parser.add_argument("--workflow", required=True, type=Path)
    submit_parser.add_argument("--output-dir", default=Path("assets/art/source/generated_raw/comfy"), type=Path)
    submit_parser.add_argument("--no-poll", action="store_true")
    args = parser.parse_args()
    if args.command == "health":
        return health(args.server)
    if args.command == "submit":
        return submit(args.server, args.workflow, args.output_dir, not args.no_poll)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
