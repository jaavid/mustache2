extends CanvasLayer
## Owns Persian presentation and touch actions. Emits intents; never mutates a round.
signal start_requested
signal pause_requested
signal investigate_requested
signal fire_requested
signal sound_toggled
signal motion_toggled
const Type = preload("res://scripts/typography.gd")
const Text = preload("res://scripts/game_text.gd")
const MustacheJoystick = preload("res://scripts/virtual_joystick.gd")
const Art = preload("res://scripts/character_art.gd")
var joystick: MustacheJoystick
var keyboard_legend: Label
var ui: Control
var status: Label
var room_label: Label
var roster: Array[PanelContainer] = []
var roster_names: Array[Label] = []
var roster_statuses: Array[Label] = []
var roster_marks: Array[Label] = []
var roster_faces: Array[TextureRect] = []
var metrics: Array[PanelContainer] = []
var metric_values: Array[Label] = []
var mission_label: Label
var ammo_label: Label
var menu_box: VBoxContainer
var menu_sound_button: Button
var menu_eyebrow: Label
var overlay: PanelContainer
var title: Label
var description: Label
var start_button: Button
var pause_button: Button
var sound_button: Button
var motion_button: Button
var search_button: Button
var fire_button: Button
var result_caption: Label
var _touch_layout := false
var _phase := ""
var _action_touches: Dictionary = {}


func _ready() -> void:
	build_ui()


func style(color: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(2 if border.a > 0 else 0)
	box.set_corner_radius_all(14)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box


func make_label(text: String, font_size: int = 18, weight: int = 400) -> Label:
	var label := Label.new()
	label.text = text
	Type.rtl(label, weight)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("f6ead2"))
	ui.add_child(label)
	return label


