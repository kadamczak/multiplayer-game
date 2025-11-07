extends Node2D

signal player_interacted()

@export var merchant_id: int = -1

var local_player_in_area: bool = false
@onready var area_2d = $Area2D


func _ready() -> void:
	if area_2d:
		area_2d.body_entered.connect(_on_body_entered)
		area_2d.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("get") and body.get("is_authority"):
		if body.is_authority:
			local_player_in_area = true

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("get") and body.get("is_authority"):
		if body.is_authority:
			local_player_in_area = false


func _process(_delta: float) -> void:
	if local_player_in_area and Input.is_action_just_pressed("ui_action"):
		player_interacted.emit()