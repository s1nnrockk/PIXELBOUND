extends CanvasLayer

var world: Node
var ambience_player: AudioStreamPlayer
var menu_player: AudioStreamPlayer
var ui_player: AudioStreamPlayer
var menu_root: Control
var settings_root: Control
var title_label: Label
var music_slider: HSlider
var ambience_slider: HSlider
var started := false
var footstep_timer := 0.0
var rng := RandomNumberGenerator.new()

func setup(game_world: Node) -> void:
	world = game_world
	rng.seed = 3102026
	_build_audio()
	_build_menu()
	_play_ambience()
	_play_menu_theme()

func _process(delta: float) -> void:
	if not started or world == null:
		return
	var character := world.get("character") as CharacterBody3D
	if character == null:
		return
	footstep_timer -= delta
	if bool(character.get("moving")) and character.is_on_floor() and footstep_timer <= 0.0:
		footstep_timer = 0.42 if Input.is_key_pressed(KEY_SHIFT) else 0.58
		ui_player.stream = _make_footstep()
		ui_player.play()

func _make_footstep() -> AudioStreamWAV:
	const RATE := 22050
	const DURATION := 0.16
	var samples := int(RATE * DURATION)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	var data := PackedByteArray()
	data.resize(samples * 2)
	var lowpass := 0.0
	for i in range(samples):
		var t := float(i) / RATE
		var envelope := exp(-t * 24.0) * (1.0 - exp(-t * 90.0))
		var noise := rng.randf_range(-1.0, 1.0)
		lowpass = lowpass * 0.78 + noise * 0.22
		var crunch := noise * 0.20 + lowpass * 0.32
		var thud := sin(TAU * (78.0 - 28.0 * t / DURATION) * t) * 0.20
		var sample := (crunch + thud) * envelope
		data.encode_s16(i * 2, int(clampf(sample, -0.9, 0.9) * 32767.0))
	wav.data = data
	return wav

func _build_audio() -> void:
	ambience_player = AudioStreamPlayer.new()
	ambience_player.name = "ForestAmbience"
	ambience_player.bus = "Master"
	ambience_player.volume_db = -12.0
	add_child(ambience_player)
	menu_player = AudioStreamPlayer.new()
	menu_player.name = "MenuAtmosphere"
	menu_player.bus = "Master"
	menu_player.volume_db = -20.0
	add_child(menu_player)
	ui_player = AudioStreamPlayer.new()
	ui_player.name = "UISounds"
	ui_player.bus = "Master"
	ui_player.volume_db = -9.0
	add_child(ui_player)

func _play_ambience() -> void:
	ambience_player.stream = _make_ambience()
	ambience_player.play()

func _play_menu_theme() -> void:
	menu_player.stream = _make_menu_theme()
	menu_player.play()

func _make_ambience() -> AudioStreamWAV:
	const RATE := 22050
	const SECONDS := 8
	var samples := RATE * SECONDS
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = samples
	var data := PackedByteArray()
	data.resize(samples * 2)
	var noise_state := 91371
	var wind := 0.0
	for i in range(samples):
		noise_state = (noise_state * 1103515245 + 12345) & 0x7fffffff
		var noise := float(noise_state % 65536) / 32768.0 - 1.0
		wind = wind * 0.992 + noise * 0.008
		var t := float(i) / RATE
		var swell := 0.65 + 0.35 * sin(TAU * t / 7.5)
		var sample := wind * 0.17 * swell
		sample += sin(TAU * 92.0 * t) * 0.012
		sample += sin(TAU * 137.0 * t + 0.3) * 0.008
		# Sparse, soft bird calls: short frequency sweeps in the upper register.
		for bird_start in [0.8, 2.7, 5.1, 6.4]:
			var bird_t := t - bird_start
			if bird_t >= 0.0 and bird_t < 0.34:
				var envelope := sin(PI * bird_t / 0.34)
				var frequency := 1700.0 + 900.0 * sin(PI * bird_t / 0.34)
				sample += sin(TAU * frequency * bird_t) * envelope * 0.045
		sample = clampf(sample, -0.85, 0.85)
		data.encode_s16(i * 2, int(sample * 32767.0))
	wav.data = data
	return wav

