# Wyrmbreaker art prompts (Google Gemini edition)

Gemini makes **one image per message**, so each prompt below asks for **one
image that contains several pieces in a grid** (a sprite sheet). I'll cut the
sheets apart, remove the backgrounds and put everything into the game.

## Rules these prompts follow

- Each prompt says exactly what shape to draw and lists what must not appear
  (faces, creatures, text). Gemini copies the subject from earlier images if
  you only say "same style".
- So "same style" means the painting style only, never the subject.

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

Start with prompts 1, 2 and 2b (the wyrm). They matter most. Send them to me
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
Use the same painting style, colors and rendering as the dragon heads above, but this image must contain NO heads, NO faces, NO eyes, NO mouths, NO teeth and NO skulls.
Create one image: a 2 by 2 sprite sheet of four short, straight pieces of serpent BODY, as if cut from the middle of each serpent's long body. Each piece is a thick horizontal cylinder lying on its side, like a short log of armor, seen from the side, roughly as tall as it is wide. Both the left end and the right end are cut off straight and plain: no head, no tail, no limbs. A row of overlapping armor scales and back-swept spikes runs along the top edge, and pale segmented belly plates run along the bottom edge.
Top left: fire dragon body piece, dark crimson rock-like scales with glowing orange lava cracks, black spikes on top.
Top right: ice drake body piece, frost-white and steel-blue scales, jagged blue ice-crystal spikes on top.
Bottom left: undead body piece, a section of spine: ivory vertebrae and curved ribs wrapped in dark sinew, faint green ghost-fire between the bones, no skull.
Bottom right: sea serpent body piece, navy and teal scales with glowing cyan bioluminescent lines, a spined fin along the top.
Each piece fully separated with lots of empty space between them, plain solid white background (not transparent, no checkerboard), no text, no labels, no borders, no shadows.
```

If any piece still has a face, reply: "Remove every face, eye and mouth. These
are plain body pieces with both ends cut flat, like logs."

## Prompt 2b: Wyrm tails → `sheet2b_tails.png`

```
Use the same painting style, colors and rendering as the serpent body pieces above. This image must contain NO heads, NO faces, NO eyes, NO mouths, NO teeth and NO skulls.
Create one image: a 2 by 2 sprite sheet of four serpent TAILS, each seen from the side and pointing LEFT: the thick end is on the right and is cut off straight and plain (where it joins the body), and the tail tapers to a sharp point on the left. Each tail is fairly short, about twice as long as it is tall, with gently curved armor scales along the top and pale belly plates along the bottom.
Top left: fire dragon tail, dark crimson rock-like scales with glowing orange lava cracks, ending in a cluster of black spikes.
Top right: ice drake tail, frost-white and steel-blue scales, ending in jagged blue ice crystals.
Bottom left: undead tail, a tapering chain of ivory vertebrae wrapped in dark sinew with faint green ghost-fire, ending in a bone spike.
Bottom right: sea serpent tail, navy and teal scales with glowing cyan lines, ending in a spined fin fluke.
Each tail fully separated with lots of empty space between them, plain solid white background (not transparent, no checkerboard), no text, no labels, no borders, no shadows.
```

## Prompt 3: Heroes → `sheet3_heroes.png`

```
Same art style. Use the same painting style and rendering as before, but these are people, not dragons: no dragons, no creatures, no background scenery. Create one image: a 3 by 2 sprite sheet of six chibi heroic fantasy heroes for a mobile game, big expressive heads, detailed armor, full body standing, three-quarter front view, premium gacha game quality.
Top row, left to right: 1) viking warrior with horned helmet, braided red beard, fur and steel armor, huge double-bladed battle axe. 2) fire mage, young sorceress in purple and gold robes with tall pointed hat, staff with a blazing fire crystal. 3) elf ranger in a green hood and leather armor drawing an ornate longbow, quiver on her back.
Bottom row, left to right: 4) holy priestess in white and gold robes with a radiant halo, golden sun mace and glowing holy book. 5) hooded rogue assassin with a dark mask, black and crimson leather armor, twin curved daggers dripping green poison. 6) warlock with small demon horns, dark violet robes with skull ornaments, green fel fire swirling around one hand.
Each hero fully separated with lots of empty space between them, plain solid white background (not transparent, no checkerboard), no text, no labels, no borders, no ground shadows.
```

## Prompt 4: Orbs and projectiles → `sheet4_items.png`

```
Use the same painting style and rendering as before, but draw only objects: no creatures, no faces, no hands holding them. Create one image: a 4 by 2 sprite sheet of eight separate game items, each one alone and centered in its own cell.
Top row, left to right: 1) glowing sapphire orb in a dark iron cage of claws with a bright white star rune inside. 2) glowing golden orb in a dark iron cage of claws with a radiant crown symbol inside. 3) a single spinning steel throwing axe. 4) a single steel throwing dagger pointing straight up.
Bottom row, left to right: 5) a single arrow pointing straight up with green fletching. 6) a blazing fireball. 7) a radiant golden-white holy light bolt shaped like a star. 8) a swirling dark violet shadow bolt with green sparks.
Each item fully separated with lots of empty space, plain solid white background (not transparent, no checkerboard), no text, no labels, no borders.
```

## Prompt 5: Defenses → `sheet5_defenses.png`

```
Use the same painting style and rendering as before, but draw only buildings and objects: no creatures, no people, no dragons. Create one image with three separate game sprites stacked vertically with lots of empty space between them:
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
Use the same painting style as before. Create one tall portrait (9:16) mobile game background with NO creatures, NO dragons, NO people and NO text: a top-down view looking straight down at a scorched desert canyon floor used as a battlefield. Cracked orange sandstone ground, glowing lava fissures, rocks and canyon cliffs along the left and right edges, a wide open flat area in the middle. Warm dramatic lighting, hand-painted, no characters, no creatures, no text.
```

**7 → `bg_frost.png`**
```
Use the same painting style as before. Create one tall portrait (9:16) mobile game background with NO creatures, NO dragons, NO people and NO text: a top-down view looking straight down at a frozen ice temple floor used as a battlefield. Polished blue ice tiles with a faint ancient rune circle, frosted pillars and snowdrifts along the left and right edges, a wide open flat area in the middle. Cold blue lighting, hand-painted, no characters, no creatures, no text.
```

**8 → `bg_crypt.png`**
```
Use the same painting style as before. Create one tall portrait (9:16) mobile game background with NO creatures, NO dragons, NO people and NO text: a top-down view looking straight down at an ancient crypt floor used as a battlefield. Dark cracked flagstones, scattered bones, candles and broken tombs along the left and right edges, eerie green ghost-light, a wide open flat area in the middle. Hand-painted, no characters, no creatures, no text.
```

**9 → `bg_abyss.png`**
```
Use the same painting style as before. Create one tall portrait (9:16) mobile game background with NO creatures, NO dragons, NO people and NO text: a top-down view looking straight down at a sunken abyssal sea floor used as a battlefield. Dark teal sand, sunken ruins, glowing coral and seaweed along the left and right edges, light rays and bubbles, a wide open flat area in the middle. Hand-painted, no characters, no creatures, no text.
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
