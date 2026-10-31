extends Node3D

@onready var character: CharacterBody3D = $Character
@onready var camera: Camera3D = $Camera3D

var camera_origin := Vector3(0.0, 8.5, 9.5)
var parallax_layers: Array[Node3D] = []

func _ready() -> void:
	_build_forest()
	camera.position = camera_origin
	camera.rotation = Vector3(-0.68, 0.0, 0.0)
	camera.size = 11.0
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true

func _process(delta: float) -> void:
	var target := character.global_position
	var desired := Vector3(target.x * 0.72, camera_origin.y, target.z * 0.72 + camera_origin.z)
	camera.position = camera.position.lerp(desired, 1.0 - exp(-delta * 2.4))
	for i in range(parallax_layers.size()):
		var layer := parallax_layers[i]
		var factor := 0.12 + float(i) * 0.12
		layer.position.x = -target.x * factor
		layer.position.z = -target.z * factor * 0.35

func _build_forest() -> void:
	var ground_mat := _mat(Color("#243d32"), 1.0)
	var ground := MeshInstance3D.new()
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(36.0, 36.0)
	ground.mesh = ground_mesh
	ground.material_override = ground_mat
	ground.position.y = -0.12
	add_child(ground)

	_build_path()
	_build_house(Vector3(-3.6, 0.0, -3.4))
	_build_tree_ring()
	_build_background_layer(-1, Color("#172d2b"), 8.0)
	_build_background_layer(-2, Color("#203b35"), 5.0)
	_build_npc(Vector3(2.2, 0.0, -1.0), Color("#d18b55"), Color("#4c6b8b"))
	_build_npc(Vector3(-1.1, 0.0, 2.5), Color("#c7a56b"), Color("#6b4d76"))
	_build_lantern(Vector3(0.8, 0.0, -2.4))
	_build_lantern(Vector3(-0.8, 0.0, 3.4))

func _build_path() -> void:
	var path_mat := _mat(Color("#796044"))
	var edge_mat := _mat(Color("#a18a61"))
	for i in range(24):
		var z := 8.0 - float(i) * 0.72
		var width := 1.35 + 0.22 * sin(float(i) * 0.6)
		_box("PathTile", Vector3(0.0, -0.045, z), Vector3(width, 0.035, 0.78), path_mat)
		if i % 3 == 0:
			_box("PathHighlight", Vector3(-width * 0.22, -0.022, z - 0.12), Vector3(0.16, 0.012, 0.12), edge_mat)

func _build_tree_ring() -> void:
	var positions := [
		Vector3(-6.0, 0.0, -5.0), Vector3(-7.5, 0.0, -1.0),
		Vector3(-6.8, 0.0, 3.4), Vector3(-5.2, 0.0, 6.0),
		Vector3(5.8, 0.0, -5.8), Vector3(7.0, 0.0, -2.4),
		Vector3(6.4, 0.0, 1.8), Vector3(5.5, 0.0, 5.8),
		Vector3(-3.5, 0.0, -7.5), Vector3(0.0, 0.0, -8.2),
		Vector3(3.5, 0.0, -7.6)
	]
	for i in range(positions.size()):
		_build_tree(positions[i], i)

func _build_tree(pos: Vector3, seed: int) -> void:
	var trunk_mat := _mat(Color("#49372e"))
	var foliage_a := _mat(Color("#254d3b"))
	var foliage_b := _mat(Color("#316447"))
	var foliage_c := _mat(Color("#47734b"))
	_box("TreeTrunk", pos + Vector3(0.0, 0.55, 0.0), Vector3(0.28, 1.1, 0.28), trunk_mat)
	for tier in range(3):
		var y := 1.15 + float(tier) * 0.52
		var size := 1.55 - float(tier) * 0.34
		var offset := Vector3(0.0, y, 0.0)
		_box("PineFoliage", pos + offset, Vector3(size, 0.68, size), foliage_a if tier == 0 else foliage_b)
		_box("FoliagePixel", pos + offset + Vector3(0.0, 0.16, -size * 0.18), Vector3(size * 0.62, 0.24, size * 0.62), foliage_c)
	if seed % 2 == 0:
		_box("Moss", pos + Vector3(0.32, 0.06, 0.1), Vector3(0.55, 0.12, 0.42), _mat(Color("#58734a")))

func _build_house(pos: Vector3) -> void:
	var wall := _mat(Color("#8b6548"))
	var roof := _mat(Color("#4b3540"))
	var dark := _mat(Color("#392a2c"))
	var window := _mat(Color("#f4bd68"), 0.25)
	_box("CabinBody", pos + Vector3(0.0, 0.8, 0.0), Vector3(2.8, 1.6, 2.1), wall)
	_box("CabinRoof", pos + Vector3(0.0, 1.85, 0.0), Vector3(3.25, 0.38, 2.5), roof)
	_box("RoofRidge", pos + Vector3(0.0, 2.12, 0.0), Vector3(0.22, 0.22, 2.55), dark)
	_box("Door", pos + Vector3(0.55, 0.52, 1.07), Vector3(0.58, 1.04, 0.08), dark)
	_box("WindowLeft", pos + Vector3(-0.72, 1.02, 1.08), Vector3(0.48, 0.48, 0.08), window)
	_box("WindowRight", pos + Vector3(1.12, 1.02, 1.08), Vector3(0.48, 0.48, 0.08), window)
	_box("WindowCross", pos + Vector3(-0.72, 1.02, 1.14), Vector3(0.06, 0.52, 0.04), dark)
	_box("Chimney", pos + Vector3(-0.9, 2.25, -0.45), Vector3(0.34, 0.9, 0.36), _mat(Color("#57444a")))

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

func _build_lantern(pos: Vector3) -> void:
	_box("LanternPost", pos + Vector3(0.0, 0.55, 0.0), Vector3(0.08, 1.1, 0.08), _mat(Color("#4a3931")))
	_box("LanternGlow", pos + Vector3(0.0, 1.12, 0.0), Vector3(0.28, 0.3, 0.28), _mat(Color("#ffc56b"), 0.2))

func _build_background_layer(index: int, color: Color, z: float) -> void:
	var layer := Node3D.new()
	layer.name = "ParallaxForest%d" % abs(index)
	layer.position.z = z
	add_child(layer)
	parallax_layers.append(layer)
	var material := _mat(color)
	for i in range(13):
		var x := -12.0 + float(i) * 2.0
		var h := 2.2 + float((i * 7 + abs(index)) % 4) * 0.55
		var trunk := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.28, h, 0.3)
		trunk.mesh = mesh
		trunk.material_override = material
		trunk.position = Vector3(x, h * 0.5, 0.0)
		layer.add_child(trunk)
		var crown := MeshInstance3D.new()
		var crown_mesh := BoxMesh.new()
		crown_mesh.size = Vector3(1.5, 1.4, 0.6)
		crown.mesh = crown_mesh
		crown.material_override = material
		crown.position = Vector3(x, h + 0.3, 0.0)
		layer.add_child(crown)

func _box(node_name: String, pos: Vector3, dimensions: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	add_child(instance)

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
