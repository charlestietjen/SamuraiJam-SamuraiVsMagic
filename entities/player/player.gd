extends CharacterBody3D

@export_category("Export Nodes")
@export var _state_chart : StateChart
@export var _third_person_pcam : PhantomCamera3D
@export var _top_down_pcam : PhantomCamera3D
@export var _lock_on_follow_cam : PhantomCamera3D
@export var _hurtbox : Area3D
@export var _animation_tree : AnimationTree
@export var _mesh : Node3D
@export_category("")

var actor_values := {
	"base_health": 5,
	"move_speed": 10,
	"acceleration": 0.1,
}

const RAY_LENGTH = 1000

var follow_zoom := 3.0
var target_zoom := 3.0
var max_zoom := 8.0
var min_zoom := 2.0
var turn_speed := 10.0

func _perspective_change_process(_delta):
	if Input.is_action_just_pressed("change_perspective"):
		_state_chart.send_event("change_perspective")

func _follow_cam_processing(delta):
	if Input.is_action_just_released("camera_zoom_in"):
		print("zoom in")
		target_zoom -= 0.5
	if Input.is_action_just_released("camera_zoom_out"):
		target_zoom += 0.5
	target_zoom = clampf(target_zoom, min_zoom, max_zoom)
	follow_zoom = move_toward(follow_zoom, target_zoom, 5 * delta)
	_third_person_pcam.set_spring_arm_spring_length(follow_zoom)
	#_lock_on_follow_cam.set_spring_arm_spring_length(follow_zoom)

func _on_enter_follow_movement():
	print("Entered follow mode")
	_third_person_pcam.set_priority(30)
	_lock_on_follow_cam.set_priority(1)
	_top_down_pcam.set_priority(1)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_enter_topdown_movement():
	print("Entered topdown mode")
	_top_down_pcam.set_priority(30)
	_third_person_pcam.set_priority(1)
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED

func _on_enter_lockon_movement():
	print("Entered locked on mode")
	_lock_on_follow_cam.set_priority(30)
	_third_person_pcam.set_priority(1)

func _process_lockon_toggle(_delta):
	if Input.is_action_just_pressed("toggle_target_lock"):
		_state_chart.send_event("toggle_lockon")

func _follow_cam_unhandled_input(event):
	if event is InputEventMouseMotion:
		#print(event.relative)
		var camera_rotation = _third_person_pcam.get_third_person_rotation_degrees()
		camera_rotation.x -= event.relative.y
		camera_rotation.y -= event.relative.x
		camera_rotation.x = clampf(camera_rotation.x, -60, 0)
		camera_rotation.y = wrapf(camera_rotation.y, 0.0, 360.0)
		_third_person_pcam.set_third_person_rotation_degrees(camera_rotation)
		#_third_person_pcam.rotation_degrees.y -= event.relative.x

func _print_state_change(event):
	print(event)

func _universal_physics(_delta):
	var loco_blend = Vector2(velocity.x, velocity.z).rotated(rotation.y).normalized()
	_animation_tree.set("parameters/locomotion_blend/blend_position", loco_blend)
	if !velocity == Vector3.ZERO:
		_animation_tree.tree_root.get_node("attack_shot").filter_enabled = true
	else:
		_animation_tree.tree_root.get_node("attack_shot").filter_enabled = false
	#velocity += Vector3.DOWN
	move_and_slide()

func _follow_movement_physics(delta):
	var camera_rotation
	if _third_person_pcam.is_active():
		camera_rotation = _third_person_pcam.get_third_person_rotation().y
	else:
		var look_at_target : Node3D = _lock_on_follow_cam.get_look_at_target()
		var angle_to_target = Vector2(global_position.x, global_position.z).angle_to_point(Vector2(look_at_target.global_position.x, look_at_target.global_position.z))
		camera_rotation = -angle_to_target
	rotation.y = lerp_angle(rotation.y, camera_rotation, turn_speed * delta)
	var input_vector := Input.get_vector("move_left", "move_right", "move_down", "move_up")
	var move_direction := input_vector.rotated(rotation.y)
	velocity.x = move_direction.x * 10
	velocity.z = -move_direction.y * 10
	

func _topdown_movement_physics(delta):
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity.x = input_vector.x * 10
	velocity.z = input_vector.y * 10
# rotate character towards mouse cursor
	var space_state = get_world_3d().direct_space_state
	var cam = get_viewport().get_camera_3d()
	var mousepos = get_viewport().get_mouse_position()

	var origin = cam.project_ray_origin(mousepos)
	var end = origin + cam.project_ray_normal(mousepos) * RAY_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true

	var result := space_state.intersect_ray(query)
	if result:
		var angle_to_result = Vector2(global_position.x, global_position.z).angle_to_point(Vector2(result.position.x, result.position.z))
		rotation.y = lerp_angle(rotation.y, -angle_to_result - 1.5, turn_speed * delta)
		#look_at(result.position, Vector3.UP)
