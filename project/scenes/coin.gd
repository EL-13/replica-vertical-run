extends Area2D


signal collect


func _on_body_entered(_body):
	collect.emit()
	queue_free()
