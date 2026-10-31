extends Node3D

@onready var character: CharacterBody3D = $Character
@onready var camera: Camera3D = $Camera3D

const WORLD_HALF := 1280.0
const PATH_WIDTH := 2.2
const PATH_STEP := 1.25

var camera_origin := Vector3(0.0, 4.8, 8.5)
var intro_label: Label
var parallax_layers: Array[Node3D] = []
var path_points: Array[Vector3] = []
var rng := RandomNumberGenerator.new()
var hearts := 3
var deaths := 0
var damage_cooldown := 0.0
var pickup_positions: Array[Vector3] = []
var pickup_nodes: Array[Node3D] = []
var hearts_label: Label
var deaths_label: Label
var hud_layer: CanvasLayer

var grass_material: StandardMaterial3D
var path_material: StandardMaterial3D
var path_edge_material: StandardMaterial3D

func _ready() -> void:
	rng.seed = 9042026
	character.global_position = Vector3(-4.45, 0.0, -5.1)
	character.controls_enabled = false
	_build_forest()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 5.8
	camera.current = true
	camera.global_position = character.global_position + camera_origin
	camera.look_at(character.global_position + Vector3(0.0, 0.9, 0.0), Vector3.UP)
	_build_intro_caption()
	_play_house_exit()

func _process(delta: float) -> void:
	damage_cooldown = maxf(0.0, damage_cooldown - delta)
	_update_health_gameplay(delta)
	var target := character.global_position
	var desired := Vector3(target.x, camera_origin.y, target.z + camera_origin.z)
	camera.global_position = camera.global_position.lerp(desired, 1.0 - exp(-delta * 3.2))
	camera.look_at(target + Vector3(0.0, 0.9, 0.0), Vector3.UP)
	for i in range(parallax_layers.size()):
		var layer := parallax_layers[i]
		var factor := 0.12 + float(i) * 0.12
		layer.position.x = -target.x * factor
		layer.position.z = -target.z * factor * 0.35

func _build_intro_caption() -> void:
	var layer := CanvasLayer.new()
	layer.name = "IntroCaption"
	add_child(layer)
	intro_label = Label.new()
	intro_label.text = "PIXELBOUND  |  A NEW JOURNEY"
	intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_label.anchor_left = 0.0
	intro_label.anchor_right = 1.0
	intro_label.anchor_top = 0.78
	intro_label.anchor_bottom = 0.92
	intro_label.add_theme_font_size_override("font_size", 24)
	intro_label.add_theme_color_override("font_color", Color("#f4dfbd"))
	intro_label.add_theme_color_override("font_shadow_color", Color("#171b24"))
	intro_label.add_theme_constant_override("shadow_offset_x", 2)
	intro_label.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(intro_label)
	intro_label.modulate.a = 0.0
	var fade := create_tween()
	fade.tween_property(intro_label, "modulate:a", 1.0, 0.8)
	fade.tween_interval(2.0)
	fade.tween_property(intro_label, "modulate:a", 0.0, 1.0)

func _play_house_exit() -> void:
	await get_tree().create_timer(0.7).timeout
	var walk := create_tween()
	walk.set_trans(Tween.TRANS_SINE)
	walk.set_ease(Tween.EASE_IN_OUT)
	walk.tween_property(character, "global_position", Vector3(-4.45, 0.0, -1.65), 2.6)
	await walk.finished
	var zoom := create_tween()
	zoom.set_trans(Tween.TRANS_SINE)
	zoom.set_ease(Tween.EASE_OUT)
	zoom.tween_property(camera, "size", 7.6, 1.1)
	await zoom.finished
	character.controls_enabled = true
	if is_instance_valid(intro_label):
		intro_label.queue_free()

