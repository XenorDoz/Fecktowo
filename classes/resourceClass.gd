class_name ResourceInstance
extends RefCounted

const jsonLoader = preload("res://scripts/jsonLoader.gd")
const resourceTileset = preload("res://tilesets/resourcesOres.tres")

var id: int # type of resource
var richness: int
var richnessThreshold := [0,1,2,3,4,5,6,7]
var state : int = 0
var sprite : Vector2i
var position : Vector2i

func _init(_id: int, _richness: int, _position := Vector2i.ZERO):
	id = _id
	richness = _richness
	position = _position	
	
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
	if richness <= 0:
		return 
	while richness > richnessThreshold[state] and state < richnessThreshold.size()-1:
		state += 1
		sprite.y = state
	updateSprite()
		
func updateSprite() -> void:
	sprite.y = state
	pass
