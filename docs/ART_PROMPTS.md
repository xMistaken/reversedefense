# Wyrmbreaker art prompts

Generate these in Midjourney, ChatGPT or DALL·E, Leonardo, or any other image
tool, and upload the results. I'll remove the backgrounds, cut and scale each
image, and wire it into the game.

## How to keep everything in one style

1. **Generate the style anchor first:** prompt `H1` (the Ember Canyon dragon
   head). Re-roll until you love it. Every other image should match it.
2. **Reuse the anchor for consistency:**
   - **Midjourney:** add `--sref <URL of your chosen H1 image>` to every other
     prompt, plus the same `--v`/`--style` settings.
   - **ChatGPT or DALL·E:** keep generating in the same chat and start each
     prompt with "Same art style as the dragon head above."
   - **Leonardo and others:** use the chosen image as a style or image
     reference.
3. **Every sprite prompt already ends with this style block**, so you can
   copy prompts as-is:

> hand-painted 2D mobile game art, dark fantasy, highly
> detailed, painterly cel shading, dramatic rim lighting, bold readable
> silhouette, rich saturated colors, premium gacha game quality, single
> subject centered, isolated on a plain solid white background, no text, no
> watermark, no frame, no ground shadow

**Midjourney settings:** `--ar 1:1 --style raw --v 6.1 --s 200` for
creatures, items and heroes. Backgrounds use `--ar 9:16`.

## File rules

- Save as **PNG** (JPG is OK), **1024px or larger**.
- Any plain background is fine; I remove it.
- **Direction matters:** wyrm heads and body segments must **face RIGHT**,
  shown in side profile.
- Name each file exactly as listed (e.g. `head_ember.png`). If a name is
  wrong, tell me which is which.

## How to send them to me

Either works:

- Attach the images in this chat, or
- On GitHub, open the repo, switch to branch `ccr-e65e60ba-slkpod`, go into
  `art_inbox/`, choose **Add file → Upload files**, and commit.

You can send them in batches. Start with **H1–H4 and B1–B4** (the wyrm), since
that's what's on screen most.

---

## 1. Wyrm heads (face RIGHT, side profile, no neck)

The head leads a long armored serpent body. Cut it off just behind the skull.

| File | Prompt |
|---|---|
| `head_ember.png` (H1, style anchor) | Menacing fire dragon head in side profile facing right, long angular skull, jaws wide open showing rows of sharp fangs with a glowing molten-orange throat, narrow glowing amber slit eyes under a heavy brow ridge, swept-back obsidian horns, dark crimson armored scales with cracks of glowing lava, head only cut off cleanly behind the skull, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow |
| `head_frost.png` (H2) | Menacing ice drake head in side profile facing right, long angular skull, open jaws with icy fangs, glowing pale-cyan slit eyes, jagged blue ice crystals growing from the brow and cheeks like a crest, frost-white and steel-blue armored scales, cold mist from the mouth, head only cut off cleanly behind the skull, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow |
| `head_crypt.png` (H3) | Menacing undead bone wyrm skull in side profile facing right, long dragon skull of cracked ivory bone, open jaws with jagged fangs, empty eye sockets burning with sickly green ghost-fire, broken horns, wisps of green spectral smoke, head only cut off cleanly behind the skull, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow |
| `head_abyss.png` (H4) | Menacing sea serpent head in side profile facing right, sleek shark-like armored skull, open jaws with needle teeth, glowing turquoise eyes, tall spined dorsal fin crest and gill frills, deep navy and teal scales with bioluminescent cyan markings, head only cut off cleanly behind the skull, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow |

## 2. Wyrm body segments (face RIGHT, side view)

One segment of the serpent's armored body. The game overlaps about 6 of these
in a row to form the body, so it should be **roughly round and compact**,
**not a whole snake**.

| File | Prompt |
|---|---|
| `body_ember.png` (B1) | Single armored body segment of a fire dragon serpent, side view facing right, compact rounded shape, overlapping dark crimson armor plates with glowing lava cracks, one sharp back-swept black spike on top, pale ridged belly scales on the bottom, isolated game sprite piece, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow |
| `body_frost.png` (B2) | Single armored body segment of an ice drake serpent, side view facing right, compact rounded shape, overlapping frost-white and steel-blue armor plates, one jagged ice-crystal spike on top, pale blue ridged belly scales on the bottom, isolated game sprite piece, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow |
| `body_crypt.png` (B3) | Single body segment of an undead bone serpent, side view facing right, compact rounded shape, ivory vertebra and rib bones wrapped in tattered dark sinew, one bone spike on top, faint green ghost-fire glow between the bones, isolated game sprite piece, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow |
| `body_abyss.png` (B4) | Single armored body segment of a sea serpent, side view facing right, compact rounded shape, overlapping navy and teal scales with glowing cyan bioluminescent lines, one spined fin on top, pale belly scales on the bottom, isolated game sprite piece, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow |

**Optional extras** (I can tint the base segment if you skip these):

| File | Prompt |
|---|---|
| `body_armored.png` | Same body segment as the fire dragon one but covered in heavy riveted iron armor plating, side view facing right, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow |
| `tail_ember.png` (and `_frost`, `_crypt`, `_abyss`) | Tapering tail tip of the same serpent ending in a cluster of sharp spikes, side view facing right, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow |

## 3. Chest orbs (embedded in the body)

| File | Prompt |
|---|---|
| `orb_skill.png` | Glowing magical sapphire orb set in a dark iron cage of claws, swirling arcane blue energy and a bright white star rune inside, game power-up item, front view, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow |
| `orb_hero.png` | Glowing golden orb set in a dark iron cage of claws, molten gold light with a radiant royal crown symbol inside, game reward item, front view, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow |

## 4. Heroes (full body, chibi heroic proportions, facing the viewer)

Style them like premium gacha heroes: big expressive head, heroic pose,
detailed armor, standing, full body visible.

| File | Prompt |
|---|---|
| `hero_warrior.png` | Chibi heroic fantasy warrior, stocky viking berserker with a horned helmet, braided red beard, heavy fur and steel armor, holding a huge double-bladed battle axe, fierce grin, full body standing, three-quarter front view, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow |
| `hero_mage.png` | Chibi heroic fantasy fire mage, young sorceress in deep purple and gold robes with a tall pointed hat, holding a staff topped with a blazing fire crystal, fireball swirling in her other hand, full body standing, three-quarter front view, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow |
| `hero_hunter.png` | Chibi heroic fantasy ranger, elf hunter with a green hood and leather armor, quiver of arrows, drawing an ornate longbow, a loyal wolf companion at her feet, full body standing, three-quarter front view, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow |
| `hero_priest.png` | Chibi heroic fantasy holy priestess, white and gold robes with a radiant halo, holding a golden sun mace and a glowing holy tome, serene but determined, full body standing, three-quarter front view, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow |
| `hero_rogue.png` | Chibi heroic fantasy rogue assassin, hooded with a dark mask over the lower face, black and crimson leather armor, twin curved daggers dripping green poison, crouched ready pose, full body, three-quarter front view, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow |
| `hero_warlock.png` | Chibi heroic fantasy warlock, sinister sorcerer with small demon horns, dark violet robes with skull ornaments, green fel fire swirling around one hand, a tiny imp familiar on his shoulder, full body standing, three-quarter front view, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow |

## 5. Stage backgrounds (portrait 9:16, top-down)

Seen **from directly above**, like a battlefield floor. Keep the **center
fairly empty and flat** (the wyrm crawls over it) and put detail at the edges.
Use `--ar 9:16` and **no white background** for these.

| File | Prompt |
|---|---|
| `bg_ember.png` | Top-down view of a scorched desert canyon floor for a mobile game battlefield, cracked orange sandstone ground, glowing lava fissures and rocks along the left and right edges, open flat area in the middle, warm dramatic lighting, hand-painted 2D mobile game background, no characters, no text --ar 9:16 |
| `bg_frost.png` | Top-down view of a frozen ice temple floor for a mobile game battlefield, polished blue ice tiles with a faint ancient rune circle, frost-covered pillars and snowdrifts along the left and right edges, open flat area in the middle, cold blue lighting, hand-painted 2D mobile game background, no characters, no text --ar 9:16 |
| `bg_crypt.png` | Top-down view of an ancient crypt floor for a mobile game battlefield, dark cracked flagstones, scattered bones, candles and broken tombs along the left and right edges, eerie green ghost-light, open flat area in the middle, hand-painted 2D mobile game background, no characters, no text --ar 9:16 |
| `bg_abyss.png` | Top-down view of a sunken abyssal sea floor for a mobile game battlefield, dark teal sand and sunken ruins, glowing coral and seaweed along the left and right edges, light rays and bubbles, open flat area in the middle, hand-painted 2D mobile game background, no characters, no text --ar 9:16 |
| `bg_menu.png` | Epic key art for a fantasy mobile game title screen: a colossal armored dragon-serpent coiling through storm clouds above a small band of chibi heroes (warrior, mage, ranger, priestess, rogue, warlock) standing on a castle wall, dramatic lighting, hand-painted, space at the top for a logo, no text --ar 9:16 |

## 6. Defenses and party vehicle

| File | Prompt |
|---|---|
| `wall_rampart.png` | Front view of a fortified stone castle rampart wall segment with crenellations and a reinforced wooden gate in the middle, battle-worn, wide horizontal game sprite, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow --ar 4:1 |
| `wall_ring.png` | Top-down view of a circular ritual stone ring wall, a ring of carved runestones glowing teal, empty center, game sprite, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow |
| `war_wagon.png` | Front view of a fantasy war wagon cart with spiked wooden sides, iron-banded wheels and a banner, empty flat platform on top for heroes to stand on, game sprite, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow --ar 3:2 |

## 7. Projectiles

| File | Prompt |
|---|---|
| `shot_axe.png` | Single spinning throwing axe, steel double blade with a wooden handle, game projectile sprite, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow |
| `shot_dagger.png` | Single throwing dagger pointing straight up, gleaming steel blade, crimson grip, game projectile sprite, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow |
| `shot_arrow.png` | Single arrow pointing straight up, steel broadhead and green fletching, game projectile sprite, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow |
| `shot_fireball.png` | Blazing fireball, swirling orange and yellow flames with a bright core, game projectile sprite, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow |
| `shot_holy.png` | Radiant holy light bolt, golden-white star of light, game projectile sprite, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow |
| `shot_shadow.png` | Swirling shadow bolt of dark violet energy with green sparks, game projectile sprite, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow |

## 8. Optional

- **UI:** AI is poor at clean, stretchable buttons and frames. Unless you want
  to try, I'll use Ravenmore's hand-painted *Fantasy UI Elements* (free, credit
  required), which match this style.
- **App icon** `app_icon.png`: The fire dragon head roaring toward the viewer,
  framed in a gold circular border, mobile app icon, hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouette, rich saturated colors, premium gacha game quality, single subject centered, isolated on a plain solid white background, no text, no watermark, no frame, no ground shadow.
- **Skill icons:** later, if you want custom icons for the 34 skills; I'll send
  a separate list.

---

**Licensing note:** check your image tool's terms for commercial use. The
paid tiers of Midjourney, ChatGPT and Leonardo grant you usage rights to what
you generate.