func _build_forest() -> void:
	grass_material = _mat(Color("#243d32"))
	path_material = _mat(Color("#796044"))
	path_edge_material = _mat(Color("#a18a61"))
	_add_ground()
	_build_long_trail()
	_build_house(Vector3(-5.0, 0.0, -5.0))
	_build_house(Vector3(280.0, 0.0, -210.0))
	_build_house(Vector3(-310.0, 0.0, 210.0))
	_build_house(Vector3(320.0, 0.0, 320.0))
	_build_lake_and_bridge(Vector3(42.0, 0.0, -30.0))
	_build_ruins(Vector3(-54.0, 0.0, -62.0))
	_build_watchtower(Vector3(62.0, 0.0, 48.0))
	_build_camp(Vector3(-48.0, 0.0, 52.0))
	_build_mushroom_glade(Vector3(18.0, 0.0, 72.0))
	_build_frontier_landmarks()
	_build_tree_population()
	_build_npc(Vector3(2.0, 0.0, -1.0), Color("#d18b55"), Color("#4c6b8b"))
	_build_npc(Vector3(-1.0, 0.0, 2.5), Color("#c7a56b"), Color("#6b4d76"))
	_build_npc(Vector3(39.0, 0.0, -26.0), Color("#c99b7a"), Color("#536f58"))
	_build_npc(Vector3(-51.0, 0.0, -59.0), Color("#b7a0d2"), Color("#8a553f"))
	_build_npc_variant(Vector3(280.0, 0.0, -210.0), 0, Color("#d9a77a"), Color("#5b7e91"))
	_build_npc_variant(Vector3(-310.0, 0.0, 210.0), 1, Color("#9c684c"), Color("#8c6b3f"))
	_build_npc_variant(Vector3(320.0, 0.0, 320.0), 2, Color("#e0bd91"), Color("#7a4d67"))
	_build_npc_variant(Vector3(-320.0, 0.0, -250.0), 3, Color("#b88b68"), Color("#435c70"))
	_build_npc_variant(Vector3(150.0, 0.0, 150.0), 4, Color("#c7a27b"), Color("#6e7b49"))
	_build_npc_variant(Vector3(-160.0, 0.0, -120.0), 5, Color("#8e624d"), Color("#78604d"))
	_build_lantern(Vector3(0.8, 0.0, -2.4))
	_build_lantern(Vector3(-0.8, 0.0, 3.4))
	_build_parallax_horizon()
	_build_heart_pickups()
	_build_health_hud()


func _build_health_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "HealthHUD"
	add_child(hud_layer)
	hearts_label = Label.new()
	hearts_label.position = Vector2(12.0, 8.0)
	hearts_label.add_theme_font_size_override("font_size", 22)
	hearts_label.add_theme_color_override("font_color", Color("#ffcfb5"))
	hearts_label.add_theme_color_override("font_shadow_color", Color("#261b2a"))
	hearts_label.add_theme_constant_override("shadow_offset_x", 2)
	hearts_label.add_theme_constant_override("shadow_offset_y", 2)
	hud_layer.add_child(hearts_label)
	deaths_label = Label.new()
	deaths_label.position = Vector2(12.0, 34.0)
	deaths_label.add_theme_font_size_override("font_size", 11)
	deaths_label.add_theme_color_override("font_color", Color("#e4d8c7"))
	hud_layer.add_child(deaths_label)
	_update_health_hud()

func _update_health_hud() -> void:
	if hearts_label == null:
		return
	var heart_text := ""
	for i in range(3):
		heart_text += "♥ " if i < hearts else "♡ "
	hearts_label.text = heart_text
	deaths_label.text = "Падения: %d / 3" % deaths

func _update_health_gameplay(delta: float) -> void:
	if not is_instance_valid(character):
		return
	var p := character.global_position
	var in_ruins := Vector2(p.x + 54.0, p.z + 62.0).length() < 7.0
	var in_bone_arch := Vector2(p.x - 850.0, p.z - 720.0).length() < 9.0
	var off_trail := not _near_path(p, 3.0) and not _near_landmark(p, 8.0)
	if damage_cooldown <= 0.0 and (in_ruins or in_bone_arch or (off_trail and rng.randf() < delta * 0.035)):
		_take_damage()

	for i in range(pickup_positions.size()):
		if pickup_nodes[i] == null:
			continue
		if character.global_position.distance_to(pickup_positions[i]) < 1.8:
			if hearts < 3:
				hearts += 1
			pickup_nodes[i].queue_free()
			pickup_nodes[i] = null
			_update_health_hud()

func _take_damage() -> void:
	if hearts <= 0:
		return
	hearts -= 1
	damage_cooldown = 2.5
	_update_health_hud()
	if hearts <= 0:
		deaths += 1
		character.global_position = Vector3(0.0, 0.0, 0.0)
		hearts = 3
		damage_cooldown = 3.0
		if deaths >= 3:
			deaths = 0
			# Three deaths restart the journey at the first location.
			character.global_position = Vector3(0.0, 0.0, 0.0)
		_update_health_hud()

