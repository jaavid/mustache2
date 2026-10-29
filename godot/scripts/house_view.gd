extends Node2D
const House = preload("res://scripts/house.gd")
const Type = preload("res://scripts/typography.gd")
const Art = preload("res://scripts/character_art.gd")
var state: RefCounted
var world_offset := Vector2.ZERO
var reduced_motion := false


func panel(r: Rect2, c: Color, radius: int = 8, border: Color = Color.TRANSPARENT) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = c
	style.border_color = border
	style.set_border_width_all(2 if border.a > 0 else 0)
	style.set_corner_radius_all(radius)
	style.draw(get_canvas_item(), r)


func oval(p: Vector2, size: Vector2, c: Color) -> void:
	draw_set_transform(world_offset + p, 0, size)
	draw_circle(Vector2.ZERO, 1, c)
	draw_set_transform(world_offset)


func _draw() -> void:
	if not is_instance_valid(state):
		return
	draw_set_transform(world_offset)
	panel(Rect2(58, 58, 1400, 914), Color("111a25"), 22)
	for i in range(House.ROOMS.size()):
		var room: Dictionary = House.ROOMS[i]
		var r := Rect2(room.x, room.y, room.w, room.h)
		var colors := [
			Color("566362"),
			Color("636271"),
			Color("797262"),
			Color("52696c"),
			Color("645c70"),
			Color("6a625d")
		]
		panel(r, colors[i], 0)
		for y in range(int(r.position.y), int(r.end.y), 32):
			for x in range(int(r.position.x), int(r.end.x), 64):
				if i == 2:
					draw_rect(
						Rect2(x, y, minf(63, r.end.x - x), minf(31, r.end.y - y)),
						(
							Color(0.95, 0.9, 0.75, 0.08)
							if (x / 64 + y / 32) % 2 == 0
							else Color(0.1, 0.12, 0.16, 0.08)
						)
					)
				else:
					draw_line(
						Vector2(x, y),
						Vector2(minf(x + 63, r.end.x), y),
						Color(0.1, 0.12, 0.2, 0.18),
						2
					)
					draw_line(
						Vector2(x, y),
						Vector2(x, minf(y + 31, r.end.y)),
						Color(1, 0.9, 0.7, 0.04),
						1
					)
		var rug := Rect2(r.position + r.size * 0.35, r.size * 0.4)
		panel(rug, Color(0.76, 0.48, 0.45, 0.22), 20, Color(0.95, 0.77, 0.56, 0.15))
		draw_string(
			Type.font(700),
			r.position + Vector2(25, 36),
			room.name,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			20,
			Color("f3e2bf")
		)
	# Floor props and ceiling-light pools remain behind actors.
	for pos in [
		Vector2(130, 140),
		Vector2(940, 150),
		Vector2(1070, 470),
		Vector2(145, 880),
		Vector2(945, 880),
		Vector2(1380, 590)
	]:
		oval(pos + Vector2(3, 7), Vector2(25, 11), Color(0, 0, 0, 0.2))
		draw_circle(pos, 18, Color("ba896c"))
		for j in range(6):
			draw_circle(
				pos + Vector2.from_angle(j * TAU / 6) * 13,
				11,
				Color("94b891") if j % 2 else Color("67977b")
			)
	for w in House.WALLS:
		var r := Rect2(w.x, w.y, w.w, w.h)
		panel(Rect2(r.position + Vector2(0, 8), r.size), Color(0, 0, 0, 0.24), 3)
		panel(r, Color("a49b8c"), 3)
		draw_line(
			r.position + Vector2(2, 2), Vector2(r.end.x - 2, r.position.y + 2), Color("e4d7bb"), 3
		)
	for p in [Vector2(310, 82), Vector2(740, 82), Vector2(1200, 82)]:
		panel(Rect2(p, Vector2(90, 12)), Color("8db9c1"), 2)
		draw_colored_polygon(
			PackedVector2Array(
				[
					p + Vector2(0, 14),
					p + Vector2(90, 14),
					p + Vector2(145, 155),
					p + Vector2(25, 155)
				]
			),
			Color(1, 0.88, 0.58, 0.055)
		)
	for noise in state.decoys:
		var pulse := 22.0 + (0.0 if reduced_motion else sin(state.elapsed * 7) * 4)
		draw_arc(noise.pos, pulse, 0, TAU, 32, Color("f6c887"), 2, true)
		draw_string(
			Type.font(700),
			noise.pos + Vector2(-16, -30),
			"تق!",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			24,
			Color("ffe2a5")
		)
	for a in state.actors:
		if a.state == "hidden" and state.player.distance_to(a.pos) < 155:
			draw_arc(a.pos, 23, 0, TAU, 32, Color("ecd39e"), 2, true)
			draw_string(
				Type.font(700),
				a.pos + Vector2(-6, 8),
				"؟",
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				25,
				Color("ffedbb")
			)
	# Sort feet and foreground furniture together for real depth/occlusion.
	var layers: Array = []
	for i in range(House.FURNITURE.size()):
		var f: Dictionary = House.FURNITURE[i]
		layers.append({"y": f.y + f.h, "kind": "furniture", "index": i})
	for i in range(state.actors.size()):
		if state.actors[i].state != "hidden":
			layers.append({"y": state.actors[i].pos.y, "kind": "actor", "index": i})
	layers.append({"y": state.player.y, "kind": "player", "index": 0})
	layers.sort_custom(func(a, b): return a.y < b.y)
	for item in layers:
		if item.kind == "furniture":
			draw_furniture(House.FURNITURE[item.index])
		elif item.kind == "actor":
			draw_actor(state.actors[item.index])
		else:
			draw_player()
	for s in state.shots:
		for i in range(s.trail.size()):
			draw_circle(s.trail[i], 2.0 + i * 0.2, Color(1, 0.78, 0.5, 0.08 + i * 0.035))
		mustache(s.pos, s.velocity.angle(), Color("241c2b"), 0.65)
	for s in [] if reduced_motion else state.sparks:
		var progress: float = 1 - s.life / 0.7
		for j in range(12):
			var p: Vector2 = s.pos + Vector2.from_angle(j * TAU / 12) * progress * 65
			draw_circle(p, 3 * (1 - progress), Color(1, 0.82, 0.48, 1 - progress))
	if state.started and not state.paused:
		var pointer: Vector2 = state.player + state.aim * 65
		draw_arc(pointer, 9, 0, TAU, 24, Color(1, 0.9, 0.65, 0.6), 1, true)
	draw_set_transform(Vector2.ZERO)
	# HUD backing isolates text from moving scenery.
	var viewport_size: Vector2 = get_viewport_rect().size
	panel(Rect2(0, 0, viewport_size.x, 270), Color("111628"), 0)
	panel(Rect2(0, viewport_size.y - 80, viewport_size.x, 80), Color("111628"), 0)
	# A compact map uses stable world coordinates, independent of camera and orientation.
	var size: Vector2 = get_viewport_rect().size
	var origin := Vector2(size.x - 168, 282)
	panel(Rect2(origin - Vector2(8, 8), Vector2(158, 100)), Color("16202b"), 10, Color("43505a"))
	var scale_map := Vector2(0.095, 0.085)
	for w in House.WALLS:
		draw_rect(
			Rect2(origin + Vector2(w.x, w.y) * scale_map, Vector2(w.w, w.h) * scale_map),
			Color("8d9a9d")
		)
	draw_circle(origin + state.player * scale_map, 4, Color("f5ce7c"))
	for a in state.actors:
		if a.state == "fleeing":
			draw_circle(origin + a.pos * scale_map, 3, Color("f8a0ad"))


