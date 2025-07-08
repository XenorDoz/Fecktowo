class_name ClusterInstance
extends RefCounted

const resourceClass = preload("res://classes/resourceClass.gd")

var id: int
var origin: Vector2i
var radius: int
var maxRichness: int
var positions:= [] # All cells in that cluster
var totalRichness: int

func _init(_origin: Vector2i, _id: int, _radius: int) -> void :
	id = _id
	origin = _origin
	radius = _radius
	
	var distFromCenter = origin.length()
	maxRichness = clamp(int(log(distFromCenter + 10) * 20), Globals.defaultMinRichness, Globals.defaultMaxRichness)
	
func updateCluster() -> void:
	
	pass

func generateResources() -> Dictionary :
	# Should
	var resourcesGenerated = {}
	print("chunk of %s generated at %s" %[id, origin])
	for x in range (-5, 6, 1):
		for y in range (-5, 6, 1):
			var cellPos = Vector2i(origin.x + x, origin.y	 + y)
			var cell = resourceClass.new(id, 6000, cellPos)
			resourcesGenerated[cellPos] = cell
	return resourcesGenerated