func _make_menu_theme() -> AudioStreamWAV:
	const RATE := 22050
	const SECONDS := 8
	var samples := RATE * SECONDS
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = samples
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / RATE
		var fade := 0.55 + 0.45 * sin(PI * t / SECONDS)
		var pad := sin(TAU * 110.0 * t) * 0.12
		pad += sin(TAU * 164.81 * t) * 0.08
		pad += sin(TAU * 220.0 * t) * 0.045
		pad += sin(TAU * 329.63 * t + 0.2) * 0.025
		var sample := pad * fade
		data.encode_s16(i * 2, int(clampf(sample, -0.8, 0.8) * 32767.0))
	wav.data = data
	return wav

func _make_ui_sound(frequency: float, duration: float, noise_amount: float) -> AudioStreamWAV:
	const RATE := 22050
	var samples := int(RATE * duration)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / RATE
		var envelope := exp(-t * 18.0)
		var noise := rng.randf_range(-1.0, 1.0) * noise_amount
		var tone := sin(TAU * frequency * t) * 0.35
		var sample := (tone + noise) * envelope
		data.encode_s16(i * 2, int(clampf(sample, -0.9, 0.9) * 32767.0))
	wav.data = data
	return wav

func _play_ui_sound(is_hover: bool = false) -> void:
	ui_player.stream = _make_ui_sound(780.0 if is_hover else 420.0, 0.075 if is_hover else 0.13, 0.04 if is_hover else 0.12)
	ui_player.play()

func _build_menu() -> void:
	menu_root = Control.new()
	menu_root.name = "MainMenu"
	menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu_root)

	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.035, 0.055, 0.76)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_root.add_child(shade)

	var glow := ColorRect.new()
	glow.color = Color(0.19, 0.34, 0.29, 0.13)
	glow.size = Vector2(560, 520)
	glow.position = Vector2(40, 10)
	glow.set_anchors_preset(Control.PRESET_CENTER)
	glow.position -= glow.size * 0.5
	menu_root.add_child(glow)

	var panel := PanelContainer.new()
	panel.name = "MenuCard"
	panel.custom_minimum_size = Vector2(420, 490)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-210, -245)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.055, 0.075, 0.085, 0.94)
	panel_style.border_color = Color(0.72, 0.64, 0.45, 0.48)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(22)
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
	panel_style.shadow_size = 24
	panel.add_theme_stylebox_override("panel", panel_style)
	menu_root.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("margin_left", 34)
	layout.add_theme_constant_override("margin_right", 34)
	panel.add_child(layout)

	var eyebrow := Label.new()
	eyebrow.text = "AN ATMOSPHERIC ADVENTURE"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size", 11)
	eyebrow.add_theme_color_override("font_color", Color("#b6a982"))
	layout.add_child(eyebrow)

	title_label = Label.new()
	title_label.text = "PIXELBOUND"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 46)
	title_label.add_theme_color_override("font_color", Color("#f0dfbd"))
	title_label.add_theme_color_override("font_shadow_color", Color("#9a7544"))
	title_label.add_theme_constant_override("shadow_offset_x", 0)
	title_label.add_theme_constant_override("shadow_offset_y", 3)
	layout.add_child(title_label)

	var subtitle := Label.new()
	subtitle.text = "Find your way through the quiet."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color("#b7c0b5"))
	layout.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 12
	layout.add_child(spacer)

	_add_button(layout, "BEGIN JOURNEY", _on_start_pressed, true)
	_add_button(layout, "SETTINGS", _on_settings_pressed, false)
	_add_button(layout, "QUIT", _on_quit_pressed, false)

	var footer := Label.new()
	footer.text = "WASD  ·  SPACE TO JUMP  ·  SHIFT TO RUN"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 10)
	footer.add_theme_color_override("font_color", Color("#758278"))
	layout.add_child(footer)

	menu_root.modulate.a = 0.0
	menu_root.scale = Vector2(0.96, 0.96)
	menu_root.pivot_offset = get_viewport_rect().size * 0.5
	var intro := create_tween().set_parallel(true)
	intro.tween_property(menu_root, "modulate:a", 1.0, 0.8)
	intro.tween_property(menu_root, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	title_label.pivot_offset = title_label.size * 0.5
	var title_tween := create_tween()
	title_tween.set_loops()
	title_tween.tween_property(title_label, "scale", Vector2(1.025, 1.025), 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	title_tween.tween_property(title_label, "scale", Vector2.ONE, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _add_button(parent: VBoxContainer, text_value: String, callback: Callable, primary: bool) -> void:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 52)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 15)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.29, 0.34, 0.29, 0.94) if primary else Color(0.10, 0.14, 0.14, 0.9)
	normal.border_color = Color("#b7a16c") if primary else Color(0.45, 0.52, 0.47, 0.5)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(12)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.39, 0.45, 0.36, 1.0) if primary else Color(0.17, 0.23, 0.21, 1.0)
	hover.border_color = Color("#e5d2a0")
	hover.shadow_color = Color(0.65, 0.55, 0.35, 0.16)
	hover.shadow_size = 8
	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.22, 0.28, 0.24, 1.0)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color("#f1eadb"))
	button.add_theme_color_override("font_hover_color", Color("#fff4d9"))
	button.pressed.connect(callback)
	button.mouse_entered.connect(_on_button_hover)
	parent.add_child(button)

