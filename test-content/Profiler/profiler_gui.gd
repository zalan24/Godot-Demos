extends Node2D

@export var fps_update_frequency_ms: float = 500

@onready var fps_label: Label = $CanvasLayer/PanelContainer/HBoxContainer/FPSLabel
@onready var vsync_checkbox: CheckBox = $CanvasLayer/PanelContainer/HBoxContainer/VSyncCheckBox
@onready var vsync_mode_option_button: OptionButton = $CanvasLayer/PanelContainer/HBoxContainer/VSyncMode
@onready var profiler_config_option_button: OptionButton = $CanvasLayer/PanelContainer/HBoxContainer/ProfilerConfigOption
@onready var profiler_config_variant_option_button: OptionButton = $CanvasLayer/PanelContainer/HBoxContainer/ProfilerConfigVariantOption
@onready var measure_button: Button = $CanvasLayer/PanelContainer/HBoxContainer/Measure
@onready var stop_measurement_button: Button = $CanvasLayer/PanelContainer/HBoxContainer/StopMeasurement
@onready var active_variant_label: Label = $CanvasLayer/PanelContainer/HBoxContainer/ActiveVariantLabel

var last_ticks: int = 0
var last_updated_ticks: int = 0
var frame_count: int = 0
var last_config_selected: ProfilerConfig = null

const vsync_ui_to_mode: Dictionary[int, int] = {
	0: DisplayServer.VSYNC_ENABLED,
	1: DisplayServer.VSYNC_ADAPTIVE,
	2: DisplayServer.VSYNC_MAILBOX
};

const vsync_mode_to_ui: Dictionary[int, int] = {
	DisplayServer.VSYNC_ENABLED: 0,
	DisplayServer.VSYNC_ADAPTIVE: 1,
	DisplayServer.VSYNC_MAILBOX: 2
};

func _ready():
	var mode = DisplayServer.window_get_vsync_mode()
	vsync_checkbox.button_pressed = mode != DisplayServer.VSYNC_DISABLED
	if mode != DisplayServer.VSYNC_DISABLED:
		vsync_mode_option_button.selected = vsync_mode_to_ui[mode]

	vsync_checkbox.pressed.connect(_on_vsync_toggled)
	vsync_mode_option_button.item_selected.connect(_on_vsync_mode_selected)

	for config in ProfilerService.profilerConfigs.configs:
		profiler_config_option_button.add_item(config.configName)
	if ProfilerService.profilerConfigs.configs.size() > 0:
		profiler_config_option_button.select(0)
		_refresh_profiler_variants(ProfilerService.profilerConfigs.configs[0])

	profiler_config_option_button.item_selected.connect(_on_profiler_config_selected)
	profiler_config_variant_option_button.item_selected.connect(_on_profiler_variant_selected)
	_on_reset_profiler()

	measure_button.pressed.connect(_on_start_measurement)
	stop_measurement_button.pressed.connect(_on_stop_measurement)

	ProfilerService.on_reset_profiler.connect(_on_reset_profiler)
	ProfilerService.on_set_variant.connect(_on_set_variant)

func _exit_tree():
	ProfilerService.on_reset_profiler.disconnect(_on_reset_profiler)
	ProfilerService.on_set_variant.disconnect(_on_set_variant)

func _on_start_measurement():
	var selected = profiler_config_option_button.selected
	if selected != -1:
		ProfilerService.select_config(ProfilerService.profilerConfigs.configs[selected].configName)

func _on_stop_measurement():
	var results = ProfilerService.get_results()
	ProfilerService.clear()
	print("Profiler results:")
	for variant in results:
		print(" - %s: Cost per frame: %.3fms +%dus" % [variant, results[variant].perfCostPerFrameMs, int(results[variant].relativeCostUs)])

func _on_reset_profiler():
	active_variant_label.text = "Current Variant: -"
	profiler_config_variant_option_button.disabled = false
	measure_button.disabled = false
	stop_measurement_button.disabled = true
	profiler_config_variant_option_button.selected = 0

func _on_set_variant(active_measurement: bool, _config_name: String, variant_name: String):
	active_variant_label.text = "Current Variant: %s" % variant_name
	measure_button.disabled = active_measurement
	stop_measurement_button.disabled = !active_measurement
	profiler_config_variant_option_button.disabled = active_measurement
	if active_measurement:
		profiler_config_variant_option_button.selected = 0

func _set_vsync_mode():
	if !vsync_checkbox.button_pressed:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	else:
		var option = vsync_ui_to_mode[vsync_mode_option_button.selected]
		DisplayServer.window_set_vsync_mode(option)

func _on_vsync_toggled():
	_set_vsync_mode()

func _on_vsync_mode_selected(_item: int):
	_set_vsync_mode()

func _refresh_profiler_variants(config: ProfilerConfig):
	profiler_config_variant_option_button.clear()
	profiler_config_variant_option_button.add_item("-")
	if config != null:
		for variant in config.variants:
			profiler_config_variant_option_button.add_item(variant)
	profiler_config_variant_option_button.selected = 0

func _on_profiler_config_selected(item: int):
	var config = ProfilerService.profilerConfigs.configs[item] if item >= 0 else null
	if config != last_config_selected:
		_refresh_profiler_variants(config)
		last_config_selected = config
		ProfilerService.clear()

func _on_profiler_variant_selected(item: int):
	if item == 0 || item == -1 || profiler_config_option_button.selected == -1:
		ProfilerService.clear()
		return
	var config = ProfilerService.profilerConfigs.configs[profiler_config_option_button.selected]
	ProfilerService.set_variant(config.configName, config.variants[item-1])

func _process(_delta):
	var ticks_us = Time.get_ticks_usec()
	if last_ticks != 0:
		var time_passed_ms = (ticks_us-last_ticks) / 1000.0
		frame_count += 1
		if time_passed_ms > fps_update_frequency_ms:
			fps_label.text = "FPS: %0.1f" % (frame_count * 1000.0 / time_passed_ms)
			last_ticks = ticks_us
			frame_count = 0
	else:
		last_ticks = ticks_us
