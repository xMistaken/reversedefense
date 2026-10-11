class_name Art
extends RefCounted
## Texture handles for everything the game draws. Sprites and backgrounds are
## painted artwork (art_inbox/ -> tools/process_art.py -> assets/art/); glow
## effects and sounds are Kenney CC0 packs. See assets/CREDITS.md.

const HERO_SCALE := 0.36

const HEROES := {
	"warrior": preload("res://assets/art/heroes/warrior.png"),
	"mage": preload("res://assets/art/heroes/mage.png"),
	"hunter": preload("res://assets/art/heroes/hunter.png"),
	"priest": preload("res://assets/art/heroes/priest.png"),
	"rogue": preload("res://assets/art/heroes/rogue.png"),
	"warlock": preload("res://assets/art/heroes/warlock.png"),
}

const SHOTS := {
	"axe": preload("res://assets/art/items/shot_axe.png"),
	"dagger": preload("res://assets/art/items/shot_dagger.png"),
	"arrow": preload("res://assets/art/items/shot_arrow.png"),
	"fire": preload("res://assets/art/items/shot_fire.png"),
	"holy": preload("res://assets/art/items/shot_holy.png"),
	"shadow": preload("res://assets/art/items/shot_shadow.png"),
}

const ORB_SKILL := preload("res://assets/art/items/orb_skill.png")
const ORB_HERO := preload("res://assets/art/items/orb_hero.png")

const WALL := preload("res://assets/art/defense/wall.png")
const WAGON := preload("res://assets/art/defense/wagon.png")
const RING := preload("res://assets/art/defense/ring.png")

## Per theme: head (faces right), body log (faces right; sliced into bands),
## tail (thick end on the right), collar (armor ring over the seam between
## sections) and socket (body piece with a hole for a chest orb).
const WYRMS := {
	"ember": {
		"head": preload("res://assets/art/wyrm/head_ember.png"),
		"body": preload("res://assets/art/wyrm/body_ember.png"),
		"tail": preload("res://assets/art/wyrm/tail_ember.png"),
		"collar": preload("res://assets/art/wyrm/collar_ember.png"),
		"socket": preload("res://assets/art/wyrm/socket_ember.png"),
	},
	"frost": {
		"head": preload("res://assets/art/wyrm/head_frost.png"),
		"body": preload("res://assets/art/wyrm/body_frost.png"),
		"tail": preload("res://assets/art/wyrm/tail_frost.png"),
		"collar": preload("res://assets/art/wyrm/collar_frost.png"),
		"socket": preload("res://assets/art/wyrm/socket_frost.png"),
	},
	"crypt": {
		"head": preload("res://assets/art/wyrm/head_crypt.png"),
		"body": preload("res://assets/art/wyrm/body_crypt.png"),
		"tail": preload("res://assets/art/wyrm/tail_crypt.png"),
		"collar": preload("res://assets/art/wyrm/collar_crypt.png"),
		"socket": preload("res://assets/art/wyrm/socket_crypt.png"),
	},
	"abyss": {
		"head": preload("res://assets/art/wyrm/head_abyss.png"),
		"body": preload("res://assets/art/wyrm/body_abyss.png"),
		"tail": preload("res://assets/art/wyrm/tail_abyss.png"),
		"collar": preload("res://assets/art/wyrm/collar_abyss.png"),
		"socket": preload("res://assets/art/wyrm/socket_abyss.png"),
	},
}

const BACKGROUNDS := {
	"ember": preload("res://assets/art/bg/ember.jpg"),
	"frost": preload("res://assets/art/bg/frost.jpg"),
	"crypt": preload("res://assets/art/bg/crypt.jpg"),
	"abyss": preload("res://assets/art/bg/abyss.jpg"),
	"menu": preload("res://assets/art/bg/menu.jpg"),
}

const FX := {
	"flame": preload("res://assets/fx/flame.png"),
	"star": preload("res://assets/fx/star.png"),
	"twirl": preload("res://assets/fx/twirl.png"),
	"magic": preload("res://assets/fx/magic.png"),
	"spark": preload("res://assets/fx/spark.png"),
	"glow": preload("res://assets/fx/glow.png"),
	"smoke": preload("res://assets/fx/smoke.png"),
	"light": preload("res://assets/fx/light.png"),
	"slash": preload("res://assets/fx/slash.png"),
	"burst": preload("res://assets/fx/burst.png"),
}

const FONT := preload("res://assets/hd/fonts/LilitaOne-Regular.ttf")


## Draws `tex` centred on `pos`, rotated and scaled.
static func draw_sprite(c: CanvasItem, tex: Texture2D, pos: Vector2, scale: float,
		angle := 0.0, modulate := Color.WHITE, flip_v := false) -> void:
	var size := tex.get_size()
	c.draw_set_transform(pos, angle, Vector2(scale, -scale if flip_v else scale))
	c.draw_texture(tex, -size / 2.0, modulate)
	c.draw_set_transform_matrix(Transform2D.IDENTITY)


## Draws part of `tex` (`src` rect) centred on `pos`, rotated and scaled.
static func draw_region(c: CanvasItem, tex: Texture2D, src: Rect2, pos: Vector2, scale: Vector2,
		angle := 0.0, modulate := Color.WHITE) -> void:
	c.draw_set_transform(pos, angle, scale)
	c.draw_texture_rect_region(tex, Rect2(-src.size / 2.0, src.size), src, modulate)
	c.draw_set_transform_matrix(Transform2D.IDENTITY)
