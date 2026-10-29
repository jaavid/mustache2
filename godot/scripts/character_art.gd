extends RefCounted
## Shared visual definitions. Gameplay deliberately does not load character textures.
const SHEETS = [
	preload("res://assets/ramin.png"),
	preload("res://assets/borhan.png"),
	preload("res://assets/mammad.png"),
]
const AVATAR_REGIONS = [Rect2(30, 18, 150, 150), Rect2(30, 18, 150, 150), Rect2(12, 1, 63, 63)]
const AVATAR_COLORS = [Color("a9607a"), Color("5b8a93"), Color("d0a16b")]


static func portrait(index: int) -> AtlasTexture:
	var image := AtlasTexture.new()
	image.atlas = SHEETS[index]
	image.region = AVATAR_REGIONS[index]
	return image