func make_button(text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.text_direction = Control.TEXT_DIRECTION_RTL
	b.language = "fa"
	b.custom_minimum_size = Vector2(54, 62)
	b.pressed.connect(callback)
	ui.add_child(b)
	return b


func themed_label(text: String, size: int, weight: int = 400, centered: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	Type.rtl(label, weight)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("fff4dc"))
	if centered:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func build_ui() -> void:
	ui = Control.new()
	ui.layout_direction = Control.LAYOUT_DIRECTION_RTL
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	var theme := Theme.new()
	theme.default_font = Type.font(400)
	theme.default_font_size = 18
	theme.set_font("font", "Button", Type.font(700))
	theme.set_stylebox("normal", "Button", style(Color("293149"), Color("64677d")))
	theme.set_stylebox("hover", "Button", style(Color("414960"), Color("ffd68d")))
	theme.set_stylebox("pressed", "Button", style(Color("723455"), Color("ffb7d1")))
	theme.set_stylebox("focus", "Button", style(Color.TRANSPARENT, Color("ffd68d")))
	theme.set_stylebox("panel", "PanelContainer", style(Color("192038"), Color("51586f")))
	ui.theme = theme
	room_label = make_label("شکارِ سیبیل", 20, 800)
	room_label.clip_text = true
	room_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status = make_label(Text.INITIAL_HINT, 17, 600)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pause_button = make_button("توقف", func(): pause_requested.emit())
	sound_button = make_button("صدا: روشن", func(): sound_toggled.emit())
	for caption in ["گرفته‌شده", "زمان باقی‌مانده", "امتیاز"]:
		var metric := PanelContainer.new()
		var metric_style := style(Color("27293f"), Color("45475c"))
		metric_style.content_margin_top = 4
		metric_style.content_margin_bottom = 4
		metric.add_theme_stylebox_override("panel", metric_style)
		ui.add_child(metric)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 0)
		metric.add_child(column)
		var label := themed_label(caption, 12, 600, true)
		label.add_theme_color_override("font_color", Color("c4c3c9"))
		column.add_child(label)
		var value := themed_label("۰", 21, 800, true)
		value.text_direction = Control.TEXT_DIRECTION_LTR
		column.add_child(value)
		metric_values.append(value)
		metrics.append(metric)
	mission_label = make_label("سه نفر، سه سیبیل!", 16, 800)
	mission_label.tooltip_text = "مأموریت ۰۱ / خانه مرموز\nقبل از پایان وقت، هر سه نفر را پیدا کن."
	for i in range(3):
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", style(Color("252940"), Color("44465c")))
		ui.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		card.add_child(row)
		var avatar_frame := PanelContainer.new()
		avatar_frame.custom_minimum_size = Vector2(48, 48)
		avatar_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var avatar_style := style(Art.AVATAR_COLORS[i])
		avatar_style.content_margin_left = 2
		avatar_style.content_margin_right = 2
		avatar_style.content_margin_top = 2
		avatar_style.content_margin_bottom = 2
		avatar_frame.add_theme_stylebox_override("panel", avatar_style)
		row.add_child(avatar_frame)
		var image := TextureRect.new()
		image.texture = Art.portrait(i)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		avatar_frame.add_child(image)
		roster_faces.append(image)
		var text_column := VBoxContainer.new()
		text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		text_column.add_theme_constant_override("separation", 0)
		row.add_child(text_column)
		var name_label := themed_label(Text.NAMES[i], 18, 800)
		text_column.add_child(name_label)
		roster_names.append(name_label)
		var state_label := themed_label("پنهان شده", 13, 500)
		state_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		state_label.add_theme_color_override("font_color", Color("b9b9c8"))
		text_column.add_child(state_label)
		roster_statuses.append(state_label)
		var mark := themed_label("؟", 23, 900, true)
		mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mark.add_theme_color_override("font_color", Color("ffd68d"))
		row.add_child(mark)
		roster_marks.append(mark)
		roster.append(card)
	joystick = MustacheJoystick.new()
	ui.add_child(joystick)
	keyboard_legend = make_label("حرکت: \u2066WASD\u2069\nدویدن: \u2066SHIFT\u2069", 14, 600)
	search_button = make_button("بگرد", func(): investigate_requested.emit())
	fire_button = make_button("شلیک", func(): fire_requested.emit())
	search_button.tooltip_text = "جست‌وجو · E"
	fire_button.tooltip_text = "شلیک سیبیل · Space"
	search_button.focus_mode = Control.FOCUS_NONE
	fire_button.focus_mode = Control.FOCUS_NONE
	ammo_label = make_label("سیبیل‌پرتاب‌کن\nدقت: —", 14, 700)
	overlay = PanelContainer.new()
	ui.add_child(overlay)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	overlay.add_child(scroll)
	menu_box = VBoxContainer.new()
	menu_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_box.add_theme_constant_override("separation", 9)
	scroll.add_child(menu_box)
	menu_eyebrow = themed_label("THE GREAT MUSTACHE HUNT", 12, 800, true)
	menu_eyebrow.text_direction = Control.TEXT_DIRECTION_LTR
	menu_eyebrow.add_theme_color_override("font_color", Color("ffcadf"))
	menu_box.add_child(menu_eyebrow)
	var step := themed_label("مرحله اول · خانه مرموز", 14, 700, true)
	step.add_theme_color_override("font_color", Color("a0edcc"))
	menu_box.add_child(step)
	title = themed_label("شکار سیبیل آغاز شد!", 30, 900, true)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_box.add_child(title)
	description = themed_label(Text.INTRO_DESCRIPTION, 16, 500, true)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_box.add_child(description)
	var instructions := HBoxContainer.new()
	instructions.add_theme_constant_override("separation", 8)
	menu_box.add_child(instructions)
	for i in range(3):
		var item := themed_label(
			["۰۱ · بگرد و کشف کن", "۰۲ · دنبالشون بدو", "۰۳ · روی لب بزن!"][i], 13, 650, true
		)
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		instructions.add_child(item)
	var controls := themed_label(Text.CONTROLS, 12, 500, true)
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_box.add_child(controls)
	start_button = Button.new()
	start_button.text = "شروع بازی"
	start_button.add_theme_font_override("font", Type.font(900))
	start_button.add_theme_stylebox_override("normal", style(Color("d95490"), Color("ffb7d1")))
	start_button.custom_minimum_size.y = 62
	start_button.pressed.connect(func(): start_requested.emit())
	menu_box.add_child(start_button)
	menu_sound_button = Button.new()
	menu_sound_button.custom_minimum_size.y = 52
	menu_sound_button.pressed.connect(func(): sound_toggled.emit())
	menu_box.add_child(menu_sound_button)
	motion_button = Button.new()
	motion_button.custom_minimum_size.y = 48
	motion_button.pressed.connect(func(): motion_toggled.emit())
	menu_box.add_child(motion_button)
	var footer := themed_label(
		"بازی دوبعدی · رامین، برهان، ممد · بدون نصب و ثبت‌نام", 12, 400, true
	)
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_box.add_child(footer)
	result_caption = themed_label("", 14, 800, true)
	menu_box.add_child(result_caption)