func _build_heart_pickups() -> void:
	var cabins := [
		Vector3(280.0, 0.0, -210.0),
		Vector3(-310.0, 0.0, 210.0),
		Vector3(320.0, 0.0, 320.0)
	]
	cabins.shuffle()
	for i in range(2):
		var p: Vector3 = cabins[i] + Vector3(rng.randf_range(-1.0, 1.0), 0.0, 1.8)
		pickup_positions.append(p + Vector3(0.0, 0.8, 0.0))
		pickup_nodes.append(_make_heart_pickup(p))

func _make_heart_pickup(pos: Vector3) -> Node3D:
	var pickup := Node3D.new()
	pickup.name = "HiddenHeart"
	pickup.position = pos
	var image := Image.create(9, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for x in [1, 2, 3, 5, 6, 7]:
		for y in [1, 2]:
			image.set_pixel(x, y, Color("#ff7892"))
	for x in range(1, 8):
		for y in range(2, 7):
			if (x >= 2 and x <= 6) or y >= 4:
				image.set_pixel(x, y, Color("#ff7892"))
	var sprite := Sprite3D.new()
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.pixel_size = 0.12
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	pickup.add_child(sprite)
	add_child(pickup)
	return pickup

func _add_ground() -> void:
	var ground := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(WORLD_HALF * 2.0 + 40.0, WORLD_HALF * 2.0 + 40.0)
	ground.mesh = mesh
	ground.material_override = grass_material
	ground.position.y = -0.12
	add_child(ground)

func _build_long_trail() -> void:
	var waypoints := [
		Vector3(-5.0, 0.0, -5.0),
		Vector3(4.0, 0.0, -18.0),
		Vector3(20.0, 0.0, -26.0),
		Vector3(42.0, 0.0, -30.0),
		Vector3(55.0, 0.0, -12.0),
		Vector3(38.0, 0.0, 8.0),
		Vector3(14.0, 0.0, 20.0),
		Vector3(-12.0, 0.0, 30.0),
		Vector3(-34.0, 0.0, 42.0),
		Vector3(-48.0, 0.0, 52.0),
		Vector3(-32.0, 0.0, 70.0),
		Vector3(-6.0, 0.0, 82.0),
		Vector3(18.0, 0.0, 72.0),
		Vector3(40.0, 0.0, 58.0),
		Vector3(62.0, 0.0, 48.0),
		Vector3(78.0, 0.0, 28.0),
		Vector3(70.0, 0.0, 4.0),
		Vector3(54.0, 0.0, -18.0),
		Vector3(42.0, 0.0, -30.0)
	]
	for segment in range(waypoints.size() - 1):
		var a: Vector3 = waypoints[segment]
		var b: Vector3 = waypoints[segment + 1]
		var length := Vector2(b.x - a.x, b.z - a.z).length()
		var steps := maxi(1, int(ceil(length / PATH_STEP)))
		for step in range(steps):
			var t := float(step) / float(steps)
			var point: Vector3 = a.lerp(b, t)
			var direction := Vector2(b.x - a.x, b.z - a.z).normalized()
			var side := Vector2(-direction.y, direction.x)
			point.x += side.x * sin(t * PI) * 1.4
			point.z += side.y * sin(t * PI) * 1.4
			path_points.append(point)
			var tile := MeshInstance3D.new()
			var tile_mesh := BoxMesh.new()
			tile_mesh.size = Vector3(PATH_WIDTH + rng.randf_range(-0.12, 0.18), 0.045, PATH_STEP + 0.12)
			tile.mesh = tile_mesh
			tile.material_override = path_material if rng.randf() > 0.16 else path_edge_material
			tile.position = Vector3(point.x, -0.035, point.z)
			tile.rotation.y = atan2(direction.x, direction.y)
			add_child(tile)
			if step % 5 == 0:
				_add_path_stone(point, side)

func _add_path_stone(point: Vector3, side: Vector2) -> void:
	var offset := rng.randf_range(1.5, 2.8) * (1.0 if rng.randf() > 0.5 else -1.0)
	var stone := _box_mesh("TrailStone", Vector3(point.x + side.x * offset, 0.06, point.z + side.y * offset), Vector3(rng.randf_range(0.18, 0.42), 0.12, rng.randf_range(0.18, 0.38)), _mat(Color("#526052")))


func _build_frontier_landmarks() -> void:
	_build_remote_trail(Vector3(62.0, 0.0, 48.0), Vector3(720.0, 0.0, -650.0))
	_build_remote_trail(Vector3(-48.0, 0.0, 52.0), Vector3(-760.0, 0.0, 620.0))
	_build_remote_trail(Vector3(62.0, 0.0, 48.0), Vector3(850.0, 0.0, 720.0))
	_build_remote_trail(Vector3(-54.0, 0.0, -62.0), Vector3(-820.0, 0.0, -760.0))
	_build_crystal_quarry(Vector3(720.0, 0.0, -650.0))
	_build_flooded_village(Vector3(-760.0, 0.0, 620.0))
	_build_bone_arch(Vector3(850.0, 0.0, 720.0))
	_build_frozen_shrine(Vector3(-820.0, 0.0, -760.0))
	_build_npc_variant(Vector3(720.0, 0.0, -650.0), 2, Color("#d9a77a"), Color("#554d78"))
	_build_npc_variant(Vector3(-760.0, 0.0, 620.0), 1, Color("#9c684c"), Color("#547b75"))
	_build_npc_variant(Vector3(850.0, 0.0, 720.0), 5, Color("#e0bd91"), Color("#7a4d67"))
	_build_npc_variant(Vector3(-820.0, 0.0, -760.0), 3, Color("#b88b68"), Color("#435c70"))

func _build_remote_trail(start: Vector3, finish: Vector3) -> void:
	var direction := Vector2(finish.x - start.x, finish.z - start.z).normalized()
	var steps := int(ceil(start.distance_to(finish) / 4.0))
	for i in range(steps):
		var point := start.lerp(finish, float(i) / float(steps))
		var tile := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(2.5, 0.05, 4.0)
		tile.mesh = mesh
		tile.material_override = path_material if i % 7 != 0 else path_edge_material
		tile.position = Vector3(point.x, -0.04, point.z)
		tile.rotation.y = atan2(direction.x, direction.y)
		add_child(tile)
		path_points.append(point)

func _build_crystal_quarry(pos: Vector3) -> void:
	var rock := _mat(Color("#4c5664"))
	var crystal := _mat(Color("#7bd2d0"), 0.8)
	for i in range(18):
		var a := TAU * i / 18.0
		var p := pos + Vector3(cos(a) * rng.randf_range(8.0, 24.0), 0.0, sin(a) * rng.randf_range(8.0, 24.0))
		_box_mesh("QuarryRock", p + Vector3(0.0, 1.0, 0.0), Vector3(rng.randf_range(3.0, 7.0), 2.0, rng.randf_range(3.0, 7.0)), rock)
		_box_mesh("CrystalCluster", p + Vector3(0.0, 2.2, 0.0), Vector3(0.8, rng.randf_range(2.0, 5.0), 0.8), crystal)
		_box_mesh("CrystalShard", p + Vector3(1.0, 1.8, 0.5), Vector3(0.45, 2.8, 0.45), crystal)

func _build_flooded_village(pos: Vector3) -> void:
	var wood := _mat(Color("#5d5145"))
	var water := _mat(Color("#345e68"), 0.2)
	for i in range(8):
		var x := -24.0 + float(i % 4) * 16.0
		var z := -18.0 + float(i / 4) * 36.0
		var p := pos + Vector3(x, 0.0, z)
		var pool := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 7.0
		mesh.bottom_radius = 7.0
		mesh.height = 0.08
		pool.mesh = mesh
		pool.material_override = water
		pool.position = p
		add_child(pool)
		_box_mesh("StiltHouse", p + Vector3(0.0, 2.0, 0.0), Vector3(7.0, 3.0, 6.0), wood)
		for xpost in [-2.5, 2.5]:
			for zpost in [-2.0, 2.0]:
				_box_mesh("Stilt", p + Vector3(xpost, 0.9, zpost), Vector3(0.35, 1.8, 0.35), wood)
	for i in range(50):
		_box_mesh("VillageWalkway", pos + Vector3(-40.0 + i * 1.6, 1.2, 0.0), Vector3(1.5, 0.18, 2.0), _mat(Color("#80664a")))

func _build_bone_arch(pos: Vector3) -> void:
	var bone := _mat(Color("#c8bea2"))
	for side in [-1.0, 1.0]:
		_box_mesh("GiantRib", pos + Vector3(side * 7.0, 5.0, 0.0), Vector3(1.2, 10.0, 1.2), bone)
		_box_mesh("ArchFoot", pos + Vector3(side * 7.0, 0.7, 0.0), Vector3(3.0, 1.4, 3.0), bone)
	_box_mesh("BoneLintel", pos + Vector3(0.0, 10.0, 0.0), Vector3(16.0, 1.5, 2.0), bone)
	for i in range(12):
		var p := pos + Vector3(rng.randf_range(-16.0, 16.0), 0.3, rng.randf_range(-14.0, 14.0))
		_box_mesh("Fossil", p, Vector3(1.4, 0.6, 2.0), bone)

func _build_frozen_shrine(pos: Vector3) -> void:
	var ice := _mat(Color("#9ac8d6"), 0.35)
	var stone := _mat(Color("#596875"))
	_box_mesh("ShrinePlatform", pos + Vector3(0.0, 0.4, 0.0), Vector3(18.0, 0.8, 18.0), stone)
	for i in range(6):
		var a := TAU * i / 6.0
		_box_mesh("IceObelisk", pos + Vector3(cos(a) * 7.0, 3.5, sin(a) * 7.0), Vector3(1.4, 7.0, 1.4), ice)
	_box_mesh("ShrineCore", pos + Vector3(0.0, 2.5, 0.0), Vector3(3.0, 5.0, 3.0), ice)

func _build_tree_population() -> void:
	var species := [
		{"trunk": Color("#49372e"), "crown": Color("#254d3b"), "height": 3.6, "width": 2.1, "kind": 0},
		{"trunk": Color("#584233"), "crown": Color("#356044"), "height": 2.8, "width": 2.8, "kind": 1},
		{"trunk": Color("#3d342d"), "crown": Color("#41694a"), "height": 4.4, "width": 1.8, "kind": 2},
		{"trunk": Color("#66513a"), "crown": Color("#5b7545"), "height": 2.4, "width": 2.4, "kind": 3}
	]
	var trunk_meshes: Array[Mesh] = []
	var crown_meshes: Array[Mesh] = []
	var trunk_mats: Array[Material] = []
	var crown_mats: Array[Material] = []
	for data in species:
		var trunk := BoxMesh.new()
		trunk.size = Vector3(0.32, float(data.height) * 0.42, 0.32)
		trunk_meshes.append(trunk)
		var crown := BoxMesh.new()
		crown.size = Vector3(float(data.width), float(data.height) * 0.52, float(data.width))
		crown_meshes.append(crown)
		trunk_mats.append(_mat(data.trunk))
		crown_mats.append(_mat(data.crown))
	var trunk_batches: Array[MultiMeshInstance3D] = []
	var crown_batches: Array[MultiMeshInstance3D] = []
	var trunks: Array[MultiMesh] = []
	var crowns: Array[MultiMesh] = []
	for i in range(species.size()):
		var trunk_batch := _new_multimesh(trunk_meshes[i], trunk_mats[i], "TreeTrunks_%d" % i)
		var crown_batch := _new_multimesh(crown_meshes[i], crown_mats[i], "TreeCanopies_%d" % i)
		trunk_batches.append(trunk_batch)
		crown_batches.append(crown_batch)
		trunks.append(trunk_batch.multimesh)
		crowns.append(crown_batch.multimesh)
	var trunk_transforms := [[], [], [], []]
	var crown_transforms := [[], [], [], []]
	for n in range(45000):
		var x := rng.randf_range(-WORLD_HALF, WORLD_HALF)
		var z := rng.randf_range(-WORLD_HALF, WORLD_HALF)
		var point := Vector3(x, 0.0, z)
		if _near_path(point, 4.5) or _near_landmark(point, 10.0):
			continue
		var species_index := rng.randi_range(0, species.size() - 1)
		var data: Dictionary = species[species_index]
		var scale := rng.randf_range(0.72, 1.38)
		var height := float(data.height) * scale
		var yaw := rng.randf_range(0.0, TAU)
		trunk_transforms[species_index].append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(scale, scale, scale)), Vector3(x, height * 0.21, z)))
		crown_transforms[species_index].append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(scale, scale, scale)), Vector3(x, height * 0.68, z)))
	for species_index in range(species.size()):
		trunks[species_index].instance_count = trunk_transforms[species_index].size()
		crowns[species_index].instance_count = crown_transforms[species_index].size()
		for instance_index in range(trunk_transforms[species_index].size()):
			trunks[species_index].set_instance_transform(instance_index, trunk_transforms[species_index][instance_index])
			crowns[species_index].set_instance_transform(instance_index, crown_transforms[species_index][instance_index])

