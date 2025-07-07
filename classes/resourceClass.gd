class_name ResourceInstance
extends RefCounted

const jsonLoader = preload("res://scripts/jsonLoader.gd")
const resourceTileset = preload("res://tilesets/resourcesOres.tres")

var id: int # type of resource
var richness: int
var richnessThresHold = []
var state : int = 7
var sprite : Vector2i
var position : Vector2i

func _init(_id: int, _richness: int, _position := Vector2i.ZERO):
	id = _id
	richness = _richness
	position = _position	
	
	richnessThresHold = GameData.resourceThresholds[id]
	for i in range (0, richnessThresHold.size(),1):
		if richness > richnessThresHold[i]:
			state = i
	
	# Grabbing sprite	
	var source = resourceTileset.get_source(id) as TileSetAtlasSource
	var atlasPos : Vector2i
	atlasPos.y = state
	atlasPos.x = randi_range(0, source.get_atlas_grid_size().x-1)
	sprite = atlasPos
	

func isInteracted() -> void:
	richness -= 1
	updateState()

func updateState() -> void:
	if richness < richnessThresHold[state] :
		state -= 1
		sprite.y = state
		updateSprite()
		
func updateSprite() -> void:
	sprite.y = state
	pass
