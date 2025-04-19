extends Node3D

class_name Controllable

var currentController: PlayerController = null

func _ready():
	pass

func _exit_tree():
	if currentController != null:
		detach_controller()

func has_controller() -> bool:
	return currentController != null

func is_actively_controlled() -> bool:
	return has_controller() && currentController.is_controller_active_for(self)

func activate_control():
	pass

func deactivate_control():
	pass

func attach_controller(controller: PlayerController):
	currentController = controller
	if currentController != null:
		currentController.push_controlled_object(self)

func detach_controller():
	if currentController != null:
		currentController.remove_controlled_object(self)
	currentController = null

func _get_current_input() -> PlayerController.ControlInput:
	if !is_actively_controlled():
		return PlayerController.ControlInput.new()
	return currentController.get_current_input()
