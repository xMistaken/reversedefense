# Wyrmbreaker — Game Design (Draft v0.1)

> Working title. An Android roguelike "chain" defense game in the style of
> *Dragon Fever TD* / *Cell Survivor*, reskinned as a classic fantasy RPG.
> Classes and tone are inspired by MMO-style fantasy (World of Warcraft), but
> all names, lore and art are original.

Items marked **[ASSUMED]** are defaults that haven't been confirmed yet.
All numbers live in `scripts/data.gd`, `scripts/meta.gd` and
`scripts/stage_config.gd`.

---

## 1. Pitch

A huge segmented monster (a wyrm) crawls along a winding track toward your
party. You aim, and your party fires on it, chewing through the wyrm one
segment at a time. Some segments carry **chests**. Breaking a chest lets you
recruit a new hero or learn a new skill, so every run builds a different party.
Destroy every segment before the wyrm reaches the end of the track.

## 2. Pillars

1. **Shoot the chain.** Reading the wyrm and choosing which segments to break
   first is the core skill.
2. **RNG build, player choice.** Every reward is a pick of 3 random options,
   with limited refreshes.
3. **A party, not a tower.** Each hero you recruit adds a new attack pattern
   to your volley.

## 3. Core loop

```
Choose starting hero ─► Stage starts ─► Wyrm advances along the track
        ▲                                   │
        │                     Shoot segments│ ◄── aim / steer
        │                                   ▼
   Meta upgrades        Break chest segment ─► Pick 1 of 3 (hero or skill)
        ▲                                   │
        │                                   ▼
   Run ends ◄── Wyrm reaches end (lose) / Every segment destroyed (win)
```

## 4. Stage types

| Stage | Party position | Player input |
|---|---|---|
| **Ritual Circle** (odd stages) | Fixed at the center of the screen | Drag to aim; the party auto-fires along the aim direction |
| **War Wagon** (even stages) | Wagon at the bottom of the screen | Drag to slide left and right; the party auto-fires upward |

The screen is portrait (1080×1920 reference resolution).

### Wyrm movement varies per stage, and the path is hidden

You never see the track; you only see the wyrm and the glowing exit portal
it's heading for. Each stage picks a path shape and a speed pattern from its
stage number, so a stage plays the same every time and can be learned when
farming.

- **Ritual Circle paths:** spiral, wobbling spiral, square spiral, drifting
  loops. Each enters from a random side and turns clockwise or
  counter-clockwise.
- **War Wagon paths:** serpentine rows, sweeping S-curves, diagonal zig-zag.
  Vertical columns were tried and cut: with straight-up fire, a column can
  only be hit from below.
- **Speed patterns:** *steady*; *pulse*, which slithers faster and slower;
  and *surge*, which crawls, then lunges.
- Speed is scaled by path length, so every shape takes about as long to
  cross.

## 5. The Wyrm

- An indestructible **head** leads a chain of body **segments** along a path
  (`Path2D`), with fixed spacing between them. The head can't be targeted,
  and projectiles pass through it.
- Each body segment has its own HP. The **rearmost segment drives** the chain
  forward, and the chain always stays connected: when a segment is
  destroyed, everything ahead of it, including the head, **slides back** to
  close the gap. Destroying the segment right behind the head pulls the head
  back one segment, so killing segments at the front buys the most time.
- The wyrm rushes in quickly at the start of a stage, then crawls at a steady
  speed. Skills can slow it, and the Priest can shove it back.
- **Win condition:** destroy **every** body segment.
- **Lose condition:** the head reaches the end of the track.

### Segment types

| Segment | Behavior |
|---|---|
| Flesh | Basic segment |
| Bone-plated | Armored, so it takes reduced damage |
| Mending | Heals neighboring segments over time |
| Brood | Spawns small adds when broken |
| **Hero Chest** | Breaking it opens a hero pick |
| **Skill Chest** | Breaking it opens a skill pick |
| Gilded (rare) | Drops bonus gold and +1 refresh **[ASSUMED]** |

## 6. Chests and rewards

- **Starting party:** one hero, chosen before the run.
- **Hero Chest:** shows **3 random heroes you don't already have**, and you
  pick one. There are no duplicates. Once all heroes are recruited, hero
  chests roll skills instead.
- **Skill Chest:** about every 3rd segment. It shows **3 random skills**, and
  you pick one. Each offer rolls a **rarity**:

  | Rarity | Chance | Ranks gained |
  |---|---|---|
  | Common | 64% | +1 |
  | Rare | 26% | +2 |
  | Epic | 10% | +3 |
  | **Legendary** | Always offered once unlocked | One-off, huge effect |

- **Legendary skills:** each hero has one. It becomes available once that
  hero's own skills total 6 ranks, and from then on it takes a slot in every
  skill chest until you take it.
