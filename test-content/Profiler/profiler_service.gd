extends Node

@export var profilerConfigs: ProfilerConfigSet = load("uid://petydnsgoaov")
@export var switchFrequencyMs: float = 250


signal on_reset_profiler()
signal on_set_variant(active_measurement: bool, config_name: String, variant_name: String)

var profiler = Profiler.new()

var lastSwitchedTicks: int = 0
var currentVariantIndex: int = -1
var activeConfig: ProfilerConfig = null

func _process(_delta):
	if activeConfig == null || activeConfig.variants.is_empty():
		return
	var now = Time.get_ticks_usec()
	if currentVariantIndex == -1 || (now-lastSwitchedTicks)/1000.0 > switchFrequencyMs:
		currentVariantIndex = (currentVariantIndex+1)%activeConfig.variants.size()
		on_set_variant.emit(true, activeConfig.configName, activeConfig.variants[currentVariantIndex])
		lastSwitchedTicks = now
	profiler.feed_per_frame(activeConfig.variants[currentVariantIndex])
		
func set_variant(config_name: String, variant_name: String):
	if activeConfig != null:
		push_error("Can't set variant manually while performing a measurement")
		return
	var config_id = profilerConfigs.configs.find_custom(func(config: ProfilerConfig): return config.configName == config_name)
	if config_id == -1:
		push_error("Profiler config not found: %s" % config_name)
		return
	var variant_id = profilerConfigs.configs[config_id].variants.find(variant_name)
	if variant_id == -1:
		push_error("Profiler variant not found: %s/%s" % [config_name, variant_name])
		return
	on_set_variant.emit(false, config_name, variant_name)


func get_results() -> Dictionary[String, Profiler.VariantResult]:
	if activeConfig == null:
		return {}
	return profiler.get_results(activeConfig.referenceVariant)

func clear():
	on_reset_profiler.emit()
	profiler.clear()
	lastSwitchedTicks = 0
	currentVariantIndex = -1
	activeConfig = null

func select_config(config_name: String):
	for config in profilerConfigs.configs:
		if config.configName == config_name:
			clear()
			activeConfig = config
			return
	push_error("Profiler config not found: %s" % config_name)

func get_config_names():
	var res: Array[String] = []
	for config in profilerConfigs.configs:
		res.push_back(config.configName)
	return res