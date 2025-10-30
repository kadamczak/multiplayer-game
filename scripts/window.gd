extends Node

# grid layout for windows (2x2 for 4 clients)
const COLS := 2
const ROWS := 2
const PADDING := 8 # pixels between windows

func _ready() -> void:
	# read index from command-line e.g. --window-index=0
	var index := -1
	var args := OS.get_cmdline_args()
	for a in args:
		if a.begins_with("--window-index="):
			index = int(a.get_slice("=", 1))
			break

	# fallback deterministic index (so simultaneous runs don't all stack)
	if index == -1:
		# use low-entropy but consistent seed: time-based
		var time_seed := Time.get_ticks_msec()
		index = int(time_seed % (COLS * ROWS))

	# clamp
	index = clamp(index, 0, COLS * ROWS - 1)

	# get primary screen size (Godot 4)
	var screen_id := DisplayServer.window_get_current_screen()
	var screen_size := DisplayServer.screen_get_size(screen_id)

	# compute target window size / grid cell
	var cell_w := int(screen_size.x / COLS)
	var cell_h := int(screen_size.y / ROWS)

	var col := index % COLS
	var row := index / COLS

	var pos := Vector2i(col * cell_w + PADDING, row * cell_h + PADDING)

	# set window position (Godot 4)
	DisplayServer.window_set_position(pos)
	print("Window positioned at index ", index, " -> ", pos)