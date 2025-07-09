class_name ClusterInstance
extends RefCounted

const resourceClass = preload("res://classes/resourceClass.gd")

var id: int
var origin: Vector2i
var radius: int
var maxRichness: int
var positions:= {} # All cells in that cluster
var totalRichness: int 

func _init(_origin: Vector2i, _id: int, _radius: int) -> void :
	id = _id
	origin = _origin
	radius = _radius
	
	var distFromCenter = origin.length()
	maxRichness = clamp(int(log(distFromCenter + 10) * 20), Globals.defaultMinRichness, Globals.defaultMaxRichness)
	if id == 0:
		maxRichness = 1500
func updateCluster() -> void:
	
	pass

func generateResources() -> Dictionary :
	# Generates resources around the cluster
	var visitedTiles = {} # Different from resourcesGenerated, also has empty tiles
	var frontier = [origin]
	if id == 0:
		radius *= 5
	while frontier.size() > 0:
		var current = frontier.pop_front()
		
		# If already visited, we skip
		if visitedTiles.has(current):	continue
		visitedTiles[current] = true
		
		# If outside of the radius, we skip
		var dist = origin.distance_to(current)
		if dist > radius: continue
		
		var tier = getDistanceTier(dist, radius)
		var proba = getTileProbability(tier, current)
		
		# If resource is created
		if randf() <= proba:			
			var richness = calculateTileRichness(dist, radius, maxRichness)
			# Forcing richness for trees
			if id == 0 : richness = randi_range(1050,1500)
			var resource = resourceClass.new(id, richness, current)
			positions[current] = resource
			
			# Pushing frontier to neighbors
			for offset in [Vector2i(-1,-1),Vector2i(-1,0),Vector2i(-1,1),Vector2i(0,-1),Vector2i(0,1),Vector2i(1,-1),Vector2i(1,0),Vector2i(1,1),]:
				var neighbor = current + offset
				if not visitedTiles.has(neighbor):
					frontier.append(neighbor)
	
	removeUniqueEmpty(visitedTiles)
	
	return positions

func removeUniqueEmpty(visitedTiles: Dictionary ) -> void:
	for key in visitedTiles:
		if not positions.has(key):
			var neighborCount = 0
			for offset in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
				if positions.has(key + offset):
					neighborCount += 1
			if neighborCount >= 3:
				var dist = origin.distance_to(key)
				var richness = calculateTileRichness(dist, radius, maxRichness)
				# Forcing richness for trees
				if id == 0 : richness = randi_range(1050,1500)
				var cell = resourceClass.new(id, richness, key)
				positions[key] = cell

func getDistanceTier(dist: float, rad: int) -> int:
	var oneThird = rad / 3.0
	if dist <= oneThird: return 1
	elif dist <= 2.0 * oneThird: return 2
	else: return 3

func getTileProbability(tier: int, pos: Vector2i) -> float:
	# Gives proba for cell to spawn resource depending on where it is and its neighbors
	var baseProb := 0.0
	match tier:
		1: baseProb = 1.0
		2: baseProb = 0.6
		3: baseProb = 0.3
	
	var neighborCount = 0
	for offset in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
		if positions.has(pos + offset):
			neighborCount += 1
			
	var bonus = neighborCount * 0.15
	return min(baseProb + bonus, 0.85)

func calculateTileRichness(dist: float, rad: int, maxValue: int):
	var oneThird = rad / 3.0
	var percent := 0.0
	if dist <= oneThird:
		percent = 1.0 - - (dist / oneThird) * 0.1 # 90%-100%
	elif dist <= 2.0 * oneThird:
		percent = 0.9 - ((dist - oneThird) / oneThird) * 0.4 # 50%-90%
	else:
		percent = 0.5 - ((dist - 2.0 * oneThird) / oneThird) * 0.5 # 0%-50%
	return int(clamp(percent, 0.0, 1.0) * maxValue)

##### Resources at the end are very rich
##### Solution could be generate resources then attribute them richness
