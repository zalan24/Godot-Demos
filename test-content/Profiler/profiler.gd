class_name Profiler

class VariantData:
	var timeTakenMs: float = 0
	var framesRendered: int = 0

	func clear():
		timeTakenMs = 0
		framesRendered = 0
	
	func feed(timeMs: float):
		timeTakenMs += timeMs
		framesRendered+=1
	
class VariantResult:
	var perfCostPerFrameMs: float = 0
	var relativeCostUs: float = 0

var lastVariant: String = ""
var lastTicks: int = 0
var totalTimeMs: float = 0
var totalFrames: int = 0
var variantData: Dictionary[String, VariantData] = {}

func clear():
	variantData.clear()
	lastVariant = ""
	lastTicks = 0
	totalFrames = 0
	totalTimeMs = 0

func feed_per_frame(variant: String):
	var now = Time.get_ticks_usec()
	if lastVariant != "":
		if !variantData.has(lastVariant):
			variantData[lastVariant] = VariantData.new()
		variantData[lastVariant].feed((now-lastTicks)/1000.0)
	totalTimeMs += (now-lastTicks)/1000.0
	totalFrames += 1
	lastTicks = now
	lastVariant = variant

func get_results(referenceVariant: String) -> Dictionary[String, VariantResult]:
	if totalFrames == 0:
		return {}
	var result: Dictionary[String, VariantResult] = {}
	var referenceVariantData: VariantData = null if (referenceVariant == "" || !variantData.has(referenceVariant)) else variantData[referenceVariant]
	var referenceCostMs = -1.0 if (referenceVariantData == null || referenceVariantData.framesRendered == 0) else (referenceVariantData.timeTakenMs / referenceVariantData.framesRendered)
	for variant in variantData.keys():
		var data = variantData[variant]
		if data.framesRendered == 0:
			continue
		var r = VariantResult.new()
		r.perfCostPerFrameMs = data.timeTakenMs / data.framesRendered
		r.relativeCostUs = 0 if referenceCostMs < 0 else (r.perfCostPerFrameMs - referenceCostMs)*1000.0
		result[variant] = r
	return result

