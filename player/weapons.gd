extends Node
#handle weapons
var can_shoot = 1
func _process(delta: float) -> void:
	if Input.is_action_pressed("attack") and can_shoot == 1:
		$pistol.play("shoot")
		$"../../sfx/weapon/pistol_shoot".play()
		can_shoot = 0


func _on_pistol_animation_finished() -> void:
	can_shoot = 1
	$pistol.play("default")