func draw_furniture(f: Dictionary) -> void:
	var r := Rect2(f.x, f.y, f.w, f.h)
	panel(Rect2(r.position + Vector2(4, 10), r.size), Color(0, 0, 0, 0.25), 8)
	var wood := Color("b28b69")
	panel(r, wood, 8, Color("735442"))
	match f.type:
		"sofa":
			panel(r, Color(f.color), 12, Color("34434b"))
			for i in range(3):
				panel(
					Rect2(
						r.position + Vector2(12 + i * (r.size.x - 24) / 3, 14),
						Vector2((r.size.x - 28) / 3, r.size.y - 27)
					),
					Color(f.color).lightened(0.18),
					7
				)
			panel(
				Rect2(r.position + Vector2(0, -7), Vector2(r.size.x, 19)),
				Color(f.color).lightened(0.08),
				7
			)
		"bed":
			panel(Rect2(r.position + Vector2(6, 5), r.size - Vector2(12, 12)), Color("e7ddc6"), 6)
			panel(Rect2(r.position + Vector2(8, 27), r.size - Vector2(16, 32)), Color(f.color), 6)
			panel(
				Rect2(r.position + Vector2(12, 9), Vector2(r.size.x * 0.5, 18)), Color("faf0d7"), 5
			)
		"closet":
			panel(Rect2(r.position + Vector2(5, -15), r.size - Vector2(10, 0)), Color(f.color), 5)
			for i in range(1, 4):
				draw_line(
					r.position + Vector2(8, i * r.size.y / 4 - 8),
					r.position + Vector2(r.size.x - 8, i * r.size.y / 4 - 8),
					Color("533e36"),
					3
				)
			for i in range(5):
				panel(
					Rect2(r.position + Vector2(10 + i * 9, 4), Vector2(6, 18)),
					[Color("d6b880"), Color("9eb2b3"), Color("c98b91")][i % 3],
					1
				)
		_:
			panel(
				Rect2(r.position + Vector2(3, -6), r.size - Vector2(6, 7)),
				Color("cfaa7b"),
				7,
				Color("ead0a1")
			)
			draw_circle(r.position + r.size * 0.5, 12, Color("f0ddbc"))
			draw_circle(r.position + r.size * 0.5, 7, Color("a4b98d"))


