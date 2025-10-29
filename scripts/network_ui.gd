extends Control

func _on_server_button_pressed() -> void:
	NetworkHandler.start_server()


func _on_client_button_pressed() -> void:
	NetworkHandler.start_client()
