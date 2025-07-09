extends Node

# Forced parameters
var chunkSize = 16 # Number of tiles in a chunk
var tileSize = 16 # Size of a tile
var defaultPlayerSpeed = 400 # Player speed while moving

# Resources parameters
var defaultMinRichness = 15000
var defaultMaxRichness = 15000000
var defaultMinDistance = 120
var defaultMaxDistance = 8000
var defaultMinRadius = 5
var defaultMaxRadius = 50

# Player-toggled parameters
var loadedChunkDistance = 10 # Number of chunks created around the player (in a square)
