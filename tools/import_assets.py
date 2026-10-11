#!/usr/bin/env python3
"""Copy the Kenney (CC0) effects and sounds the game uses into assets/.
(The cartoon art is original SVG; see tools/hd_art.py and assets/hd/.)

Usage:
    python3 tools/import_assets.py /path/to/kenney_downloads

The download folder must contain these packs unzipped (from kenney.nl):
    kenney_particle-pack/  kenney_rpg-audio/  kenney_impact-sounds/

Requires Pillow. Re-running overwrites the same files.
"""
import shutil
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets"



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


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    src = Path(sys.argv[1])
    particles = src / "kenney_particle-pack" / "PNG (Transparent)"
    sounds = {"impact": src / "kenney_impact-sounds" / "Audio", "rpg": src / "kenney_rpg-audio" / "Audio"}

    def dest(rel: str) -> Path:
        p = OUT / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        return p

    for rel, name in PARTICLES.items():
        img = Image.open(particles / f"{name}.png").convert("RGBA")
        img.resize((PARTICLE_SIZE, PARTICLE_SIZE), Image.LANCZOS).save(dest(rel))
    for rel, (pack, name) in SOUNDS.items():
        shutil.copy(sounds[pack] / name, dest(rel))

    print(f"Assets written to {OUT}")


if __name__ == "__main__":
    main()
