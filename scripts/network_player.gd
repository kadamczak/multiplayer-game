extends CharacterBody2D

const SPEED: float = 500.0

var is_authority: bool:
	get: return !NetworkHandler.is_server && owner_id == ClientNetworkGlobals.id
	
# the peer_id of some particular player
# the client has 1 NetworkPlayer for each player
var owner_id: int

func _ready():
	if is_authority:
		var camera = Camera2D.new()
		add_child(camera)
		camera.enabled = true

func _enter_tree() -> void:
	ServerNetworkGlobals.handle_player_position.connect(server_handle_player_position)
	ClientNetworkGlobals.handle_player_position.connect(client_handle_player_position)


func _exit_tree() -> void:
	ServerNetworkGlobals.handle_player_position.disconnect(server_handle_player_position)
	ClientNetworkGlobals.handle_player_position.disconnect(client_handle_player_position)

# local player -> server communication
func _physics_process(delta: float) -> void:
	if !is_authority: return
	velocity = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * SPEED
	move_and_slide()
	PlayerPosition.create(owner_id, global_position).send(NetworkHandler.server_peer)

# server -> all players
func server_handle_player_position(peer_id: int, player_position: PlayerPosition) -> void:
	if owner_id != peer_id: return
	global_position = player_position.position
	PlayerPosition.create(owner_id, global_position).broadcast(NetworkHandler.connection)
	
# handles other players on the client
func client_handle_player_position(player_position: PlayerPosition) -> void:
	if is_authority || owner_id != player_position.id: return
	global_position = player_position.position
