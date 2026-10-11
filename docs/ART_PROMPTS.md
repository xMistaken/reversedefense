# Wyrmbreaker art prompts (Google Gemini edition)

Gemini makes **one image per message**, so each prompt below asks for **one
image that contains several pieces in a grid** (a sprite sheet). I'll cut the
sheets apart, remove the backgrounds and put everything into the game.

## How to do it

1. Open **one** Gemini chat and keep using it for every prompt, so the style
   stays consistent.
2. Send **one prompt per message** and wait for the image before sending the
   next.
3. If a result is bad, reply **"Try again, same style"** or describe what to
   fix (e.g. "make the heads face right").
4. Download each image (open it, then download, at full size) and name it as
   shown, e.g. `sheet1_heads.png`.
5. Send them to me: attach them in this chat, or upload them to the
   `art_inbox/` folder on branch `ccr-e65e60ba-slkpod` on GitHub
   (**Add file → Upload files**).

Start with prompts 1 and 2 (the wyrm). They matter most. Send them to me
first if you like, and I'll check they work before you do the rest.

---

## Prompt 1: Wyrm heads → `sheet1_heads.png`

```
Create one image: a 2 by 2 sprite sheet of four menacing dragon-serpent heads for a mobile game, each head in side profile facing RIGHT, with the head cut off cleanly just behind the skull (no neck, no body). Each head has a long angular skull, jaws wide open with rows of sharp fangs, narrow glowing slit eyes under a heavy brow ridge.
Top left: fire dragon, dark crimson armored scales with glowing lava cracks, swept-back black horns, molten orange glowing throat, amber eyes.
Top right: ice drake, frost-white and steel-blue scales, jagged blue ice crystals growing from the brow like a crest, glowing pale cyan eyes, cold mist.
Bottom left: undead bone wyrm skull, cracked ivory bone, broken horns, empty eye sockets burning with green ghost-fire.
Bottom right: sea serpent, sleek shark-like navy and teal armored head, tall spined fin crest, needle teeth, glowing turquoise eyes and bioluminescent cyan markings.
Style: hand-painted 2D mobile game art, dark fantasy, highly detailed, painterly cel shading, dramatic rim lighting, bold readable silhouettes, premium gacha game quality. Each head fully separated with lots of empty space between them, on a plain solid white background (not transparent, no checkerboard), no text, no labels, no borders, no shadows on the background.
```

## Prompt 2: Wyrm body segments → `sheet2_bodies.png`

```
Same art style as the heads above. Create one image: a 2 by 2 sprite sheet of four single body segments for the same four serpents, each segment seen from the side facing RIGHT. Each segment is ONE compact, roughly round chunk of armored body (not a whole snake), about as tall as it is wide, with one sharp back-swept spike on top and pale ridged belly scales on the bottom, designed to overlap in a chain.
Top left: fire dragon segment, dark crimson armor plates with glowing lava cracks, black spike.
Top right: ice drake segment, frost-white and steel-blue plates, ice-crystal spike.
Bottom left: bone wyrm segment, ivory vertebra and ribs wrapped in dark sinew, bone spike, faint green ghost-fire between the bones.
Bottom right: sea serpent segment, navy and teal scales with glowing cyan lines, spined fin on top.
Each segment fully separated with lots of empty space between them, plain solid white background (not transparent, no checkerboard), no text, no labels, no borders.
```

## Prompt 3: Heroes → `sheet3_heroes.png`

```
Same art style. Create one image: a 3 by 2 sprite sheet of six chibi heroic fantasy heroes for a mobile game, big expressive heads, detailed armor, full body standing, three-quarter front view, premium gacha game quality.
Top row, left to right: 1) viking warrior with horned helmet, braided red beard, fur and steel armor, huge double-bladed battle axe. 2) fire mage, young sorceress in purple and gold robes with tall pointed hat, staff with a blazing fire crystal. 3) elf ranger in a green hood and leather armor drawing an ornate longbow, quiver on her back.
Bottom row, left to right: 4) holy priestess in white and gold robes with a radiant halo, golden sun mace and glowing holy book. 5) hooded rogue assassin with a dark mask, black and crimson leather armor, twin curved daggers dripping green poison. 6) warlock with small demon horns, dark violet robes with skull ornaments, green fel fire swirling around one hand.
Each hero fully separated with lots of empty space between them, plain solid white background (not transparent, no checkerboard), no text, no labels, no borders, no ground shadows.
```

