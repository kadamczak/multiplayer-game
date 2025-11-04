extends CharacterBody2D

const SPEED: float = 300.0
const JUMP_VELOCITY: float = -700.0

var is_authority: bool:
	get: return !NetworkHandler.is_server && owner_id == ClientNetworkGlobals.id
	
# The peer_id of some particular player
# The client has 1 NetworkPlayer for each player
var owner_id: int
var player_username: String = ""

@onready var label = $Label
@onready var sprite = $AnimatedSprite2D

func _ready():
	if is_authority:
		var camera = Camera2D.new()
		add_child(camera)
		camera.enabled = true
		z_index = 1
	else:
		z_index = 0
	
	# Check if username already exists for this player
	if ClientNetworkGlobals.player_usernames.has(owner_id):
		player_username = ClientNetworkGlobals.player_usernames[owner_id]
		label.text = player_username

func _enter_tree() -> void:
	ServerNetworkGlobals.handle_player_position.connect(server_handle_player_position)
	ClientNetworkGlobals.handle_player_position.connect(client_handle_player_position)
	ClientNetworkGlobals.handle_player_username.connect(client_handle_player_username)
	ClientNetworkGlobals.handle_player_animation.connect(client_handle_player_animation)


func _exit_tree() -> void:
	ServerNetworkGlobals.handle_player_position.disconnect(server_handle_player_position)
	ClientNetworkGlobals.handle_player_position.disconnect(client_handle_player_position)
	ClientNetworkGlobals.handle_player_username.disconnect(client_handle_player_username)
	ClientNetworkGlobals.handle_player_animation.disconnect(client_handle_player_animation)

# local player -> server communication
func _physics_process(delta: float) -> void:
	if !is_authority: return
	
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Get horizontal input (A/D keys map to ui_left/ui_right)
	var direction := Input.get_axis("ui_left", "ui_right")
	
	# Determine which animation should play
	var target_animation := ""
	if not is_on_floor():
		target_animation = "air"
	elif direction != 0:
		target_animation = "walk"
	else:
		target_animation = "idle"
	
	# Only play animation if it's different from current
	if sprite.animation != target_animation:
		sprite.play(target_animation)
	
	# Handle horizontal movement and sprite flipping
	if direction != 0:
		velocity.x = direction * SPEED
		# Flip sprite based on movement direction
		if direction > 0:
			sprite.flip_h = true
		elif direction < 0:
			sprite.flip_h = false
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()
	PlayerPosition.create(owner_id, global_position).send(NetworkHandler.server_peer)
	PlayerAnimation.create(owner_id, sprite.animation, sprite.flip_h).send(NetworkHandler.server_peer)

# server -> all players
func server_handle_player_position(peer_id: int, player_position: PlayerPosition) -> void:
	if owner_id != peer_id: return
	global_position = player_position.position
	PlayerPosition.create(owner_id, global_position).broadcast(NetworkHandler.connection)
	
# handles other players on the client
func client_handle_player_position(player_position: PlayerPosition) -> void:
	if is_authority || owner_id != player_position.id: return
	global_position = player_position.position

# handles username updates on the client
func client_handle_player_username(username_packet: PlayerUsername) -> void: #13
	print("Player ", owner_id, " received username packet for ID ", username_packet.id, ": ", username_packet.username)
	if owner_id != username_packet.id: return
	player_username = username_packet.username
	label.text = player_username
	print("Player ", owner_id, " updated label to: ", label.text)

# handles animation updates on the client
func client_handle_player_animation(anim_packet: PlayerAnimation) -> void:
	if is_authority || owner_id != anim_packet.id: return
	# Only play animation if it's different from current
	if sprite.animation != anim_packet.animation_name:
		sprite.play(anim_packet.animation_name)
	sprite.flip_h = anim_packet.flip_h
