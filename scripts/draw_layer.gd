class_name DrawLayer
extends Node2D
## A Node2D whose drawing is delegated to a callable, so a parent can paint
## on a separate layer (e.g. above its children).

var painter: Callable


func _draw() -> void:
	if painter.is_valid():
		painter.call(self)
