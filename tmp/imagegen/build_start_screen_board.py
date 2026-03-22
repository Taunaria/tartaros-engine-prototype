from __future__ import annotations

from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "tmp/imagegen/start_screen_styleboard.png"
SIZE = (1920, 1080)


def rgba(*values: int) -> tuple[int, int, int, int]:
    if len(values) == 3:
        return values[0], values[1], values[2], 255
    return values  # type: ignore[return-value]


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def lerp_color(a: tuple[int, int, int, int], b: tuple[int, int, int, int], t: float) -> tuple[int, int, int, int]:
    return tuple(int(lerp(x, y, t)) for x, y in zip(a, b))  # type: ignore[return-value]


def crop_alpha(image: Image.Image) -> Image.Image:
    if "A" not in image.getbands():
        return image
    bbox = image.getchannel("A").getbbox()
    return image.crop(bbox) if bbox else image


def make_vertical_gradient(size: tuple[int, int], top: tuple[int, int, int, int], bottom: tuple[int, int, int, int]) -> Image.Image:
    width, height = size
    image = Image.new("RGBA", size)
    pixels = image.load()
    for y in range(height):
        t = y / max(1, height - 1)
        color = lerp_color(top, bottom, t)
        for x in range(width):
            pixels[x, y] = color
    return image


def overlay_gradient(base: Image.Image, left: tuple[int, int, int, int], right: tuple[int, int, int, int], opacity: int = 255) -> None:
    width, height = base.size
    image = Image.new("RGBA", base.size)
    pixels = image.load()
    for x in range(width):
        t = x / max(1, width - 1)
        color = lerp_color(left, right, t)
        for y in range(height):
            pixels[x, y] = color[:3] + (opacity,)
    base.alpha_composite(image)


def draw_glow(base: Image.Image, center: tuple[int, int], radius: int, color: tuple[int, int, int, int], blur: int) -> None:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    x, y = center
    draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=color)
    layer = layer.filter(ImageFilter.GaussianBlur(blur))
    base.alpha_composite(layer)


def average_color(image: Image.Image) -> tuple[int, int, int, int]:
    small = image.convert("RGBA").resize((1, 1))
    return small.getpixel((0, 0))


def tint(color: tuple[int, int, int, int], factor: float) -> tuple[int, int, int, int]:
    return tuple(max(0, min(255, int(channel * factor))) for channel in color[:3]) + (color[3],)


