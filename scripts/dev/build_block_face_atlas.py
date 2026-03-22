#!/usr/bin/env python3

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageOps


REPO_ROOT = Path(__file__).resolve().parents[2]
SWATCH_DIR = REPO_ROOT / "assets" / "textures" / "block_materials"
OUTPUT_ATLAS = REPO_ROOT / "assets" / "textures" / "block_faces_generated.png"
OUTPUT_PREVIEW = REPO_ROOT / "tmp" / "imagegen" / "block_faces_generated_preview.png"

ATLAS_SIZE = (128, 320)
TOP_FACE_SIZE = (64, 32)
SIDE_FACE_SIZE = (32, 32)

MATERIALS = [
	"grass",
	"dirt",
	"wood",
	"light_stone",
	"dark_stone",
	"foliage",
	"temple_stone",
	"lava",
	"cracked",
	"forest_grass",
]

TOP_POLYGON = [(32, 1), (63, 16), (32, 31), (1, 16)]
LEFT_POLYGON = [(1, 1), (31, 16), (31, 31), (1, 16)]
RIGHT_POLYGON = [(1, 16), (31, 1), (31, 16), (1, 31)]


def main() -> None:
	atlas = Image.new("RGBA", ATLAS_SIZE, (0, 0, 0, 0))
	for index, material in enumerate(MATERIALS):
		row_y = index * 32
		top_source = _load_swatch(material, "top")
		side_source = _load_swatch(material, "side")

		top_face = _build_top_face(top_source)
		left_face = _build_side_face(side_source, LEFT_POLYGON, brightness=0.92, shadow_strength=0.18)
		right_face = _build_side_face(side_source, RIGHT_POLYGON, brightness=0.8, shadow_strength=0.28)

		atlas.alpha_composite(top_face, (0, row_y))
		atlas.alpha_composite(left_face, (64, row_y))
		atlas.alpha_composite(right_face, (96, row_y))

	OUTPUT_ATLAS.parent.mkdir(parents=True, exist_ok=True)
	atlas.save(OUTPUT_ATLAS)

	OUTPUT_PREVIEW.parent.mkdir(parents=True, exist_ok=True)
	atlas.resize((ATLAS_SIZE[0] * 4, ATLAS_SIZE[1] * 4), Image.Resampling.NEAREST).save(OUTPUT_PREVIEW)

	print(OUTPUT_ATLAS)
	print(OUTPUT_PREVIEW)


def _load_swatch(material: str, face_kind: str) -> Image.Image:
	path = SWATCH_DIR / f"{material}_{face_kind}.png"
	if not path.exists():
		raise FileNotFoundError(f"Missing swatch: {path}")
	return Image.open(path).convert("RGBA")


def _prepare_surface(source: Image.Image, size: tuple[int, int], brightness: float) -> Image.Image:
	surface = ImageOps.fit(source, size, method=Image.Resampling.LANCZOS, centering=(0.5, 0.5))
	surface = ImageEnhance.Color(surface).enhance(1.05)
	surface = ImageEnhance.Contrast(surface).enhance(1.12)
	surface = ImageEnhance.Brightness(surface).enhance(brightness)
	return surface.filter(ImageFilter.UnsharpMask(radius=1.0, percent=120, threshold=2))


def _polygon_mask(size: tuple[int, int], polygon: list[tuple[int, int]]) -> Image.Image:
	mask = Image.new("L", size, 0)
	ImageDraw.Draw(mask).polygon(polygon, fill=255)
	return mask


def _build_top_face(source: Image.Image) -> Image.Image:
	face = _prepare_surface(source, TOP_FACE_SIZE, brightness=1.04)
	mask = _polygon_mask(TOP_FACE_SIZE, TOP_POLYGON)
	face.putalpha(mask)

	# Glossy top-left highlight to match the sharper character style.
	highlight = Image.new("RGBA", TOP_FACE_SIZE, (0, 0, 0, 0))
	draw = ImageDraw.Draw(highlight)
	draw.line([(2, 16), (32, 1), (46, 8)], fill=(255, 255, 255, 82), width=1)
	draw.line([(20, 10), (31, 5), (40, 10)], fill=(255, 255, 255, 44), width=1)
	highlight.putalpha(ImageChops.multiply(mask, highlight.getchannel("A")))
	face.alpha_composite(highlight)

	shadow = Image.new("RGBA", TOP_FACE_SIZE, (0, 0, 0, 0))
	draw = ImageDraw.Draw(shadow)
	draw.line([(17, 24), (32, 31), (61, 16)], fill=(0, 0, 0, 48), width=1)
	shadow.putalpha(ImageChops.multiply(mask, shadow.getchannel("A")))
	face.alpha_composite(shadow)

	_draw_outline(face, TOP_POLYGON)
	return face


def _build_side_face(
	source: Image.Image,
	polygon: list[tuple[int, int]],
	brightness: float,
	shadow_strength: float
) -> Image.Image:
	face = _prepare_surface(source, SIDE_FACE_SIZE, brightness=brightness)
	mask = _polygon_mask(SIDE_FACE_SIZE, polygon)
	face.putalpha(mask)

	shade = Image.new("RGBA", SIDE_FACE_SIZE, (0, 0, 0, 0))
	draw = ImageDraw.Draw(shade)
	if polygon == LEFT_POLYGON:
		draw.polygon([(1, 1), (31, 16), (31, 31), (20, 26), (18, 14), (8, 9)], fill=(255, 255, 255, 14))
		draw.line([(1, 1), (1, 16), (31, 31)], fill=(255, 255, 255, 34), width=1)
	else:
		draw.polygon([(14, 8), (31, 1), (31, 16), (1, 31), (1, 23), (16, 13)], fill=(0, 0, 0, int(255 * shadow_strength)))
		draw.line([(31, 1), (31, 16), (1, 31)], fill=(0, 0, 0, 56), width=1)
	shade.putalpha(ImageChops.multiply(mask, shade.getchannel("A")))
	face.alpha_composite(shade)

	_draw_outline(face, polygon)
	return face


def _draw_outline(face: Image.Image, polygon: list[tuple[int, int]]) -> None:
	draw = ImageDraw.Draw(face)
	draw.line(polygon + [polygon[0]], fill=(33, 24, 18, 110), width=1)


if __name__ == "__main__":
	main()
