extends Area2D

@export var currency_value: int = 5

func _on_body_entered(body: Node2D) -> void:
	# Check if the body is a player and if it's the local player (authority)
	if body is CharacterBody2D and body.has_method("get") and body.get("is_authority"):
		if body.is_authority:
			# Add currency to the local player
			ClientNetworkGlobals.balance += currency_value
			
			# Optional: Play pickup sound/animation here
			# AudioStreamPlayer2D.play()
			
			# Remove the pickup
			queue_free()
