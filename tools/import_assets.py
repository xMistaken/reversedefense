#!/usr/bin/env python3
"""Copy the Kenney (CC0) assets the game uses into assets/ and generate the
wyrm's pixel-art sprites.

Usage:
    python3 tools/import_assets.py /path/to/kenney_downloads

The download folder must contain these packs unzipped (from kenney.nl):
    kenney_tiny-dungeon/  kenney_particle-pack/  kenney_ui-pack-rpg-expansion/
    kenney_kenney-fonts/  kenney_rpg-audio/      kenney_impact-sounds/

Requires Pillow. Re-running overwrites assets/ with the same output.
"""
import shutil
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets"

OUTLINE = (63, 38, 49, 255)  # Tiny Dungeon's outline colour

# Tiny Dungeon tile numbers -> our names
TILES = {
    "heroes/warrior.png": 87,
    "heroes/mage.png": 84,
    "heroes/hunter.png": 112,
    "heroes/priest.png": 100,
    "heroes/rogue.png": 98,
    "heroes/warlock.png": 111,
    "items/chest_skill.png": 89,
    "items/chest_hero.png": 91,
    "items/axe.png": 119,
    "items/dagger.png": 103,
    "items/arrow.png": 131,
    "tiles/dirt_0.png": 0,
    "tiles/dirt_1.png": 12,
    "tiles/dirt_2.png": 24,
    "tiles/sand_0.png": 48,
    "tiles/sand_1.png": 49,
    "tiles/sand_2.png": 51,
    "tiles/gravestone.png": 65,
    "tiles/cross.png": 64,
    "tiles/barrel.png": 82,
}

# Particle pack textures (512px) -> downsized glow sprites
PARTICLES = {
    "fx/flame.png": "flame_01",
    "fx/star.png": "star_06",
    "fx/twirl.png": "twirl_02",
    "fx/magic.png": "magic_01",
    "fx/spark.png": "spark_01",
    "fx/glow.png": "circle_05",
    "fx/smoke.png": "smoke_04",
    "fx/light.png": "light_01",
    "fx/slash.png": "slash_02",
    "fx/burst.png": "star_04",
}
PARTICLE_SIZE = 128

UI = {
    "ui/panel.png": "panel_brown.png",
    "ui/panel_inset.png": "panelInset_beige.png",
    "ui/button.png": "buttonLong_brown.png",
    "ui/button_pressed.png": "buttonLong_brown_pressed.png",
    "ui/button_gold.png": "buttonLong_beige.png",
    "ui/button_gold_pressed.png": "buttonLong_beige_pressed.png",
    "ui/button_grey.png": "buttonLong_grey.png",
    "ui/bar_back.png": "barBack_horizontalMid.png",
    "ui/bar_red.png": "barRed_horizontalMid.png",
}

UI_SCALE = 3  # pixel-art UI is upscaled so 9-slice borders stay crisp on phones

FONTS = {
    "fonts/kenney_future.ttf": "Kenney Future.ttf",
    "fonts/kenney_pixel.ttf": "Kenney Pixel.ttf",
}

SOUNDS = {
    "sfx/hit_0.ogg": ("impact", "impactPunch_medium_000.ogg"),
    "sfx/hit_1.ogg": ("impact", "impactPunch_medium_001.ogg"),
    "sfx/hit_2.ogg": ("impact", "impactPunch_medium_002.ogg"),
    "sfx/crit.ogg": ("impact", "impactMetal_light_002.ogg"),
    "sfx/kill_0.ogg": ("impact", "impactSoft_heavy_000.ogg"),
    "sfx/kill_1.ogg": ("impact", "impactSoft_heavy_001.ogg"),
    "sfx/armor.ogg": ("impact", "impactPlate_light_000.ogg"),
    "sfx/legendary.ogg": ("impact", "impactBell_heavy_001.ogg"),
    "sfx/chest.ogg": ("rpg", "doorOpen_1.ogg"),
    "sfx/pick.ogg": ("rpg", "bookFlip2.ogg"),
    "sfx/coins.ogg": ("rpg", "handleCoins.ogg"),
    "sfx/shove.ogg": ("rpg", "cloth3.ogg"),
    "sfx/click.ogg": ("rpg", "metalClick.ogg"),
}


