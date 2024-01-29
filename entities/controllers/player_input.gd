extends Node

@export var _control_target : Samurai3D
@export var _target_area : TargetArea

#func _ready():
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(_delta):
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if is_instance_valid(_control_target):
		_control_target.move_actor(input_vector)
		if Input.is_action_just_pressed("attack"):
			_control_target.attack()
		elif Input.is_action_just_released("camera_zoom_in"):
			_control_target.zoom_camera(-1.0)
		elif Input.is_action_just_released("camera_zoom_out"):
			_control_target.zoom_camera(1.0)
		elif Input.is_action_just_pressed("high_stance"):
			_control_target.target_stance = _control_target.STANCE.HIGH
		elif Input.is_action_just_pressed("low_stance"):
			_control_target.target_stance = _control_target.STANCE.LOW
		elif Input.is_action_just_pressed("mid_stance"):
			_control_target.target_stance = _control_target.STANCE.MID
		if is_instance_valid(_target_area):
			if Input.is_action_just_pressed("toggle_target_lock") && _target_area.get_target_list().size() > 0:
				var targets = _target_area.get_target_list()
				var target_distances = targets.map(func (target): 
					return _control_target.global_position.distance_to(target.global_position))
				var closest_target_index = target_distances.find(target_distances.min())
				if !is_instance_valid(_control_target.current_target):
					_control_target.current_target = targets[closest_target_index]
				elif _control_target.current_target != null:
					_control_target.current_target = null


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		_control_target.rotate_camera(event)
