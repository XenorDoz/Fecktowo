extends Camera2D

@export var playerPath: NodePath

var margin = 0.2 # percentage of side where player can move without moving the cam
var player


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if has_node(playerPath):
		player = get_node(playerPath)
		global_position = player.global_position
	make_current()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	var playerPosFromCam = player.global_position - global_position
	var windowSize = get_viewport_rect().size
	
	if playerPosFromCam.x > windowSize.x/2 * margin :
		global_position.x += 1
	if playerPosFromCam.x <  -windowSize.x/2 * margin:
		global_position.x -= 1
	if playerPosFromCam.y > windowSize.y/2 * margin :
		global_position.y += 1
	if playerPosFromCam.y <  -windowSize.y/2 * margin:
		global_position.y -= 1
