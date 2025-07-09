extends Node2D

const jsonLoader = preload("res://scripts/jsonLoader.gd")
const resourceClass = preload("res://classes/resourceClass.gd")
const clusterClass = preload("res://classes/clusterClass.gd")

# Waiting for these
@onready var backgroundWallpaper: TileMapLayer = $backgroundWallpaper
@onready var backgroundLayer: TileMapLayer = $background
@onready var resourcesLayer: TileMapLayer = $resources
@onready var hiddenResourcesLayer: TileMapLayer = $hiddenResources
@onready var chunkOutline: TileMapLayer = $chunkOutline
@onready var player: Node2D = $"../Player"

# Var used
var playerChunkPos: Vector2i
var toggleChunkOutline = false
var generatedChunks = {} # Chunks generated : {Vector2i(int, int)}

# Resource stuff
var resourceMap = {} # Resource cells of their own class, {Vector2i : resource}
var blockedChunksByResource = {} # Will have every info on what resources are blocked on that chunk, {id : {Vector2i, Vector2i...}
var clusterMap = {} # Cluster infos, will contain all clusters, {Vector2i : cluster}

var tileInfo = jsonLoader.loadJson("res://assets/tiles/groundTiles.json")
var resourceInfo = jsonLoader.loadJson("res://assets/tiles/resourceTiles.json")
# Var used just for tests
var time = 0.0
var reg = 0.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#seed(1234573756)
	
	# Setting up layers 
	backgroundLayer.z_index = -10
	backgroundWallpaper.z_index = backgroundLayer.z_index - 1
	resourcesLayer.z_index = backgroundLayer.z_index + 1
	chunkOutline.z_index = resourcesLayer.z_index + 1
	
	# Generating world spawn
	generateWorld(Vector2i(-Globals.loadedChunkDistance, -Globals.loadedChunkDistance),
				  Vector2i(Globals.loadedChunkDistance, Globals.loadedChunkDistance))
	#generateWorld2(Vector2i(-Globals.loadedChunkDistance, -Globals.loadedChunkDistance),
				  #Vector2i(Globals.loadedChunkDistance, Globals.loadedChunkDistance),
				  #5
				

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var prevChunkPos = playerChunkPos
	var px = player.global_position.x
	var py = player.global_position.y
	if px < 0:
		px -= Globals.tileSize
	if py < 0:
		py -= Globals.tileSize
		
	playerChunkPos.x = int(floor((px / Globals.tileSize / Globals.chunkSize)))
	playerChunkPos.y = int(floor((py / Globals.tileSize / Globals.chunkSize)))
	if prevChunkPos.x != playerChunkPos.x:
		if prevChunkPos.x < playerChunkPos.x : # Player going right
			generateWorld(Vector2i(playerChunkPos.x + Globals.loadedChunkDistance, playerChunkPos.y - Globals.loadedChunkDistance),
						  Vector2i(playerChunkPos.x + Globals.loadedChunkDistance, playerChunkPos.y + Globals.loadedChunkDistance))
			#generateWorld2(Vector2i(chunkPos.x + Globals.loadedChunkDistance, chunkPos.y - Globals.loadedChunkDistance),
						  #Vector2i(chunkPos.x + Globals.loadedChunkDistance, chunkPos.y + Globals.loadedChunkDistance),
						  #1)
		else : # Player going left
			generateWorld(Vector2i(playerChunkPos.x - Globals.loadedChunkDistance, playerChunkPos.y - Globals.loadedChunkDistance),
						  Vector2i(playerChunkPos.x - Globals.loadedChunkDistance, playerChunkPos.y + Globals.loadedChunkDistance))
			#generateWorld2(Vector2i(chunkPos.x - Globals.loadedChunkDistance, chunkPos.y - Globals.loadedChunkDistance),
						  #Vector2i(chunkPos.x - Globals.loadedChunkDistance, chunkPos.y + Globals.loadedChunkDistance),
						  #3)
	if prevChunkPos.y != playerChunkPos.y:
		if prevChunkPos.y < playerChunkPos.y : # Player going down
			generateWorld(Vector2i(playerChunkPos.x - Globals.loadedChunkDistance, playerChunkPos.y + Globals.loadedChunkDistance),
						  Vector2i(playerChunkPos.x + Globals.loadedChunkDistance, playerChunkPos.y + Globals.loadedChunkDistance))
			#generateWorld2(Vector2i(chunkPos.x - Globals.loadedChunkDistance, chunkPos.y + Globals.loadedChunkDistance),
						  #Vector2i(chunkPos.x + Globals.loadedChunkDistance, chunkPos.y + Globals.loadedChunkDistance),
						  #2)
		else : # Player going up
			generateWorld(Vector2i(playerChunkPos.x - Globals.loadedChunkDistance, playerChunkPos.y - Globals.loadedChunkDistance),
						  Vector2i(playerChunkPos.x + Globals.loadedChunkDistance, playerChunkPos.y - Globals.loadedChunkDistance))
			#generateWorld2(Vector2i(chunkPos.x - Globals.loadedChunkDistance, chunkPos.y - Globals.loadedChunkDistance),
						  #Vector2i(chunkPos.x + Globals.loadedChunkDistance, chunkPos.y - Globals.loadedChunkDistance),
						  #0)
	
	if Input.is_action_just_pressed("chunkOutline"):
		toggleChunkOutline = not toggleChunkOutline
		showChunkOutline(toggleChunkOutline)
			
	time += delta
	if time > 1:
		time = 0
		

