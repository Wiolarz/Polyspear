extends hitbox

var active_status = true

func active_state_change():
	if active_status:
		active_status = false
		monitorable = false
		$ShieldSprite.modulate = "ffffff40" 

	else:
		active_status = true
		monitorable = true
		$ShieldSprite.modulate = "ffffff"


func destruction():
	queue_free()