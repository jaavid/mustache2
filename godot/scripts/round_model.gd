extends RefCounted
## Round model: no nodes, UI, device polling, persistence or network access.
## The same public operations drive the playable scene and headless regression checks.
signal round_started
signal round_finished(result: Dictionary)
signal sound_requested(frequency: float, duration: float)
const House = preload("res://scripts/house.gd")
const Text = preload("res://scripts/game_text.gd")
const NAMES = Text.NAMES
var nav: RefCounted
var player := Vector2(320, 452)
var actors: Array = []
var shots: Array = []
var sparks: Array = []
var decoys: Array = []
var time_left := 180.0
var cooldown := 0.0
var elapsed := 0.0
var score := 0
var caught := 0
var fired := 0
var started := false
var paused := false
var walking := false
var outcome := ""
var aim := Vector2.RIGHT
var hint: String = Text.INITIAL_HINT


func _init(navigation: RefCounted) -> void:
	nav = navigation


func reset() -> void:
	player = Vector2(320, 452)
	time_left = 180.0
	elapsed = 0.0
	cooldown = 0.0
	score = 0
	caught = 0
	fired = 0
	shots.clear()
	sparks.clear()
	decoys.clear()
	actors.clear()
	var tables: Array = House.SPOTS.filter(
		func(spot):
			return spot.cover == "table" and player.distance_to(Vector2(spot.x, spot.y)) > 200
	)
	tables.shuffle()
	var first: Dictionary = tables[0]
	var choices: Array = House.SPOTS.filter(
		func(spot):
			return (
				spot != first
				and Vector2(spot.x, spot.y).distance_to(Vector2(first.x, first.y)) > 120
				and Vector2(spot.x, spot.y).distance_to(player) > 140
			)
	)
	choices.shuffle()
	var starts := [first, choices[0], choices[1]]
	for i in range(3):
		actors.append(
			{
				"id": i,
				"pos": Vector2(starts[i].x, starts[i].y),
				"state": "hidden",
				"target": null,
				"path": PackedVector2Array(),
				"refresh": 0.0,
				"chase": 0.0,
				"wave": 0.0,
				"orbit": 1,
				"cover": false,
				"noise_timer": randf_range(6, 9),
				"last_noise": Vector2.ZERO
			}
		)
	started = true
	paused = false
	hint = "سه نفر داخل خانه مخفی‌اند؛ نزدیک وسایل بگرد!"
	outcome = ""
	round_started.emit()


func obstructed(p: Vector2, radius: float = 16) -> bool:
	return nav.blocked(p, radius)


func move_safe(p: Vector2, displacement: Vector2, radius: float = 16) -> Vector2:
	return nav.slide(p, displacement, radius)


func inspect() -> void:
	if not started or paused:
		return
	var candidate: Variant = null
	var distance := 155.0
	for actor in actors:
		if actor.state == "hidden" and player.distance_to(actor.pos) < distance:
			candidate = actor
			distance = player.distance_to(actor.pos)
	var noise_index := -1
	for i in range(decoys.size()):
		if player.distance_to(decoys[i].pos) < minf(distance, 140):
			noise_index = i
			distance = player.distance_to(decoys[i].pos)
	if noise_index >= 0:
		decoys.remove_at(noise_index)
		hint = "این صدا ساختگی بود! ممد گولت زد؛ جای دیگری را بگرد."
		sound_requested.emit(135, 0.2)
	elif candidate != null:
		reveal(candidate)
	else:
		hint = "اینجا کسی نیست؛ سراغ مبل‌ها و کمدهای دیگر برو."
		sound_requested.emit(180, 0.08)


func reveal(actor: Dictionary) -> void:
	if actor.state != "hidden":
		return
	actor.state = "fleeing"
	actor.refresh = 0.0
	actor.chase = 0.0
	actor.target = null
	actor.path = PackedVector2Array()
	hint = NAMES[actor.id] + " را پیدا کردی! قبل از فرار روی لبش شلیک کن!"
	sound_requested.emit(540, 0.22)


func fire_auto() -> void:
	var target := player + aim * 500
	var nearest := INF
	for actor in actors:
		if actor.state == "fleeing" and player.distance_to(actor.pos) < nearest:
			target = lip(actor)
			nearest = player.distance_to(actor.pos)
	fire(target)


func fire(target: Vector2) -> void:
	if not started or paused or cooldown > 0:
		return
	aim = (target - player).normalized()
	if aim.length() < 0.1:
		aim = Vector2.RIGHT
	shots.append({"pos": player + aim * 27, "velocity": aim * 780, "life": 0.85, "trail": []})
	cooldown = 0.2
	fired += 1
	sound_requested.emit(440, 0.12)


func choose_escape(actor: Dictionary) -> void:
	var route: Dictionary = (
		nav.flank(actor, player) if actor.id == 1 and actor.chase < 7 else nav.cover(actor, player)
	)
	if route.is_empty():
		actor.target = null
		actor.path = PackedVector2Array()
	else:
		actor.target = route.target
		actor.path = route.path
		actor.cover = route.cover
		actor.orbit = route.get("orbit", actor.orbit)
	actor.refresh = 1.4 if actor.id == 1 else 2.5


