extends Node2D

const jsonLoader = preload("res://scripts/jsonLoader.gd")

# Waiting for these
@onready var background: TileMapLayer = $background
@onready var chunkOutline: TileMapLayer = $chunkOutline
@onready var player: Node2D = $"../Player"

# Var used
var chunkPos: Vector2i
var toggleChunkOutline = false
var generatedChunks = {}

var tile = jsonLoader.loadJson("res://assets/tiles/groundTiles.json")

# Var used just for tests
var time = 0.0
var reg = 0.5


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#seed(1234573756)
	generateWorld(Vector2i(-Globals.loadedChunkDistance, -Globals.loadedChunkDistance),
				  Vector2i(Globals.loadedChunkDistance, Globals.loadedChunkDistance))
	#generateWorld2(Vector2i(-Globals.loadedChunkDistance, -Globals.loadedChunkDistance),
				  #Vector2i(Globals.loadedChunkDistance, Globals.loadedChunkDistance),
				  #5)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var prevChunkPos = chunkPos
	
	
	var px = player.global_position.x
	var py = player.global_position.y
	if px < 0:
		px -= Globals.tileSize
	if py < 0:
		py -= Globals.tileSize
		
	chunkPos.x = int(floor((px / Globals.tileSize / Globals.chunkSize)))
	chunkPos.y = int(floor((py / Globals.tileSize / Globals.chunkSize)))
	if prevChunkPos.x != chunkPos.x:
		if prevChunkPos.x < chunkPos.x : # Player going right
			generateWorld(Vector2i(chunkPos.x + Globals.loadedChunkDistance, chunkPos.y - Globals.loadedChunkDistance),
						  Vector2i(chunkPos.x + Globals.loadedChunkDistance, chunkPos.y + Globals.loadedChunkDistance))
			#generateWorld2(Vector2i(chunkPos.x + Globals.loadedChunkDistance, chunkPos.y - Globals.loadedChunkDistance),
						  #Vector2i(chunkPos.x + Globals.loadedChunkDistance, chunkPos.y + Globals.loadedChunkDistance),
						  #1)
		else : # Player going left
			generateWorld(Vector2i(chunkPos.x - Globals.loadedChunkDistance, chunkPos.y - Globals.loadedChunkDistance),
						  Vector2i(chunkPos.x - Globals.loadedChunkDistance, chunkPos.y + Globals.loadedChunkDistance))
			#generateWorld2(Vector2i(chunkPos.x - Globals.loadedChunkDistance, chunkPos.y - Globals.loadedChunkDistance),
						  #Vector2i(chunkPos.x - Globals.loadedChunkDistance, chunkPos.y + Globals.loadedChunkDistance),
						  #3)
	if prevChunkPos.y != chunkPos.y:
		if prevChunkPos.y < chunkPos.y : # Player going down
			generateWorld(Vector2i(chunkPos.x - Globals.loadedChunkDistance, chunkPos.y + Globals.loadedChunkDistance),
						  Vector2i(chunkPos.x + Globals.loadedChunkDistance, chunkPos.y + Globals.loadedChunkDistance))
			#generateWorld2(Vector2i(chunkPos.x - Globals.loadedChunkDistance, chunkPos.y + Globals.loadedChunkDistance),
						  #Vector2i(chunkPos.x + Globals.loadedChunkDistance, chunkPos.y + Globals.loadedChunkDistance),
						  #2)
		else : # Player going up
			generateWorld(Vector2i(chunkPos.x - Globals.loadedChunkDistance, chunkPos.y - Globals.loadedChunkDistance),
						  Vector2i(chunkPos.x + Globals.loadedChunkDistance, chunkPos.y - Globals.loadedChunkDistance))
			#generateWorld2(Vector2i(chunkPos.x - Globals.loadedChunkDistance, chunkPos.y - Globals.loadedChunkDistance),
						  #Vector2i(chunkPos.x + Globals.loadedChunkDistance, chunkPos.y - Globals.loadedChunkDistance),
						  #0)
	
	if Input.is_action_just_pressed("chunkOutline"):
		toggleChunkOutline = not toggleChunkOutline
		showChunkOutline(toggleChunkOutline)
			
	time += delta

