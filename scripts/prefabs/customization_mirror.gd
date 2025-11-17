extends Node2D

@onready var interaction_area = $InteractionArea
@onready var customization_ui = $CustomizationUI

var local_player_in_range: bool = false
var local_customization: PlayerCustomization = null


func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	
	customization_ui.part_changed.connect(_on_part_changed)
	customization_ui.cancelled.connect(_on_ui_cancelled)
	customization_ui.applied.connect(_on_customization_applied)


func _on_body_entered(body: Node2D) -> void:
	if not _is_local_player(body):
		return
	
	local_player_in_range = true
	local_customization = body.get_node_or_null("PlayerCustomization") as PlayerCustomization


func _on_body_exited(body: Node2D) -> void:
	if not _is_local_player(body):
		return

	local_player_in_range = false
	local_customization = null
	customization_ui.hide_ui()


func _input(event: InputEvent) -> void:
	if local_player_in_range and event.is_action_pressed("ui_accept"):
		customization_ui.show_ui(local_customization.active_player_customization)
		get_viewport().set_input_as_handled()


func _on_part_changed(part_name: String) -> void:
	var part = local_customization.active_player_customization[part_name]
	local_customization.apply_customization(part)


func _on_ui_cancelled() -> void:
	local_customization.apply_all_customization()


func _on_customization_applied() -> void:
	var applied_customization = UserModels.UpdateUserCustomizationRequest.new(local_customization.active_player_customization)
	var response = await UserAPI.update_user_customization(applied_customization)
	
	if response.success:
		customization_ui.hide_ui()
		
		# Send customization update to other players
		var packet = PlayerCustomizationPacket.create(
			ClientNetworkGlobals.id,
			local_customization.active_player_customization
		)
		packet.send(NetworkHandler.server_peer)
		DebugLogger.log("Sent customization update to server")
	else:
		var problem: ApiResponse.ProblemDetails = response.problem
		DebugLogger.error("Customization update failed: " + problem.title)


func _is_local_player(body: Node2D) -> bool:
	return (body is CharacterBody2D 
		and body.has_method("get") 
		and body.get("is_authority") 
		and body.is_authority)