func resize_layout() -> void:
	var size := get_viewport().get_visible_rect().size
	ui.size = size
	ui.position = Vector2.ZERO
	room_label.size = Vector2(250, 40)
	room_label.position = Vector2(size.x - 270, 12)
	pause_button.size = Vector2(78, 52)
	pause_button.position = Vector2(16, 12)
	sound_button.size = Vector2(124, 52)
	sound_button.position = Vector2(104, 12)
	for i in range(3):
		metrics[i].size = Vector2((size.x - 44) / 3, 80)
		metrics[i].position = Vector2(size.x - 16 - (i + 1) * (size.x - 32) / 3, 66)
	mission_label.size = Vector2(size.x - 32, 32)
	mission_label.position = Vector2(16, 148)
	for i in range(3):
		roster[i].size = Vector2((size.x - 44) / 3, 76)
		roster[i].position = Vector2(size.x - 16 - (i + 1) * (size.x - 32) / 3, 184)
		roster_statuses[i].visible = size.x >= 720
	_touch_layout = size.x < 900 or DisplayServer.is_touchscreen_available()
	joystick.reset()
	joystick.size = Vector2(180, 180)
	joystick.position = Vector2(24, size.y - 270)
	keyboard_legend.size = Vector2(210, 90)
	keyboard_legend.position = Vector2(24, size.y - 180)
	keyboard_legend.visible = not _touch_layout
	search_button.size = Vector2(126, 64)
	search_button.position = Vector2(size.x - 246, size.y - 150)
	fire_button.size = Vector2(94, 64)
	fire_button.position = Vector2(size.x - 110, size.y - 150)
	ammo_label.size = Vector2(230, 70)
	ammo_label.position = Vector2(size.x - 250, size.y - 224)
	status.size = Vector2(size.x - 40, 68)
	status.position = Vector2(20, size.y - 74)
	overlay.size.x = minf(size.x - 36, 550)
	overlay.position.x = (size.x - overlay.size.x) / 2
	fit_overlay.call_deferred()


func fit_overlay() -> void:
	await get_tree().process_frame
	if not is_instance_valid(overlay):
		return
	var size := get_viewport().get_visible_rect().size
	overlay.size.y = minf(menu_box.get_combined_minimum_size().y + 24, size.y - 32)
	overlay.position.y = maxf(16, (size.y - overlay.size.y) / 2)


