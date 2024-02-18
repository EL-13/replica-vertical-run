extends CanvasLayer


signal pause


func _on_pause_button_pressed():
	pause.emit()