func _new_multimesh(mesh: Mesh, material: Material, node_name: String) -> MultiMeshInstance3D:
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = 0
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multi
	instance.material_override = material
	add_child(instance)
	return instance

func _near_path(point: Vector3, margin: float) -> bool:
	for path_point in path_points:
		if Vector2(point.x - path_point.x, point.z - path_point.z).length() < margin:
			return true
	return false

func _near_landmark(point: Vector3, margin: float) -> bool:
	var landmarks := [
		Vector3(-5.0, 0.0, -5.0), Vector3(42.0, 0.0, -30.0),
		Vector3(-54.0, 0.0, -62.0), Vector3(62.0, 0.0, 48.0),
		Vector3(-48.0, 0.0, 52.0), Vector3(18.0, 0.0, 72.0)
	]
	for landmark in landmarks:
		if Vector2(point.x - landmark.x, point.z - landmark.z).length() < margin:
			return true
	return false

func _build_house(pos: Vector3) -> void:
	var wall := _mat(Color("#8b6548"))
	var roof := _mat(Color("#4b3540"))
	var dark := _mat(Color("#392a2c"))
	var window := _mat(Color("#f4bd68"), 0.25)
	_box_mesh("CabinBody", pos + Vector3(0.0, 0.8, 0.0), Vector3(2.8, 1.6, 2.1), wall)
	_box_mesh("CabinRoof", pos + Vector3(0.0, 1.85, 0.0), Vector3(3.25, 0.38, 2.5), roof)
	_box_mesh("RoofRidge", pos + Vector3(0.0, 2.12, 0.0), Vector3(0.22, 0.22, 2.55), dark)
	_box_mesh("Door", pos + Vector3(0.55, 0.52, 1.07), Vector3(0.58, 1.04, 0.08), dark)
	_box_mesh("WindowLeft", pos + Vector3(-0.72, 1.02, 1.08), Vector3(0.48, 0.48, 0.08), window)
	_box_mesh("WindowRight", pos + Vector3(1.12, 1.02, 1.08), Vector3(0.48, 0.48, 0.08), window)
	_box_mesh("Chimney", pos + Vector3(-0.9, 2.25, -0.45), Vector3(0.34, 0.9, 0.36), _mat(Color("#57444a")))
	_box_mesh("Porch", pos + Vector3(0.0, 0.12, 1.45), Vector3(3.1, 0.18, 0.8), _mat(Color("#6e503b")))

