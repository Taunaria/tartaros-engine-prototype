#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
SRC_DIR = ROOT / "assets/textures/characters/directional"
OUT_DIR = ROOT / "assets/textures/characters/extended"

CHARACTERS = ["player", "zombie", "skeleton", "boss"]
DIAGONAL_MAP = {
    "up_left": "ul",
    "up_right": "ur",
    "down_left": "dl",
    "down_right": "dr",
}


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for character in CHARACTERS:
        generate_character(character)
    print("generated extended character frames in", OUT_DIR)


def generate_character(character: str) -> None:
    idle = {key: load(character, "idle", short) for key, short in DIAGONAL_MAP.items()}
    attack = {key: load(character, "attack", short) for key, short in DIAGONAL_MAP.items()}

    base_idle = {
        **idle,
        "up": idle["up_left"].copy(),
        "down": idle["down_right"].copy(),
        "left": idle["down_left"].copy(),
        "right": idle["down_right"].copy(),
    }
    base_attack = {
        **attack,
        "up": attack["up_left"].copy(),
        "down": attack["down_right"].copy(),
        "left": attack["down_left"].copy(),
        "right": attack["down_right"].copy(),
    }

    for direction, image in base_idle.items():
        save_frame(character, "idle", direction, image)
        save_frame(character, "hit", direction, make_hit_frame(image, direction))
        save_frame(character, "death", direction, make_death_frame(image, direction))
        walk_a, walk_b = make_walk_frames(image, direction)
        save_frame(character, "walk", direction, walk_a, "1")
        save_frame(character, "walk", direction, walk_b, "2")

    for direction, image in base_attack.items():
        save_frame(character, "attack", direction, image)


def load(character: str, state: str, short_direction: str) -> Image.Image:
    return Image.open(SRC_DIR / f"{character}_{state}_{short_direction}.png").convert("RGBA")


def save_frame(character: str, state: str, direction: str, image: Image.Image, suffix: str = "") -> None:
    name = f"{character}_{state}_{direction}"
    if suffix:
        name += f"_{suffix}"
    image.save(OUT_DIR / f"{name}.png")


def make_walk_frames(image: Image.Image, direction: str) -> tuple[Image.Image, Image.Image]:
    return (
        compose_walk_variant(image, direction, 1),
        compose_walk_variant(image, direction, -1),
    )


def compose_walk_variant(
    image: Image.Image,
    direction: str,
    phase: int,
) -> Image.Image:
    bbox = image.getbbox()
    if bbox is None:
        return image.copy()
    crop = image.crop(bbox)
    scale_x = 1.0 + 0.02 * phase
    scale_y = 1.0 - 0.02 * phase
    warped = crop.resize((max(1, int(crop.width * scale_x)), max(1, int(crop.height * scale_y))), Image.LANCZOS)
    canvas = Image.new("RGBA", image.size, (0, 0, 0, 0))
    x_shift = 2 * phase if direction in {"left", "right", "up_left", "down_right"} else -2 * phase if direction in {"right", "down_left", "up_right"} else 0
    y_shift = -2 if phase > 0 else 0
    x = bbox[0] - int((warped.width - crop.width) * 0.5) + x_shift
    y = bbox[3] - warped.height + y_shift
    canvas.alpha_composite(warped, (x, y))
    return trim_to_canvas(canvas)


def make_hit_frame(image: Image.Image, direction: str) -> Image.Image:
    bbox = image.getbbox()
    if bbox is None:
        return image.copy()
    x0, y0, x1, y1 = bbox
    crop = image.crop(bbox)
    squashed = crop.resize((int(crop.width * 1.04), int(crop.height * 0.94)), Image.LANCZOS)
    dx, dy = direction_to_offset(direction, 10)
    canvas = Image.new("RGBA", image.size, (0, 0, 0, 0))
    px = x0 - int((squashed.width - crop.width) * 0.5) - dx
    py = y1 - squashed.height - dy
    canvas.alpha_composite(squashed, (px, py))
    return trim_to_canvas(canvas)


def make_death_frame(image: Image.Image, direction: str) -> Image.Image:
    bbox = image.getbbox()
    if bbox is None:
        return image.copy()
    crop = image.crop(bbox)
    angle = direction_to_death_angle(direction)
    rotated = crop.rotate(angle, resample=Image.Resampling.BICUBIC, expand=True)
    canvas = Image.new("RGBA", image.size, (0, 0, 0, 0))
    x = (image.width - rotated.width) // 2
    y = image.height - rotated.height - 26
    canvas.alpha_composite(rotated, (x, y))
    return trim_to_canvas(canvas)


def trim_to_canvas(image: Image.Image) -> Image.Image:
    bbox = image.getbbox()
    if bbox is None:
        return image
    cropped = image.crop(bbox)
    canvas = Image.new("RGBA", image.size, (0, 0, 0, 0))
    x = (image.width - cropped.width) // 2
    y = image.height - cropped.height - 24
    canvas.alpha_composite(cropped, (x, y))
    return canvas


def direction_to_offset(direction: str, amount: int) -> tuple[int, int]:
    mapping = {
        "up": (0, -amount // 2),
        "down": (0, amount // 2),
        "left": (-amount // 2, 0),
        "right": (amount // 2, 0),
        "up_left": (-amount // 2, -amount // 3),
        "up_right": (amount // 2, -amount // 3),
        "down_left": (-amount // 2, amount // 3),
        "down_right": (amount // 2, amount // 3),
    }
    return mapping.get(direction, (0, 0))


def direction_to_death_angle(direction: str) -> float:
    mapping = {
        "up": -82.0,
        "down": 82.0,
        "left": -90.0,
        "right": 90.0,
        "up_left": -72.0,
        "up_right": 72.0,
        "down_left": -104.0,
        "down_right": 104.0,
    }
    return mapping.get(direction, 90.0)


if __name__ == "__main__":
    main()
