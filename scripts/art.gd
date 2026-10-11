class_name Art
extends RefCounted
## Texture handles for everything the game draws. Assets are Kenney CC0 packs
## plus generated wyrm sprites (see tools/import_assets.py and assets/CREDITS.md).

const SPRITE_SCALE := 5.5  # 16px pixel art -> on-screen size

const HEROES := {
	"warrior": preload("res://assets/heroes/warrior.png"),
	"mage": preload("res://assets/heroes/mage.png"),
	"hunter": preload("res://assets/heroes/hunter.png"),
	"priest": preload("res://assets/heroes/priest.png"),
	"rogue": preload("res://assets/heroes/rogue.png"),
	"warlock": preload("res://assets/heroes/warlock.png"),
}

const ITEMS := {
	"axe": preload("res://assets/items/axe.png"),
	"dagger": preload("res://assets/items/dagger.png"),
	"arrow": preload("res://assets/items/arrow.png"),
	"chest_skill": preload("res://assets/items/chest_skill.png"),
	"chest_hero": preload("res://assets/items/chest_hero.png"),
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

const WYRM_SEGMENT := preload("res://assets/wyrm/segment.png")
const WYRM_PLATE := preload("res://assets/wyrm/plate.png")
const WYRM_HEAD := preload("res://assets/wyrm/head.png")

const GROUND := {
	"dirt": [preload("res://assets/tiles/dirt_0.png"), preload("res://assets/tiles/dirt_1.png"), preload("res://assets/tiles/dirt_2.png")],
	"sand": [preload("res://assets/tiles/sand_0.png"), preload("res://assets/tiles/sand_1.png"), preload("res://assets/tiles/sand_2.png")],
}
const DECOR := [
	preload("res://assets/tiles/gravestone.png"),
	preload("res://assets/tiles/cross.png"),
	preload("res://assets/tiles/barrel.png"),
]

const FONT := preload("res://assets/fonts/kenney_future.ttf")


## Draws `tex` centred on `pos`, rotated and scaled (pixel units of the texture).
static func draw_sprite(c: CanvasItem, tex: Texture2D, pos: Vector2, scale: float,
		angle := 0.0, modulate := Color.WHITE, flip_v := false) -> void:
	var size := tex.get_size()
	c.draw_set_transform(pos, angle, Vector2(scale, -scale if flip_v else scale))
	c.draw_texture(tex, -size / 2.0, modulate)
	c.draw_set_transform_matrix(Transform2D.IDENTITY)


## Tiles the ground with random variants (plus a few props) into one texture.
static func ground_texture(view: Vector2, kind: String, decor_count: int) -> ImageTexture:
	var cols := int(ceil(view.x / (16.0 * 4.0))) + 1
	var rows := int(ceil(view.y / (16.0 * 4.0))) + 1
	var img := Image.create(cols * 16, rows * 16, false, Image.FORMAT_RGBA8)
	var variants: Array = GROUND[kind]
	var tiles: Array[Image] = []
	for t in variants:
		var ti: Image = t.get_image()
		ti.convert(Image.FORMAT_RGBA8)
		tiles.append(ti)
	for y in rows:
		for x in cols:
			var pick := 0 if randf() < 0.97 else 1 + randi() % (tiles.size() - 1)
			img.blit_rect(tiles[pick], Rect2i(0, 0, 16, 16), Vector2i(x * 16, y * 16))
	for i in decor_count:
		var d: Image = DECOR[randi() % DECOR.size()].get_image()
		d.convert(Image.FORMAT_RGBA8)
		img.blend_rect(d, Rect2i(0, 0, 16, 16), Vector2i(randi() % (cols * 16 - 16), 60 + randi() % (rows * 16 - 76)))
	return ImageTexture.create_from_image(img)
