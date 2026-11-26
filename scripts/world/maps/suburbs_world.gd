extends "res://scripts/world/maps/suburbs_hd.gd"
## One depth buffer for terrain, architecture, interactables and moving actors.
var world_view := SubViewport.new()
var world := Node3D.new()
var camera := Camera3D.new()
var display := Sprite2D.new()
var sun := DirectionalLight3D.new()
var lamp := SpotLight3D.new()
var actors := {}
var gates := {}
var cutaways: Array = []
var world_props := {}
var focus := CameraAttributesPractical.new()
var overlays := {}
var laser := MeshInstance3D.new()
var grenade := MeshInstance3D.new()
var blast := OmniLight3D.new()

func ground_point(p: Vector2) -> Vector3:
	var logical: Vector2 = geometry.projection.world_to_logical(p)/48.0
	return Vector3(logical.x,0,logical.y)

func put(id: String, point: Vector3) -> Node3D:
	var model := model_named(id)
	world.add_child(model)
	model.position = point
	return model

func setup(map: Node2D) -> void:
	geometry = map
	process_priority = 40
	world_view.own_world_3d = true
	world_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(world_view)
	world_view.add_child(world)
	world.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.far = 145
	camera.attributes = focus
	focus.dof_blur_far_enabled = true
	focus.dof_blur_near_enabled = true
	focus.dof_blur_amount = .075
	focus.dof_blur_far_distance = 61
	focus.dof_blur_far_transition = 9
	focus.dof_blur_near_distance = 46
	focus.dof_blur_near_transition = 5
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#53594c")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#c7d4df")
	env.ambient_light_energy = .63
	env.fog_enabled = true
	env.fog_light_color = Color("#c1b69e")
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_depth_begin = 58
	env.fog_depth_end = 91
	env.fog_density = .30
	env.ssao_enabled = true
	env.ssao_radius = .55
	env.ssao_intensity = 1.1
	camera.environment = env
	world.add_child(sun)
	sun.rotation_degrees = Vector3(-38,-44,0)
	sun.light_color = Color("#ffddb1")
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90
	world.add_child(lamp)
	lamp.spot_range = 7
	lamp.spot_angle = 30
	lamp.shadow_enabled = true
	laser.mesh=BoxMesh.new()
	var red:=StandardMaterial3D.new()
	red.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	red.albedo_color=Color("#d44c35")
	laser.material_override=red
	world.add_child(laser)
	grenade.mesh=SphereMesh.new()
	grenade.scale=Vector3.ONE*.14
	grenade.material_override=red
	world.add_child(grenade)
	blast.light_color=Color("#ffaf59")
	blast.omni_range=4.
	world.add_child(blast)
	display.texture = world_view.get_texture()
	display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	display.material = mat
	display.z_index = -5
	add_child(display)
	var mid := Vector3(map.content.size[0]/96.0,0,map.content.size[1]/96.0)
	put("terrain",mid)
	put("utility_truck",Vector3(32.5,0,30.50))
	var scatter := RandomNumberGenerator.new()
	scatter.seed = 340169
	for i in 45:
		var tree := put("spruce",Vector3(scatter.randf_range(-4,54),0,scatter.randf_range(-4,-.8)) if i<24 else Vector3(scatter.randf_range(-3,-.6),0,scatter.randf_range(0,43)))
		tree.scale *= scatter.randf_range(1.2,2.0)
		tree.rotation.y = scatter.randf_range(0,TAU)
	for room: Dictionary in map.content.rooms:
		var rect: Rect2 = map.rect(room.rect)
		var p := rect.get_center()/48.
		var model: Node3D = load("res://scenes/art/suburbs_hd/"+str(room.id)+".tscn").instantiate()
		world.add_child(model)
		model.position = Vector3(p.x,0,p.y)
		var front: Array = []
		for piece: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
			if piece.name in [&"Roof",&"Front",&"NearSide"]:front.append(piece)
			if piece.name==&"Gate":gates[room.id] = piece
		var flag := Node2D.new()
		add_child(flag)
		map.roofs.append({"rect":rect,"node":flag})
		cutaways.append({"flag":flag,"front":front,"rect":rect,"amount":0.})
		var room_light:=OmniLight3D.new()
		model.add_child(room_light)
		room_light.position=Vector3(-.7,1.46,-.7)
		room_light.light_color=Color("#f3cd99") if room.id=="cottage" else Color("#bad8e2")
		room_light.light_energy=.44
		room_light.omni_range=4
	for i: int in map.content.trees.size():
		var coord: Array = map.content.trees[i]
		var tree := put("spruce",Vector3(coord[0]/48.,0,coord[1]/48.))
		tree.rotation.y = (i%4)*1.4
		tree.scale *= 1.15+(i%3)*.18
	plant_shoulders(scatter)
	map.arena.child_entered_tree.connect(watch_child)
	for child in map.arena.get_children():watch_child(child)
	var indicators:=preload("res://scripts/ui/hd_world_indicators.gd").new()
	indicators.stage=self
	map.arena.hud.add_child(indicators)
	map.arena.hud.move_child(indicators,0)
	tree_exiting.connect(indicators.queue_free,CONNECT_ONE_SHOT)
	sync_camera()