## Prompt 4: Orbs and projectiles → `sheet4_items.png`

```
Same art style. Create one image: a 4 by 2 sprite sheet of eight game items, each centered in its own cell.
Top row, left to right: 1) glowing sapphire orb in a dark iron cage of claws with a bright white star rune inside. 2) glowing golden orb in a dark iron cage of claws with a radiant crown symbol inside. 3) a single spinning steel throwing axe. 4) a single steel throwing dagger pointing straight up.
Bottom row, left to right: 5) a single arrow pointing straight up with green fletching. 6) a blazing fireball. 7) a radiant golden-white holy light bolt shaped like a star. 8) a swirling dark violet shadow bolt with green sparks.
Each item fully separated with lots of empty space, plain solid white background (not transparent, no checkerboard), no text, no labels, no borders.
```

## Prompt 5: Defenses → `sheet5_defenses.png`

```
Same art style. Create one image with three game sprites stacked vertically with lots of empty space between them:
Top: a long horizontal fortified stone castle rampart wall, front view, crenellations and a reinforced wooden gate in the middle, battle-worn, spanning the full width of the image.
Middle: a fantasy war wagon cart, front view, spiked wooden sides, iron-banded wheels and a small banner, flat empty platform on top.
Bottom: a circular ring of carved runestones glowing teal, seen from directly above, empty center.
Plain solid white background (not transparent, no checkerboard), no text, no labels, no borders.
```

## Prompts 6 to 10: Backgrounds (one per message, portrait/vertical)

These are full scenes, so no white background. If Gemini makes them square,
reply "Make it tall portrait, 9:16."

**6 → `bg_ember.png`**
```
Same art style. Create one tall portrait (9:16) mobile game background: a top-down view looking straight down at a scorched desert canyon floor used as a battlefield. Cracked orange sandstone ground, glowing lava fissures, rocks and canyon cliffs along the left and right edges, a wide open flat area in the middle. Warm dramatic lighting, hand-painted, no characters, no creatures, no text.
```

**7 → `bg_frost.png`**
```
Same art style. Create one tall portrait (9:16) mobile game background: a top-down view looking straight down at a frozen ice temple floor used as a battlefield. Polished blue ice tiles with a faint ancient rune circle, frosted pillars and snowdrifts along the left and right edges, a wide open flat area in the middle. Cold blue lighting, hand-painted, no characters, no creatures, no text.
```

**8 → `bg_crypt.png`**
```
Same art style. Create one tall portrait (9:16) mobile game background: a top-down view looking straight down at an ancient crypt floor used as a battlefield. Dark cracked flagstones, scattered bones, candles and broken tombs along the left and right edges, eerie green ghost-light, a wide open flat area in the middle. Hand-painted, no characters, no creatures, no text.
```

**9 → `bg_abyss.png`**
```
Same art style. Create one tall portrait (9:16) mobile game background: a top-down view looking straight down at a sunken abyssal sea floor used as a battlefield. Dark teal sand, sunken ruins, glowing coral and seaweed along the left and right edges, light rays and bubbles, a wide open flat area in the middle. Hand-painted, no characters, no creatures, no text.
```

**10 → `bg_menu.png`**
```
Same art style. Create one tall portrait (9:16) title-screen illustration for a fantasy mobile game: a colossal armored fire dragon-serpent coiling through storm clouds, roaring down at a small band of six chibi heroes (viking warrior, fire mage, elf ranger, holy priestess, hooded rogue, horned warlock) standing on a castle wall. Epic dramatic lighting, hand-painted, empty sky space at the top for a logo, no text.
```

---

## Notes

- **If Gemini refuses or stops:** shorten the prompt by removing one or two
  items, or split a 2 by 2 sheet into two 1 by 2 sheets. Tell me what you
  changed.
- **If pieces touch or overlap:** reply "Spread them out more, with lots of
  white space between each one."
- **UI:** I'll use Ravenmore's free hand-painted fantasy UI, so you don't need
  to generate buttons or frames.
- **Licensing:** check Google's current Gemini terms for commercial use of
  generated images before publishing. Gemini images also carry an invisible
  SynthID watermark, which doesn't affect the game.
