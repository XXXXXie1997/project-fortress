extends Node3D
## A skinned Blender actor follows its authoritative 2D physics body.
const UNITS_TO_PIXELS := 48.0 * sqrt(2.0)
var actor: CharacterBody2D
var stage: Node2D
var hero := false
var kind := ""
var rig: Node3D
var skeleton: Skeleton3D
var gear: Array = [[], [], [], []]
var muzzle: Array = []
var module: Node3D
var battery: Node3D
var phase := 0.0
var kick := 0.0
var dodge_age := 0.0
var elapsed := 0.0
var equip_age := 1.0
var last_weapon := -1
var size_factor := 0.6
var bones := {}
var flash: OmniLight3D
var body_shape: CollisionShape2D
var original_bounds := Vector2.ZERO
var original_center := Vector2.ZERO

func configure(owner_actor: CharacterBody2D, world: Node2D, type: String) -> void:
	actor = owner_actor
	stage = world
	kind = type
	hero = kind == "survivor"
	size_factor = {"fast":0.53,"armored":0.68,"boss":0.91}.get(kind,0.60)
	rig = load("res://assets/runtime/actors_hd/"+kind+".glb").instantiate()
	add_child(rig)
	rig.scale *= size_factor
	body_shape = actor.get_node("ProjectileBody").get_child(0)
	var capsule: CapsuleShape2D = body_shape.shape
	original_bounds = Vector2(capsule.radius,capsule.height)
	original_center = body_shape.position
	capsule.height = 1.81*size_factor*UNITS_TO_PIXELS*cos(PI/6)
	capsule.radius = (.41 if kind in ["boss","armored"] else .265)*size_factor*UNITS_TO_PIXELS
	body_shape.position = Vector2.UP*capsule.height*.5
	skeleton = rig.find_children("*","Skeleton3D",true,false)[0]
	for i in skeleton.get_bone_count():
		bones[skeleton.get_bone_name(i)] = i
	if hero:
		for i in 4:
			gear[i] = rig.find_children("Gear"+str(i)+"*","MeshInstance3D",true,false)
			muzzle.append(rig.find_child("Muzzle"+str(i),true,false))
		module = rig.find_child("Module",true,false)
		battery = rig.find_child("Battery",true,false)
		flash = OmniLight3D.new()
		flash.light_color = Color("#ffda99")
		flash.omni_range = 2.2
		flash.hide()
		add_child(flash)
		actor.visual.set_meta("hd_actor",self)
		actor.visual.hide()
	else:
		actor.art_visual.visibility_layer = 0

func pose(bone: String,axis: Vector3,angle: float) -> void:
	var i: int = bones[bone]
	var rest := skeleton.get_bone_rest(i).basis.get_rotation_quaternion()
	var local_axis := skeleton.get_bone_global_rest(i).basis.inverse()*axis
	skeleton.set_bone_pose_rotation(i,rest*Quaternion(local_axis.normalized(),angle))

func heading(dir: Vector2) -> float:
	var logical: Vector2 = stage.geometry.projection.world_to_logical(dir)-stage.geometry.projection.world_to_logical(Vector2.ZERO)
	return atan2(logical.x,logical.y)

func project_offset(v: Vector3) -> Vector2:
	return Vector2((v.x-v.z)/sqrt(2.0),(v.x+v.z)/sqrt(8.0)-v.y*cos(PI/6))*UNITS_TO_PIXELS

func muzzle_point(direction: Vector2) -> Vector2:
	var index := clampi(actor.visual.weapon_index,0,3)
	rotation.y = heading(direction)
	var marker: Node3D = muzzle[index]
	return actor.global_position+project_offset(marker.global_position-global_position)

func shoulder_point() -> Vector2:
	return actor.global_position+project_offset(Vector3.UP*1.261*size_factor)

func fired() -> void:
	kick = 1.0

func advance(dt: float) -> void:
	elapsed += dt
	position = stage.ground_point(actor.position)
	var v: Vector2 = actor.velocity
	var aim: Vector2 = actor.visual.aim if hero else actor.art_visual.facing
	var action: String = "" if hero else actor.art_visual.action
	rotation.y = heading(aim)
	var speed := v.length()
	phase += dt*clampf(speed/14.0,0,22)
	var stride := sin(phase)*minf(speed/130.0,1.0)
	var turn := wrapf(heading(v)-rotation.y,-PI,PI) if speed>1 else 0.0
	if absf(turn)>PI*.5:
		turn = wrapf(turn+PI,-PI,PI)
		stride = -stride
	pose("Root",Vector3.UP,turn)
	pose("Torso",Vector3.UP,-turn)
	pose("LegL",Vector3.RIGHT,stride*.56)
	pose("LegR",Vector3.RIGHT,-stride*.56)
	pose("ShinL",Vector3.RIGHT,maxf(-stride,0)*.65)
	pose("ShinR",Vector3.RIGHT,maxf(stride,0)*.65)
	var lift := absf(stride)*.029+.006*sin(2.8*elapsed)
	if hero:
		var visual: Node2D = actor.visual
		var index := clampi(visual.weapon_index,0,3)
		if last_weapon!=index:
			equip_age=0.
			last_weapon=index
		equip_age=minf(1,equip_age+dt*5.5)
		for i in gear.size():
			for piece: MeshInstance3D in gear[i]:piece.visible = visual.weapon.visible and i==index
		module.visible = index<3 and visual.attachment.visible
		battery.visible = visual.charging
		kick = maxf(0,kick-dt*9)
		flash.visible = kick>.64 and index<3
		flash.global_position = muzzle[index].global_position
		flash.light_energy = kick*1.7
		dodge_age = dodge_age+dt if visual.dodging else 0.0
		var roll := clampf(dodge_age/float(actor.arena.config.dodge_duration),0.,1.)*PI
		rig.rotation.x = -.96*sin(roll) if visual.dodging else kick*.065+sin(equip_age*PI)*.18
		if visual.dodging:lift-=.09*sin(roll)
		if index==3 and actor.arena.state.player.combat.melee:
			rig.rotation.y=-minf(actor.cooldown*3.5,1.)*1.32
		else:rig.rotation.y=0
		pose("ArmL",Vector3.RIGHT,-.55 if visual.charging else 0.)
		pose("ArmR",Vector3.RIGHT,kick*.17)
	else:
		pose("ArmL",Vector3.RIGHT,-.98 if action=="strike" else .52 if action=="windup" else -stride*.42)
		pose("ArmR",Vector3.RIGHT,-.64 if action=="strike" else stride*.43)
		rig.rotation.x = PI*.48 if action=="dead" else -.16 if kind=="fast" else 0.
	rig.position.y = lift

func _exit_tree() -> void:
	if is_instance_valid(actor):
		if is_instance_valid(body_shape) and (not hero or actor.visual.get_meta("hd_actor",null)==self):
			body_shape.shape.radius = original_bounds.x
			body_shape.shape.height = original_bounds.y
			body_shape.position = original_center
		if hero and is_instance_valid(actor.visual) and actor.visual.get_meta("hd_actor",null)==self:
			actor.visual.remove_meta("hd_actor")
			actor.visual.show()
		elif not hero and is_instance_valid(actor.art_visual):
			actor.art_visual.visibility_layer = 1
