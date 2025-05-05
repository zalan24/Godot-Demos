extends Node3D

@export var world_environment: WorldEnvironment = null

var has_restore_values = false
var fog_enabled_restore: bool = false
var height_fog_density_restore: float = 0
var fog_density_restore: float = 0
var fog_height_falloff_restore: float = 0

func _ready():
	ProfilerService.on_reset_profiler.connect(_on_reset_profiler)
	ProfilerService.on_set_variant.connect(_on_set_variant)

func _exit_tree():
	ProfilerService.on_reset_profiler.disconnect(_on_reset_profiler)
	ProfilerService.on_set_variant.disconnect(_on_set_variant)

func _restore():
	if has_restore_values && world_environment != null:
		world_environment.environment.fog_enabled = fog_enabled_restore
		world_environment.environment.fog_height_density = height_fog_density_restore
		world_environment.environment.fog_density = fog_density_restore
		world_environment.environment.fog_height_falloff = fog_height_falloff_restore
		has_restore_values = false

func _on_reset_profiler():
	_restore()

func _on_set_variant(_active_measurement: bool, config_name: String, variant_name: String):
	if config_name == "Fog":
		if !has_restore_values:
			fog_enabled_restore = world_environment.environment.fog_enabled
			height_fog_density_restore = world_environment.environment.fog_height_density
			fog_density_restore = world_environment.environment.fog_density
			fog_height_falloff_restore = world_environment.environment.fog_height_falloff
			has_restore_values = true
		world_environment.environment.fog_density = 0.00015
		world_environment.environment.fog_enabled = variant_name != "Off"
		world_environment.environment.fog_height_density = 0.0 if variant_name == "No-height" else height_fog_density_restore
	else:
		_restore()