extends Node3D

class_name PlayerController

@export var mouseSensitivity: Vector2 = Vector2(1, 1)
@export var lookDirThetaMarginDeg: float = 3.0

var controlledObjectStack: Array[WeakRef] = []

var lookDirPhi: float = 0.0 # Rotation around Y
var lookDirTheta: float = 0.0 # Signed angular deviation from horizontal plane
var wantsMouseLocked = false
var holdsMouseCaptured = false

class ControlInput:
	var lookDir: Vector3 = Vector3(0, 0, -1)
	var lookOrientation: Quaternion = Quaternion.IDENTITY
	var lookDirPhi: float = 0.0 # Rotation around Y
	var lookDirTheta: float = 0.0 # Signed angular deviation from horizontal plane
	var movement: Vector2 = Vector2(0, 0)
	var freeCameraY: float = 0
	var jumpsTriggered: bool = false
	var jumpingContinuous: bool = false
	var crouchTriggered: bool = false
	var crouchContinuous: bool = false
	var run: bool = false

func _ready():
	pass
	# GameInstance.mouse_capture_blocked.connect(_update_capture_mouse)
	# GameInstance.mouse_capture_unblocked.connect(_update_capture_mouse)

func _exit_tree():
	# GameInstance.mouse_capture_blocked.disconnect(_update_capture_mouse)
	# GameInstance.mouse_capture_unblocked.disconnect(_update_capture_mouse)
	var activeTarget = get_active_target()
	if activeTarget != null:
		_deactivate_target(activeTarget)

func _request_lock_mouse():
	if !wantsMouseLocked:
		wantsMouseLocked = true
		_update_capture_mouse()

func _request_unlock_mouse():
	if wantsMouseLocked:
		wantsMouseLocked = false
		_update_capture_mouse()

func _update_capture_mouse():
	# if GameInstance.mouseCaptureBlockerCount == 0:
	if wantsMouseLocked && !holdsMouseCaptured:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		holdsMouseCaptured = true
	elif !wantsMouseLocked && holdsMouseCaptured:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		holdsMouseCaptured = false
	# elif holdsMouseCaptured:
	# 	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# 	holdsMouseCaptured = false

func _activate_target(object: Controllable):
	object.activate_control()
	_request_lock_mouse()

func _deactivate_target(object: Controllable):
	_request_unlock_mouse()
	object.deactivate_control()

func push_controlled_object(object: Controllable):
	var prevActiveTarget = get_active_target()
	controlledObjectStack.push_back(weakref(object))
	var currentActiveTarget = get_active_target()
	if prevActiveTarget != currentActiveTarget:
		if prevActiveTarget != null:
			_deactivate_target(prevActiveTarget)
		if currentActiveTarget != null:
			_activate_target(currentActiveTarget)

func remove_controlled_object(object: Controllable):
	var wasActive = is_controller_active_for(object)
	var index = -1
	for i in controlledObjectStack.size():
		if controlledObjectStack[i].get_ref() == object:
			index = i
			break
	assert(index > -1)
	if index > -1:
		controlledObjectStack.remove_at(index)
	if wasActive:
		_deactivate_target(object)
		var activeTarget = get_active_target()
		if activeTarget != null:
			_activate_target(activeTarget)

func is_controller_active_for(object: Controllable):
	return get_active_target() == object

func get_active_target() -> Controllable: 
	if controlledObjectStack.is_empty():
		return null
	return controlledObjectStack.back().get_ref()

func get_current_input() -> ControlInput:
	var result = ControlInput.new()
	if Input.is_action_just_pressed("Jump"):
		result.jumpsTriggered = true
	if Input.is_action_pressed("Jump"):
		result.jumpingContinuous = true
	if Input.is_action_just_pressed("Crouch"):
		result.crouchTriggered = true
	if Input.is_action_pressed("Crouch"):
		result.crouchContinuous = true
	if Input.is_action_pressed("Run"):
		result.run = true
	result.movement = Input.get_vector("MoveLeft", "MoveRight", "MoveForward", "MoveBackward")
	result.freeCameraY = Input.get_axis("FreeCamera Down", "FreeCamera Up")
	result.lookDir = Vector3(sin(lookDirPhi)*cos(lookDirTheta), sin(lookDirTheta), -cos(lookDirPhi)*cos(lookDirTheta))
	result.lookOrientation = Quaternion(Vector3(0, -1, 0), lookDirPhi) * Quaternion(Vector3(1, 0, 0), lookDirTheta)
	result.lookDirPhi = lookDirPhi
	result.lookDirTheta = lookDirTheta
	return result

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var viewport = get_viewport()
		if viewport != null:
			var screenSize = min(viewport.get_visible_rect().size.x, viewport.get_visible_rect().size.y)
			if screenSize > 0:
				var normalizedMotion = event.screen_relative / screenSize
				lookDirPhi = fmod(lookDirPhi + normalizedMotion.x * mouseSensitivity.x, 2.0*PI)
				var limits = PI/2 - lookDirThetaMarginDeg/180.0*PI
				lookDirTheta = clamp(lookDirTheta - normalizedMotion.y * mouseSensitivity.y, -limits, limits)

# func _physics_process(delta: float):
# 	if allowDragObjects:
# 		pass