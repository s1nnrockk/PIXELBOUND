extends CharacterBody3D
const W:=48
const H:=64
const GRAVITY:=18.0
const JUMP_VELOCITY:=7.2
var controls_enabled:=true
var jump_requested:=false
var sprite:Sprite3D
var walk_textures: Array[Texture2D] = []
var idle_textures: Array[Texture2D] = []
var last_texture: Texture2D
var frame:=0
var anim_time:=0.0
var move_time:=0.0
var moving:=false
var sneak:=false
func _ready()->void:
 sprite=Sprite3D.new()
 sprite.name="PixelSprite"
 sprite.pixel_size=0.035
 sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
 sprite.shaded=false
 sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
 sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
 sprite.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
 add_child(sprite)
 for i in range(4):
  walk_textures.append(_create_frame(i, true))
 for i in range(2):
  idle_textures.append(_create_frame(i, false))
 sprite.texture = idle_textures[0]
 sprite.position.y = 1.08
func _input(event:InputEvent)->void:
 if controls_enabled and event is InputEventKey and event.keycode==KEY_SPACE and event.pressed and not event.echo:
  jump_requested=true
func _process(delta:float)->void:
 anim_time+=delta
 if is_walking:
  move_time+=delta*(2.8 if sneak else 5.2)
  frame=int(move_time)%4
 else:
  frame=int(anim_time*2.0)%2
 var next_texture: Texture2D = walk_textures[frame] if moving else idle_textures[frame]
 if next_texture != last_texture:
  sprite.texture = next_texture
  last_texture = next_texture
func _physics_process(delta:float)->void:
 if not controls_enabled:
  velocity=Vector3.ZERO
  return
 var horizontal:=float(Input.is_key_pressed(KEY_D))-float(Input.is_key_pressed(KEY_A))
 var vertical:=float(Input.is_key_pressed(KEY_S))-float(Input.is_key_pressed(KEY_W))
 var crouching:=Input.is_key_pressed(KEY_CTRL)
 var running:=Input.is_key_pressed(KEY_SHIFT) and not crouching
 moving=absf(horizontal)>0.01 or absf(vertical)>0.01
 sneak=crouching
 var speed:=1.0 if crouching else (4.0 if running else 2.2)
 var direction:=Vector2(horizontal, vertical)
 if direction.length_squared()>1.0:
  direction=direction.normalized()
 velocity.x=direction.x*speed
 velocity.z=direction.y*speed
 if is_on_floor():
  velocity.y=0.0
  if jump_requested:
   velocity.y=JUMP_VELOCITY
 else:
  velocity.y-=GRAVITY*delta
 move_and_slide()
 jump_requested=false
func _create_frame(index:int, is_walking:bool)->Texture2D:
 var image:=Image.create(W,H,false,Image.FORMAT_RGBA8)
 image.fill(Color.TRANSPARENT)
 var dark:=Color("#151827")
 var cloak:=Color("#252b3b")
 var mid:=Color("#41485c")
 var edge:=Color("#727b91")
 var skin:=Color("#c4a18b")
 var mask:=Color("#a6b0bd")
 var leg_shift:=0
 var bob:=0
 if moving:
  leg_shift=[-2,-1,1,2][index]
  bob=[0,-1,0,1][index]
 elif index==1:
  bob=-1
 _rect(image,7,25+bob,4,5+max(0,leg_shift),dark)
 _rect(image,13,25+bob,4,5+max(0,-leg_shift),dark)
 _rect(image,6,29+bob+max(0,leg_shift),5,2,Color("#090c14"))
 _rect(image,13,29+bob+max(0,-leg_shift),5,2,Color("#090c14"))
 _rect(image,6,3+bob,12,11,dark)
 _rect(image,8,1+bob,8,8,cloak)
 _rect(image,7,4+bob,10,7,mid)
 _rect(image,8,6+bob,8,5,skin)
 _rect(image,7,10+bob,10,15,cloak)
 _rect(image,5,12+bob,14,12,dark)
 _rect(image,6,13+bob,12,10,cloak)
 _rect(image,8,15+bob,2,8,mid)
 _rect(image,14,14+bob,2,9,mid)
 _rect(image,8,8+bob,8,3,dark)
 _rect(image,9,8+bob,6,1,mask)
 _rect(image,10,9+bob,4,1,Color("#202638"))
 _rect(image,6,4+bob,2,6,edge)
 _rect(image,16,5+bob,2,5,mid)
 _rect(image,7,12+bob,1,10,edge)
 _rect(image,16,13+bob,1,8,mid)
 _rect(image,10,18+bob,1,5,edge)
 var arm: int=[-1,0,1,0][index] if is_walking else 0
 _rect(image,3,13+bob+arm,3,9,dark)
 _rect(image,18,13+bob-arm,3,9,dark)
 _rect(image,3,20+bob+arm,3,2,skin)
 _rect(image,18,20+bob-arm,3,2,skin)
 return ImageTexture.create_from_image(image)
func _rect(image:Image,x:int,y:int,w:int,h:int,color:Color)->void:
 var scale_factor:=2
 for px in range(max(0,x*scale_factor),min(W,(x+w)*scale_factor)):
  for py in range(max(0,y*scale_factor),min(H,(y+h)*scale_factor)):
   image.set_pixel(px,py,color)
