extends Area2D

@export var destination_scene: String = "res://scenes/levels/hub.tscn"
@export var portal_name: String = "Portal"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("get") and body.get("is_authority"):
		if body.is_authority:
			_travel_to_destination(body)


func _travel_to_destination(player: Node2D) -> void:
	var player_id = player.owner_id
	DebugLogger.log("Player " + str(player_id) + " is traveling to " + destination_scene)
	
	var current_scene_path = get_tree().current_scene.scene_file_path
	ClientNetworkGlobals.previous_scene = current_scene_path
	ClientNetworkGlobals.current_scene = destination_scene
	
	get_tree().change_scene_to_file(destination_scene)

	if NetworkHandler.server_peer != null:
		PlayerSceneChange.create(player_id, destination_scene).send(NetworkHandler.server_peer)
		DebugLogger.log("Sent scene change notification to server")
	
