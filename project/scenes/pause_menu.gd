extends CanvasLayer


signal resume
signal credits


func _on_resume_button_pressed():
	resume.emit()

func _on_credits_button_pressed():
	credits.emit()
