extends CharacterBody3D
const W:=24
const H:=32
var sprite:Sprite3D
var frame:=0
var anim_time:=0.0
var move_time:=0.0
var moving:=false
var sneak:=false
func _ready()->void:
 var image:=Image.create(W,H,false,Image.FORMAT_RGBA8)
 image.fill(Color.TRANSPARENT)
 sprite=Sprite3D.new()
 sprite.name="PixelSprite"
 sprite.texture=ImageTexture.create_from_image(image)
 sprite.pixel_size=0.025
 sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
 sprite.shaded=true
 sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
 sprite.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
 add_child(sprite)
 _draw_frame(0)
func _process(delta:float)->void:
 anim_time+=delta
 if moving:
  move_time+=delta*(2.8 if sneak else 5.2)
  frame=int(move_time)%4
 else:
  frame=int(anim_time*2.0)%2
 _draw_frame(frame)
func _physics_process(_delta:float)->void:
 var horizontal:=float(Input.is_key_pressed(KEY_D))-float(Input.is_key_pressed(KEY_A))
 var crouching:=Input.is_key_pressed(KEY_CTRL)
 var running:=Input.is_key_pressed(KEY_SHIFT) and not crouching
 moving=absf(horizontal)>0.01
 sneak=crouching
 var speed:=1.0 if crouching else (4.0 if running else 2.2)
 velocity.x=horizontal*speed
 velocity.z=0.0
 move_and_slide()
func _draw_frame(index:int)->void:
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
 var arm: int=[-1,0,1,0][index] if moving else 0
 _rect(image,3,13+bob+arm,3,9,dark)
 _rect(image,18,13+bob-arm,3,9,dark)
 _rect(image,3,20+bob+arm,3,2,skin)
 _rect(image,18,20+bob-arm,3,2,skin)
 sprite.texture=ImageTexture.create_from_image(image)
 sprite.position.y=0.42
func _rect(image:Image,x:int,y:int,w:int,h:int,color:Color)->void:
 for px in range(max(0,x),min(W,x+w)):
  for py in range(max(0,y),min(H,y+h)):
   image.set_pixel(px,py,color)