def pattern_fill(texture: Image.Image, size: tuple[int, int], scale: float = 1.0) -> Image.Image:
    tex = texture.convert("RGBA")
    tex_w = max(24, int(tex.width * scale))
    tex_h = max(24, int(tex.height * scale))
    tex = tex.resize((tex_w, tex_h), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    for x in range(0, size[0], tex_w):
        for y in range(0, size[1], tex_h):
            canvas.alpha_composite(tex, (x, y))
    return canvas


def polygon_fill(base: Image.Image, polygon: list[tuple[float, float]], fill: Image.Image | tuple[int, int, int, int], opacity: int = 255) -> None:
    xs = [p[0] for p in polygon]
    ys = [p[1] for p in polygon]
    left = int(min(xs))
    top = int(min(ys))
    right = int(max(xs))
    bottom = int(max(ys))
    if right <= left or bottom <= top:
        return
    mask = Image.new("L", (right - left, bottom - top), 0)
    shifted = [(x - left, y - top) for x, y in polygon]
    ImageDraw.Draw(mask).polygon(shifted, fill=opacity)
    if isinstance(fill, Image.Image):
        pattern = pattern_fill(fill, (right - left, bottom - top), scale=0.42)
        layer = Image.new("RGBA", (right - left, bottom - top), (0, 0, 0, 0))
        layer.alpha_composite(pattern)
    else:
        layer = Image.new("RGBA", (right - left, bottom - top), fill)
    base.paste(layer, (left, top), mask)


def iso_points(center: tuple[float, float], size: tuple[float, float]) -> tuple[tuple[float, float], tuple[float, float], tuple[float, float], tuple[float, float]]:
    cx, cy = center
    w, h = size
    return (
        (cx, cy - h / 2.0),
        (cx + w / 2.0, cy),
        (cx, cy + h / 2.0),
        (cx - w / 2.0, cy),
    )


def draw_iso_block(
    base: Image.Image,
    center: tuple[float, float],
    size: tuple[float, float],
    height: float,
    top_fill: Image.Image | tuple[int, int, int, int],
    left_fill: Image.Image | tuple[int, int, int, int],
    right_fill: Image.Image | tuple[int, int, int, int],
    opacity: int = 255,
) -> None:
    top, right, bottom, left = iso_points(center, size)
    left_poly = [left, bottom, (bottom[0], bottom[1] + height), (left[0], left[1] + height)]
    right_poly = [bottom, right, (right[0], right[1] + height), (bottom[0], bottom[1] + height)]
    top_poly = [top, right, bottom, left]
    polygon_fill(base, left_poly, left_fill, opacity=opacity)
    polygon_fill(base, right_poly, right_fill, opacity=opacity)
    polygon_fill(base, top_poly, top_fill, opacity=opacity)


def world_to_screen(origin: tuple[float, float], tile_size: tuple[float, float], grid_x: int, grid_y: int) -> tuple[float, float]:
    ox, oy = origin
    tw, th = tile_size
    return ox + (grid_x - grid_y) * tw / 2.0, oy + (grid_x + grid_y) * th / 2.0


def alpha_silhouette(source: Image.Image, color: tuple[int, int, int, int], blur: int = 0) -> Image.Image:
    alpha = source.getchannel("A")
    silhouette = Image.new("RGBA", source.size, color)
    silhouette.putalpha(alpha)
    if blur > 0:
        silhouette = silhouette.filter(ImageFilter.GaussianBlur(blur))
    return silhouette


def paste_character(
    base: Image.Image,
    image: Image.Image,
    anchor: tuple[int, int],
    target_height: int,
    opacity: int = 255,
    shadow_offset: tuple[int, int] = (18, 22),
    shadow_blur: int = 16,
    shadow_scale: float = 1.04,
    add_glow: tuple[int, int, int, int] | None = None,
) -> None:
    source = crop_alpha(image.convert("RGBA"))
    scale = target_height / source.height
    target_size = (max(1, int(source.width * scale)), max(1, int(source.height * scale)))
    sprite = source.resize(target_size, Image.Resampling.LANCZOS)
    if opacity < 255:
        alpha = sprite.getchannel("A").point(lambda value: value * opacity // 255)
        sprite.putalpha(alpha)

    shadow = alpha_silhouette(sprite, (0, 0, 0, 140), blur=shadow_blur)
    shadow = shadow.resize(
        (max(1, int(shadow.width * shadow_scale)), max(1, int(shadow.height * shadow_scale))),
        Image.Resampling.LANCZOS,
    )

    x = int(anchor[0] - sprite.width / 2)
    y = int(anchor[1] - sprite.height)
    sx = x + shadow_offset[0] - int((shadow.width - sprite.width) / 2)
    sy = y + shadow_offset[1] - int((shadow.height - sprite.height) / 2)
    base.alpha_composite(shadow, (sx, sy))

    if add_glow is not None:
        glow = alpha_silhouette(sprite, add_glow, blur=26)
        base.alpha_composite(glow, (x, y))

    base.alpha_composite(sprite, (x, y))


def paste_shadow_enemy(
    base: Image.Image,
    image: Image.Image,
    anchor: tuple[int, int],
    target_height: int,
    tint_color: tuple[int, int, int, int],
    opacity: int,
    blur: int,
) -> None:
    sprite = crop_alpha(image.convert("RGBA"))
    scale = target_height / sprite.height
    target_size = (max(1, int(sprite.width * scale)), max(1, int(sprite.height * scale)))
    sprite = sprite.resize(target_size, Image.Resampling.LANCZOS)
    tinted = Image.new("RGBA", sprite.size, tint_color)
    tinted.putalpha(sprite.getchannel("A"))
    tinted = tinted.filter(ImageFilter.GaussianBlur(blur))
    alpha = tinted.getchannel("A").point(lambda value: value * opacity // 255)
    tinted.putalpha(alpha)
    x = int(anchor[0] - tinted.width / 2)
    y = int(anchor[1] - tinted.height)
    base.alpha_composite(tinted, (x, y))


def add_mist_band(base: Image.Image, polygon: Iterable[tuple[float, float]], color: tuple[int, int, int, int], blur: int) -> None:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.polygon(list(polygon), fill=color)
    layer = layer.filter(ImageFilter.GaussianBlur(blur))
    base.alpha_composite(layer)


def main() -> None:
    textures = {
        "grass_top": Image.open(ROOT / "assets/textures/block_materials/grass_top.png"),
        "grass_side": Image.open(ROOT / "assets/textures/block_materials/grass_side.png"),
        "forest_top": Image.open(ROOT / "assets/textures/block_materials/forest_grass_top.png"),
        "forest_side": Image.open(ROOT / "assets/textures/block_materials/forest_grass_side.png"),
        "wood_top": Image.open(ROOT / "assets/textures/block_materials/wood_top.png"),
        "wood_side": Image.open(ROOT / "assets/textures/block_materials/wood_side.png"),
        "dark_top": Image.open(ROOT / "assets/textures/block_materials/dark_stone_top.png"),
        "dark_side": Image.open(ROOT / "assets/textures/block_materials/dark_stone_side.png"),
        "temple_top": Image.open(ROOT / "assets/textures/block_materials/temple_stone_top.png"),
        "temple_side": Image.open(ROOT / "assets/textures/block_materials/temple_stone_side.png"),
        "lava_top": Image.open(ROOT / "assets/textures/block_materials/lava_top.png"),
        "lava_side": Image.open(ROOT / "assets/textures/block_materials/lava_side.png"),
    }
    characters = {
        "hero": Image.open(ROOT / "assets/textures/characters/directional/player_attack_ur.png"),
        "zombie": Image.open(ROOT / "assets/textures/characters/directional/zombie_attack_ul.png"),
        "skeleton": Image.open(ROOT / "assets/textures/characters/directional/skeleton_attack_ul.png"),
        "boss": Image.open(ROOT / "assets/textures/characters/directional/boss_idle_ul.png"),
    }

    canvas = make_vertical_gradient(SIZE, rgba(39, 48, 66), rgba(19, 21, 31))
    overlay_gradient(canvas, rgba(52, 88, 63, 120), rgba(72, 48, 36, 80), opacity=90)

    draw_glow(canvas, (260, 160), 280, rgba(122, 177, 114, 110), 110)
    draw_glow(canvas, (980, 260), 340, rgba(71, 92, 128, 90), 130)
    draw_glow(canvas, (340, 880), 300, rgba(255, 110, 46, 120), 150)
    draw_glow(canvas, (1450, 420), 280, rgba(191, 201, 220, 72), 140)

    add_mist_band(
        canvas,
        [(0, 330), (260, 260), (520, 280), (770, 340), (980, 310), (1220, 360), (1920, 300), (1920, 0), (0, 0)],
        rgba(32, 49, 44, 80),
        32,
    )
    add_mist_band(
        canvas,
        [(0, 470), (350, 420), (760, 455), (1120, 420), (1540, 460), (1920, 430), (1920, 250), (0, 250)],
        rgba(41, 54, 64, 110),
        42,
    )

    origin = (720, 590)
    tile_size = (180, 90)
    ground_specs: list[tuple[Image.Image, Image.Image]] = [
        (textures["grass_top"], textures["grass_side"]),
        (textures["grass_top"], textures["wood_side"]),
        (textures["forest_top"], textures["forest_side"]),
        (textures["dark_top"], textures["dark_side"]),
        (textures["temple_top"], textures["temple_side"]),
        (textures["temple_top"], textures["temple_side"]),
    ]

    for gy in range(0, 6):
        for gx in range(0, 10):
            center = world_to_screen(origin, tile_size, gx, gy)
            spec_index = min(len(ground_specs) - 1, max(0, gx - 1))
            top_tex, side_tex = ground_specs[spec_index]
            height = 18 + max(0, 5 - gy) * 3
            if gx in (3, 4) and gy == 0:
                top_tex, side_tex = textures["lava_top"], textures["lava_side"]
                height = 8
            if gx >= 8 and gy <= 2:
                height = 10
            draw_iso_block(canvas, center, tile_size, height, top_tex, side_tex, tint(average_color(side_tex), 0.76), opacity=210)

    # Village huts on the left.
    for cx, cy, scale in [(280, 470, 1.0), (430, 420, 0.82)]:
        size = (170 * scale, 85 * scale)
        draw_iso_block(canvas, (cx, cy), size, 150 * scale, textures["wood_top"], textures["wood_side"], tint(average_color(textures["wood_side"]), 0.85), 220)
        draw_iso_block(canvas, (cx, cy - 98 * scale), (185 * scale, 92 * scale), 46 * scale, textures["grass_top"], textures["wood_side"], tint(average_color(textures["wood_side"]), 0.82), 224)

    # Forest blocks / trees.
    for cx, cy, scale in [(620, 385, 1.0), (760, 355, 0.88), (880, 375, 0.74)]:
        trunk_side = tint(average_color(textures["wood_side"]), 0.70)
        draw_iso_block(canvas, (cx, cy), (54 * scale, 27 * scale), 125 * scale, textures["wood_top"], textures["wood_side"], trunk_side, 205)
        draw_iso_block(canvas, (cx, cy - 132 * scale), (150 * scale, 74 * scale), 72 * scale, textures["forest_top"], textures["forest_side"], tint(average_color(textures["forest_side"]), 0.70), 190)
        draw_iso_block(canvas, (cx - 26 * scale, cy - 186 * scale), (118 * scale, 58 * scale), 42 * scale, textures["forest_top"], textures["forest_side"], tint(average_color(textures["forest_side"]), 0.62), 160)

    # Cave arch / dark stone mass.
    for cx, cy, w, h, block_h in [
        (990, 342, 112, 56, 165),
        (1134, 342, 112, 56, 165),
        (1062, 286, 256, 128, 40),
        (1062, 412, 322, 161, 30),
    ]:
        draw_iso_block(canvas, (cx, cy), (w, h), block_h, textures["dark_top"], textures["dark_side"], tint(average_color(textures["dark_side"]), 0.70), 180)

    # Temple silhouette on the right, kept calm and faded for menu area.
    for cx, cy, scale in [(1455, 360, 1.0), (1600, 332, 0.92), (1740, 356, 0.86)]:
        draw_iso_block(canvas, (cx, cy), (84 * scale, 42 * scale), 190 * scale, textures["temple_top"], textures["temple_side"], tint(average_color(textures["temple_side"]), 0.84), 150)
        draw_iso_block(canvas, (cx, cy - 156 * scale), (116 * scale, 58 * scale), 24 * scale, textures["temple_top"], textures["temple_side"], tint(average_color(textures["temple_side"]), 0.82), 136)

    # Abyss fissure glow behind the foreground.
    lava_layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    lava_draw = ImageDraw.Draw(lava_layer)
    lava_draw.polygon(
        [(120, 735), (280, 685), (545, 720), (735, 660), (942, 702), (880, 770), (610, 812), (360, 790), (160, 770)],
        fill=rgba(255, 111, 42, 160),
    )
    lava_draw.polygon(
        [(180, 680), (330, 642), (520, 670), (690, 640), (850, 672), (786, 720), (610, 748), (355, 726)],
        fill=rgba(255, 191, 79, 110),
    )
    lava_layer = lava_layer.filter(ImageFilter.GaussianBlur(42))
    canvas.alpha_composite(lava_layer)

    # Calm mist on the menu side.
    add_mist_band(
        canvas,
        [(1170, 150), (1920, 120), (1920, 900), (1290, 860), (1120, 590), (1140, 300)],
        rgba(111, 122, 146, 44),
        64,
    )

    # Midground enemy silhouettes.
    paste_shadow_enemy(canvas, characters["zombie"], (380, 610), 250, rgba(45, 72, 46, 255), 140, 2)
    paste_shadow_enemy(canvas, characters["skeleton"], (930, 598), 230, rgba(167, 181, 203, 255), 124, 1)
    paste_shadow_enemy(canvas, characters["boss"], (1260, 525), 300, rgba(114, 58, 46, 255), 118, 2)

    # Hero in the foreground, left of center.
    paste_character(
        canvas,
        characters["hero"],
        anchor=(760, 890),
        target_height=620,
        opacity=255,
        shadow_offset=(24, 30),
        shadow_blur=18,
        shadow_scale=1.05,
        add_glow=rgba(255, 159, 89, 40),
    )

    # Light directional wash from top-left and subtle lava rim.
    light_layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    light_draw = ImageDraw.Draw(light_layer)
    light_draw.polygon([(0, 0), (780, 0), (540, 540), (0, 740)], fill=rgba(255, 255, 255, 44))
    light_layer = light_layer.filter(ImageFilter.GaussianBlur(90))
    canvas.alpha_composite(light_layer)
    draw_glow(canvas, (860, 840), 150, rgba(255, 143, 72, 38), 72)

    vignette = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    vdraw = ImageDraw.Draw(vignette)
    vdraw.rectangle((0, 0, SIZE[0], SIZE[1]), outline=rgba(0, 0, 0, 210), width=48)
    vignette = vignette.filter(ImageFilter.GaussianBlur(90))
    canvas.alpha_composite(vignette)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(OUT)
    print(OUT)


if __name__ == "__main__":
    main()