func _on_start_pressed() -> void:
	if started:
		return
	started = true
	_play_ui_sound()
	var fade := create_tween()
	fade.tween_property(menu_root, "modulate:a", 0.0, 0.45)
	fade.parallel().tween_property(menu_root, "scale", Vector2(1.04, 1.04), 0.45)
	await fade.finished
	menu_player.stop()
	ambience_player.volume_db = -9.0
	menu_root.queue_free()
	world.call("start_game")

func _on_settings_pressed() -> void:
	_play_ui_sound()
	if settings_root != null:
		settings_root.queue_free()
		settings_root = null
		return
	settings_root = PanelContainer.new()
	settings_root.name = "SettingsPanel"
	settings_root.custom_minimum_size = Vector2(360, 250)
	settings_root.set_anchors_preset(Control.PRESET_CENTER)
	settings_root.position = Vector2(-180, -125)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.09, 0.09, 0.98)
	style.border_color = Color("#b7a16c")
	style.set_border_width_all(1)
	style.set_corner_radius_all(18)
	settings_root.add_theme_stylebox_override("panel", style)
	menu_root.add_child(settings_root)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	settings_root.add_child(layout)
	var heading := Label.new()
	heading.text = "SOUND SETTINGS"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 18)
	layout.add_child(heading)
	music_slider = _add_slider(layout, "Music", -35.0, 0.0, menu_player.volume_db)
	ambience_slider = _add_slider(layout, "Nature ambience", -35.0, 0.0, ambience_player.volume_db)
	music_slider.value_changed.connect(func(value: float): menu_player.volume_db = value)
	ambience_slider.value_changed.connect(func(value: float): ambience_player.volume_db = value)
	var back := Button.new()
	back.text = "BACK"
	back.custom_minimum_size.y = 42
	back.pressed.connect(func():
		_play_ui_sound()
		settings_root.queue_free()
		settings_root = null
	)
	layout.add_child(back)

func _add_slider(parent: VBoxContainer, caption: String, min_value: float, max_value: float, current: float) -> HSlider:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	var label := Label.new()
	label.text = caption
	label.add_theme_font_size_override("font_size", 12)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = 1.0
	slider.value = current
	row.add_child(slider)
	return slider

func _on_quit_pressed() -> void:
	_play_ui_sound()
	get_tree().quit()

func _on_button_hover() -> void:
	_play_ui_sound(true)
