extends Node

const resourceClass = preload("res://classes/resourceClass.gd")
const jsonLoader = preload("res://scripts/jsonLoader.gd")

var resourceThresholds = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	getResourceThresholds()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func getResourceThresholds():
	var result = jsonLoader.loadJson("res://assets/tiles/resourceTiles.json")
	for value in result:
		resourceThresholds.insert(value.id, value.richnessThresold)