func watch_child(child: Node) -> void:
	if child.get_script()==preload("res://scripts/game/session/survivor_encounter.gd"):
		track_encounter.call_deferred(child)
	elif child.get_script()==preload("res://scripts/game/projectile.gd"):
		add_tracer(child)

func track_encounter(child: Node2D) -> void:
	if not is_instance_valid(child) or child.is_queued_for_deletion():return
	var model: Node3D = load("res://assets/runtime/actors_hd/survivor.glb").instantiate()
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		if mesh.name!=&"Body":mesh.hide()
	model.scale*=.57
	model.rotation.y=1.4
	world.add_child(model)
	model.position=ground_point(child.position)
	for item in child.get_children():
		if item is Node2D:item.visibility_layer=0
	child.label.hide()
	overlays[child]=model
	child.tree_exiting.connect(release_overlay.bind(child),CONNECT_ONE_SHOT)

func release_overlay(source: Node2D) -> void:
	if overlays.has(source):
		overlays[source].queue_free()
		overlays.erase(source)

func add_tracer(source: Node2D) -> void:
	var model:=MeshInstance3D.new()
	var mesh:=SphereMesh.new()
	mesh.radial_segments=6
	mesh.rings=2
	mesh.radius=.035
	mesh.height=.07
	model.mesh=mesh
	var material:=StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color=Color("#ffa66d") if source.hostile else Color("#8df3ff")
	model.material_override=material
	model.scale.z=4
	world.add_child(model)
	source.visibility_layer=0
	overlays[source]=model
	source.tree_exiting.connect(release_overlay.bind(source),CONNECT_ONE_SHOT)

func plant_shoulders(scatter: RandomNumberGenerator) -> void:
	var points: Array[Vector2] = []
	for values: Array in geometry.content.roads:
		var r: Rect2 = geometry.rect(values)
		var along_x := r.size.x>r.size.y
		var length := maxf(r.size.x,r.size.y)
		for i in int(length/18):
			var edge := r.position + (Vector2(scatter.randf()*r.size.x,0) if along_x else Vector2(0,scatter.randf()*r.size.y))
			var normal := Vector2.DOWN if along_x else Vector2.RIGHT
			if i%2==0:edge+=normal*(r.size.y if along_x else r.size.x)
			else:normal=-normal
			for j in 9:
				var point := edge+normal*scatter.randf_range(7,38)+normal.orthogonal()*scatter.randf_range(-20,20)
				var keep := true
				for room: Dictionary in geometry.content.rooms:
					if geometry.rect(room.rect).grow(22).has_point(point) or geometry.rect(room.door).grow(80).has_point(point):keep=false
				if keep:points.append(point)
	var sample := model_named("grass")
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = sample.find_children("*","MeshInstance3D",true,false)[0].mesh
	batch.instance_count = points.size()
	for i in points.size():
		var scale_factor := scatter.randf_range(.73,1.25)
		var basis := Basis(Vector3.UP,scatter.randf_range(0,TAU)).scaled(Vector3.ONE*scale_factor)
		batch.set_instance_transform(i,Transform3D(basis,Vector3(points[i].x/48,0,points[i].y/48)))
	var plants := MultiMeshInstance3D.new()
	plants.multimesh = batch
	var wind := ShaderMaterial.new()
	wind.shader = preload("res://assets/runtime/suburbs_hd/grass_wind.gdshader")
	plants.material_override=wind
	plants.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(plants)
	sample.free()

