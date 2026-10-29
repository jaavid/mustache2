extends SceneTree
var count := 0
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	count += 1
	if not condition:
		push_error("FAIL: " + message)
		failures += 1


func run() -> void:
	var Model = load("res://scripts/round_model.gd")
	var Navigation = load("res://scripts/navigation.gd")
	if Model == null or not Model.can_instantiate():
		quit(1)
		return
	var scene = Model.new(Navigation.new())
	scene.reset()
	check(scene.House.ROOMS.size() == 6, "six original rooms")
	check(scene.House.FURNITURE.size() == 13, "all original furniture")
	check(scene.actors.size() == 3, "three characters")
	check(
		scene.House.SPOTS.any(
			func(s): return s.cover == "table" and scene.actors[0].pos == Vector2(s.x, s.y)
		),
		"Ramin starts at table cover"
	)
	check(
		scene.actors[0].pos != scene.actors[1].pos and scene.actors[1].pos != scene.actors[2].pos,
		"distinct starting spots"
	)
	check(scene.obstructed(Vector2(160, 220)), "furniture collision")
	check(not scene.obstructed(Vector2(320, 452)), "player spawn is free")
	check(
		scene.move_safe(Vector2(120, 235), Vector2(150, 0), 19).x < 125,
		"fast movement cannot tunnel into sofa"
	)
	# Every hideout must be reachable from every other one. Check each route's segments.
	for from in scene.House.SPOTS:
		for to in scene.House.SPOTS:
			var origin := Vector2(from.x, from.y)
			var route: PackedVector2Array = scene.nav.route(origin, Vector2(to.x, to.y))
			check(not route.is_empty(), "reachable hideout pair")
			for point in route:
				check(scene.nav.clear_segment(origin, point), "route respects obstacle clearance")
				origin = point
	var a: Dictionary = scene.actors[0]
	scene.player = a.pos + Vector2(70, 0)
	scene.inspect()
	check(a.state == "fleeing", "investigation reveals nearby hider")
	a.pos = Vector2(320, 452)
	a.chase = 10.0
	a.target = Vector2(1217, 288)
	a.cover = true
	scene.player = Vector2(1260, 850)
	check(not scene.nav.can_rehide(a, scene.player), "no disappearing before reaching cover")
	a.pos = a.target
	check(scene.nav.can_rehide(a, scene.player), "rehide only at distant physical cover")
	a.cover = false
	check(not scene.nav.can_rehide(a, scene.player), "flank waypoint is not physical cover")
	a.pos = Vector2(320, 452)
	var cover: Dictionary = scene.nav.cover(a, Vector2(260, 435))
	check(not cover.is_empty() and cover.cover, "Ramin selects reachable cover")
	var flank: Dictionary = scene.nav.flank(scene.actors[1], Vector2(320, 452))
	check(
		not flank.is_empty() and not flank.path.is_empty(),
		"Borhan selects traversable flank or fallback"
	)
	# A fake clue disappears on inspection without affecting score or capture count.
	scene.player = Vector2(320, 452)
	for actor in scene.actors:
		actor.pos = Vector2(1264, 834)
	scene.decoys = [{"pos": Vector2(330, 452), "life": 8.0}]
	scene.inspect()
	check(scene.decoys.is_empty() and scene.score == 0 and scene.caught == 0, "decoys never score")
	var trickster: Dictionary = scene.actors[2]
	trickster.pos = Vector2(1264, 834)
	scene.make_false_noise(trickster)
	check(
		scene.decoys.size() == 1 and scene.decoys[0].pos.distance_to(trickster.pos) > 210,
		"Mammad creates remote clue"
	)
	# Stationary impact test avoids movement noise and uses the original ellipse and score.
	a.pos = Vector2(350, 350)
	a.state = "fleeing"
	var lip: Vector2 = scene.lip(a)
	scene.shots = [
		{"pos": lip - Vector2(80, 0), "velocity": Vector2(780, 0), "life": 0.85, "trail": []}
	]
	scene.fired = 1
	scene.update_shots(0.15)
	check(
		a.state == "captured" and scene.score == 1540 and scene.caught == 1,
		"swept lip capture and baseline score"
	)
	scene.shots = [
		{"pos": Vector2(120, 235), "velocity": Vector2(780, 0), "life": 0.85, "trail": []}
	]
	scene.update_shots(0.2)
	check(scene.shots.is_empty() and scene.score == 1540, "wall blocks projectile with no points")
	scene.toggle_pause()
	var before: float = scene.time_left
	scene.step(1.0)
	check(scene.paused and scene.time_left == before, "pause freezes timer with overlay")
	scene.toggle_pause()
	check(not scene.paused, "pause resumes without restart")
	scene.time_left = 0.01
	scene.step(0.02)
	check(not scene.started, "timer expiry")
	scene.reset()
	check(
		(
			scene.caught == 0
			and scene.score == 0
			and scene.fired == 0
			and scene.decoys.is_empty()
			and scene.time_left == 180.0
		),
		"full round reset"
	)
	check(
		not ProjectSettings.get_setting("application/boot_splash/show_image"),
		"default engine splash disabled"
	)
	print(
		(
			("PASS" if failures == 0 else "FAIL")
			+ (": %d model checks (routes, NPCs, impacts, scoring, lifecycle)" % count)
		)
	)
	scene = null
	await process_frame
	quit(0 if failures == 0 else 1)
