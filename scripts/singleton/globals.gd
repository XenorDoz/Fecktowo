extends Node

# Forced parameters
var chunkSize = 16 # Number of tiles in a chunk
var tileSize = 16 # Size of a tile

# Resources parameters
var defaultMinRichness = 1500
var defaultMaxRichness = 1500000000
var defaultMinDistance = 120
var defaultMaxDistance = 8000
var defaultMinRadius = 5
var defaultMaxRadius = 50

# Player-toggled parameters
var loadedChunkDistance = 5 # Number of chunks created around the player (in a square)
