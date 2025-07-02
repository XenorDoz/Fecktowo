extends Node2D

var speed = 200 # Move speed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Player loaded")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	move(delta)
	

func move(delta : float) -> void :
	var moveVector = Vector2.ZERO
	
	# Keyboard inputs
	if Input.is_action_pressed("moveUp"):
		moveVector.y -= 1
	if Input.is_action_pressed("moveDown"):
		moveVector.y += 1
	if Input.is_action_pressed("moveLeft"):
		moveVector.x -= 1
	if Input.is_action_pressed("moveRight"):
		moveVector.x += 1
	
	# Normalization, so no fast diagonals
	if moveVector.length() > 0:
		moveVector = moveVector.normalized()
	
	# Moving player
	self.position += moveVector * speed * delta
