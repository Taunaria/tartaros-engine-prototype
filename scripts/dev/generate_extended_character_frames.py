#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
SPECS_PATH = ROOT / "tmp/imagegen/character_extension/specs.json"
OUT_DIR = ROOT / "assets/textures/characters/extended"
IMAGE_GEN_SCRIPT = Path("/Users/jurgenreichardt-kron/.codex/skills/imagegen/scripts/image_gen.py")

CHARACTER_DESCRIPTIONS = {
    "player": "the same blue-armored fantasy knight with a silver helmet, brown gloves and boots, and a steel sword",
    "zombie": "the same blocky green zombie with a torn brown shirt, blue pants, and simple undead features",
    "skeleton": "the same white skeleton warrior with a sword and clean stylized bone shapes",
    "boss": "the same bulky horned abyss guardian with black-and-red armor plates, glowing orange core accents, and oversized gauntlets",
}

STATE_DESCRIPTIONS = {
    "idle": "neutral idle poses",
    "walk": "a two-frame walking cycle",
    "attack": "combat attack poses",
    "hit": "hurt recoil poses",
    "death": "defeated death poses",
}

STATE_AVOID = {
    "idle": "combat stance; jumping; leaning; extra effects",
    "walk": "sliding feet; mismatched stride length; identical consecutive frames",
    "attack": "idle stance; oversized weapon arcs; extra particles",
    "hit": "attack swings; gore; falling over completely",
    "death": "standing poses; attack swings; gore",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--character", choices=["player", "zombie", "skeleton", "boss"], default=None)
    parser.add_argument("--state", choices=["idle", "walk", "attack", "hit", "death"], default=None)
    parser.add_argument("--extract-only", action="store_true")
    parser.add_argument("--force-generate", action="store_true")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    specs = load_specs()
    filtered_specs = [
        spec
        for spec in specs
        if (args.character is None or spec["character"] == args.character)
        and (args.state is None or spec["state"] == args.state)
    ]
    if not filtered_specs:
        raise SystemExit("No matching character/state specs found.")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for spec in filtered_specs:
        generated_path = generated_sheet_path(spec)
        if not args.extract_only:
            generate_sheet(spec, generated_path, force_generate=args.force_generate)
        extract_sheet(spec, generated_path)

    validate_uniqueness(filtered_specs)
    print("rebuilt extended character frames in", OUT_DIR)


def load_specs() -> list[dict]:
    return json.loads(SPECS_PATH.read_text())


def generated_sheet_path(spec: dict) -> Path:
    return Path(spec["base"]).with_name(f"{spec['state']}_generated.png")


def generate_sheet(spec: dict, generated_path: Path, force_generate: bool) -> None:
    if generated_path.exists() and not force_generate:
        print("using existing sheet", generated_path)
        return

    if not IMAGE_GEN_SCRIPT.exists():
        raise SystemExit(f"Image generator not found: {IMAGE_GEN_SCRIPT}")
    if not os.environ.get("OPENAI_API_KEY"):
        raise SystemExit("OPENAI_API_KEY is required to generate missing sheets.")

    base_path = Path(spec["base"])
    mask_path = Path(spec["mask"])
    prompt = build_prompt(spec)
    size = Image.open(base_path).size
    size_arg = f"{size[0]}x{size[1]}"
    command = [
        sys.executable,
        str(IMAGE_GEN_SCRIPT),
        "edit",
        "--image",
        str(base_path),
        "--mask",
        str(mask_path),
        "--prompt",
        prompt,
        "--size",
        size_arg,
        "--quality",
        "high",
        "--background",
        "transparent",
        "--output-format",
        "png",
        "--input-fidelity",
        "high",
        "--out",
        str(generated_path),
        "--force",
    ]
    print("generating", spec["character"], spec["state"])
    subprocess.run(command, check=True, cwd=ROOT)


def build_prompt(spec: dict) -> str:
    meta = load_meta(spec)
    order_lines = []
    placements_by_row: dict[int, list[str]] = defaultdict(list)
    for placement in sorted(meta["placements"], key=lambda item: (item["row"], item["col"])):
        direction_name = placement["name"].removeprefix(f"{spec['character']}_{spec['state']}_").removesuffix(".png")
        placements_by_row[placement["row"]].append(direction_name)

    for row_index, row in enumerate(sorted(placements_by_row), start=1):
        order_lines.append(f"masked row {row_index} left to right: {', '.join(placements_by_row[row])}")

    return (
        "Use case: stylized-concept. "
        "Asset type: game character sprite sheet repair. "
        f"Primary request: fill the masked cells of this transparent sprite sheet with {STATE_DESCRIPTIONS[spec['state']]} for {CHARACTER_DESCRIPTIONS[spec['character']]} already shown in the unmasked reference cells. "
        "Scene/background: transparent background only. "
        f"Subject: {CHARACTER_DESCRIPTIONS[spec['character']]}. "
        "Style/medium: polished game-ready isometric 3D sprite render matching the existing sheet exactly. "
        "Composition/framing: keep the exact canvas size, exact grid layout, exact scale, exact camera angle, and exact character centering used by the unmasked reference cells; each masked cell must contain one complete full-body pose. "
        f"Cell order: {'; '.join(order_lines)}. "
        "Constraints: change only the masked cells; keep all unmasked cells unchanged; preserve palette, proportions, lighting, silhouette, materials, and transparent background; every filled cell must be visually distinct and must match its named direction/state in the cell order. "
        f"Avoid: {STATE_AVOID[spec['state']]}; blurry details; merged cells; extra props; changed costume; changed anatomy; watermark."
    )


def load_meta(spec: dict) -> dict:
    return json.loads(Path(spec["meta"]).read_text())


def extract_sheet(spec: dict, generated_path: Path) -> None:
    if not generated_path.exists():
        raise SystemExit(f"Generated sheet missing: {generated_path}")

    meta = load_meta(spec)
    image = Image.open(generated_path).convert("RGBA")
    for placement in meta["placements"]:
        box = tuple(placement["box"])
        out_path = OUT_DIR / placement["name"]
        image.crop(box).save(out_path)
        print("wrote", out_path)


def validate_uniqueness(specs: list[dict]) -> None:
    hashes_by_group: dict[tuple[str, str], dict[str, list[str]]] = defaultdict(lambda: defaultdict(list))
    for spec in specs:
        character = spec["character"]
        state = spec["state"]
        meta = load_meta(spec)
        for placement in meta["placements"]:
            path = OUT_DIR / placement["name"]
            digest = subprocess.check_output(["shasum", "-a", "256", str(path)], text=True).split()[0]
            hashes_by_group[(character, state)][digest].append(placement["name"])

    duplicate_groups = []
    for (character, state), hashes in sorted(hashes_by_group.items()):
        for names in hashes.values():
            if len(names) > 1:
                duplicate_groups.append(f"{character} {state}: {', '.join(sorted(names))}")

    if duplicate_groups:
        raise SystemExit("Duplicate extracted frames detected:\n" + "\n".join(duplicate_groups))


if __name__ == "__main__":
    main()
