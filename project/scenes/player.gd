extends CharacterBody2D


signal hit_obstacle								# signal to be emitted when the player collide with an obstacle
signal start_game								# signal to be emitted when the timer runs out

@onready var main = get_node("/root/Main")		# main scene of the game
var speed: int									# player speed
var spd_multiplier: float = 1.05				# player speed multiplier
var tile_size									# tile size on map
var map_pos										# position of map

var length: int = 50							# threshold to determine if the player is swiping
var swiping: bool = false						# indicates if the player is swiping
var startPos: Vector2							# start position of which the player pressed to swipe
var curPos: Vector2								# current position of which the player is pressing
var threshold: int = 25							# distance threshold to determine swipe direction


# ========== SETUP ==========
# set up player for a new game
# player speed to 0
func _ready():
	speed = 0

# set up map and player for a new game
# reposition map
# set player sprite frame to the first frame
func reset():
	tile_size = main.TILE_SIZE * main.scale_final
	map_pos = (main.screen_x - (5 * tile_size.x)) / 2
	$PlayerSprite.frame = 0
# ========================================


# ========== RECURRING PROCESS ==========
# listen for player input
func _process(_delta):
	check_input()
	print(speed)

# move player
func _physics_process(_delta):
	velocity.y = -speed
	move_and_slide()

# check the type of input and call function accordingly
func check_input():
	if Input.is_action_just_pressed("Left"):
		move_left()
	elif Input.is_action_just_pressed("Right"):
		move_right()
	elif Input.is_action_just_pressed("press"):
		if swiping == false:
			swiping = true
			startPos = get_global_mouse_position()
		else: pass
	elif Input.is_action_pressed("press"):
		if swiping == true:
			curPos = get_global_mouse_position()
			if startPos.distance_to(curPos) >= length:
				check_swipe_direction()
			else: pass
		else: pass
	else:
		swiping = false

# check swipe direction
# ignore vertical swipe
func check_swipe_direction():
	if abs(startPos.y - curPos.y) <= threshold:
		swiping = false
		horizontal_swipe()
	elif abs(startPos.x - curPos.x) <= threshold:
		swiping = false
	else: pass

# keep player in lane whenever player moves from one lane to another
func in_line():
	if position.x >= (map_pos + (1.25 * tile_size.x)) and position.x <= (map_pos + (1.75 * tile_size.x)):
		position.x = (map_pos + (1.5 * tile_size.x))
	elif position.x >= (map_pos + (2.25 * tile_size.x)) and position.x <= (map_pos + (2.75 * tile_size.x)):
		position.x = (map_pos + (2.5 * tile_size.x))
	elif position.x >= (map_pos + (3.25 * tile_size.x)) and position.x <= (map_pos + (3.75 * tile_size.x)):
		position.x = (map_pos + (3.5 * tile_size.x))
	else: pass

# calculate player speed and apply
func adjust_player_speed():
	speed *= spd_multiplier

func set_speed():
	if speed == 0:
		speed = 250 * main.scale_final.x
	else: pass
# ========================================


# ========== INPUT HANDLING ==========
# move player left or right according to input
func horizontal_swipe():
	if startPos.x > curPos.x:
		move_left()
	elif startPos.x < curPos.x:
		move_right()
	else: pass

# move player one lane left
func move_left():
	if position.x > (map_pos + (2 * tile_size.x)):
		position.x -= tile_size.x
		position.x = int(position.x)
		in_line()
	else: pass

# move player one lane right
func move_right():
	if position.x < (map_pos + (3 * tile_size.x)):
		position.x += tile_size.x
		position.x = int(position.x)
		in_line()
	else: pass
# ========================================


# ========== CUES / SIGNALS ==========
func _on_timer_timeout():
	start_game.emit()
	$PlayerSprite.play()
	set_speed()

func _on_player_area_body_entered(_body):
	hit_obstacle.emit()
# ========================================