func generateWorld(from: Vector2i, to: Vector2i) -> void:
	# Generates chunks
	# from is the top-left corner chunk, to is the bottom-right corner
	generateResources_async(from, to)
	generateBackgroundWallpaper_async(from,to)
	for yChunk in range(from.y, to.y+1, 1):
		for xChunk in range(from.x, to.x+1, 1):
			# Checking if chunk is not already loaded
			if not isChunkGenerated(Vector2i(xChunk, yChunk)) :
				for y in range(yChunk * Globals.chunkSize, (yChunk + 1) * Globals.chunkSize, 1):
					for x in range(xChunk * Globals.chunkSize, (xChunk + 1) * Globals.chunkSize, 1):
						# Placing cells
						backgroundLayer.set_cell(Vector2i(x,y), tileInfo[randi() % tileInfo.size()]["id"], Vector2i(randi_range(0,1),randi_range(0,1)))

						# Chunk borders
						var localX = x - xChunk * Globals.chunkSize
						var localY = y - yChunk * Globals.chunkSize
						
						if (localX == 0 or localX == Globals.chunkSize - 1
							or localY == 0 or localY == Globals.chunkSize - 1):
								chunkOutline.set_cell(Vector2i(x,y), 0, Vector2i(0,0))
				showResoucesOnChunk(Vector2i(xChunk,yChunk))
				markChunkGenerated(Vector2i(xChunk,yChunk))
	
	pass 

func generateResources_async(from: Vector2i, to: Vector2i) -> void:
	var chunkRadius := int(ceil(float(Globals.defaultMaxRadius) / Globals.chunkSize))
	var extendFrom = from - Vector2i(chunkRadius, chunkRadius)
	var extendTo = to + Vector2i(chunkRadius, chunkRadius)
	
	var chunksToCheck := []
	
	for yChunk in range(extendFrom.y, extendTo.y+1, 1):
		for xChunk in range(extendFrom.x, extendTo.x+1, 1):
			chunksToCheck.append(Vector2i(xChunk, yChunk))
	
	chunksToCheck.shuffle()
	for chunk in chunksToCheck:
		await get_tree().process_frame
		if not clusterMap.has(chunk):
			# Grabbing infos about if we can generate it depending on distance
			@warning_ignore("integer_division")
			var chunkPos = Vector2i(chunk.x * Globals.chunkSize + Globals.chunkSize / 2,
											   chunk.y * Globals.chunkSize + Globals.chunkSize / 2)
			var chunkDistFromCenter = chunkPos.length()
			var radius = clamp(Globals.defaultMinRadius + int(pow(chunkDistFromCenter / 100, 0.55)),
								  Globals.defaultMinRadius, Globals.defaultMaxRadius)
			
			# Checking for every id if it's far enough from others
			for res in resourceInfo:
				var id = res["id"]
				if canGenerateClusterAt(chunkPos, id, radius):
					var clusterPos = Vector2i(randi_range(0,15) + chunk.x * Globals.chunkSize, randi_range(0,15) + chunk.y *Globals.chunkSize)
					var newCluster = clusterClass.new(clusterPos,id, radius)
					var tilesCreated = newCluster.generateResources()
					updateMapFromClusterPlaced(newCluster)
					for key in tilesCreated.keys():
						hiddenResourcesLayer.set_cell(tilesCreated[key].position, tilesCreated[key].id, tilesCreated[key].sprite)
						resourceMap[key] = tilesCreated[key]
			pass
	
	pass

