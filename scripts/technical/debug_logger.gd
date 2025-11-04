extends Node
## Debug Logger - Adds instance name prefix to all debug messages

var instance_name: String = ""


func _ready() -> void:
	# Read --name argument from command line
	var args := OS.get_cmdline_args()
	for arg in args:
		if arg.begins_with("--name="):
			instance_name = arg.get_slice("=", 1)
			break
	
	if instance_name.is_empty():
		instance_name = "Client"
	
	print("[", instance_name, "] Debug logger initialized")


## Print with instance name prefix
func log(message: String) -> void:
	print("[", instance_name, "] ", message)


## Print with instance name prefix (alias for consistency with regular print)
func debug(message: String) -> void:
	print("[", instance_name, "] ", message)


## Print with instance name prefix and additional values
func logv(message: String, values: Array) -> void:
	var full_message = "[" + instance_name + "] " + message
	for value in values:
		full_message += " " + str(value)
	print(full_message)
