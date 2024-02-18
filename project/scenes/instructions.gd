extends CanvasLayer


signal start_game

var instructions_p1
var instructions_p2


# setup the InstructionsMenu scene
func _ready():
	instructions_p1 = get_tree().get_nodes_in_group("Instructions_P1")
	instructions_p2 = get_tree().get_nodes_in_group("Instructions_P2")
	
	for i in instructions_p2:
		i.hide()


func _on_next_button_pressed():
	for i in instructions_p1:
		i.hide()
	
	for j in instructions_p2:
		j.show()

func _on_start_game_button_pressed():
	start_game.emit()
