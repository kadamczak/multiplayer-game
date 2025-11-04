extends Area2D
## Portal - teleports players to another scene in multiplayer

@export var destination_scene: String = "res://scenes/levels/level1.tscn"
@export var portal_name: String = "Portal"


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("get") and body.get("is_authority"):
		if body.is_authority:
			_travel_to_destination(body)


func _on_body_exited(_body: Node2D) -> void:
	# Not needed anymore since we travel immediately
	pass


func _travel_to_destination(player: Node2D) -> void:
	print("Traveling to: ", destination_scene)
	
	# Get player ID before scene change
	var player_id = player.owner_id
	print("Player ", player_id, " is traveling to ", destination_scene)
	
	# Notify server and other clients about scene change
	if NetworkHandler.server_peer != null:
		PlayerSceneChange.create(player_id, destination_scene).send(NetworkHandler.server_peer)
		print("Sent scene change notification to server")
	
	# Update local scene tracking
	ClientNetworkGlobals.current_scene = destination_scene
	
	# Change scene
	get_tree().change_scene_to_file(destination_scene)
