class_name BotController extends Node

@export var _control_target : Samurai3D
@export var _behavior_chart : StateChart
@export var _target_area : TargetArea

var _target : Samurai3D
var combat_range := 3.5

func _ready():
	if is_instance_valid(_control_target):
		_control_target._state_chart.event_received.connect(_pass_state_chart_event)

func _acquire_target_process(_delta):
	if _target_area.get_target_list().size() > 0:
		_target = _target_area.get_target_list()[0]
		_behavior_chart.send_event("acquire_target")

func _out_of_range_process(_delta):
	if _control_target.global_position.distance_squared_to(_target.global_position) < combat_range:
		_behavior_chart.send_event("in_range")
		return
	var direction_to_target = _control_target.global_position.direction_to(_target.global_position)
	_control_target.move_actor(Vector2(direction_to_target.x,direction_to_target.z))

func _enter_in_range():
	_control_target.move_actor(Vector2.ZERO)

func _in_range_process(_delta):
	if _control_target.global_position.distance_squared_to(_target.global_position) > combat_range + 1:
		_behavior_chart.send_event("out_of_range")
		return
	print("in range")

func _pass_state_chart_event(event):
	if event is String:
		_behavior_chart.send_event(event)
