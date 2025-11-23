extends Node

# Example test script for SATB Fractalizer
# This demonstrates how to use the system

const TAG = "TestExample"
const Planner = preload("res://addons/musiclib/satb_fractalizer/planner/Planner.gd")

func run():
	LogBus.info(TAG, "===== SATB Fractalizer Test =====")
	LogBus.set_verbose(true)

	# Load test chords
	var test_chords = _create_test_chords()

	# Configure planner
	var planner = Planner.new()
	var params = {
		"time_num": 4,
		"time_den": 4,
		"grid_unit": 0.25,
		"time_windows": [
			{"start": 0.0, "end": 4.0},
			{"start": 4.0, "end": 8.0}
		],
		"allowed_techniques": ["passing_tone", "neighbor_tone"],
		"voice_window_pattern": "SA",
		"triplet_allowed": false
	}

	# Apply fractalizer
	var result = planner.apply(test_chords, params)

	# Display result
	LogBus.info(TAG, "===== Result =====")
	LogBus.info(TAG, "Original chords: " + str(test_chords.size()))
	LogBus.info(TAG, "Result chords: " + str(result.size()))
	LogBus.info(TAG, "Result: " + JSON.print(result, "\t"))

	LogBus.info(TAG, "===== Test Complete =====")

func _create_test_chords():
	# Create a simple 4-chord progression in C major
	return [
		{
			"index": 0,
			"pos": 0,
			"length_beats": 2,
			"key_midi_root": 60,
			"scale_array": [0, 2, 4, 5, 7, 9, 11],
			"key_alterations": {},
			"key_scale_name": "major",
			"kind": "diatonic",
			"Soprano": 72,
			"Alto": 67,
			"Tenor": 64,
			"Bass": 48
		},
		{
			"index": 1,
			"pos": 2,
			"length_beats": 2,
			"key_midi_root": 60,
			"scale_array": [0, 2, 4, 5, 7, 9, 11],
			"key_alterations": {},
			"key_scale_name": "major",
			"kind": "diatonic",
			"Soprano": 76,
			"Alto": 69,
			"Tenor": 64,
			"Bass": 52
		},
		{
			"index": 2,
			"pos": 4,
			"length_beats": 2,
			"key_midi_root": 60,
			"scale_array": [0, 2, 4, 5, 7, 9, 11],
			"key_alterations": {},
			"key_scale_name": "major",
			"kind": "diatonic",
			"Soprano": 74,
			"Alto": 67,
			"Tenor": 62,
			"Bass": 50
		},
		{
			"index": 3,
			"pos": 6,
			"length_beats": 2,
			"key_midi_root": 60,
			"scale_array": [0, 2, 4, 5, 7, 9, 11],
			"key_alterations": {},
			"key_scale_name": "major",
			"kind": "diatonic",
			"Soprano": 72,
			"Alto": 64,
			"Tenor": 60,
			"Bass": 48
		}
	]
