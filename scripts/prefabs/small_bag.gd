extends Area2D

@export var currency_value: int = 5
@export var pickup_id: String = ""

func _ready():
	# Generate unique ID if not set
	if pickup_id.is_empty():
		pickup_id = str(global_position.x) + "_" + str(global_position.y)

func _on_body_entered(body: Node2D) -> void:
	# Check if the body is a player and if it's the local player (authority)
	if body is CharacterBody2D and body.has_method("get") and body.get("is_authority"):
		if body.is_authority:
			ClientNetworkGlobals.balance += currency_value
			
			# Send pickup request to server for validation
			# Server will:
			# 1. Validate pickup exists and wasn't already collected
			# 2. Validate player is close enough
			# 3. Apply currency change
			# 4. Broadcast removal to all clients
			# 5. Send corrected balance back if needed
			send_pickup_request()
			
			# Optional: Play pickup sound/animation here
			# AudioStreamPlayer2D.play()
			
			# Hide immediately for instant feedback (server will confirm removal)
			visible = false
			monitoring = false  # Disable collision to prevent double-pickup
			
func send_pickup_request() -> void:
	# TODO: Create and send PickupItem packet to server
	# Server validates and processes the pickup
	# Format: { pickup_id, player_id, pickup_type, expected_value }
	
	# Placeholder - you'll need to create this packet type
	# PickupRequest.create(ClientNetworkGlobals.id, pickup_id, currency_value).send(NetworkHandler.server_peer)
	
	# For now, just remove locally (will need sync in multiplayer)
	queue_free()
