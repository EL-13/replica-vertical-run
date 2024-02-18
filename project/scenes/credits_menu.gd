extends CanvasLayer


signal close
signal resume


func _on_close_button_pressed():
	close.emit()

func _on_resume_button_pressed():
	resume.emit()