func _build_lake_and_bridge(pos: Vector3) -> void:
	var water := _mat(Color("#294e59"), 0.18)
	var lake := MeshInstance3D.new()
	var lake_mesh := CylinderMesh.new()
	lake_mesh.top_radius = 10.5
	lake_mesh.bottom_radius = 10.5
	lake_mesh.height = 0.08
	lake.mesh = lake_mesh
	lake.material_override = water
	lake.position = pos + Vector3(0.0, -0.02, 0.0)
	add_child(lake)
	for i in range(13):
		var x := -6.0 + float(i) * 1.0
		_box_mesh("BridgePlank", pos + Vector3(x, 0.12, 0.0), Vector3(0.9, 0.16, 2.6), _mat(Color("#76563c")))
	for side in [-1.0, 1.0]:
		for i in range(5):
			var x := -5.0 + float(i) * 2.5
			_box_mesh("BridgeRail", pos + Vector3(x, 0.62, side * 1.15), Vector3(0.12, 0.9, 0.12), _mat(Color("#49372e")))
		_box_mesh("BridgeHandrail", pos + Vector3(0.0, 1.0, side * 1.15), Vector3(11.0, 0.12, 0.12), _mat(Color("#49372e")))
	for i in range(28):
		var angle := TAU * float(i) / 28.0
		var rock_pos := pos + Vector3(cos(angle) * 10.8, 0.08, sin(angle) * 10.8)
		_box_mesh("LakesideRock", rock_pos, Vector3(rng.randf_range(0.4, 1.0), 0.3, 0.5), _mat(Color("#58645a")))

