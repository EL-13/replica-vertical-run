extends Node2D


# map scenes
var map_start_scene = preload("res://scenes/start.tscn")
var map_0_scene = preload("res://scenes/map_0.tscn")
var map_1_scene = preload("res://scenes/map_1.tscn")
var map_2_scene = preload("res://scenes/map_2.tscn")
var map_3_scene = preload("res://scenes/map_3.tscn")
var map_4_scene = preload("res://scenes/map_4.tscn")
var map_5_scene = preload("res://scenes/map_5.tscn")

# dictionary for map scenes numbering
@onready var maps_collection: Dictionary = {0:map_0_scene, 1:map_1_scene, 2:map_2_scene, \
											3:map_3_scene, 4:map_4_scene, 5:map_5_scene}

const MAP_HEIGHT: int = 2400					# default height of map
const TILE_SIZE: int = 80						# default width or height of a tile
const DEFAULT_X: float = 400.0					# default width of game
const DEFAULT_Y: float = 800.0					# default height of game
const DEFAULT_SHADE_PANEL_Y: float = 600.0		# default height of shade panel

var screen_x: int								# viewport width
var screen_y: int								# viewport height
var scale_x: float								# horizontal scale
var scale_y: float								# vertical scale
var scale_final: Vector2						# final scale vector
var scaled_pos_x: float							# position in x-direction after scale applied
var scaled_pos_y: float							# position in y-direction after scale applied

var start_map									# first map
var map											# map, an element contained in maps
var maps										# an array of maps

var cam_start_pos: Vector2						# initial position of camera
var cam_pos										# position of camera
var player_pos									# position of player
var curr_multiplier: float						# current level the player in
var next_multiplier: int						# next level the player in
var can_add_map: bool							# used to determine if a map can be added to game
var is_game_over: bool							# used to determine if a game is over

const SCORE_MULTIPLIER: float = 150.0			# score multiplier
var score: int									# player's score
var coin_score: int								# number of coins collected

const DIFFICULTY_MULTIPLIER: int = 15			# score interval between two consecutive levels
var difficulty: int								# game level
var prev_difficulty: int						# previous game level
var curr_difficulty: int						# current game level


# ========== SETUP ==========
# run once whenever the game is loaded
# setup the game
func _ready():
	get_tree().paused = true
	new_game()
	$Instructions.show()

# run once whenever a new game is started
func new_game():
	calculate_scale()
	reset_stats()
	reset_map()
	adjust_scale()
	can_add_map = true
	difficulty = 0
	prev_difficulty = difficulty
	$Player.speed = 0
	$StartMenu.hide()
	$PauseMenu.hide()
	$CreditsMenu.hide()
	$GameOverMenu.hide()
	$ExitMenu.hide()
	$Player.reset()

# reset the score and coins collected from previous game
func reset_stats():
	score = 0
	coin_score = 0
	update_label()

# reset the map
# clear all maps in game and setup a new start_map
func reset_map():
	get_tree().call_group("Maps", "queue_free")
	start_map = map_start_scene.instantiate()
	start_map.scale = scale_final
	start_map.position.x = scaled_pos_x
	start_map.position.y = -MAP_HEIGHT * scale_final.y
	start_map.collect_coin.connect(gain_coin)
	add_child(start_map)

# reset the instructions scene
func reset_instructions():
	var instructions_p1 = $Instructions.get_tree().get_nodes_in_group("Instructions_P1")
	var instructions_p2 = $Instructions.get_tree().get_nodes_in_group("Instructions_P2")
	
	for j in instructions_p2:
		j.hide()
	
	for i in instructions_p1:
		i.show()

# calculate the scale of which the maps, camera, player and game assets needed to be resized to
func calculate_scale():
	screen_x = get_viewport_rect().size.x
	screen_y = get_viewport_rect().size.y
	scale_x = screen_x / DEFAULT_X
	scale_y = screen_y / DEFAULT_Y
	scale_final = Vector2(min(scale_x, scale_y), min(scale_x, scale_y))
	scale = scale_final
	scaled_pos_x = (screen_x - (DEFAULT_X * scale_final.x)) / 2
	scaled_pos_y = ((screen_y - (DEFAULT_SHADE_PANEL_Y * scale_final.y)) / 2)
	cam_start_pos = Vector2(screen_x / 2, -screen_y / 2)

# apply the change in size onto the maps, camera, player and game assets
# position them accordingly in game
func adjust_scale():
	$Camera2D.zoom = Vector2(1, 1) / scale_final
	$Camera2D.position = cam_start_pos
	$Player.scale = scale_final
	$Player.position = Vector2(screen_x / 2, -screen_y * 0.15)
	
	$HUD/Panel.scale = scale_final
	$HUD/Panel.position.x = scaled_pos_x
	
	var scale_scenes = get_tree().get_nodes_in_group("Scale2")
	for i in scale_scenes:
		var scene_panel = i.get_node("ShadePanel")
		scene_panel.scale = scale_final
		scene_panel.position.x = scaled_pos_x
		scene_panel.position.y = scaled_pos_y
# ========================================


