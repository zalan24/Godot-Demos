extends Controllable

@onready var camera = $Camera3D
@onready var controller: PlayerController = $Controller
@export var movementSpeed: float = 3.0
@export var fastMovementSpeed: float = 100.0
@export var expAcceleration: float = 8.0
@export var flatAcceleration: float = 10.0

var velocity: Vector3 = Vector3.ZERO

func _ready():
	super()

func _exit_tree():
	super()

func activate_control():
	super()
	camera.make_current()

func deactivate_control():
	super()
	camera.clear_current()

func _toggle_controls():
	if has_controller():
		detach_controller()
	else:
		if controller != null:
			var currentTarget = controller.get_active_target()
			if currentTarget != null:
				position = currentTarget.position
				rotation = currentTarget.rotation
			attach_controller(controller)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("Free Camera"):
		_toggle_controls()
		
func _process(delta: float):
	if !is_actively_controlled():
		return
	var input = _get_current_input()
	rotation = Vector3(0, -input.lookDirPhi, 0)
	camera.rotation = Vector3(input.lookDirTheta, 0, 0)
	var targetVelocity = input.lookOrientation * Vector3(input.movement.x, input.freeCameraY, input.movement.y)
	if input.jumpingContinuous:
		targetVelocity = targetVelocity + Vector3(0, 1, 0)
	elif input.crouchContinuous:
		targetVelocity = targetVelocity + Vector3(0, -1, 0)
	if input.run:
		targetVelocity = targetVelocity*fastMovementSpeed
	else:
		targetVelocity = targetVelocity*movementSpeed
	var expAcc = 1.0-pow(0.5, delta * expAcceleration)
	velocity = lerp(velocity, targetVelocity, expAcc)
	var diff = targetVelocity-velocity
	var distance = diff.length()
	var flatAcc = flatAcceleration*delta
	if distance < flatAcc:
		velocity = targetVelocity
	else:
		velocity += flatAcceleration*delta * diff / distance
	global_position += velocity*delta
