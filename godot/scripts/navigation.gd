extends RefCounted
const House = preload("res://scripts/house.gd")
var grid := AStarGrid2D.new()
var obstacles: Array[Rect2] = []


func _init() -> void:
	for data in House.WALLS + House.FURNITURE:
		obstacles.append(Rect2(data.x, data.y, data.w, data.h))
	grid.region = Rect2i(0, 0, 62, 42)
	grid.cell_size = Vector2(24, 24)
	grid.offset = Vector2(12, 12)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for y in range(42):
		for x in range(62):
			grid.set_point_solid(Vector2i(x, y), blocked(Vector2(x * 24 + 12, y * 24 + 12), 18))


func blocked(p: Vector2, radius: float = 16) -> bool:
	if p.x - radius < 94 or p.y - radius < 94 or p.x + radius > 1420 or p.y + radius > 924:
		return true
	for r in obstacles:
		var nearest := p.clamp(r.position, r.end)
		if nearest.distance_squared_to(p) < radius * radius:
			return true
	return false


func slide(p: Vector2, displacement: Vector2, radius: float = 16) -> Vector2:
	var result := p
	var count := maxi(1, ceili(displacement.length() / 6))
	var step := displacement / count
	for i in range(count):
		if not blocked(result + Vector2(step.x, 0), radius):
			result.x += step.x
		if not blocked(result + Vector2(0, step.y), radius):
			result.y += step.y
	return result


func clear_segment(a: Vector2, b: Vector2, radius: float = 15) -> bool:
	var count := maxi(1, ceili(a.distance_to(b) / 6))
	for i in range(count + 1):
		if blocked(a.lerp(b, float(i) / count), radius):
			return false
	return true


func nearest_cell(p: Vector2) -> Vector2i:
	var center := Vector2i(floori(p.x / 24), floori(p.y / 24))
	var best := Vector2i(-1, -1)
	var distance := INF
	for y in range(center.y - 2, center.y + 3):
		for x in range(center.x - 2, center.x + 3):
			var cell := Vector2i(x, y)
			if not grid.is_in_boundsv(cell) or grid.is_point_solid(cell):
				continue
			var pos := grid.get_point_position(cell)
			if p.distance_squared_to(pos) < distance and clear_segment(p, pos):
				distance = p.distance_squared_to(pos)
				best = cell
	return best


func route(from: Vector2, to: Vector2) -> PackedVector2Array:
	if blocked(to, 15):
		return PackedVector2Array()
	if clear_segment(from, to):
		return PackedVector2Array([to])
	var start := nearest_cell(from)
	var end := nearest_cell(to)
	if start.x < 0 or end.x < 0:
		return PackedVector2Array()
	var path := grid.get_point_path(start, end)
	if path.is_empty():
		return path
	path.append(to)
	return path


func cover(actor: Dictionary, player: Vector2) -> Dictionary:
	var choices: Array = []
	for spot in House.SPOTS:
		var pos := Vector2(spot.x, spot.y)
		if pos.distance_to(actor.pos) <= 95 or pos.distance_to(player) <= 180:
			continue
		var value: float = pos.distance_to(player) - pos.distance_to(actor.pos) * 0.21
		if actor.id == 0:
			value += 330 if spot.cover == "table" else (110 if spot.cover == "sofa" else 0)
		choices.append({"pos": pos, "value": value})
	choices.sort_custom(func(a, b): return a.value > b.value)
	for choice in choices:
		var path := route(actor.pos, choice.pos)
		if not path.is_empty():
			return {"target": choice.pos, "path": path, "cover": true}
	return {}


func flank(actor: Dictionary, player: Vector2) -> Dictionary:
	var bearing: float = (actor.pos - player).angle()
	for side in [actor.orbit, -actor.orbit]:
		for offset in [1.12, 1.72, 2.25]:
			for radius in [275, 335]:
				var target: Vector2 = player + Vector2.from_angle(bearing + offset * side) * radius
				if target.distance_to(actor.pos) < 85:
					continue
				var path := route(actor.pos, target)
				if not path.is_empty():
					return {"target": target, "path": path, "cover": false, "orbit": side}
	return cover(actor, player)


func can_rehide(actor: Dictionary, player: Vector2) -> bool:
	if not actor.has("target") or actor.target == null:
		return false
	# A flank waypoint is not a hiding spot. Borhan eventually routes to physical cover.
	if not actor.get("cover", false):
		return false
	return (
		actor.pos.distance_to(actor.target) <= 34
		and actor.chase >= (7.0 if actor.id == 1 else 1.7)
		and actor.pos.distance_to(player) > (390 if actor.id == 1 else 300)
	)


func noise_spot(actor: Dictionary, player: Vector2, actors: Array) -> Variant:
	var candidates: Array = []
	for spot in House.SPOTS:
		var pos := Vector2(spot.x, spot.y)
		if (
			pos.distance_to(actor.pos) <= 210
			or pos.distance_to(player) <= 100
			or pos.distance_to(player) >= 750
			or pos == actor.get("last_noise", Vector2.ZERO)
		):
			continue
		var occupied := false
		for other in actors:
			if other.id != actor.id and other.state == "hidden" and pos.distance_to(other.pos) < 95:
				occupied = true
		if not occupied:
			candidates.append(pos)
	candidates.sort_custom(func(a, b): return a.distance_to(player) < b.distance_to(player))
	return candidates[0] if not candidates.is_empty() else null