func _build_ruins(pos: Vector3) -> void:
	var stone := _mat(Color("#646b68"))
	var moss := _mat(Color("#3e6347"))
	for i in range(7):
		var angle := TAU * float(i) / 7.0
		var p := pos + Vector3(cos(angle) * 4.8, 1.2, sin(angle) * 4.8)
		_box_mesh("RuinedPillar", p, Vector3(0.8, 2.4 + rng.randf_range(-0.8, 0.5), 0.8), stone)
		_box_mesh("PillarMoss", p + Vector3(0.0, 0.7, 0.42), Vector3(0.84, 0.36, 0.12), moss)
	_box_mesh("BrokenAltar", pos + Vector3(0.0, 0.45, 0.0), Vector3(2.6, 0.9, 1.6), stone)
	_box_mesh("RuneStone", pos + Vector3(0.0, 1.1, 0.0), Vector3(0.7, 1.2, 0.25), _mat(Color("#83b8a0"), 0.4))

func _build_watchtower(pos: Vector3) -> void:
	var wood := _mat(Color("#654631"))
	var roof := _mat(Color("#493a42"))
	for x in [-1.2, 1.2]:
		for z in [-1.2, 1.2]:
			_box_mesh("TowerLeg", pos + Vector3(x, 3.0, z), Vector3(0.24, 6.0, 0.24), wood)
	_box_mesh("TowerDeck", pos + Vector3(0.0, 4.8, 0.0), Vector3(3.4, 0.3, 3.4), wood)
	_box_mesh("TowerRoof", pos + Vector3(0.0, 6.4, 0.0), Vector3(4.0, 0.4, 4.0), roof)
	for y in [5.4, 6.0]:
		_box_mesh("TowerRailFront", pos + Vector3(0.0, y, 1.5), Vector3(3.2, 0.12, 0.12), wood)
		_box_mesh("TowerRailBack", pos + Vector3(0.0, y, -1.5), Vector3(3.2, 0.12, 0.12), wood)

