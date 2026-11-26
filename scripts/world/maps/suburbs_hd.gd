extends Node2D
## Orthographic HD-2D scenery composited at the existing physics feet.
const CELL_PIXELS := 48.0 * sqrt(2.0)
const SAMPLE_SCALE := 2.0
const MODEL_DIR := "res://assets/runtime/suburbs_hd/"
const CAMERA_AXIS := Vector3(1, 0.81649658, 1)
var geometry: Node2D

func make_view(model: Node3D, pixels: Vector2i) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = pixels
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	viewport.add_child(model)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = pixels.y * SAMPLE_SCALE / CELL_PIXELS
	cam.far = 240
	viewport.add_child(cam)
	cam.position = CAMERA_AXIS * 70
	cam.look_at(Vector3.ZERO)
	var sky := Environment.new()
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.ambient_light_color = Color("#e1e7f2")
	sky.ambient_light_energy = 0.83
	cam.environment = sky
	var sun := DirectionalLight3D.new()
	viewport.add_child(sun)
	sun.rotation_degrees = Vector3(-48,-38,0)
	sun.light_color = Color("#fff0d6")
	sun.light_energy = 1.48
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 180
	return viewport

func sprite_at(view: SubViewport, point: Vector2, anchor: Vector2, depth := 0) -> Node2D:
	var pivot := Node2D.new()
	pivot.position = anchor
	pivot.z_index = depth
	var sprite := Sprite2D.new()
	sprite.texture = view.get_texture()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * SAMPLE_SCALE
	sprite.position = point-anchor
	pivot.add_child(sprite)
	geometry.add_child(pivot)
	return pivot

func model_named(id: String) -> Node3D:
	return load(MODEL_DIR + id + ".glb").instantiate()

func _process(_dt: float) -> void:
	for landmark in landmarks:
		landmark.visible = visible_at(landmark.position)


var prop_views := {}
var landmarks: Array[Node2D] = []

func add_prop(id: String, point: Vector2) -> Node2D:
	if not prop_views.has(id):
		prop_views[id] = make_view(model_named(id),Vector2i(108,152))
	return sprite_at(prop_views[id],point,point)

func add_landmarks() -> void:
	var content: Dictionary = geometry.arena.catalog[geometry.content.id]
	var shapes := {"spawn":"camp","travel":"relay","exit":"sign","extraction":"evac"}
	for entry: Dictionary in content.points.values():
		landmarks.append(add_prop(shapes[entry.kind],Vector2(entry.position[0],entry.position[1])))
	for group in ["objectives","events"]:
		for entry: Dictionary in content[group]:
			landmarks.append(add_prop("radio" if group=="objectives" else "beacon",Vector2(entry.position[0],entry.position[1])))

func visible_at(point: Vector2) -> bool:
	var feet: Vector2 = geometry.projection.world_to_logical(geometry.arena.player.position)
	var target: Vector2 = geometry.projection.world_to_logical(point)
	for roof: Dictionary in geometry.roofs:
		if roof.rect.has_point(target) and not roof.rect.grow(8).has_point(feet):
			return false
	return true