func make_false_noise(actor: Dictionary) -> void:
	if decoys.size() >= 2:
		return
	var spot: Variant = nav.noise_spot(actor, player, actors)
	if spot == null:
		return
	actor.last_noise = spot
	decoys.append({"pos": spot, "life": 8.0})
	hint = "تق تق! صدای مشکوکی از " + room_name(spot) + " می‌آید…"
	sound_requested.emit(260, 0.14)


func step(dt: float, direction: Vector2 = Vector2.ZERO, sprint: bool = false) -> void:
	if not started or paused:
		return
	time_left = maxf(0, time_left - dt)
	if time_left <= 0:
		finish(false)
		return
	elapsed += dt
	cooldown = maxf(0, cooldown - dt)
	walking = direction.length() > 0.05
	player = move_safe(player, direction.limit_length() * dt * (295 if sprint else 218), 19)
	for i in range(decoys.size() - 1, -1, -1):
		decoys[i].life -= dt
		if decoys[i].life <= 0:
			decoys.remove_at(i)
	for actor in actors:
		actor.wave += dt * 5
		if actor.id == 2 and actor.state != "captured":
			actor.noise_timer -= dt
			if actor.noise_timer <= 0:
				make_false_noise(actor)
				actor.noise_timer = randf_range(9, 13)
		if actor.state == "hidden":
			if player.distance_to(actor.pos) < 78:
				reveal(actor)
			continue
		if actor.state != "fleeing":
			continue
		actor.chase += dt
		if nav.can_rehide(actor, player):
			actor.state = "hidden"
			actor.path = PackedVector2Array()
			actor.target = null
			hint = NAMES[actor.id] + " پشت وسایل دوباره قایم شد! پیدایش کن."
			continue
		actor.refresh -= dt
		if actor.refresh <= 0:
			choose_escape(actor)
		if actor.path.size() > 0 and actor.pos.distance_to(actor.path[0]) < 10:
			actor.path.remove_at(0)
		var waypoint: Variant = actor.path[0] if actor.path.size() > 0 else actor.target
		if waypoint != null:
			var step: Vector2 = (waypoint - actor.pos).limit_length(dt * [160, 178, 145][actor.id])
			actor.pos = move_safe(actor.pos, step, 15)
	update_shots(dt)
	for i in range(sparks.size() - 1, -1, -1):
		sparks[i].life -= dt
		if sparks[i].life <= 0:
			sparks.remove_at(i)


func update_shots(dt: float) -> void:
	for i in range(shots.size() - 1, -1, -1):
		var projectile: Dictionary = shots[i]
		projectile.life -= dt
		var destroyed: bool = projectile.life <= 0
		var count := maxi(1, ceili(projectile.velocity.length() * dt / 5))
		for j in range(count):
			if destroyed:
				break
			projectile.pos += projectile.velocity * dt / count
			if obstructed(projectile.pos, 5):
				destroyed = true
				break
			for actor in actors:
				if actor.state != "fleeing":
					continue
				var face := lip(actor)
				var local: Vector2 = (projectile.pos - face) / Vector2(17, 12)
				if local.length_squared() <= 1:
					actor.state = "captured"
					actor.path = PackedVector2Array()
					caught += 1
					score += 1000 + roundi(time_left * 3)
					if actor.id == 2:
						decoys.clear()
					sparks.append({"pos": face, "life": 0.7})
					hint = (
						"عالی! "
						+ NAMES[actor.id]
						+ " سیبیل‌دار شد! "
						+ Text.number(3 - caught)
						+ " نفر مانده."
					)
					sound_requested.emit(830, 0.3)
					destroyed = true
					break
				if (
					absf(projectile.pos.x - actor.pos.x) < 24
					and projectile.pos.y > face.y + 18
					and projectile.pos.y < actor.pos.y + 7
				):
					destroyed = true
					hint = "نزدیک بود! باید دقیق روی لبش بخورد."
					break
		if destroyed:
			shots.remove_at(i)
		else:
			projectile.trail.append(projectile.pos)
			if projectile.trail.size() > 7:
				projectile.trail.pop_front()
	if caught == 3 and started:
		finish(true)


func finish(victory: bool) -> void:
	if not started:
		return
	started = false
	paused = false
	if victory:
		score = roundi(score + time_left * 10)
	outcome = "won" if victory else "lost"
	(
		round_finished
		. emit(
			{
				"victory": victory,
				"score": score,
				"caught": caught,
				"shots": fired,
				"elapsedSeconds": roundi(180 - time_left),
			}
		)
	)


func lip(actor: Dictionary) -> Vector2:
	return actor.pos + Vector2(0, -84 + 84 * (125.0 if actor.id == 1 else 136.0) / 362)


func room_name(pos: Vector2) -> String:
	for room in House.ROOMS:
		if Rect2(room.x, room.y, room.w, room.h).has_point(pos):
			return room.name
	return "راهرو"


func toggle_pause() -> void:
	if started:
		paused = not paused