func present(round: RefCounted, preferences: RefCounted) -> void:
	if metric_values.is_empty():
		return
	room_label.text = "شکارِ سیبیل · " + round.room_name(round.player)
	metric_values[0].text = Text.number(round.caught) + " / ۳"
	metric_values[1].text = Text.number(
		"%02d:%02d" % [int(round.time_left) / 60, int(round.time_left) % 60]
	)
	metric_values[2].text = Text.number(round.score)
	status.text = "یه لحظه استراحت!" if round.paused else round.hint
	pause_button.text = "ادامه" if round.paused else "توقف"
	sound_button.text = "صدا: " + ("خاموش" if preferences.muted else "روشن")
	menu_sound_button.text = sound_button.text
	motion_button.text = "حرکت کمتر: " + ("روشن" if preferences.reduced_motion else "خاموش")
	result_caption.text = (
		"بهترین رکورد شما: " + Text.number(preferences.best) if preferences.best > 0 else ""
	)
	ammo_label.text = (
		"سیبیل‌پرتاب‌کن\n"
		+ (
			"دقت: " + Text.number(roundi(100.0 * round.caught / round.fired)) + "٪"
			if round.fired > 0
			else "دقت: —"
		)
	)
	for i in range(3):
		var actor_state: String = round.actors[i].state if round.actors.size() == 3 else "hidden"
		var caption: String = (
			"گرفته شد"
			if actor_state == "captured"
			else (
				["به سمت میز فرار می‌کند!", "دورت می‌زند!", "حواست را پرت می‌کند!"][i]
				if actor_state == "fleeing"
				else ("زیر وسایل پنهان است" if i == 0 else "پنهان شده")
			)
		)
		roster_statuses[i].text = caption
		roster_marks[i].text = (
			"✓" if actor_state == "captured" else ("!" if actor_state == "fleeing" else "؟")
		)
		roster[i].tooltip_text = Text.NAMES[i] + " · " + caption
		var color := (
			Color("a0edcc")
			if actor_state == "captured"
			else (Color("ff6fa7") if actor_state == "fleeing" else Color("ffd68d"))
		)
		roster_marks[i].add_theme_color_override("font_color", color)

	var active: bool = round.started and not round.paused
	joystick.visible = _touch_layout and active
	search_button.disabled = not active
	fire_button.disabled = not active
	_present_phase(round)


func _present_phase(round: RefCounted) -> void:
	var phase: String = (
		"paused"
		if round.paused
		else (
			"playing"
			if round.started
			else (round.outcome if not round.outcome.is_empty() else "menu")
		)
	)
	if phase == _phase:
		return
	_phase = phase
	joystick.reset()
	if phase == "playing":
		overlay.hide()
		get_viewport().gui_release_focus()
		return
	if phase != "menu":
		var copy := Text.phase_copy(phase, round.score, round.caught)
		title.text = copy.title
		description.text = copy.description
		menu_eyebrow.text = copy.eyebrow
		start_button.text = copy.action
	overlay.show()
	fit_overlay.call_deferred()
	if phase != "menu":
		start_button.grab_focus()


func _action_buttons() -> Array:
	return (
		[start_button, menu_sound_button, motion_button]
		if overlay.visible
		else [pause_button, sound_button, search_button, fire_button]
	)


func _input(event: InputEvent) -> void:
	# Keep native mouse/keyboard buttons, but do not activate them twice for one touch.
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		for button in _action_buttons():
			if button.is_visible_in_tree() and button.get_global_rect().has_point(event.position):
				get_viewport().set_input_as_handled()
				return
		return
	# Finger 2 can use these actions while finger 1 owns the movement pad.
	if not event is InputEventScreenTouch:
		return
	if _action_touches.has(event.index):
		if not event.pressed or event.canceled:
			_action_touches.erase(event.index)
		get_viewport().set_input_as_handled()
		return
	if not event.pressed or event.canceled:
		return
	for button in _action_buttons():
		if (
			button.is_visible_in_tree()
			and not button.disabled
			and button.get_global_rect().has_point(event.position)
		):
			_action_touches[event.index] = true
			button.pressed.emit()
			get_viewport().set_input_as_handled()
			return


func release_touch() -> void:
	_action_touches.clear()
	joystick.reset()