func generateWorld(from: Vector2i, to: Vector2i) -> void:
	# Generates chunks
	# from is the top-left corner chunk, to is the bottom-right corner
	for yChunk in range(from.y, to.y+1, 1):
		for xChunk in range(from.x, to.x+1, 1):
			# Checking if chunk is not already loaded
			if not isChunkGenerated(Vector2i(xChunk, yChunk)) :
				for y in range(yChunk * Globals.chunkSize, (yChunk + 1) * Globals.chunkSize, 1):
					for x in range(xChunk * Globals.chunkSize, (xChunk + 1) * Globals.chunkSize, 1):
						background.set_cell(Vector2i(x,y), tile[randi() % tile.size()]["id"], Vector2i(randi_range(0,1),randi_range(0,1)))
						
						var localX = x - xChunk * Globals.chunkSize
						var localY = y - yChunk * Globals.chunkSize
						
						if (localX == 0 or localX == Globals.chunkSize - 1
							or localY == 0 or localY == Globals.chunkSize - 1):
								chunkOutline.set_cell(Vector2i(x,y), 0, Vector2i(0,0))

				markChunkGenerated(Vector2i(xChunk,yChunk))
	pass 

func generateResources(x: int, y: int) -> void:
	pass

func isChunkGenerated(chunk : Vector2i) -> bool:
	return generatedChunks.has(chunk)
	
func markChunkGenerated(chunk : Vector2i) -> void:
	generatedChunks[chunk] = true

func showChunkOutline(toggle : bool) -> void:
	if toggle : 
		chunkOutline.show()
	else:
		chunkOutline.hide()
	
func print_generated_chunks() -> void:
	if generatedChunks.is_empty():
		print("Aucun chunk généré.")
		return

	print("Chunks générés :")
	for coords in generatedChunks.keys():
		var data = generatedChunks[coords]
		if typeof(data) == TYPE_DICTIONARY:
			var parts := []
			for key in data.keys():
				parts.append("%s: %s" % [key, data[key]])
			print("- Chunk (%d, %d) → {%s}" % [coords.x, coords.y, ", ".join(parts)])
		else:
			print("- Chunk (%d, %d) → %s" % [coords.x, coords.y, str(data)])

# Keeping the code for later...
# It is bugged, but one solution would be to instead of get a range of coords,
# Grab array of couples of coords that is chunks that need to be generated
# -> Generation will be chunk by chunk, but if there are multiple chunks in a row
#	 Would like to instead make it one big rectangular chunk so we generate one
#	whole line / column, instead of chunk by chunk, would help to reduce noise  

#func generateWorld2(from: Vector2i, to: Vector2i, dir : int) -> void:
	## Generates chunks selecting the direction to use
	## we check which direction by using dir // 2 for first dir, and dir % 2 for second dir
	## from = top-left chunk, to = bottom-left chunk
	## firstDir : 0 = north, 1 = east, 2 = south, 3 = west
	## secondDir : 0 = west or north, 1 = east or south (depending on firstDir)
	#
	#var step = Vector2i(-(dir-2),(dir-1))
	#
	## Grabbing all chunks needed to change
	#
	#var xChunkRange = customRange(from.x, to.x + 1, 1)
	#var yChunkRange = customRange(from.y, to.y + 1, 1)
	#if step.x == -1 : xChunkRange.reverse()
	#if step.y == -1 : yChunkRange.reverse()
	#
	#var xTileRange = []
	#var yTileRange = []
	## Acutally modifying them
	#if dir % 2 == 1: # If we generate whole columns
		#for xChunk in xChunkRange:
			#for yChunk in yChunkRange:
				#if background.get_cell_source_id(Vector2i(xChunk * Globals.chunkSize, yChunk * Globals.chunkSize)) == -1:
					## Chunk has not been generated for now
					#xTileRange = customRange(xChunk * Globals.chunkSize, (xChunk+1) * Globals.chunkSize, 1)
					#yTileRange = customRange(yChunk * Globals.chunkSize, (yChunk+1) * Globals.chunkSize, 1)
					#if step.x == -1 : xTileRange.reverse()
					#if step.y == -1 : yTileRange.reverse()
					#var matChunk = [[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]]
					#var bwa = 1
					#for xTile in xTileRange:
						#var row = []
						#for yTile in yTileRange:
							#matChunk[yTile%16][xTile%16] = bwa
							#bwa += 1	
							#chooseTileID(xTile,yTile)
					#
					#if time > reg : 
						#print("\n\n\n\n\n")
						#for y in matChunk:
							#print(y)
					#time = 0
					#for xTile in xTileRange:
						#for yTile in yTileRange:
							#applyRules(xTile,yTile)
	#else: # if we generate whole rows
		#for yChunk in yChunkRange:
			#for xChunk in xChunkRange:
				#if background.get_cell_source_id(Vector2i(xChunk * Globals.chunkSize, yChunk * Globals.chunkSize)) == -1:
					## Chunk has not been generated for now
					#xTileRange = customRange(xChunk * Globals.chunkSize, (xChunk+1) * Globals.chunkSize, 1)
					#yTileRange = customRange(yChunk * Globals.chunkSize, (yChunk+1) * Globals.chunkSize, 1)
					#if step.x == -1 : xTileRange.reverse()
					#if step.y == -1 : yTileRange.reverse()
					#var matChunk = [[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]]
					#var bwa = 1
					#for yTile in yTileRange:
						#var row = []
						#for xTile in xTileRange:
							#matChunk[yTile%16][xTile%16] = bwa
							#bwa += 1	
							#chooseTileID(xTile,yTile)
					#
					#if time > reg : 
						#print("\n\n\n\n\n")
						#for y in matChunk:
							#print(y)
					#time = 0
					#for yTile in yTileRange:
						#for xTile in xTileRange:
							#applyRules(xTile,yTile)
	#pass
	#
