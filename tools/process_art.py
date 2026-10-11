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
BODY_BLEND = 0.22   # share of the body art cross-faded to make it loop seamlessly
BODY_PAD = 0.08     # wrap-around padding on each side (keep in sync with wyrm.gd)


def remove_white(img: Image.Image, strict_holes: bool = False) -> np.ndarray:
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
        hole = means[i] > 246 and stds[i] < 9
        if strict_holes:  # no white art on these sheets, so any enclosed pale gap goes
            hole = means[i] > 232 and stds[i] < 16
        if i + 1 not in border and sizes[i] > 60 and hole:
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


def clean(rgba: np.ndarray) -> np.ndarray:
    """Remove stray pixels: near-invisible noise and small blobs that aren't
    part of the main piece (JPEG specks, embers, slivers of neighbours)."""
    out = rgba.copy()
    alpha = out[..., 3]
    alpha[alpha < 0.12] = 0.0
    solid = alpha > 0.0
    labels, n = ndimage.label(ndimage.binary_dilation(solid, iterations=2))
    if n > 1:
        sizes = ndimage.sum(solid, labels, index=np.arange(1, n + 1))
        keep_ids = np.nonzero(sizes >= max(sizes.max() * 0.03, 400))[0] + 1
        alpha[~np.isin(labels, keep_ids)] = 0.0
    out[..., 3] = alpha
    return out


def save(rgba: np.ndarray, box, path: Path, width: int = 0, height: int = 0, crop_x=(0.0, 1.0)) -> None:
    x0, y0, x1, y1 = box
    pad = 6
    x0, y0 = max(0, x0 - pad), max(0, y0 - pad)
    x1, y1 = min(rgba.shape[1], x1 + pad), min(rgba.shape[0], y1 + pad)
    cw = x1 - x0
    x0, x1 = x0 + int(cw * crop_x[0]), x0 + int(cw * crop_x[1])
    piece = clean(rgba[y0:y1, x0:x1])
    # Trim to what's left after cleaning.
    ys, xs = np.nonzero(piece[..., 3] > 0)
    piece = piece[max(0, ys.min() - 2):ys.max() + 3, max(0, xs.min() - 2):xs.max() + 3]
    img = Image.fromarray((piece * 255).astype(np.uint8), "RGBA")
    if width:
        img = img.resize((width, round(img.height * width / img.width)), Image.LANCZOS)
    elif height:
        img = img.resize((round(img.width * height / img.height), height), Image.LANCZOS)
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)
    print(f"  {path.relative_to(ROOT)}  {img.size}")


def fade_right(path: Path, share: float = 0.2) -> None:
    """Fade the right end of an image to transparent (tail joins the body)."""
    a = np.asarray(Image.open(path).convert("RGBA")).astype(np.float32)
    w = a.shape[1]
    k = int(w * share)
    ramp = np.linspace(1.0, 0.0, k, dtype=np.float32) ** 1.5
    a[:, w - k:, 3] *= ramp[None, :]
    Image.fromarray(a.astype(np.uint8), "RGBA").save(path)


def make_seamless(path: Path) -> None:
    """Cross-fade the ends of a body strip so it tiles horizontally, then pad
    both sides with wrapped columns so slices near the ends read real pixels."""
    a = np.asarray(Image.open(path).convert("RGBA")).astype(np.float32)
    h, w, _ = a.shape
    k = int(w * BODY_BLEND)
    period = w - k
    out = a[:, :period].copy()
    ramp = (np.arange(k, dtype=np.float32) / k)[None, :, None]
    # Premultiplied blend of the right end into the left end.
    left, right = a[:, :k], a[:, period:]
    lp = left[..., :3] * left[..., 3:] / 255.0
    rp = right[..., :3] * right[..., 3:] / 255.0
    alpha = right[..., 3:] * (1 - ramp) + left[..., 3:] * ramp
    rgb = (rp * (1 - ramp) + lp * ramp) / np.maximum(alpha / 255.0, 1e-3)
    out[:, :k, :3] = np.clip(rgb, 0, 255)
    out[:, :k, 3:] = alpha
    pad = int(period * BODY_PAD)
    out = np.concatenate([out[:, period - pad:], out, out[:, :pad]], axis=1)
    Image.fromarray(out.astype(np.uint8), "RGBA").save(path)
    print(f"  seamless {path.relative_to(ROOT)}  period {period}px, pad {pad}px")


def socket_window(path: Path, aspect: float = 1.35) -> None:
    """Crop a body-with-socket piece down to a window centred on the socket."""
    a = np.asarray(Image.open(path).convert("RGBA")).astype(np.float32)
    h, w, _ = a.shape
    # The socket is the biggest round, solid dark blob.
    lum = a[..., :3].mean(axis=2)
    labels, n = ndimage.label((lum < 70) & (a[..., 3] > 128))
    best, cx = 0.0, w // 2
    for i, sl in enumerate(ndimage.find_objects(labels)):
        bh, bw = sl[0].stop - sl[0].start, sl[1].stop - sl[1].start
        area = float((labels[sl] == i + 1).sum())
        if bh < h * 0.15 or not 0.7 < bw / bh < 1.4 or area / (bh * bw) < 0.6:
            continue
        if area > best:
            best, cx = area, (sl[1].start + sl[1].stop) // 2
    half = int(h * aspect / 2)
    x0 = min(max(0, cx - half), max(0, w - 2 * half))
    Image.fromarray(a[:, x0:x0 + 2 * half].astype(np.uint8), "RGBA").save(path)
    print(f"  socket {path.relative_to(ROOT)}  centre {cx / w:.2f}")


def sheet(name: str, names: list, folder: str, merge: int = 18, **kw) -> None:
    src = next(INBOX.glob(name + ".*"))
    rgba = remove_white(Image.open(src), strict_holes=folder == "wyrm")
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
    for t in THEMES:
        make_seamless(OUT / "wyrm" / f"body_{t}.png")
    # Collars: rounded armor rings over the seams between sections. Trim the
    # thin side rim on the right.
    sheet("sheet2f_rings", [f"collar_{t}" for t in THEMES], "wyrm", merge=10, height=300, crop_x=(0.0, 0.88))
    # Chest sections: a body log with an empty socket for the orb. Cut off the
    # meat caps, then keep a window around the socket.
    sheet("sheet2d_sockets", [f"socket_{t}" for t in THEMES], "wyrm", merge=10, height=300, crop_x=(0.06, 0.94))
    for t in THEMES:
        socket_window(OUT / "wyrm" / f"socket_{t}.png")
    # Tails: drop the meat cap on the thick end, then fade the join into the body.
    sheet("sheet2e_tails", [f"tail_{t}" for t in THEMES], "wyrm", merge=10, height=260, crop_x=(0.0, 0.95))
    for t in THEMES:
        fade_right(OUT / "wyrm" / f"tail_{t}.png", 0.1)
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
