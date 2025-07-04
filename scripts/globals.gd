extends Node

# Forced parameters
var chunkSize = 16 # Number of tiles in a chunk
var tileSize = 16 # Size of a tile
var availableTiles = [0,1,2,3] # IDs of tiles wanted
var tileProbability = [0.5, 0.5, 0.5, 0.5] # Should be equal to 1
var totalTileNumber = availableTiles.size() # Number of textures available for tile generation

# Player-toggled parameters
var loadedChunkDistance = 2 # Number of chunks created around the player (in a square)