def outline(img: Image.Image) -> Image.Image:
    """Add a 1px outline around every opaque pixel, Tiny Dungeon style."""
    w, h = img.size
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    src = img.load()
    dst = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] > 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] > 0:
                    dst[x, y] = OUTLINE
                    break
    out.alpha_composite(img)
    return out


def make_segment() -> Image.Image:
    """Greyscale body segment (tinted per segment type in game). Faces +x."""
    img = Image.new("RGBA", (18, 18), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.polygon([(6, 5), (9, 0), (12, 5)], fill=(200, 200, 200, 255))      # dorsal spike
    d.ellipse((2, 3, 15, 16), fill=(175, 175, 175, 255))                 # shadow side
    d.ellipse((2, 3, 14, 14), fill=(220, 220, 220, 255))                 # body
    d.ellipse((4, 5, 9, 9), fill=(250, 250, 250, 255))                   # highlight
    for x0, y0 in ((6, 10), (10, 7), (10, 12)):                          # scales
        d.arc((x0 - 2, y0 - 2, x0 + 2, y0 + 2), 20, 160, fill=(150, 150, 150, 255))
    return outline(img)


def make_plate() -> Image.Image:
    """Bone armour plate overlay for armoured segments."""
    img = Image.new("RGBA", (18, 18), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle((5, 6, 12, 12), fill=(232, 226, 200, 255))
    d.line((5, 9, 12, 9), fill=(170, 160, 130, 255))
    d.line((8, 6, 8, 12), fill=(170, 160, 130, 255))
    return outline(img)


def make_head() -> Image.Image:
    """Wyrm head facing +x."""
    img = Image.new("RGBA", (24, 22), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    horn, horn_dark = (236, 226, 196, 255), (176, 160, 128, 255)
    body, dark, light = (138, 40, 64, 255), (92, 24, 44, 255), (186, 72, 92, 255)
    d.polygon([(4, 7), (1, 1), (8, 5)], fill=horn)                       # back horn
    d.polygon([(9, 5), (8, 0), (13, 5)], fill=horn_dark)                 # front horn
    d.ellipse((2, 4, 15, 18), fill=body)                                 # skull
    d.rectangle((11, 8, 21, 15), fill=body)                              # snout
    d.rectangle((11, 13, 21, 16), fill=dark)                             # jaw
    d.ellipse((4, 6, 10, 11), fill=light)                                # brow highlight
    d.point([(13, 16), (16, 16), (19, 16)], fill=(255, 255, 255, 255))   # teeth
    d.rectangle((9, 8, 11, 10), fill=(255, 210, 63, 255))                # eye
    d.point([(11, 9)], fill=(40, 8, 8, 255))                             # pupil
    d.point([(20, 10)], fill=dark)                                       # nostril
    return outline(img)


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    src = Path(sys.argv[1])
    dungeon = src / "kenney_tiny-dungeon" / "Tiles"
    particles = src / "kenney_particle-pack" / "PNG (Transparent)"
    ui = src / "kenney_ui-pack-rpg-expansion" / "PNG"
    fonts = next((src / "kenney_kenney-fonts").rglob("Kenney Future.ttf")).parent
    sounds = {"impact": src / "kenney_impact-sounds" / "Audio", "rpg": src / "kenney_rpg-audio" / "Audio"}

    def dest(rel: str) -> Path:
        p = OUT / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        return p

    for rel, n in TILES.items():
        shutil.copy(dungeon / f"tile_{n:04d}.png", dest(rel))
    for rel, name in PARTICLES.items():
        img = Image.open(particles / f"{name}.png").convert("RGBA")
        img.resize((PARTICLE_SIZE, PARTICLE_SIZE), Image.LANCZOS).save(dest(rel))
    for rel, name in UI.items():
        img = Image.open(ui / name).convert("RGBA")
        img.resize((img.width * UI_SCALE, img.height * UI_SCALE), Image.NEAREST).save(dest(rel))
    for rel, name in FONTS.items():
        shutil.copy(fonts / name, dest(rel))
    for rel, (pack, name) in SOUNDS.items():
        shutil.copy(sounds[pack] / name, dest(rel))

    make_segment().save(dest("wyrm/segment.png"))
    make_plate().save(dest("wyrm/plate.png"))
    make_head().save(dest("wyrm/head.png"))
    print(f"Assets written to {OUT}")


if __name__ == "__main__":
    main()