func sync_camera() -> void:
	var transform2 := get_viewport().get_canvas_transform()
	var viewport_size := get_viewport_rect().size
	var center := transform2.affine_inverse()*(viewport_size/2)
	var zoom := transform2.get_scale().abs()
	var image_size := Vector2i((viewport_size/2).ceil())
	if world_view.size!=image_size:world_view.size = image_size
	camera.size = viewport_size.y/zoom.y/CELL_PIXELS
	var band:=maxf(7.,camera.size*.55)
	focus.dof_blur_far_distance=54.+band
	focus.dof_blur_near_distance=54.-band
	var target := ground_point(center)
	camera.position = target+CAMERA_AXIS.normalized()*54.
	camera.look_at(target)
	display.position = center
	display.scale = viewport_size/Vector2(image_size)/zoom

func add_prop(id: String, point: Vector2) -> Node2D:
	var anchor := Node2D.new()
	geometry.add_child(anchor)
	anchor.position = point
	var model := put(id,ground_point(point))
	anchor.tree_exiting.connect(model.queue_free)
	world_props[anchor] = model
	anchor.tree_exiting.connect(func():world_props.erase(anchor))
	return anchor

func track(actor: CharacterBody2D,type: String,dt: float) -> void:
	if not actors.has(actor):
		var avatar := preload("res://scripts/art/hd_rig_actor.gd").new()
		world.add_child(avatar)
		avatar.configure(actor,self,type)
		actors[actor] = avatar
		actor.tree_exiting.connect(release_actor.bind(actor),CONNECT_ONE_SHOT)
	var avatar: Node3D = actors[actor]
	avatar.visible = actor.visible
	if avatar.visible:avatar.advance(dt)

func release_actor(actor: CharacterBody2D) -> void:
	if actors.has(actor):
		actors[actor].queue_free()
		actors.erase(actor)

func _process(dt: float) -> void:
	if not is_instance_valid(geometry.arena.player) or geometry.is_queued_for_deletion():return
	sync_camera()
	var arena: Node2D = geometry.arena
	var player: CharacterBody2D = arena.player
	for source: Node2D in overlays:
		var model: Node3D = overlays[source]
		if source.get_script()==preload("res://scripts/game/projectile.gd"):
			var height:=.75
			var at_feet:=source.position+Vector2.DOWN*height*CELL_PIXELS*cos(PI/6)
			model.position=ground_point(at_feet)+Vector3.UP*height
			var forward:=ground_point(at_feet+source.direction)-ground_point(at_feet)
			model.look_at(model.position+forward)
		else:model.visible=source.visible and visible_at(source.position)
	track(player,"survivor",dt)
	for actor in arena.targets:
		if is_instance_valid(actor) and not actor.is_queued_for_deletion():track(actor,actor.kind,dt)
	if is_instance_valid(arena.blood_visual):sync_blood(arena.blood_visual)
	for item: Dictionary in cutaways:
		var inside: bool=item.flag.modulate.a<.5
		var dest:=1. if inside else 0.
		var player_logical:Vector2=geometry.projection.world_to_logical(player.position)
		var rect:Rect2=item.rect
		var behind:=rect.grow(94).has_point(player_logical) and not inside and (player_logical.x<rect.position.x or player_logical.y<rect.position.y)
		item.amount=move_toward(item.amount,1. if behind else dest,dt*8)
		for piece: MeshInstance3D in item.front:
			piece.transparency=item.amount*(.72 if behind else 1.)
			piece.visible=piece.transparency<.999
	for id: String in gates:gates[id].visible = geometry.doors.has(id)
	for anchor: Node2D in world_props:
		world_props[anchor].visible = visible_at(anchor.position)
	var night := float(arena.ambient_brightness)<.4
	sun.light_energy = .22 if night else 1.05
	sun.light_color = Color("#a3bada") if night else Color("#ffddb1")
	camera.environment.fog_light_color=Color("#334352") if night else Color("#c1b69e")
	camera.environment.ambient_light_energy = maxf(.16,arena.darkness.color.r) if night else .63
	lamp.visible = is_instance_valid(player.tactical) and player.tactical.light.enabled
	if lamp.visible:
		lamp.position = actors[player].muzzle[clampi(player.visual.weapon_index,0,3)].global_position
		var dir := ground_point(player.position+player.visual.aim*80)-ground_point(player.position)
		lamp.look_at(lamp.position+dir-Vector3.UP*.16)
	update_tactical(player)

