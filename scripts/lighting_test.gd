extends Node3D
var time:=0.0
var warm:OmniLight3D
var cyan:OmniLight3D
var purple:OmniLight3D
func _ready()->void:
 warm=get_node("WarmLight")
 cyan=get_node("CyanLight")
 purple=get_node("PurpleLight")
 var shadow:=MeshInstance3D.new()
 shadow.name="CharacterShadow"
 var mesh:=QuadMesh.new()
 mesh.size=Vector2(0.9,0.42)
 shadow.mesh=mesh
 shadow.position=Vector3(0,0.005,0.05)
 shadow.rotation.x=-PI/2
 var mat:=StandardMaterial3D.new()
 mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 mat.albedo_color=Color(0.01,0.015,0.03,0.48)
 mat.cull_mode=BaseMaterial3D.CULL_DISABLED
 shadow.material_override=mat
 get_node("Character").add_child(shadow)
func _process(delta:float)->void:
 time+=delta
 warm.position=Vector3(-2.1+sin(time*0.7)*0.8,1.7,1.2)
 cyan.position=Vector3(2.1+cos(time*0.55)*0.7,1.6,-0.4)
 purple.position.y=2.1+sin(time*0.9)*0.35
