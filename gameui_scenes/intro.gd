extends TextureRect

func _ready():
	# Start the timer
	await get_tree().create_timer(2.0).timeout
	fade_out()

func _input(event):
	# Check for any button/key press
	if event is InputEventKey or event is InputEventMouseButton:
		if event.pressed:
			fade_out()

func fade_out():
	# Create a tween for smooth fade out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	# Optional: queue_free() if you want to remove the node after fading
	tween.tween_callback(queue_free)
