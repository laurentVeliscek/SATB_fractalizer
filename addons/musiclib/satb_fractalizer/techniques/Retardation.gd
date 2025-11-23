extends "res://addons/musiclib/satb_fractalizer/techniques/TechniqueBase.gd"

const TAG = "Retardation"

# =============================================================================
# RETARDATION
# =============================================================================
# Like suspension, but resolves UPWARD by step instead of downward
# A note is held over from the previous chord (creating dissonance)
# Then resolves UPWARD by step to a chord tone
# Pattern: held_pitch (from chord_a) → resolved_pitch (step up, in chord_b)
# =============================================================================

func get_id():
	return Constants.TECHNIQUE_RETARDATION

func applies(chord_a, chord_b, voice_id, progression):
	var from_pitch = chord_a.get_voice_pitch(voice_id)
	var to_pitch = chord_b.get_voice_pitch(voice_id)

	if from_pitch == null or to_pitch == null:
		return false

	# Retardation works when pitches are different
	if from_pitch == to_pitch:
		return false

	# Need at least 2 cells for retardation + resolution
	var n_cells = _get_n_cells(chord_a, chord_b, progression)
	if n_cells < 2:
		return false

	# Check if from_pitch can resolve UP by step to a diatonic pitch in chord_b's scale
	var scale_b = chord_b.scale_context
	if not scale_b.is_diatonic(from_pitch):
		LogBus.debug(TAG, "Retardation requires from_pitch to be diatonic in chord_b scale")
		return false

	var neighbors = scale_b.get_neighbor_pitches(from_pitch)
	if neighbors == null or neighbors["upper"] == null:
		return false

	# The resolution pitch should be close to the target to_pitch
	# For retardation to make sense, the resolution should lead naturally to to_pitch
	# Let's allow it if the upper neighbor exists
	return true

func apply(chord_a, chord_b, voice_id, progression, params):
	LogBus.info(TAG, "Applying retardation technique")

	var from_pitch = chord_a.get_voice_pitch(voice_id)
	var to_pitch = chord_b.get_voice_pitch(voice_id)
	var scale_b = chord_b.scale_context

	# The held pitch is from_pitch
	var held_pitch = from_pitch

	# Get the resolution pitch (step up in chord_b's scale)
	var neighbors = scale_b.get_neighbor_pitches(held_pitch)
	var resolved_pitch = neighbors["upper"]

	if resolved_pitch == null:
		LogBus.warn(TAG, "No upper neighbor found for retardation resolution")
		return null

	LogBus.debug(TAG, "Retardation: " + str(held_pitch) + " (held) → " + str(resolved_pitch) + " (resolved up)")

	# Choose rhythm pattern
	var n_cells = _get_n_cells(chord_a, chord_b, progression)
	var triplet_allowed = params.get("triplet_allowed", false)
	var rhythm_pattern = _choose_rhythm_pattern(
		n_cells,
		progression,
		Constants.TECHNIQUE_RETARDATION,
		triplet_allowed
	)

	# We want a 2-note pattern: retardation (longer) + resolution (shorter)
	if rhythm_pattern.pattern.size() != 2:
		# Retardation is typically longer than resolution (e.g., 3:1 ratio)
		var retardation_ratio = 0.75
		var retardation_duration = n_cells * retardation_ratio
		var resolution_duration = n_cells * (1.0 - retardation_ratio)
		rhythm_pattern = {
			"pattern": [retardation_duration, resolution_duration],
			"triplet": false
		}

	var pitches = [held_pitch, resolved_pitch]

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
		Constants.ROLE_RETARDATION,
		Constants.TECHNIQUE_RETARDATION,
		"retardation in " + voice_id + " between chord " + str(chord_a.id) + " and " + str(chord_b.id)
	)

	if new_chords == null or new_chords.empty():
		LogBus.warn(TAG, "Failed to create chords")
		return null

	LogBus.info(TAG, "Successfully applied retardation: " + str(new_chords.size()) + " chords inserted")
	return new_chords