- **Refreshes:** a shared pool for the whole run that rerolls the 3 options on
  either chest type. You start with 2, plus the Insight upgrade, and Gilded
  segments give more.
- The game pauses while a pick is open.

### The "crazy damage" feel

- Floating damage numbers on every hit, with crits bigger, yellow and marked
  "!"
- Big-number formatting (K, M, B, T and beyond)
- Splash rings, crit flashes and pop effects on kills
- The end screen shows total damage, biggest hit and skills learned

## 7. Heroes (starting roster of 6)

Each hero adds a basic attack to the party volley and has 4 skills plus a
legendary. There are also 4 party-wide skills, 34 skills in all.

| Class | Basic attack | Skills | Legendary |
|---|---|---|---|
| **Warrior** | Thrown axes that pierce 2 segments | Whirling Axes, Shield Ricochet, Execute, Heavy Axes | **Bladestorm**: +3 axes, +3 pierce, x2 damage |
| **Mage** | Fireball with splash | Pyroblast, Frost Nova (slows the wyrm), Arcane Barrage, Ignite | **Meteor**: x2 blast radius, x3 damage |
| **Hunter** | Rapid arrows | Multishot, Piercing Shot, Rapid Fire, Serpent Sting | **Storm of Arrows**: +4 arrows, 40% faster, bounce twice |
| **Priest** | Holy bolt, plus a periodic shove of the wyrm | Divine Shield, Smite, Holy Nova, Blessing of Haste | **Divine Wrath**: whole party x2 damage |
| **Rogue** | Fan of 3 daggers with high crit | Poisoned Blades, Fan of Knives, Cold Blood, Deadly Throw | **Death Mark**: +30% crit, x2 crit damage |
| **Warlock** | Shadow bolt that curses (DoT) | Corruption (curse spreads), Shadow Volley, Agony, Soul Fire | **Plague**: x3 curse damage, spreads 2 more each side |

**Party-wide skills:** Sharpened Steel (+damage), War Drums (+attack speed),
Keen Eye (+crit), Chilling Aura (slower wyrm).

## 8. Roguelite progression

### 100 stages

- Stages alternate between Ritual Circle (odd numbers) and War Wagon (even
  numbers).
- Every 10th stage is a **boss**, the Elder Wyrm: 60% more HP and 15 extra
  segments.
- Each stage, segment HP grows **exponentially**. Wyrms also get longer (45
  segments, up to 90), faster, and have more bone and mending segments.
- Clearing a stage unlocks the next one. You can replay any unlocked stage.

### Gold and farming

- You always keep the gold you earn, even when you lose or retreat.
- Gold per segment scales with the stage number.
- Clearing a stage gives a bonus, tripled on the first clear.
- Stage HP grows a bit faster than the power you can buy, so pushing deeper
  means replaying stages to farm gold, and more farming the deeper you go.

### Permanent upgrades (gold)

| Upgrade | Effect | Cap |
|---|---|---|
| Hero level (each hero) | +15% damage per level, compounding | none |
| Might | +8% damage for all heroes, compounding | none |
| Haste | +3% attack speed | 25 |
| Ferocity | +25% crit damage | none |
| Fortune | +10% gold earned | none |
| Insight | +1 starting refresh | 5 |
| Treasure Hunter | +2 skill chests per stage | 8 |
| Head Start | Start each run with +1 random skill | 5 |

Progress is saved automatically after every run and purchase.

## 9. Tech plan

- **Engine:** Godot 4.x with GDScript, exported to an Android APK
  **[ASSUMED]**.
- **Wyrm:** a `Path2D` with segments placed by distance along the curve.
  When a segment is removed, the offsets behind it are compacted.
- **Data-driven:** heroes, skills and segment types are data tables in
  `scripts/data.gd`, so balancing is just editing numbers.
- **Art and audio:** Kenney CC0 packs (Tiny Dungeon heroes and tiles,
  Particle Pack effects, RPG UI, Kenney Future font, RPG and impact sounds),
  plus original pixel-art wyrm sprites. `tools/import_assets.py` rebuilds
  `assets/` from the downloaded packs, and `assets/CREDITS.md` lists the
  sources.
- **Business model:** offline, with no ads or in-app purchases for now
  **[ASSUMED]**.

## 10. Milestones

1. **Playable prototype (done):** both stage types, 6 heroes, chests with
   pick 1 of 3 and refreshes, Android APK built by CI.
2. **Roguelite progression (done):** 100 stages, bosses, gold, permanent
   upgrades, save game, rarities, legendaries, damage numbers.
3. **Next ideas:** real art and sound, more segment types (brood spawners,
   shielded), more stage layouts, hero unlocks, achievements, balance pass
   from real play.