func update_tactical(player: CharacterBody2D) -> void:
	var tool: Node2D=player.tactical
	if not is_instance_valid(tool):return
	var tip: Node3D=actors[player].muzzle[clampi(player.visual.weapon_index,0,3)]
	laser.visible=tool.enabled and tool.mode==1 and tool.battery().get("energy",0)>0
	if laser.visible:
		var start:Vector2=player.visual.muzzle_position(player.visual.aim)
		var end:Vector2=start+player.visual.aim*600.
		var hit:=preload("res://scripts/combat/body_geometry.gd").ray(player,start,end,1+8+256)
		if not hit.is_empty():end=hit.position
		var delta:=ground_point(end)-ground_point(start)
		if delta.length()>.005:
			laser.position=tip.global_position+delta*.5
			laser.look_at(laser.position+delta)
			laser.scale=Vector3(.018,.018,delta.length())
	grenade.visible=tool.flight>0
	if grenade.visible:
		var t:float=1.-tool.flight/.5
		var launch_height:=.76
		var launch:=ground_point(tool.flight_start+Vector2.DOWN*launch_height*CELL_PIXELS*cos(PI/6))+Vector3.UP*launch_height
		grenade.position=launch.lerp(ground_point(tool.destination),t)+Vector3.UP*1.7*sin(PI*t)
	blast.visible=tool.pulse>0
	if blast.visible:
		blast.position=ground_point(tool.destination)+Vector3.UP*.5
		blast.light_energy=tool.pulse*18

func blood_mesh(source: Node2D,flat: bool) -> Node3D:
	if overlays.has(source):return overlays[source]
	var instance:=MeshInstance3D.new()
	var mesh:=SphereMesh.new()
	mesh.radius=.2 if flat else .065
	mesh.height=.018 if flat else .11
	mesh.rings=1
	mesh.radial_segments=7
	instance.mesh=mesh
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color("#682f27")
	material.roughness=.86
	instance.material_override=material
	world.add_child(instance)
	source.visibility_layer=0
	overlays[source]=instance
	source.tree_exiting.connect(release_overlay.bind(source),CONNECT_ONE_SHOT)
	return instance

func sync_blood(effects: Node2D) -> void:
	for source: Node2D in effects.stains.values():
		var stain:=blood_mesh(source,true)
		stain.position=ground_point(source.global_position)+Vector3.UP*.085
		stain.scale=Vector3(1.8,1,1.25)
	for burst: Dictionary in effects.bursts:
		var source: Node2D = burst.node
		var drop:=blood_mesh(source,false)
		drop.position=ground_point(source.global_position+Vector2.DOWN*24)+Vector3.UP*maxf(.12,.72-burst.age*2.)
	for source: Node2D in effects.corpses.values():
		if overlays.has(source):continue
		var corpse: Node3D=load("res://assets/runtime/actors_hd/"+str(source.kind)+".glb").instantiate()
		corpse.scale*=.88 if source.kind=="boss" else .6
		corpse.rotation.x=PI*.49
		world.add_child(corpse)
		corpse.position=ground_point(source.global_position)+Vector3.UP*.14
		overlays[source]=corpse
		source.visibility_layer=0
		source.tree_exiting.connect(release_overlay.bind(source),CONNECT_ONE_SHOT)
