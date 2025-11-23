extends "res://addons/musiclib/satb_fractalizer/techniques/TechniqueBase.gd"

const TAG = "Anticipation"

# =============================================================================
# ANTICIPATION
# =============================================================================
# A note from the next chord is played early (anticipation)
# Pattern: from_pitch → to_pitch (early, before chord change)
# The anticipated pitch then continues into the next chord
# =============================================================================

func get_id():
	return Constants.TECHNIQUE_ANTICIPATION

func applies(chord_a, chord_b, voice_id, progression):
	var from_pitch = chord_a.get_voice_pitch(voice_id)
	var to_pitch = chord_b.get_voice_pitch(voice_id)

	if from_pitch == null or to_pitch == null:
		return false

	# Anticipation requires different pitches
	if from_pitch == to_pitch:
		return false

	# Need at least 2 cells for anticipation
	var n_cells = _get_n_cells(chord_a, chord_b, progression)
	if n_cells < 2:
		return false

	# The anticipated note (to_pitch) should be diatonic in the NEXT chord's scale
	if not chord_b.scale_context.is_diatonic(to_pitch):
		return false

	return true

func apply(chord_a, chord_b, voice_id, progression, params):
	LogBus.info(TAG, "Applying anticipation technique")

	var from_pitch = chord_a.get_voice_pitch(voice_id)
	var to_pitch = chord_b.get_voice_pitch(voice_id)

	# The anticipation is simply the to_pitch played early
	# We insert one chord with to_pitch before chord_b
	var anticipation_pitch = to_pitch

	LogBus.debug(TAG, "Anticipation: " + str(from_pitch) + " → " + str(anticipation_pitch) + " (early)")

	# Choose rhythm pattern for single anticipation note
	var n_cells = _get_n_cells(chord_a, chord_b, progression)

	# For anticipation, we want the anticipated note to be shorter (weak beat)
	# Let's use a simple pattern where most of the time is on from_pitch
	# and a short anticipation at the end
	var triplet_allowed = params.get("triplet_allowed", false)
	var rhythm_pattern = _choose_rhythm_pattern(
		n_cells,
		progression,
		Constants.TECHNIQUE_ANTICIPATION,
		triplet_allowed
	)

	# We want a 2-note pattern: long from_pitch, short to_pitch (anticipation)
	if rhythm_pattern.pattern.size() != 2:
		# Create a pattern favoring the first note
		var anticipation_ratio = 0.25  # Anticipation is 1/4 of total duration
		var from_duration = n_cells * (1.0 - anticipation_ratio)
		var anticipation_duration = n_cells * anticipation_ratio
		rhythm_pattern = {
			"pattern": [from_duration, anticipation_duration],
			"triplet": false
		}

	var pitches = [from_pitch, anticipation_pitch]

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
		Constants.ROLE_ANTICIPATION,
		Constants.TECHNIQUE_ANTICIPATION,
		"anticipation in " + voice_id + " between chord " + str(chord_a.id) + " and " + str(chord_b.id)
	)

	if new_chords == null or new_chords.empty():
		LogBus.warn(TAG, "Failed to create chords")
		return null

	LogBus.info(TAG, "Successfully applied anticipation: " + str(new_chords.size()) + " chords inserted")
	return new_chords
