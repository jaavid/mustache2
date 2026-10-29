extends RefCounted
const SOURCE = preload("res://assets/NotoSansArabic.ttf")
static var weights: Dictionary = {}


static func font(weight: int = 400) -> FontVariation:
	weight = clampi(weight, 100, 900)
	if not weights.has(weight):
		var variant := FontVariation.new()
		variant.base_font = SOURCE
		# Numeric OpenType tags avoid ambiguous string aliases; these are real variable outlines.
		variant.variation_opentype = {
			TextServerManager.get_primary_interface().name_to_tag("wght"): float(weight)
		}
		weights[weight] = variant
	return weights[weight]


static func rtl(label: Label, weight: int = 400) -> void:
	label.language = "fa"
	label.text_direction = Control.TEXT_DIRECTION_RTL
	# Godot mirrors logical leading alignment under an RTL Control.
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.add_theme_font_override("font", font(weight))