#func customRange(x : int, y : int, step : int) -> Array:
	#var myRange = []
	#if step > 0 :
		#if x > y:
			#print("Can't do range of (%s, %s, %s)" %[x,y,step])
		#else :
			#while x < y:
				#myRange.append(x)
				#x += step
	#else :
		#if x < y:
			#print("Can't do range of (%s, %s, %s)" %[x,y,step])
		#else :
			#while x > y:
				#myRange.append(x)
				#x += step
	#return myRange 
#
#func chooseTileID(x : int, y : int) -> void:
	#var neighborsID = getNeighbors(x, y)
	#var possibleIds = []
	#
	#if not neighborsID.is_empty():
		#var totalNeighbors = 0
		#for count in neighborsID.values():
			#totalNeighbors += count
			#
		#for i in Globals.totalTileNumber:
			## Checking neighbors around
			#var id = Globals.availableTiles[i]
			#var globalProb = Globals.tileProbability[i]
			#var neighborCount = neighborsID.get(id,0)
			#var weight = (globalProb * 0.6 + float(neighborCount) / float(totalNeighbors) * 0.4)
			#
			#for j in range(int(weight * 100)):
				#possibleIds.append(id)
				#
	#else:
		## If no neighbors, then just pick one randomly
		#for i in Globals.totalTileNumber:
			#var id = Globals.availableTiles[i]
			#var prob = Globals.tileProbability[i]
			#for j in range(int(prob * 100)):
				#possibleIds.append(id)
		## No neighbors
	## Choosing ID
	#tileID = possibleIds[randi() % possibleIds.size()]
	#background.set_cell(Vector2i(x, y), tileID,Vector2i(randi_range(0,1),randi_range(0,1)))
	##if not neighborsID.is_empty() :
		##for id in neighborsID.keys():
			##for i in range(neighborsID[id]):
				##possibleIds.append(id)
		##if neighborsID.keys().size() == 1 and neighborsID[neighborsID.keys()[0]] >= rule1:
			##for i in range(Globals.totalTileNumber): # Add every ID possible to diversify
				##for j in range(Globals.tileProbability[i] * 100): 
					##possibleIds.append(Globals.availableTiles[i])
		##tileID = possibleIds[randi() % possibleIds.size()]
	##background.set_cell(Vector2i(x, y), tileID,Vector2i(randi_range(0,1),randi_range(0,1)))
	##set_cell(<cell position> Vector2i, <Tilse set id> Int, <position on atlas> Vector2i)
#
#func applyRules(x : int, y : int) -> void:
	#var neighborsID = getNeighbors(x, y)
#
	## Checking if we have the dictionnary
	#if not neighborsID.is_empty() :
		## Grabbing ID of the cell and check if neighbors have it too
		#var currentID = background.get_cell_source_id((Vector2i(x,y)))
		#var currentIDCount = 0
		#if neighborsID.has(currentID):
			#currentIDCount = neighborsID[currentID]
		## If less than <rule2> neighbors have this ID, then we give the same one as most of them
		#if currentIDCount < rule2:
			#var maxCount = 0
			#var majorID = currentID
			#for id in neighborsID.keys():
				#if neighborsID[id] > maxCount:
					#maxCount = neighborsID[id]
					#majorID = id
			#background.set_cell(Vector2i(x,y), majorID, Vector2i(randi_range(0,1),randi_range(0,1)))
#
#func getNeighbors(x: int, y: int) -> Dictionary :
	## Choosing what type of tile do we want
	#var neighborsID = {}
	#for neighborsY in range(y-1, y+2, 1):
		#for neighborsX in range(x-1, x+2, 1):
			#if neighborsY != y or neighborsX != x :
				#var cellID = background.get_cell_source_id(Vector2i(neighborsX,neighborsY))
				#if cellID != -1 :
					#if neighborsID.has(cellID): # If ID has been seen we add 1 to it
						#neighborsID[cellID] += 1
					#else :  # Otherwise we create it
						#neighborsID[cellID] = 1
	#return neighborsID