func generateBackgroundWallpaper_async(from: Vector2i, to: Vector2i) -> void:
	var loadDistance = clamp(Globals.loadedChunkDistance * 2, 20, 30)
	var expandedFrom = Vector2i(from.x - loadDistance, from.y - loadDistance/2)
	var expandedTo = Vector2i(to.x + loadDistance, to.y + loadDistance/2)
	var textureSize = backgroundWallpaper.tile_set.get_tile_size()
	var tilesToModifyX = range(expandedFrom.x * Globals.chunkSize, expandedTo.x * Globals.chunkSize, textureSize.x)
	var tilesToModifyY = range(expandedFrom.y * Globals.chunkSize, expandedTo.y * Globals.chunkSize, textureSize.y)
	var i = 0
	for x in range(expandedFrom.x, expandedTo.x + 1):
		for y in range(expandedFrom.y, expandedTo.y + 1):
			i += 1
			if i > 5 :
				await get_tree().process_frame
				i = 0
			if backgroundWallpaper.get_cell_source_id(Vector2i(x,y)) != 0:
				backgroundWallpaper.set_cell(Vector2i(x,y), 0, Vector2i(0,0))



func isChunkGenerated(chunk: Vector2i) -> bool:
	return generatedChunks.has(chunk)
	
func markChunkGenerated(chunk: Vector2i) -> void:
	generatedChunks[chunk] = true

func showChunkOutline(toggle: bool) -> void:
	if toggle : 
		chunkOutline.show()
	else:
		chunkOutline.hide()

func getChunkOfTile(pos: Vector2i) -> Vector2i:
	if pos.x < 0:
		pos.x -= Globals.chunkSize
	if pos.y < 0:
		pos.y -= Globals.chunkSize
	@warning_ignore("integer_division")
	return(Vector2i(int(pos.x / Globals.chunkSize), int(pos.y / Globals.chunkSize))) 

func canGenerateClusterAt(pos: Vector2i, id: int, rad: int) -> bool:
	if blockedChunksByResource.has(id) and blockedChunksByResource[id].has(pos):
		# If that chunk cannot receive that resource
		return false
	var chunkDistFromCenter = pos.length()
	var minClusterDistance = int((Globals.defaultMinDistance
				+ pow(chunkDistFromCenter, 1.05) * 0.2
				+ log(chunkDistFromCenter + 10) * 12) * randf_range(0.8,1.2))
	for existingCluster in clusterMap.keys():
		if id == clusterMap[existingCluster].id :
			# If it's same resource, we check if it's far enough
			if (clusterMap[existingCluster].origin - pos).length() < minClusterDistance:
				return false
		else:
			# Otherwise, we just check that does not overlap any other
			if (clusterMap[existingCluster].origin - pos).length() < rad + clusterMap[existingCluster].radius:
				return false
	return true

func updateMapFromClusterPlaced(cluster : clusterClass) -> void:
	var chunkPos = getChunkOfTile(cluster.origin)
	var clusterId = cluster.id
	@warning_ignore("integer_division")
	var offset = 1 + cluster.radius/Globals.chunkSize
	
	# Adding cluster to cluster map
	clusterMap[chunkPos] = cluster
	# Blocking that chunk position and around from having any cluster
	
	for x in range(chunkPos.x - offset, chunkPos.x + offset + 1, 1):
		for y in range (chunkPos.y - offset, chunkPos.y + offset + 1, 1):
			var pos = Vector2i(x,y)
			for resId in resourceInfo :
				var id = resId["id"]
				if not blockedChunksByResource.has(id):
					blockedChunksByResource[id] = {}
				blockedChunksByResource[id][pos] = true
					
	# Blocking all around that cluster the same id bc we know they'll be too close 
	var minClusterDistance = int((Globals.defaultMinDistance
				+ pow(cluster.origin.length(), 1.05) * 0.2
				+ log(cluster.origin.length() + 10) * 12) * 0.8)
	var offsetChunkDistance = int(minClusterDistance / Globals.chunkSize)
	for x in range(chunkPos.x - offsetChunkDistance, chunkPos.x + offsetChunkDistance + 1, 1):
		for y in range (chunkPos.y - offsetChunkDistance, chunkPos.y + offsetChunkDistance + 1, 1):
			var pos = Vector2i(x,y)
			if not blockedChunksByResource.has(clusterId):
				blockedChunksByResource[clusterId] = {}
			blockedChunksByResource[clusterId][pos] = true

func showResoucesOnChunk(chunk: Vector2i) -> void:
	for x in range(chunk.x * Globals.chunkSize, (chunk.x + 1) * Globals.chunkSize, 1):
		for y in range(chunk.y * Globals.chunkSize, (chunk.y + 1) * Globals.chunkSize, 1):
			var cellID = hiddenResourcesLayer.get_cell_source_id(Vector2i(x,y))
			if cellID != -1:
				var cell = resourceMap.get(Vector2i(x,y))
				resourcesLayer.set_cell(cell.position, cell.id, cell.sprite)
				hiddenResourcesLayer.erase_cell(cell.position)
				pass
				
func print_generated_chunks() -> void:
	if generatedChunks.is_empty():
		print("No chunk generated.")
		return

	print("Generated chunks :")
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
