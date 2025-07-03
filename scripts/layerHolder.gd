extends Node2D

# Preloading textures 
const GRASS = preload("res://assets/tiles/grass2.png")
const STONE = preload("res://assets/tiles/stone.png")

# Waiting for these
@onready var background: TileMapLayer = $background
@onready var player: Node2D = $"../Player"

# Var used later
var chunkPos: Vector2i
var time = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generateWorld(Vector2i(-Globals.loadedChunkDistance*2, -Globals.loadedChunkDistance*2),
				  Vector2i(Globals.loadedChunkDistance*2, Globals.loadedChunkDistance*2))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var prevChunkPos = chunkPos
	
	chunkPos.x = int(player.global_position.x / Globals.tileSize / Globals.chunkSize)
	chunkPos.y = int(player.global_position.y / Globals.tileSize / Globals.chunkSize)
	
	if prevChunkPos.x != chunkPos.x:
		if prevChunkPos.x < chunkPos.x : # Player going right
			generateWorld(Vector2i(chunkPos.x + Globals.loadedChunkDistance, chunkPos.y - Globals.loadedChunkDistance),
						  Vector2i(chunkPos.x + Globals.loadedChunkDistance, chunkPos.y + Globals.loadedChunkDistance))
		else : # Player going left
			generateWorld(Vector2i(chunkPos.x - Globals.loadedChunkDistance, chunkPos.y - Globals.loadedChunkDistance),
						  Vector2i(chunkPos.x - Globals.loadedChunkDistance, chunkPos.y + Globals.loadedChunkDistance))
	if prevChunkPos.y != chunkPos.y:
		if prevChunkPos.y < chunkPos.y : # Player going down
			generateWorld(Vector2i(chunkPos.x - Globals.loadedChunkDistance, chunkPos.y + Globals.loadedChunkDistance),
						  Vector2i(chunkPos.x + Globals.loadedChunkDistance, chunkPos.y + Globals.loadedChunkDistance))
		else : # Player going up
			generateWorld(Vector2i(chunkPos.x - Globals.loadedChunkDistance, chunkPos.y - Globals.loadedChunkDistance),
						  Vector2i(chunkPos.x + Globals.loadedChunkDistance, chunkPos.y - Globals.loadedChunkDistance))
	
	time += delta
	if time >= 1.0 :
		time = 0
		#print (chunkPos)
	
	
	
func generateWorld(from: Vector2i, to: Vector2i) -> void:
	# Generates chunks
	print("Generating world from ", from, " to ", to, "...")

	for chunkY in range (from.y-1, to.y+1, 1):
		for chunkX in range (from.x-1, to.x+1, 1):
			if background.get_cell_source_id(Vector2i(chunkX * Globals.chunkSize, chunkY * Globals.chunkSize)) == -1:
				print("\t\tChunk ", Vector2i(chunkX, chunkY), " detected as unloaded !")
				for y in range(chunkY * Globals.chunkSize, (chunkY+1) * Globals.chunkSize, 1):
					for x in range(chunkX * Globals.chunkSize, (chunkX+1) * Globals.chunkSize, 1):
						background.set_cell(Vector2i(x, y), 0,Vector2i(randi_range(0,1),randi_range(0,1)))
						#set_cell(<cell position> Vector2i, <Tilse set id> Int, <position on atlas> Vector2i)
