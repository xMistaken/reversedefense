extends Node2D
## Renders all four themed wyrms on a serpentine path in a 2x2 grid and saves
## a PNG, to check the painted body slicing, head and tail. Needs a display:
##   godot --resolution 1080x1920 res://tests/wyrm_preview.tscn -- out=/path/wyrms.png

var out_path := "user://wyrms.png"


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			out_path = arg.trim_prefix("out=")
	var themes := ["ember", "frost", "crypt", "abyss"]
	for i in themes.size():
		var holder := Node2D.new()
		holder.position = Vector2((i % 2) * 540, (i / 2) * 960)
		holder.scale = Vector2(0.5, 0.5)
		add_child(holder)
		var bg := Sprite2D.new()
		bg.texture = Art.BACKGROUNDS[themes[i]]
		bg.centered = false
		bg.scale = Vector2.ONE * 1080.0 / bg.texture.get_width()
		holder.add_child(bg)
		var w := Wyrm.new()
		w.skin = Art.WYRMS[themes[i]].duplicate()
		holder.add_child(w)
		var curve := TrackBuilder.serpentine(150, 930, 380, 300, 4, true)
		var types: Array[String] = []
		for k in 10:
			types.append("skill_chest" if k == 3 else ("hero_chest" if k == 7 else ("bone" if k == 5 else "flesh")))
		w.setup(curve, types, 100.0, 0.1)
		w.base_speed = 120.0
		for f in 60 * 22:
			w._process(1.0 / 60.0)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_path)
	get_tree().quit()
