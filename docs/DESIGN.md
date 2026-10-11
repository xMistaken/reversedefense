# Wyrmbreaker — Game Design (Draft v0.1)

> Working title. An Android roguelike "chain" defense game in the style of
> *Dragon Fever TD* / *Cell Survivor*, reskinned as a classic fantasy RPG.
> Classes and tone are inspired by MMO-style fantasy (World of Warcraft), but
> all names, lore and art are original.

Items marked **[ASSUMED]** are defaults that haven't been confirmed yet.

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

| Stage | Party position | Player input | Track shape |
|---|---|---|---|
| **Ritual Circle** (stationary) | Fixed at the center of the screen | Drag to aim; party auto-fires along the aim direction **[ASSUMED]** | Spiral or loop around the center |
| **War Wagon** (vehicle) | Wagon at the bottom of the screen | Drag to slide left and right; party auto-fires upward **[ASSUMED]** | Serpentine, zig-zagging down from the top |

The screen is portrait (1080×1920 reference resolution).

## 5. The Wyrm

- A chain of **segments** following a path (`Path2D`), with fixed spacing
  between them.
- Each segment has its own HP. The **rearmost segment drives** the chain and
  pushes everything ahead of it, Zuma-style. Breaking a middle segment leaves
  a gap: the front part **stalls** until the back catches up and closes the
  gap. Breaking segments mid-chain buys time.
- The wyrm moves at a steady speed. It rushes in quickly at the start of a
  stage, and skills can slow it.
- **Head:** just the front of the chain. It has no boss HP and no special
  role.
- **Win condition:** destroy **every** segment of the creature.
- **Lose condition:** the front of the chain reaches the end of the track.

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

- **Starting party:** one hero, chosen before the run **[ASSUMED]**.
- **Hero Chest:** shows **3 random heroes you don't already have**, and you
  pick one. There are no duplicates. Once all heroes are recruited, hero
  chests roll skills instead.
- **Skill Chest:** shows **3 random skills**, and you pick one. Skills can be
  new skills or ranks on ones you already have, for your current heroes or for
  the whole party.
- **Refreshes:** a shared pool for the whole run that rerolls the 3 options on
  either chest type. You start with **2** **[ASSUMED]**, and more come from
  Gilded segments.
- The game pauses while a pick is open.

## 7. Heroes (starting roster of 6)

Each hero adds a basic attack to the party volley and has its own skill pool.

| Class | Role | Basic attack | Sample skills |
|---|---|---|---|
| **Warrior** | Close-range cleave | Thrown axe that pierces 2 segments | Whirlwind (spin AoE), Shield Ricochet (bounces along the chain), Execute (bonus damage vs. low HP) |
| **Mage** | Area damage and control | Fireball with splash | Frost Nova (slows the whole wyrm), Arcane Barrage, Meteor |
| **Hunter** | Sustained single target | Fast arrows | Multishot, Beast Companion (a pet that bites segments), Piercing Shot |
| **Priest** | Support | Holy bolt | Divine Shield (pushes the wyrm back on the track), Smite Chain, Blessing (party attack speed) |
| **Rogue** | Crits and burst | Fan of daggers | Poisoned Blades (stacking damage over time), Ambush (bonus vs. full-HP segments), Shadowstep Volley |
| **Warlock** | Damage over time and spread | Shadow bolt | Corruption (spreads to adjacent segments), Summon Imp, Soul Drain (damage refreshes skill cooldowns) |

**Party-wide skills** (available whatever heroes you have): +attack speed,
+damage, +crit chance, +projectile count, slow aura.

Skills have ranks 1–5. The skill pool only offers skills for heroes you
currently have.

## 8. Progression between runs **[ASSUMED]**

- Runs earn **gold** based on segments destroyed and stages cleared.
- Gold unlocks classes for the starting-hero pick (2 are unlocked at first)
  and buys small permanent stat upgrades.
- A **campaign** of stages with increasing difficulty: longer wyrms, more
  armored segments and faster speed. Stages alternate between the two stage
  types.

## 9. Tech plan

- **Engine:** Godot 4.x with GDScript, exported to an Android APK
  **[ASSUMED]**.
- **Wyrm:** a `Path2D` with segments placed by distance along the curve.
  When a segment is removed, the offsets behind it are compacted.
- **Data-driven:** heroes, skills and segment types are data tables in
  `scripts/data.gd`, so balancing is just editing numbers.
- **Art:** placeholder shapes and colors first, swapped for real assets later
  **[ASSUMED]**.
- **Business model:** offline, with no ads or in-app purchases for now
  **[ASSUMED]**.

## 10. Milestone 1: playable prototype

- One Ritual Circle stage and one War Wagon stage
- One wyrm with Flesh, Bone-plated, Hero Chest and Skill Chest segments
- 3 heroes (Warrior, Mage, Hunter), each with about 3 skills, plus about 4
  party-wide skills
- Pick-3 UI with refreshes
- Win and lose screens; no meta progression yet
- Builds and runs as an Android APK
