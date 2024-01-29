class_name Samurai3D extends CharacterBody3D

@export_category("Exported Nodes")
@export var _state_chart : StateChart
@export var _animation_tree : AnimationTree
@export var _hurtbox : Area3D
@export var _pcam : PhantomCamera3D
@export var _mesh : MeshInstance3D
@export var _hitbox_collider : CollisionShape3D
@export var _weapon_trail_fx : PackedScene

@export_category("Statistics")
@export var actor_values := {
	"base_health": 1,
	"current_health": 1,
	"move_speed": 3,
	"damage": 1,
	"attack_distance": -10,
}
@export_category("")
enum STANCE{
	LOW,
	MID,
	HIGH,
	STAGGER,
}

var camera_zoom := 3
var camera_zoom_min := 1
var camera_zoom_max := 3
var current_stance := STANCE.LOW
var movement_vector := Vector2.ZERO
var target_stance := STANCE.MID
var current_target : Samurai3D

func _update_stance():
	_animation_tree.set("parameters/stance_attack_blend/blend_position", current_stance)
	#_animation_tree.set("parameters/stance_idle_blend/blend_position", current_stance)

func _rotate_towards_target(delta):
	if is_instance_valid(current_target):
		var angle_to_target = Vector2(global_position.x, global_position.z).angle_to_point(Vector2(current_target.global_position.x, current_target.global_position.z))
		var angle_from_target = Vector2(current_target.global_position.x, current_target.global_position.z).angle_to_point(Vector2(global_position.x, global_position.z))
		var direction_to_target = global_position.direction_to(current_target.global_position)
		#rotation.y = lerp_angle(rotation.y, angle_to_target, 5 * delta)
		look_at(global_position + direction_to_target, Vector3.UP)
		if is_instance_valid(_pcam):
			var camera_rotation = _pcam.get_third_person_rotation()
			#camera_rotation = camera_rotation.rotated(Vector3.UP, angle_from_target)
			camera_rotation.y = lerp_angle(camera_rotation.y, rotation.y, 0.5)
			_pcam.set_third_person_rotation(camera_rotation)

func _enter_high_stance():
	current_stance = STANCE.HIGH

func _enter_mid_stance():
	current_stance = STANCE.MID

func _enter_low_stance():
	current_stance = STANCE.LOW

func _process_stance_change(delta):
	if current_stance != target_stance:
		match target_stance:
			STANCE.MID:
				_state_chart.send_event("enter_mid")
				_animation_tree.set("parameters/stance_transition/transition_request", "mid_stance")
			STANCE.HIGH:
				_state_chart.send_event("enter_high")
				_animation_tree.set("parameters/stance_transition/transition_request", "high_stance")
			STANCE.LOW:
				_state_chart.send_event("enter_low")
				_animation_tree.set("parameters/stance_transition/transition_request", "low_stance")
		current_stance = target_stance
		_animation_tree.set("parameters/stance_attack_blend/blend_position", current_stance)
	#_animation_tree.set("parameters/stance_idle_blend/blend_position", lerp(_animation_tree.get("parameters/stance_idle_blend/blend_position"), float(current_stance), 10 * delta))

func _attack_process(_delta):
	_state_chart.send_event("attack")

func _enter_attacking():
	_animation_tree.set("parameters/attack_shot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	velocity = Vector3(0,velocity.y, actor_values["attack_distance"]).rotated(Vector3.UP, rotation.y)

func _attack_movement_process(delta):
	var current_velocity = Vector2(velocity.x, velocity.z)
	current_velocity = lerp(current_velocity, Vector2.ZERO, 5 * delta)
	velocity = Vector3(current_velocity.x, velocity.y, current_velocity.y)

func _attack_animation_finished():
	_state_chart.send_event("attack_end")

func exit_attacking():
	_hitbox_collider.set_deferred("disabled", true)

func _process_movement(delta):
	var move_direction = Vector2.ZERO
	if is_instance_valid(_pcam):
		move_direction = Vector3(movement_vector.x, velocity.y, movement_vector.y).rotated(Vector3.UP, _pcam.get_third_person_rotation().y)
		rotation.y = lerp_angle(rotation.y, _pcam.get_third_person_rotation().y, 5 * delta)
	else:
		move_direction = Vector3(movement_vector.x, velocity.y, movement_vector.y)
	rotation_degrees.y = wrapf(rotation_degrees.y, 0, 360)
	velocity = move_direction * actor_values["move_speed"]

func _physics_process(_delta):
	var animate_direction = Vector2(velocity.x, velocity.z).rotated(rotation.y).normalized()
	_animation_tree.set("parameters/high_movement/blend_position", animate_direction)
	_animation_tree.set("parameters/low_movement/blend_position", animate_direction)
	_animation_tree.set("parameters/mid_movement/blend_position", animate_direction)
	velocity += Vector3.DOWN
	move_and_slide()

func move_actor(direction:Vector2):
	movement_vector = direction

func rotate_camera(event : InputEventMouseMotion):
	if !is_instance_valid(current_target):
		var camera_rotation = _pcam.get_third_person_rotation_degrees()
		camera_rotation.x -= event.relative.y
		camera_rotation.y -= event.relative.x
		camera_rotation.x = clampf(camera_rotation.x, -60, 0)
		camera_rotation.y = wrapf(camera_rotation.y, 0.0, 360.0)
		_pcam.set_third_person_rotation_degrees(camera_rotation)
	else:
		var camera_rotation = _pcam.get_third_person_rotation_degrees()
		camera_rotation.x -= event.relative.y
		camera_rotation.x = clampf(camera_rotation.x, -60, 0)
		_pcam.set_third_person_rotation_degrees(camera_rotation)

func attack():
	_state_chart.send_event("attack")

func zoom_camera(delta:float):
	var target_zoom = _pcam.get_spring_arm_spring_length()
	target_zoom += delta
	target_zoom = clamp(target_zoom, camera_zoom_min, camera_zoom_max)
	_pcam.set_spring_arm_spring_length(target_zoom)

func _on_hurtbox_enter(area):
	if area.get_owner() == self:
		return
	var enemy : Samurai3D = area.get_owner()
	if enemy.current_stance == current_stance:
		_state_chart.send_event("hit_react")
		enemy.trigger_stagger()
		return
	_state_chart.send_event("dying")

func _on_enter_stagger():
	_animation_tree.set("parameters/stagger_state/transition_request", "true")
	velocity = Vector3.ZERO
	current_stance = STANCE.STAGGER

func _on_exit_stagger():
	_animation_tree.set("parameters/stagger_state/transition_request", "false")

func _on_enter_hit_react():
	_animation_tree.set("parameters/hit_react_state/transition_request", "blocked")

func _on_exit_hit_react():
	_animation_tree.set("parameters/hit_react_state/transition_request", "false")

func _on_enter_dying():
	queue_free()

func _instantiate_weapon_vfx():
	var new_trail = _weapon_trail_fx.instantiate()
	add_child(new_trail)
	new_trail.position.z -= 2
	new_trail.top_level = true

func trigger_stagger():
	_state_chart.send_event("stagger")
