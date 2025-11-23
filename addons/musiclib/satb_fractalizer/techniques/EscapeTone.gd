extends "res://addons/musiclib/satb_fractalizer/techniques/TechniqueBase.gd"

const TAG = "EscapeTone"

# =============================================================================
# ESCAPE TONE (Échappée)
# =============================================================================
# Pattern: chord_tone → step (up/down) → leap (opposite direction) to target
# Example: C → D (step up) → A (leap down)
# The escape note leaves by step and resolves by leap in the opposite direction
# =============================================================================

func get_id():
	return Constants.TECHNIQUE_ESCAPE_TONE

func applies(chord_a, chord_b, voice_id, progression):
	var from_pitch = chord_a.get_voice_pitch(voice_id)
	var to_pitch = chord_b.get_voice_pitch(voice_id)

	if from_pitch == null or to_pitch == null:
		return false

	# Escape tone works best when pitches are different
	if from_pitch == to_pitch:
		return false

	# Need at least 3 cells for 3-note pattern (step + leap)
	var n_cells = _get_n_cells(chord_a, chord_b, progression)
	if n_cells < 3:
		return false

	return true

func apply(chord_a, chord_b, voice_id, progression, params):
	LogBus.info(TAG, "Applying escape_tone technique")

	var from_pitch = chord_a.get_voice_pitch(voice_id)
	var to_pitch = chord_b.get_voice_pitch(voice_id)
	var scale = chord_a.scale_context

	# Choose direction for the step (up or down)
	var step_direction = "upper"
	if params.has("escape_step_direction"):
		step_direction = params["escape_step_direction"]
	else:
		# Random choice
		step_direction = "upper" if (progression.rng.randi() % 2 == 0) else "lower"

	# Get the escape pitch (step from anchor)
	var neighbor_pitches = scale.get_neighbor_pitches(from_pitch)
	if neighbor_pitches == null:
		LogBus.warn(TAG, "No diatonic neighbors found for escape anchor " + str(from_pitch))
		return null

	var escape_pitch = neighbor_pitches["upper"] if step_direction == "upper" else neighbor_pitches["lower"]
	if escape_pitch == null:
		LogBus.warn(TAG, "No " + step_direction + " neighbor found for escape anchor " + str(from_pitch))
		return null

	# The leap direction is opposite to step direction
	# If we stepped up, we leap down to target (and vice versa)
	var leap_direction = Constants.DIRECTION_DESCENDING if step_direction == "upper" else Constants.DIRECTION_ASCENDING

	# Build the 3-note pattern
	var pitches = [from_pitch, escape_pitch, to_pitch]

	LogBus.debug(TAG, "Escape tone: " + str(from_pitch) + " → " + str(escape_pitch) + " (step " + step_direction + ") → " + str(to_pitch) + " (leap " + leap_direction + ")")

	# Choose rhythm pattern
	var n_cells = _get_n_cells(chord_a, chord_b, progression)
	var triplet_allowed = params.get("triplet_allowed", false)
	var rhythm_pattern = _choose_rhythm_pattern(
		n_cells,
		progression,
		Constants.TECHNIQUE_ESCAPE_TONE,
		triplet_allowed
	)

	# Force 3-note pattern if needed
	if rhythm_pattern.pattern.size() != 3:
		var cell_per_note = n_cells / 3.0
		rhythm_pattern = {
			"pattern": [cell_per_note, cell_per_note, cell_per_note],
			"triplet": false
		}

	# Validate NCT pitches
	if not _validate_nct_pitches(pitches, from_pitch, to_pitch):
		LogBus.warn(TAG, "NCT validation failed")
		return null

	# Create the new chords
	var new_chords = _create_chords_from_pattern(
		chord_a,
		chord_b,
		voice_id,
		pitches,
		rhythm_pattern,
		progression,
		Constants.ROLE_ESCAPE_TONE,
		Constants.TECHNIQUE_ESCAPE_TONE,
		"escape_tone in " + voice_id + " between chord " + str(chord_a.id) + " and " + str(chord_b.id)
	)

	if new_chords == null or new_chords.empty():
		LogBus.warn(TAG, "Failed to create chords")
		return null

	LogBus.info(TAG, "Successfully applied escape_tone: " + str(new_chords.size()) + " chords inserted")
	return new_chords