func _build_camp(pos: Vector3) -> void:
	_box_mesh("CampfireStone", pos + Vector3(0.0, 0.08, 0.0), Vector3(1.5, 0.16, 1.5), _mat(Color("#65594a")))
	_box_mesh("CampfireEmbers", pos + Vector3(0.0, 0.2, 0.0), Vector3(0.6, 0.18, 0.6), _mat(Color("#ff8b45"), 1.2))
	_box_mesh("Tent", pos + Vector3(3.0, 1.0, 0.0), Vector3(3.2, 2.0, 2.8), _mat(Color("#8b6847")))
	_box_mesh("TentDoor", pos + Vector3(3.0, 0.65, 1.42), Vector3(1.0, 1.3, 0.08), _mat(Color("#49382e")))
	for i in range(6):
		var angle := TAU * float(i) / 6.0
		_box_mesh("CampLog", pos + Vector3(cos(angle) * 1.2, 0.16, sin(angle) * 1.2), Vector3(0.9, 0.25, 0.28), _mat(Color("#73543b")))

func _build_mushroom_glade(pos: Vector3) -> void:
	var grass := _mat(Color("#527447"))
	_box_mesh("GladePatch", pos + Vector3(0.0, -0.02, 0.0), Vector3(14.0, 0.04, 12.0), grass)
	for i in range(42):
		var x := rng.randf_range(-6.0, 6.0)
		var z := rng.randf_range(-5.0, 5.0)
		var stem_height := rng.randf_range(0.18, 0.42)
		_box_mesh("MushroomStem", pos + Vector3(x, stem_height * 0.5, z), Vector3(0.12, stem_height, 0.12), _mat(Color("#e4d8b4")))
		_box_mesh("MushroomCap", pos + Vector3(x, stem_height + 0.08, z), Vector3(rng.randf_range(0.28, 0.48), 0.16, rng.randf_range(0.28, 0.48)), _mat(Color("#bd6c78") if i % 2 == 0 else Color("#d8a65c"), 0.12))

func _build_npc(pos: Vector3, skin: Color, clothes: Color) -> void:
	var sprite := Sprite3D.new()
	sprite.name = "ForestTraveler"
	sprite.texture = _make_npc_texture(skin, clothes)
	sprite.pixel_size = 0.035
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.position = pos + Vector3(0.0, 0.56, 0.0)
	add_child(sprite)