# ========== RECURRING PROCESS ==========
# move camera and player
# calculate current game level and adjust player speed accordingly
# calculate and update player score
func _process(delta):
	maps = get_tree().get_nodes_in_group("Maps")
	move_camera(delta)
	cam_pos = $Camera2D.position
	player_pos = $Player.position
	$CoinAudio.position = player_pos
	$StartMenu/CountdownAudio.position = player_pos
	curr_multiplier = cam_pos.y / (-MAP_HEIGHT * scale_final.y)
	next_multiplier = roundi(curr_multiplier)
	score = round((-player_pos.y - 120) / SCORE_MULTIPLIER)
	update_label()
	adjust_speed()
	
	if next_multiplier > curr_multiplier and can_add_map:
		select_map()
		add_map(map, next_multiplier)
	elif next_multiplier <= curr_multiplier and !can_add_map:
		remove_map(maps)
	else: pass

# adjust player speed according to game level
func adjust_speed():
	curr_difficulty = floori(score / DIFFICULTY_MULTIPLIER)
	
	if curr_difficulty > prev_difficulty and difficulty < 20:
		difficulty += 1
		$Player.adjust_player_speed()
		prev_difficulty = curr_difficulty
	else: pass

# randomly select a map from maps_collection to be added to game
func select_map():
	var m = randi() % maps_collection.size()
	map = maps_collection[m]

# add map to game
func add_map(m, multiplier):
	var selected_map = m.instantiate()
	selected_map.scale = scale_final
	selected_map.position.x = scaled_pos_x
	selected_map.position.y = (multiplier + 1) * -MAP_HEIGHT * scale_final.y
	selected_map.collect_coin.connect(gain_coin)
	add_child(selected_map)
	can_add_map = false

# remove passed map
func remove_map(maps):
	if maps.size() > 2:
		maps[0].queue_free()
	else: pass
	
	can_add_map = true

# move camera to follow player's position
func move_camera(delta):
	if $Player.position.y <= -screen_y * 0.4:
		$Camera2D.position.y -= $Player.speed * delta / scale_final.y
	else: pass

# update number of coins gained
func gain_coin():
	$CoinAudio.play()
	coin_score += 1
	update_label()
# ========================================


# ========== GAME STATUS ==========
# update score and number of coins gained labels
func update_label():
	$HUD/Panel/ScoreLabel.text = str(score)
	$HUD/Panel/CoinLabel.text = "× " + str(coin_score)

# pause game and show the game over menu
func game_over():
	get_tree().paused = true
	is_game_over = true
	$GameOverMenu/ShadePanel/GameOverPanel/ScoreLabel.text = "DISTANCE: " + str(score) + "m"
	$GameOverMenu/ShadePanel/GameOverPanel/CoinLabel.text = "COINS: " + str(coin_score)
	$GameOverMenu.show()
# ========================================


# ========== CUES / SIGNALS ==========
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().paused = true
		$Player/StartTimer.stop()
		$StartMenu/CountdownAudio.stop()
		$Instructions.hide()
		$StartMenu.hide()
		$PauseMenu.hide()
		$CreditsMenu.hide()
		$GameOverMenu.hide()
		$ExitMenu.show()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().paused = true
		$Player/StartTimer.stop()
		$StartMenu/CountdownAudio.stop()
		$Instructions.hide()
		$StartMenu.hide()
		$PauseMenu.hide()
		$CreditsMenu.hide()
		$GameOverMenu.hide()
		$ExitMenu.show()
	else: pass

func _on_player_start_game():
	get_tree().paused = false
	is_game_over = false
	$StartMenu.hide()

func _on_player_hit_obstacle():
	game_over()

func _on_hud_pause():
	get_tree().paused = true
	$PauseMenu.show()

func _on_instructions_start_game():
	$Instructions.hide()
	$StartMenu.show()
	$StartMenu.start_tween()
	$Player/StartTimer.start()

func _on_pause_menu_credits():
	$PauseMenu.hide()
	$CreditsMenu/ShadePanel/CreditsPanel/CloseButton.hide()
	$CreditsMenu/ShadePanel/CreditsPanel/ResumeButton.show()
	$CreditsMenu.show()

func _on_pause_menu_resume():
	$PauseMenu.hide()
	$StartMenu.show()
	$StartMenu.start_tween()
	$Player/StartTimer.start()

func _on_credits_menu_close():
	$CreditsMenu.hide()
	$GameOverMenu.show()

func _on_credits_menu_resume():
	$CreditsMenu.hide()
	$PauseMenu.show()

func _on_game_over_menu_credits():
	$GameOverMenu.hide()
	$CreditsMenu/ShadePanel/CreditsPanel/ResumeButton.hide()
	$CreditsMenu/ShadePanel/CreditsPanel/CloseButton.show()
	$CreditsMenu.show()

func _on_game_over_menu_instructions():
	reset_instructions()
	new_game()
	$Instructions.show()

func _on_game_over_menu_restart():
	new_game()
	$StartMenu.show()
	$StartMenu.start_tween()
	$Player/StartTimer.start()

func _on_exit_menu_cancel():
	$ExitMenu.hide()
	if is_game_over == true:
		$GameOverMenu.show()
	else:
		$PauseMenu.show()

func _on_exit_menu_exit():
	get_tree().quit()
# ========================================