func draw_actor(a: Dictionary) -> void:
	var p: Vector2 = a.pos
	oval(p + Vector2(0, 3), Vector2(24, 9), Color(0, 0, 0, 0.28))
	var sheet: Texture2D = Art.SHEETS[a.id]
	var frame_width := sheet.get_width() / 4.0
	var height := float(sheet.get_height())
	var frame := (
		3 if a.state == "captured" else (2 if not reduced_motion and sin(a.wave * 2) > 0.85 else 0)
	)
	var bounce: float = (
		absf(sin(a.wave * 2)) * 2.0 if a.state == "fleeing" and not reduced_motion else 0.0
	)
	var width := 84.0 * frame_width / height
	draw_texture_rect_region(
		sheet,
		Rect2(p + Vector2(-width / 2, -84 - bounce), Vector2(width, 84)),
		Rect2(frame * frame_width, 0, frame_width, height)
	)
	if a.state == "captured":
		mustache(state.lip(a), 0, Color("211924"), 0.65)
	else:
		draw_string(
			Type.font(700),
			p + Vector2(-8, -94),
			"!",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			25,
			Color("ffdda1")
		)
	# Grounded name badges stay readable without extra facial target rings.
	panel(Rect2(p + Vector2(-36, 9), Vector2(72, 27)), Color("1a2633"), 8)
	draw_string(
		Type.font(700),
		p + Vector2(-28, 29),
		state.NAMES[a.id],
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color("f4e8cd")
	)


func draw_player() -> void:
	var p: Vector2 = state.player
	oval(p + Vector2(0, 7), Vector2(24, 10), Color(0, 0, 0, 0.25))
	var bounce: float = sin(state.elapsed * 15) * 2 if state.walking and not reduced_motion else 0.0
	panel(Rect2(p + Vector2(-16, -12 + bounce), Vector2(32, 29)), Color("456579"), 10)
	draw_circle(p + Vector2(0, -23 + bounce), 15, Color("edc28d"))
	draw_arc(p + Vector2(0, -24 + bounce), 14, PI, TAU, 20, Color("302f3b"), 8, true)
	draw_line(p + state.aim * 12, p + state.aim * 34, Color("e3bb70"), 10, true)
	draw_circle(p + state.aim * 35, 6, Color("795448"))


func mustache(
	p: Vector2, angle: float = 0.0, color: Color = Color("251b27"), scale_value: float = 1.0
) -> void:
	for side in [-1, 1]:
		var center := p + Vector2(side * 7, 0).rotated(angle) * scale_value
		draw_circle(center, 7 * scale_value, color)
		draw_line(
			center,
			p + Vector2(side * 17, -5).rotated(angle) * scale_value,
			color,
			5 * scale_value,
			true
		)
