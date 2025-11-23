extends Node

const TAG = "Planner"
const Constants = preload("res://addons/musiclib/satb_fractalizer/core/Constants.gd")

var ProgressionAdapter = load("res://addons/musiclib/satb_fractalizer/core/ProgressionAdapter.gd")
var PassingTone = load("res://addons/musiclib/satb_fractalizer/techniques/PassingTone.gd")
var NeighborTone = load("res://addons/musiclib/satb_fractalizer/techniques/NeighborTone.gd")
var Appoggiatura = load("res://addons/musiclib/satb_fractalizer/techniques/Appoggiatura.gd")

# =============================================================================
# MAIN ENTRY POINT
# =============================================================================

func apply(chords_array, params):
	LogBus.info(TAG, "=== SATB Fractalizer: Starting ===")

	# Extract global params
	var time_num = params.get("time_num", Constants.DEFAULT_TIME_NUM)
	var time_den = params.get("time_den", Constants.DEFAULT_TIME_DEN)
	var grid_unit = params.get("grid_unit", Constants.DEFAULT_GRID_UNIT)
	var time_windows = params.get("time_windows", [])
	var voice_pattern = params.get("voice_window_pattern", Constants.DEFAULT_VOICE_PATTERN)
	var allowed_techniques = params.get("allowed_techniques", [
		Constants.TECHNIQUE_PASSING_TONE,
		Constants.TECHNIQUE_NEIGHBOR_TONE,
		Constants.TECHNIQUE_APPOGGIATURA
	])
	var triplet_allowed = params.get("triplet_allowed", Constants.DEFAULT_TRIPLET_ALLOWED)
	var pair_strategy = params.get("pair_selection_strategy", Constants.STRATEGY_EARLIEST)

	# 1. Convert JSON Array to Progression
	var adapter = ProgressionAdapter.new()
	var progression = adapter.from_json_array(chords_array, time_num, time_den, grid_unit)

	if not progression:
		LogBus.error(TAG, "Failed to convert JSON to Progression")
		return chords_array

	LogBus.info(TAG, "Converted to Progression: " + str(progression.get_chord_count()) + " chords")

	# 2. Process each time window
	for w in range(time_windows.size()):
		var window = time_windows[w]
		LogBus.info(TAG, "Processing window " + str(w) + ": [" + str(window.start) + ", " + str(window.end) + "]")

		# Get pattern voice for this window
		var pattern_voice = _get_pattern_voice(w, voice_pattern)
		LogBus.debug(TAG, "Pattern voice for window " + str(w) + ": " + pattern_voice)

		# Process window
		progression = _process_window(
			progression,
			window,
			pattern_voice,
			allowed_techniques,
			triplet_allowed,
			pair_strategy,
			params
		)

	# 3. Convert Progression back to JSON Array
	var result = adapter.to_json_array(progression)

	if not result:
		LogBus.error(TAG, "Failed to convert Progression to JSON")
		return chords_array

	LogBus.info(TAG, "=== SATB Fractalizer: Complete ===")
	return result

# =============================================================================
# GET PATTERN VOICE
# =============================================================================

func _get_pattern_voice(window_index, pattern):
	# pattern = "SA" → window 0: S, window 1: A, window 2: S, etc.
	var pattern_length = pattern.length()
	if pattern_length == 0:
		LogBus.warn(TAG, "_get_pattern_voice: empty pattern, using default S")
		return Constants.VOICE_SOPRANO

	var idx = window_index % pattern_length
	var char = pattern[idx]

	# Map character to voice ID
	if char == "S":
		return Constants.VOICE_SOPRANO
	elif char == "A":
		return Constants.VOICE_ALTO
	elif char == "T":
		return Constants.VOICE_TENOR
	elif char == "B":
		return Constants.VOICE_BASS
	else:
		LogBus.warn(TAG, "_get_pattern_voice: unknown voice char '" + char + "', using S")
		return Constants.VOICE_SOPRANO

# =============================================================================
# PROCESS WINDOW
# =============================================================================

func _process_window(progression, window, voice_id, allowed_techniques, triplet_allowed, pair_strategy, global_params):
	# Select and apply one technique for this window

	# Check if voice is modifiable
	if not _is_voice_modifiable(progression, voice_id):
		LogBus.warn(TAG, "Voice " + voice_id + " is not modifiable, skipping window")
		return progression

	# Select a technique
	var chosen_technique = _select_technique(allowed_techniques)
	if not chosen_technique:
		LogBus.warn(TAG, "No technique selected, skipping window")
		return progression

	LogBus.info(TAG, "Applying technique: " + chosen_technique + " on voice " + voice_id)

	# Create technique instance
	var technique = _create_technique_instance(chosen_technique)
	if not technique:
		LogBus.error(TAG, "Failed to create technique instance for " + chosen_technique)
		return progression

	# Prepare params for technique
	var technique_params = {
		"time_window": window,
		"voice": voice_id,
		"triplet_allowed": triplet_allowed,
		"pair_selection_strategy": pair_strategy
	}

	# Merge with global params (for technique-specific overrides)
	for key in global_params:
		if not technique_params.has(key):
			technique_params[key] = global_params[key]

	# Apply technique
	var new_progression = technique.apply(progression, technique_params)

	# Record in metadata
	# (TODO: add to progression.metadata.history)

	return new_progression

# =============================================================================
# VOICE MODIFIABILITY CHECK
# =============================================================================

func _is_voice_modifiable(progression, voice_id):
	# Check voice_policy if it exists
	if progression.voice_policy.has(voice_id):
		var policy = progression.voice_policy[voice_id]
		if policy.has("modifiable"):
			return policy.modifiable

	# Default: allow modification
	return true

# =============================================================================
# TECHNIQUE SELECTION
# =============================================================================

func _select_technique(allowed_techniques):
	# Simple selection: pick the first allowed technique
	# (TODO: implement weighted random, preferred order, etc.)

	if allowed_techniques.empty():
		return null

	# For now, randomly select from allowed
	var idx = randi() % allowed_techniques.size()
	return allowed_techniques[idx]

# =============================================================================
# TECHNIQUE INSTANTIATION
# =============================================================================

func _create_technique_instance(technique_id):
	if technique_id == Constants.TECHNIQUE_PASSING_TONE:
		return PassingTone.new()
	elif technique_id == Constants.TECHNIQUE_NEIGHBOR_TONE:
		return NeighborTone.new()
	elif technique_id == Constants.TECHNIQUE_APPOGGIATURA:
		return Appoggiatura.new()
	else:
		LogBus.error(TAG, "_create_technique_instance: unknown technique " + technique_id)
		return null
