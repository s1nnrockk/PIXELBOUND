extends Node3D

var time := 0.0
var warm: OmniLight3D
var cyan: OmniLight3D
var purple: OmniLight3D
var character: CharacterBody3D
var shadow: MeshInstance3D
var shadow_material: StandardMaterial3D

func _ready() -> void:
	warm = get_node("WarmLight")
	cyan = get_node("CyanLight")
	purple = get_node("PurpleLight")
	character = get_node("Character")

	shadow = MeshInstance3D.new()
	shadow.name = "SoftContactShadow"
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.2, 0.62)
	shadow.mesh = mesh
	shadow.position = Vector3(0.0, 0.008, 0.04)
	shadow.rotation.x = -PI / 2.0

	var image := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	for y in range(32):
		for x in range(64):
			var nx := (float(x) - 31.5) / 31.5
			var ny := (float(y) - 15.5) / 15.5
			var distance := sqrt(nx * nx + ny * ny)
			var alpha := pow(max(0.0, 1.0 - distance), 1.6) * 0.62
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	var shadow_texture := ImageTexture.create_from_image(image)

	shadow_material = StandardMaterial3D.new()
	shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	shadow_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	shadow_material.albedo_texture = shadow_texture
	shadow_material.albedo_color = Color(0.018, 0.025, 0.05, 0.78)
	shadow_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	shadow.material_override = shadow_material
	character.add_child(shadow)

func _process(delta: float) -> void:
	time += delta
	warm.position = Vector3(-2.1 + sin(time * 0.7) * 0.8, 1.7, 1.2)
	cyan.position = Vector3(2.1 + cos(time * 0.55) * 0.7, 1.6, -0.4)
	purple.position.y = 2.1 + sin(time * 0.9) * 0.35

	var sneaking := bool(character.get("sneak"))
	shadow.scale = Vector3(0.82, 1.0, 0.82) if sneaking else Vector3.ONE
	shadow_material.albedo_color.a = 0.62 if sneaking else 0.78
