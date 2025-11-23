extends Node

const TAG = "ProgressionAdapter"
const Constants = preload("res://addons/musiclib/satb_fractalizer/core/Constants.gd")

var ScaleContext = load("res://addons/musiclib/satb_fractalizer/core/ScaleContext.gd")
var Voice = load("res://addons/musiclib/satb_fractalizer/core/Voice.gd")
var Chord = load("res://addons/musiclib/satb_fractalizer/core/Chord.gd")
var TimeGrid = load("res://addons/musiclib/satb_fractalizer/core/TimeGrid.gd")
var Progression = load("res://addons/musiclib/satb_fractalizer/core/Progression.gd")

# =============================================================================
# JSON ARRAY → PROGRESSION
# =============================================================================

func from_json_array(chords_array, time_num, time_den, grid_unit):
	LogBus.info(TAG, "Converting JSON array to Progression (" + str(chords_array.size()) + " chords)")

	var prog = Progression.new()
	prog.time_grid = TimeGrid.new(time_num, time_den, grid_unit)

	for i in range(chords_array.size()):
		var json_chord = chords_array[i]

		# Build ScaleContext
		var scale = ScaleContext.new(
			json_chord.key_midi_root,
			json_chord.scale_array,
			json_chord.get("key_alterations", {}),
			json_chord.get("key_scale_name", "unknown")
		)

		# Build Voices
		var voices = {}
		for voice_id in Constants.VOICES:
			var json_voice_name = Constants.VOICE_TO_JSON[voice_id]

			if not json_chord.has(json_voice_name):
				LogBus.error(TAG, "from_json_array: missing voice " + json_voice_name + " in chord " + str(i))
				return null

			voices[voice_id] = Voice.new(
				json_chord[json_voice_name],  # pitch
				Constants.ROLE_CHORD_TONE,
				null,  # technique
				Constants.DIRECTION_STATIC,
				false,  # locked
				{}  # metadata
			)

		# Build Chord
		var chord = Chord.new(
			json_chord.get("index", i),
			float(json_chord.pos),
			float(json_chord.length_beats),
			voices,
			scale,
			json_chord.get("kind", "diatonic")
		)

		prog.add_chord(chord)

	LogBus.info(TAG, "Conversion complete: " + str(prog.get_chord_count()) + " chords")
	return prog

# =============================================================================
# PROGRESSION → JSON ARRAY
# =============================================================================

func to_json_array(progression):
	LogBus.info(TAG, "Converting Progression to JSON array (" + str(progression.get_chord_count()) + " chords)")

	var result = []

	for chord in progression.chords:
		var json_chord = {
			"index": chord.id,
			"pos": chord.start_time,
			"length_beats": chord.duration,
			"key_midi_root": chord.scale_context.root,
			"scale_array": chord.scale_context.steps.duplicate(),
			"key_alterations": chord.scale_context.alterations.duplicate(),
			"key_scale_name": chord.scale_context.scale_name,
			"kind": chord.kind
		}

		# Add voices
		for voice_id in Constants.VOICES:
			var json_voice_name = Constants.VOICE_TO_JSON[voice_id]

			if chord.voices.has(voice_id):
				json_chord[json_voice_name] = chord.voices[voice_id].pitch
			else:
				LogBus.error(TAG, "to_json_array: missing voice " + voice_id + " in chord " + str(chord.id))
				return null

		result.append(json_chord)

	LogBus.info(TAG, "Conversion complete: " + str(result.size()) + " chords")
	return result
