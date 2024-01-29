class_name TargetArea extends Area3D

@export var _owner : Samurai3D

var target_list : Array[Samurai3D] = []

func _ready():
	body_entered.connect(_enter_area)
	body_exited.connect(_exit_area)

func _enter_area(body):
	if target_list.has(body) or body == _owner:
		return
	target_list.append(body)

func _exit_area(body):
	if !target_list.has(body):
		return
	var i = target_list.find(body)
	target_list.remove_at(i)

func get_target_list():
	return target_list
