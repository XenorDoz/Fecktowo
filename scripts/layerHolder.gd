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
var tileID = 0 # Default tile ID will be grass

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
						
						# Choosing what type of tile do we want
						var neighborsID = getNeighbors(x, y)
						var possibleIds = []
						if not neighborsID.is_empty() :
							for id in neighborsID.keys():
								for i in range(neighborsID[id]):
									possibleIds.append(id)
							if neighborsID.keys().size() == 1 and neighborsID[neighborsID.keys()[0]] >= 4:
								for i in range(Globals.totalTileNumbre): # Add every ID possible to diversify
									possibleIds.append(i)
							tileID = possibleIds[randi() % possibleIds.size()]
						
						background.set_cell(Vector2i(x, y), tileID,Vector2i(randi_range(0,1),randi_range(0,1)))
						#set_cell(<cell position> Vector2i, <Tilse set id> Int, <position on atlas> Vector2i)
			
			# We check again cells to eliminate the ones that are too small
				for y in range(chunkY * Globals.chunkSize, (chunkY+1) * Globals.chunkSize, 1):
					for x in range(chunkX * Globals.chunkSize, (chunkX+1) * Globals.chunkSize, 1):
						var neighborsID = getNeighbors(x, y)
						
						# Checking if we have the dictionnary
						if not neighborsID.is_empty() :
							# Grabbing ID of the cell and check if neighbors have it too
							var currentID = background.get_cell_source_id((Vector2i(x,y)))
							var currentIDCount = 0
							if neighborsID.has(currentID):
								currentIDCount = neighborsID[currentID]
								
							# If less than 2 neighbors have this ID, then we give the same one as most of them
							if currentIDCount < 7:
								var maxCount = 0
								var majorID = currentID
								for id in neighborsID.keys():
									if neighborsID[id] > maxCount:
										maxCount = neighborsID[id]
										majorID = id
									background.set_cell(Vector2i(x,y), majorID, Vector2i(randi_range(0,1),randi_range(0,1)))


func getNeighbors(x: int, y: int) -> Dictionary :
	# Choosing what type of tile do we want
	var neighborsID = {}
	for neighborsY in range(y-1, y+2, 1):
		for neighborsX in range(x-1, x+2, 1):
			if neighborsY != y or neighborsX != x :
				var cellID = background.get_cell_source_id(Vector2i(neighborsX,neighborsY))
				if cellID != -1 :
					if neighborsID.has(cellID): # If ID has been seen we add 1 to it
						neighborsID[cellID] += 1
					else :  # Otherwise we create it
						neighborsID[cellID] = 1
	return neighborsID