func _make_npc_texture(skin: Color, clothes: Color) -> Texture2D:
	var image := Image.create(20, 28, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	_pixel_rect(image, 6, 2, 8, 7, skin)
	_pixel_rect(image, 5, 1, 10, 3, Color("#49372e"))
	_pixel_rect(image, 4, 9, 12, 10, clothes)
	_pixel_rect(image, 2, 10, 3, 8, clothes.darkened(0.25))
	_pixel_rect(image, 15, 10, 3, 8, clothes.darkened(0.25))
	_pixel_rect(image, 5, 19, 4, 7, Color("#292a36"))
	_pixel_rect(image, 11, 19, 4, 7, Color("#292a36"))
	_pixel_rect(image, 4, 25, 5, 2, Color("#151722"))
	_pixel_rect(image, 11, 25, 5, 2, Color("#151722"))
	return ImageTexture.create_from_image(image)

func _pixel_rect(image: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for px in range(x, x + w):
		for py in range(y, y + h):
			image.set_pixel(px, py, color)


func _build_npc_variant(pos: Vector3, archetype: int, skin: Color, clothes: Color) -> void:
	var image := Image.create(24, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	# Shared pixel body, with silhouette/accessory changes per traveler archetype.
	_pixel_rect(image, 7, 5, 10, 8, skin)
	_pixel_rect(image, 6, 4, 12, 3, Color("#342b2b") if archetype % 2 == 0 else Color("#5b4031"))
	_pixel_rect(image, 5, 13, 14, 10, clothes)
	_pixel_rect(image, 4, 14, 3, 8, clothes.darkened(0.2))
	_pixel_rect(image, 17, 14, 3, 8, clothes.darkened(0.2))
	_pixel_rect(image, 7, 23, 4, 7, Color("#292a36"))
	_pixel_rect(image, 13, 23, 4, 7, Color("#292a36"))
	match archetype:
		0: # windmill keeper: broad hat
			_pixel_rect(image, 3, 3, 18, 2, Color("#c7b28a"))
			_pixel_rect(image, 6, 1, 12, 3, Color("#c7b28a"))
		1: # marsh guide: hood and reed bundle
			_pixel_rect(image, 4, 3, 16, 5, Color("#5b5945"))
			_pixel_rect(image, 19, 12, 3, 13, Color("#9b9a62"))
		2: # canyon courier: scarf
			_pixel_rect(image, 6, 12, 12, 3, Color("#d17b58"))
			_pixel_rect(image, 16, 14, 5, 5, Color("#d17b58"))
		3: # astronomer: tall cap and star badge
			_pixel_rect(image, 8, 0, 8, 5, Color("#39475c"))
			_pixel_rect(image, 11, 16, 3, 3, Color("#9bb8d4"))
		4: # orchard worker: apron and basket
			_pixel_rect(image, 8, 15, 8, 8, Color("#c9b38a"))
			_pixel_rect(image, 18, 18, 5, 5, Color("#9a6841"))
		5: # railway mechanic: tool satchel
			_pixel_rect(image, 3, 16, 5, 7, Color("#8c6848"))
			_pixel_rect(image, 15, 18, 5, 3, Color("#b8b8b0"))
	var sprite := Sprite3D.new()
	sprite.name = "Traveler_%d" % archetype
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.pixel_size = 0.035
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.position = pos + Vector3(0.0, 0.64, 0.0)
	add_child(sprite)

func _build_lantern(pos: Vector3) -> void:
	_box_mesh("LanternPost", pos + Vector3(0.0, 0.55, 0.0), Vector3(0.08, 1.1, 0.08), _mat(Color("#4a3931")))
	_box_mesh("LanternGlow", pos + Vector3(0.0, 1.12, 0.0), Vector3(0.28, 0.3, 0.28), _mat(Color("#ffc56b"), 0.2))

func _build_parallax_horizon() -> void:
	_build_background_layer(-1, Color("#172d2b"), -150.0, 160.0)
	_build_background_layer(-2, Color("#203b35"), -115.0, 190.0)

func _build_background_layer(index: int, color: Color, z: float, span: float) -> void:
	var layer := Node3D.new()
	layer.name = "ParallaxForest%d" % abs(index)
	layer.position.z = z
	add_child(layer)
	parallax_layers.append(layer)
	var material := _mat(color)
	for i in range(61):
		var x := -span + float(i) * (span * 2.0 / 60.0)
		var h := 8.0 + float((i * 7 + abs(index)) % 7) * 1.4
		_box_mesh_parent(layer, "FarTreeTrunk", Vector3(x, h * 0.5, 0.0), Vector3(1.0, h, 1.0), material)
		_box_mesh_parent(layer, "FarTreeCrown", Vector3(x, h + 1.0, 0.0), Vector3(9.0, 4.0, 1.0), material)

func _box_mesh_parent(parent: Node3D, node_name: String, pos: Vector3, dimensions: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	parent.add_child(instance)

func _box_mesh(node_name: String, pos: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	add_child(instance)
	return instance

func _mat(color: Color, emission: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission
	return material
