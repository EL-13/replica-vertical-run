extends CanvasLayer


# setup the label for countdown indicator
func set_label_text(value):
	$ShadePanel/StartLabel.text = str(value)

# start the countdown tween animation
func start_tween():
	var tween = $ShadePanel/StartLabel.create_tween()
	tween.tween_method(set_label_text, 4, 1, 3.0).set_ease(Tween.EASE_IN_OUT)
	$ShadePanel/StartLabel.text = ""
	$CountdownAudio.play()
