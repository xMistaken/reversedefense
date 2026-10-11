#!/usr/bin/env python3
"""Turn the generated artwork in art_inbox/ into game sprites in assets/art/.

- Removes the plain white background. Soft glows (fire, frost mist, ghost
  fire) stay semi-transparent ("colour to alpha" on the background region).
- Finds each piece on a sprite sheet, crops it, scales it and saves it with
  a game name.

Usage:  python3 tools/process_art.py        (needs Pillow, numpy, scipy)
"""
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parent.parent
INBOX = ROOT / "art_inbox"
OUT = ROOT / "assets" / "art"

THEMES = ["ember", "frost", "crypt", "abyss"]  # sheet order: TL, TR, BL, BR


def remove_white(img: Image.Image) -> np.ndarray:
    """RGBA float array (0-1) with the white background made transparent."""
    rgb = np.asarray(img.convert("RGB")).astype(np.float32)
    lo = rgb.min(axis=2)
    sat = rgb.max(axis=2) - lo
    light = (lo > 190) & (sat < 60)
    labels, n = ndimage.label(light)
    h, w = lo.shape
    border = set(np.unique(np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]])))
    border.discard(0)
    bg = np.isin(labels, list(border))
    # Enclosed holes (inside a bow, between ribs or teeth) are background
    # too when they're flat, near-pure white. Shaded white art such as robes
    # varies more and is kept.
    idx = np.arange(1, n + 1)
    sizes = ndimage.sum(np.ones_like(lo), labels, index=idx)
    means = ndimage.mean(lo, labels, index=idx)
    stds = ndimage.standard_deviation(lo, labels, index=idx)
    for i in range(n):
        if i + 1 not in border and sizes[i] > 60 and means[i] > 246 and stds[i] < 9:
            bg |= labels == i + 1

    alpha = np.ones((h, w), np.float32)
    # Colour-to-alpha against white inside the background region.
    a_bg = np.clip((255.0 - lo - 10.0) / 235.0, 0.0, 1.0)
    alpha[bg] = a_bg[bg]
    # Soften the 1px seam where background meets art.
    edge = ndimage.binary_dilation(bg) & ~bg
    alpha[edge] = np.minimum(alpha[edge], 0.85)
    out = np.zeros((h, w, 4), np.float32)
    safe = np.maximum(alpha, 1e-3)[..., None]
    unmixed = (rgb / 255.0 - (1.0 - alpha[..., None])) / safe
    out[..., :3] = np.where(bg[..., None], np.clip(unmixed, 0, 1), rgb / 255.0)
    out[..., 3] = alpha
    return out


def pieces(rgba: np.ndarray, merge: int = 18, min_frac: float = 0.004) -> list:
    """Bounding boxes (x0, y0, x1, y1) of separate pieces, reading order."""
    solid = rgba[..., 3] > 0.08
    grown = ndimage.binary_dilation(solid, iterations=merge)
    labels, n = ndimage.label(grown)
    boxes = []
    h, w = solid.shape
    for sl in ndimage.find_objects(labels):
        ys, xs = sl
        if (ys.stop - ys.start) * (xs.stop - xs.start) < h * w * min_frac:
            continue
        sub = solid[ys, xs]
        yy, xx = np.nonzero(sub)
        boxes.append((xs.start + xx.min(), ys.start + yy.min(), xs.start + xx.max() + 1, ys.start + yy.max() + 1))
    # Reading order: group into rows by vertical centre, then left to right.
    boxes.sort(key=lambda b: (b[1] + b[3]) / 2)
    rows, row = [], []
    for b in boxes:
        if row and (b[1] + b[3]) / 2 - (row[-1][1] + row[-1][3]) / 2 > h * 0.18:
            rows.append(row)
            row = []
        row.append(b)
    rows.append(row)
    return [b for r in rows for b in sorted(r, key=lambda b: b[0])]


def save(rgba: np.ndarray, box, path: Path, width: int = 0, height: int = 0, crop_x=(0.0, 1.0)) -> None:
    x0, y0, x1, y1 = box
    pad = 6
    x0, y0 = max(0, x0 - pad), max(0, y0 - pad)
    x1, y1 = min(rgba.shape[1], x1 + pad), min(rgba.shape[0], y1 + pad)
    cw = x1 - x0
    x0, x1 = x0 + int(cw * crop_x[0]), x0 + int(cw * crop_x[1])
    img = Image.fromarray((rgba[y0:y1, x0:x1] * 255).astype(np.uint8), "RGBA")
    if width:
        img = img.resize((width, round(img.height * width / img.width)), Image.LANCZOS)
    elif height:
        img = img.resize((round(img.width * height / img.height), height), Image.LANCZOS)
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)
    print(f"  {path.relative_to(ROOT)}  {img.size}")


def sheet(name: str, names: list, folder: str, merge: int = 18, **kw) -> None:
    src = next(INBOX.glob(name + ".*"))
    rgba = remove_white(Image.open(src))
    boxes = pieces(rgba, merge)
    print(f"{src.name}: {len(boxes)} pieces")
    if len(boxes) != len(names):
        raise SystemExit(f"Expected {len(names)} pieces in {src.name}, found {len(boxes)}")
    for box, n in zip(boxes, names):
        opts = kw.get("per", {}).get(n, {})
        save(rgba, box, OUT / folder / f"{n}.png", **{**{k: v for k, v in kw.items() if k != "per"}, **opts})


def main() -> None:
    sheet("sheet1_heads", [f"head_{t}" for t in THEMES], "wyrm", merge=10, width=520)
    # Bodies: drop the hollow cut end on the right so slices tile cleanly.
    sheet("sheet2_bodies", [f"body_{t}" for t in THEMES], "wyrm", merge=10, width=900, crop_x=(0.02, 0.86))
    sheet("sheet2b_tails", [f"tail_{t}" for t in THEMES], "wyrm", merge=10, width=520)
    sheet("sheet3_heroes", ["warrior", "mage", "hunter", "priest", "rogue", "warlock"], "heroes", merge=8, height=360)
    sheet("sheet4_items", ["orb_skill", "orb_hero", "shot_axe", "shot_dagger", "shot_arrow", "shot_fire", "shot_holy", "shot_shadow"],
          "items", merge=8, height=240)
    sheet("sheet5_defenses", ["wall", "wagon", "ring"], "defense", merge=6,
          per={"wall": {"width": 1080}, "wagon": {"width": 460}, "ring": {"width": 560}})
    for t in THEMES + ["menu"]:
        src = next(INBOX.glob(f"bg_{t}.*"))
        dst = OUT / "bg" / f"{t}.jpg"
        dst.parent.mkdir(parents=True, exist_ok=True)
        Image.open(src).convert("RGB").resize((1080, 1935), Image.LANCZOS).save(dst, quality=90)
        print(f"  {dst.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
