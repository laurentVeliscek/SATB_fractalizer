# User Manual – SATB Fractalizer 

**Version 0.4**
**Platform: Godot 3.6**
**License: GNU GPL v3.0**

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Installation and Setup](#2-installation-and-setup)
3. [Getting Started](#3-getting-started)
4. [Data Format](#4-data-format)
5. [Configuration Parameters](#5-configuration-parameters)
6. [Composition Techniques](#6-composition-techniques)
7. [Practical Examples](#7-practical-examples)
8. [Advanced Features](#8-advanced-features)
9. [Troubleshooting](#9-troubleshooting)
10. [Quick Reference](#10-quick-reference)

---

## 1. Introduction

### 1.1 What is SATB Fractalizer?

**SATB Fractalizer** is an algorithmic composition tool designed to enrich four-part harmonic progressions (Soprano, Alto, Tenor, Bass) by inserting melodic ornamentations called **Passing Notes** or **Non-Chord Tones (NCTs)**.

### 1.2 Goals

* **Transform** simple chord progressions into elaborate contrapuntal textures
* **Add** classical melodic ornamentation techniques between structural chord tones
* **Preserve** musical correctness through voice-leading rules
* **Enable** progressive "fractalization" via successive passes (re-injection)

### 1.3 Core Concept

The system operates on time-based chord progressions, inserting decorative notes between structural notes while respecting classical music theory rules.

### 1.4 Who is this manual for?

* Composers and arrangers using Godot for music generation
* Developers integrating algorithmic generation into their projects
* Researchers in computational musicology
* Students in computer-assisted composition

---

## 2. Installation and Setup

### 2.1 Prerequisites

* **Godot Engine 3.6** (not compatible with Godot 4.x)
* Basic knowledge of GDScript
* Understanding of basic musical concepts (chords, voices, key)

### 2.2 Installation

#### Step 1: Copy the files

Copy the folder `/addons/musiclib/satb_fractalizer/` into your Godot project:

```text
your_project/
└── addons/
    └── musiclib/
        └── satb_fractalizer/
            ├── core/
            ├── techniques/
            ├── planner/
            ├── utils/
            └── tests/
```

#### Step 2: Install LogBus

The system uses a logging singleton called `LogBus`.

1. Open **Project Settings** → **Autoload**
2. Add a new entry:

   * **Name**: `LogBus`
   * **Path**: `res://LogBus.gd`
3. Click **Add**

#### Step 3: Check the installation

Create a test script:

```gdscript
extends Node

func _ready():
	var Planner = load("res://addons/musiclib/satb_fractalizer/planner/Planner.gd")
	var planner = Planner.new()
	print("SATB Fractalizer loaded successfully!")
```

### 2.3 Project Structure

```text
addons/musiclib/satb_fractalizer/
├── core/
│   ├── ProgressionAdapter.gd    # JSON ↔ internal format conversion
│   ├── Progression.gd           # Full progression with metadata
│   ├── Chord.gd                 # SATB chord with harmonic context
│   ├── Voice.gd                 # Individual voice with metadata
│   ├── ScaleContext.gd          # Scale and alterations system
│   ├── TimeGrid.gd              # Rhythmic grid and beat strength
│   └── Constants.gd             # Global constants
├── techniques/
│   ├── TechniqueBase.gd         # Abstract base class
│   └── [13 implemented techniques]
├── planner/
│   ├── Planner.gd               # Main orchestrator
│   └── RhythmPattern.gd         # Intelligent rhythm selection
└── utils/
    └── VoiceLeading.gd          # Voice-leading rules
```

---

## 3. Getting Started

### 3.1 Minimal Example

Here is a complete example to enrich a chord progression:

```gdscript
extends Node

const TAG = "MyScript"

func _ready():
	# 1. Enable logging
	LogBus.set_verbose(true)

	# 2. Load the Planner
	var Planner = load("res://addons/musiclib/satb_fractalizer/planner/Planner.gd")
	var planner = Planner.new()

	# 3. Load a progression (JSON file)
	var chords = _load_progression("res://chords.json")

	# 4. Configure parameters
	var params = {
		"time_num": 4,
		"time_den": 4,
		"grid_unit": 0.25,
		"time_windows": [
			{"start": 0.0, "end": 4.0}
		],
		"allowed_techniques": ["passing_tone", "neighbor_tone"],
		"voice_window_pattern": "SA",
		"rng_seed": 42
	}

	# 5. Apply fractalization
	var result = planner.apply(chords, params)

	# 6. Save the result
	_save_progression("res://chords_enrichis.json", result.chords)

	# 7. Display statistics
	LogBus.info(TAG, "Original chords: " + str(chords.size()))
	LogBus.info(TAG, "Enriched chords: " + str(result.chords.size()))
	LogBus.info(TAG, "Notes added: " + str(result.chords.size() - chords.size()))

func _load_progression(path):
	var file = File.new()
	if file.open(path, File.READ) != OK:
		LogBus.error(TAG, "Cannot read " + path)
		return []
	var content = file.get_as_text()
	file.close()
	return parse_json(content)

func _save_progression(path, chords):
	var file = File.new()
	if file.open(path, File.WRITE) != OK:
		LogBus.error(TAG, "Cannot write " + path)
		return
	file.store_string(JSON.print(chords, "\t"))
	file.close()
```

### 3.2 Expected Result

After running, you will get:

* A file `chords_enrichis.json` containing the enriched progression
* Logs detailing the applied techniques
* Statistics on the number of notes added

---

## 4. Data Format

### 4.1 Input Format (JSON)

Each chord is a JSON object with the following fields:

```json
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
}
```

#### Required Fields

| Field             | Type   | Description                                    |
| ----------------- | ------ | ---------------------------------------------- |
| `index`           | int    | Position in the sequence (starts at 0)         |
| `pos`             | float  | Start time in beats                            |
| `length_beats`    | float  | Duration in beats                              |
| `key_midi_root`   | int    | Key tonic pitch (MIDI, 60 = C4)                |
| `scale_array`     | Array  | Scale intervals (in semitones)                 |
| `key_alterations` | Dict   | Alterations: `{"4": 1}` = ♯4, `{"7": -1}` = ♭7 |
| `key_scale_name`  | String | Scale name: `"major"`, `"minor"`, etc.         |
| `kind`            | String | Chord type: `"diatonic"`, `"chromatic"`, etc.  |
| `Soprano`         | int    | MIDI pitch of the soprano                      |
| `Alto`            | int    | MIDI pitch of the alto                         |
| `Tenor`           | int    | MIDI pitch of the tenor                        |
| `Bass`            | int    | MIDI pitch of the bass                         |

#### Common Scales

```json
// Major (C major)
"scale_array": [0, 2, 4, 5, 7, 9, 11]

// Natural minor (A minor)
"scale_array": [0, 2, 3, 5, 7, 8, 10]

// Harmonic minor
"scale_array": [0, 2, 3, 5, 7, 8, 11]

// Melodic minor
"scale_array": [0, 2, 3, 5, 7, 9, 11]
```

### 4.2 Output Format

The Planner returns a dictionary with two keys:

```gdscript
{
	"chords": [...],      # Array of enriched chords
	"metadata": {         # Tracking information
		"generation_depth": 1,
		"rng_seed": 42,
		"global_params": {...},
		"history": [...],
		"technique_report": {...}
	}
}
```

#### Structure of Enriched Chords

Output chords contain:

* **Original chords** (possibly with adjusted durations)
* **New decorative chords** with `"kind": "decorative"`
* **Per-voice metadata** indicating roles: `"chord_tone"`, `"passing_tone"`, etc.

Example of a chord with voice metadata:

```json
{
  "Soprano": 72,
  "Soprano_role": "chord_tone",
  "Alto": 69,
  "Alto_role": "passing_tone",
  "Tenor": 64,
  "Tenor_role": "chord_tone",
  "Bass": 48,
  "Bass_role": "chord_tone"
}
```

### 4.3 Re-injection

The output `chords` array can be directly reused as input for another pass:

```gdscript
var result1 = planner.apply(chords, params1)
var result2 = planner.apply(result1.chords, params2)  # Second pass
var result3 = planner.apply(result2.chords, params3)  # Third pass
```

---

## 5. Configuration Parameters

### 5.1 Essential Parameters

#### time_num / time_den

```gdscript
"time_num": 4,        # Time signature numerator
"time_den": 4         # Time signature denominator
```

* Defines the meter (4/4, 3/4, 6/8, etc.)
* Affects beat-strength calculation (strong/weak beats)

#### grid_unit

```gdscript
"grid_unit": 0.25     # Minimum rhythmic subdivision in beats
```

* **0.25** = eighth notes
* **0.125** = sixteenth notes
* **0.5** = quarter notes
* Determines the fineness of available subdivisions

#### time_windows

```gdscript
"time_windows": [
	{"start": 0.0, "end": 4.0},    # Bars 1–4
	{"start": 4.0, "end": 8.0},    # Bars 5–8
	{"start": 8.0, "end": 12.0}    # Bars 9–12
]
```

* Defines time segments where techniques are applied
* Each window processes **a single voice** (chosen by the pattern)
* Each window applies **at most one technique**

#### allowed_techniques

```gdscript
"allowed_techniques": [
	"passing_tone",
	"neighbor_tone",
	"appoggiatura",
	"suspension"
]
```

* List of techniques allowed for this pass
* See [6. Composition Techniques](#6-composition-techniques)

#### voice_window_pattern

```gdscript
"voice_window_pattern": "SATB"
```

* Controls which voice is modified in each window
* **"SA"**: Window 0 = Soprano, Window 1 = Alto, Window 2 = Soprano…
* **"SATB"**: Full rotation through the four voices
* **"SSAA"**: More activity in Soprano/Alto
* **"TB"**: Tenor and Bass only

### 5.2 Advanced Parameters

#### rng_seed

```gdscript
"rng_seed": 42        # Random seed (null = timestamp)
```

* Makes results exactly reproducible
* Useful for debugging and comparison

#### triplet_allowed

```gdscript
"triplet_allowed": false
```

* Allows triplet subdivisions
* Not implemented in the current version

#### pair_selection_strategy

```gdscript
"pair_selection_strategy": "earliest"  # or "longest"
```

* **"earliest"**: chooses the first valid chord pair
* **"longest"**: chooses the pair with the longest duration

#### technique_weights

```gdscript
"technique_weights": {
	"passing_tone": 1.0,              # Normal weight
	"chromatic_passing_tone": 0.3,    # Less likely
	"appoggiatura": 1.5,              # More likely
	"suspension": 0.8
}
```

* Controls the probability of each technique
* Default weight = 1.0
* Helps create specific musical styles

### 5.3 Full Configuration Example

```gdscript
var params = {
	# Meter and grid
	"time_num": 4,
	"time_den": 4,
	"grid_unit": 0.125,

	# Time windows
	"time_windows": [
		{"start": 0.0, "end": 2.0},
		{"start": 2.0, "end": 4.0},
		{"start": 4.0, "end": 6.0},
		{"start": 6.0, "end": 8.0}
	],

	# Allowed techniques
	"allowed_techniques": [
		"passing_tone",
		"chromatic_passing_tone",
		"neighbor_tone",
		"appoggiatura",
		"suspension"
	],

	# Technique weights
	"technique_weights": {
		"passing_tone": 1.0,
		"chromatic_passing_tone": 0.5,
		"neighbor_tone": 1.0,
		"appoggiatura": 1.2,
		"suspension": 0.8
	},

	# Voice pattern
	"voice_window_pattern": "SATB",

	# Strategy and reproducibility
	"pair_selection_strategy": "longest",
	"triplet_allowed": false,
	"rng_seed": 12345
}
```

---

## 6. Composition Techniques

### 6.1 Overview

SATB Fractalizer implements **13 classical** non-chord tone techniques from the Baroque and Classical tradition.

### 6.2 Implemented Techniques

#### 1. Passing Tone

```text
ID: "passing_tone"
Beat Strength: WEAK
```

**Description:** Stepwise note between two chord tones.

**Example:**

```text
C → D → E
(C) (PT) (E)
```

**Rules:**

* Stepwise motion (by degree)
* Placed on a weak beat
* Connects two chord tones

---

#### 2. Chromatic Passing Tone

```text
ID: "chromatic_passing_tone"
Beat Strength: WEAK
```

**Description:** Chromatic note filling a whole tone interval.

**Example:**

```text
C → C♯ → D
(C) (CPT) (D)
```

**Rules:**

* Fills an interval of one whole tone
* Chromatic note (outside the scale)
* Weak beat

---

#### 3. Extended Passing Tones

```text
ID: "extended_passing_tones"
Beat Strength: WEAK
```

**Description:** Chain of 2–3 passing tones.

**Example:**

```text
C → D → E → F → G
(C) (PT) (PT) (PT) (G)
```

**Rules:**

* 2–3 consecutive passing notes
* All stepwise
* Used to fill larger intervals

---

#### 4. Neighbor Tone

```text
ID: "neighbor_tone"
Beat Strength: WEAK
```

**Description:** Ornament around a stable note (upper or lower neighbor).

**Examples:**

```text
C → D → C    (upper neighbor)
(C) (NT) (C)

C → B → C    (lower neighbor)
(C) (NT) (C)
```

**Rules:**

* Returns to the same starting note
* Distance of one scale degree
* Weak beat

---

#### 5. Chromatic Neighbor Tone

```text
ID: "chromatic_neighbor_tone"
Beat Strength: WEAK
```

**Description:** Neighbor note using a chromatic pitch.

**Example:**

```text
C → C♯ → C
(C) (CNT) (C)
```

---

#### 6. Double Neighbor

```text
ID: "double_neighbor"
Beat Strength: WEAK
```

**Description:** Two neighbor notes around a chord tone.

**Example:**

```text
C → D → B → C
(C) (UN) (LN) (C)
```

**Patterns:** Upper–Lower or Lower–Upper.

---

#### 7. Appoggiatura

```text
ID: "appoggiatura"
Beat Strength: STRONG ⚠️
```

**Description:** Dissonance on a strong beat, resolving by step.

**Example:**

```text
D → C
(APP on strong beat) → (resolution)
```

**Rules:**

* **MUST** be on a strong beat (key difference vs. passing tone)
* Stepwise upward or downward resolution
* Creates expressive tension

---

#### 8. Escape Tone

```text
ID: "escape_tone"
Beat Strength: WEAK
```

**Description:** Step to a non-chord tone followed by a leap to a chord tone.

**Example:**

```text
C → D → G
(C) (ET-step) → (G-leap)
```

**Rules:**

* Starts with stepwise motion
* Ends with a leap (disjunct interval)

---

#### 9. Anticipation

```text
ID: "anticipation"
Beat Strength: WEAK
```

**Description:** Anticipates a note from the next chord.

**Example:**

```text
Chord 1: C - E - G
Chord 2: F - A - C

Alto: E → A (anticipates the A of the next chord)
              (ANT)
```

**Rules:**

* The anticipated note MUST appear in the next chord
* Weak beat
* Creates a sense of expectation

---

#### 10. Suspension

```text
ID: "suspension"
Beat Strength: MIXED (preparation + resolution)
```

**Description:** Prepared note, held over, then resolved downward.

**Example:**

```text
Chord 1: C (preparation)
Chord 2: C (suspension – held) → B (resolution)
```

**Rules:**

* **Preparation**: chord tone in the previous chord
* **Suspension**: held note becomes dissonant
* **Resolution**: stepwise downward

---

#### 11. Retardation

```text
ID: "retardation"
Beat Strength: MIXED
```

**Description:** Like a suspension, but with **upward** resolution.

**Example:**

```text
Chord 1: B (preparation)
Chord 2: B (retardation) → C (upward resolution)
```

**Rules:**

* Same as suspension
* But resolves **upwards**

---

#### 12. Pedal

```text
ID: "pedal"
Beat Strength: ALL
```

**Description:** Sustained note across several chords.

**Example:**

```text
Bass:   C - C - C - C
Chords: I - IV - V - I
```

**Rules:**

* Generally in the bass
* Spans several harmonic changes
* Creates tonal stability

---

#### 13. Forced Neighbor Tone

```text
ID: "neighbor_tone_forced"
Beat Strength: WEAK
```

**Description:** Variant of the neighbor tone with specific constraints.

---

### 6.3 Summary Table

| Technique          | ID                        | Beat Strength | Motion      | Feature                    |
| ------------------ | ------------------------- | ------------- | ----------- | -------------------------- |
| Passing tone       | `passing_tone`            | Weak          | Stepwise    | Between 2 chord tones      |
| Chromatic passing  | `chromatic_passing_tone`  | Weak          | Stepwise    | Chromatic                  |
| Extended passing   | `extended_passing_tones`  | Weak          | Stepwise    | 2–3 notes                  |
| Neighbor tone      | `neighbor_tone`           | Weak          | Stepwise    | Returns to same note       |
| Chromatic neighbor | `chromatic_neighbor_tone` | Weak          | Stepwise    | Chromatic                  |
| Double neighbor    | `double_neighbor`         | Weak          | Stepwise    | Upper+Lower or Lower+Upper |
| Forced neighbor    | `neighbor_tone_forced`    | Weak          | Stepwise    | Variant                    |
| Appoggiatura       | `appoggiatura`            | **Strong** ⚠️ | Stepwise    | Expressive dissonance      |
| Escape tone        | `escape_tone`             | Weak          | Step + Leap | Step then leap             |
| Anticipation       | `anticipation`            | Weak          | Variable    | Anticipates next chord     |
| Suspension         | `suspension`              | Mixed         | Descending  | Prepared–Held–Resolved ↓   |
| Retardation        | `retardation`             | Mixed         | Ascending   | Prepared–Held–Resolved ↑   |
| Pedal              | `pedal`                   | All           | Static      | Sustained note             |

### 6.4 Selection Tips

**Baroque style:**

```gdscript
"allowed_techniques": [
	"suspension",
	"passing_tone",
	"neighbor_tone",
	"appoggiatura"
]
```

**Classical style:**

```gdscript
"allowed_techniques": [
	"passing_tone",
	"neighbor_tone",
	"appoggiatura",
	"anticipation"
]
```

**Chromatic style:**

```gdscript
"allowed_techniques": [
	"chromatic_passing_tone",
	"chromatic_neighbor_tone",
	"appoggiatura"
]
```

---

## 7. Practical Examples

### 7.1 Example 1: Simple Enrichment

**Goal:** Add passing tones and neighbor notes to a basic progression.

```gdscript
extends Node

const TAG = "Example1"

func _ready():
	LogBus.set_verbose(true)

	var Planner = load("res://addons/musiclib/satb_fractalizer/planner/Planner.gd")
	var planner = Planner.new()

	# Load a progression (4 chords in C major)
	var chords = _create_simple_progression()

	# Simple configuration
	var params = {
		"time_num": 4,
		"time_den": 4,
		"grid_unit": 0.25,  # Eighth notes
		"time_windows": [
			{"start": 0.0, "end": 4.0},
			{"start": 4.0, "end": 8.0}
		],
		"allowed_techniques": ["passing_tone", "neighbor_tone"],
		"voice_window_pattern": "SA",  # Soprano then Alto
		"rng_seed": 100
	}

	var result = planner.apply(chords, params)

	LogBus.info(TAG, "Chords before: " + str(chords.size()))
	LogBus.info(TAG, "Chords after: " + str(result.chords.size()))
	LogBus.info(TAG, "Notes added: " + str(result.chords.size() - chords.size()))

	# Save
	_save("res://exemple1_resultat.json", result.chords)

func _create_simple_progression():
	# I - IV - V - I in C major
	return [
		{
			"index": 0, "pos": 0.0, "length_beats": 2.0,
			"key_midi_root": 60, "scale_array": [0,2,4,5,7,9,11],
			"key_alterations": {}, "key_scale_name": "major",
			"kind": "diatonic",
			"Soprano": 72, "Alto": 67, "Tenor": 64, "Bass": 48
		},
		{
			"index": 1, "pos": 2.0, "length_beats": 2.0,
			"key_midi_root": 60, "scale_array": [0,2,4,5,7,9,11],
			"key_alterations": {}, "key_scale_name": "major",
			"kind": "diatonic",
			"Soprano": 72, "Alto": 69, "Tenor": 65, "Bass": 53
		},
		{
			"index": 2, "pos": 4.0, "length_beats": 2.0,
			"key_midi_root": 60, "scale_array": [0,2,4,5,7,9,11],
			"key_alterations": {}, "key_scale_name": "major",
			"kind": "diatonic",
			"Soprano": 71, "Alto": 67, "Tenor": 62, "Bass": 55
		},
		{
			"index": 3, "pos": 6.0, "length_beats": 2.0,
			"key_midi_root": 60, "scale_array": [0,2,4,5,7,9,11],
			"key_alterations": {}, "key_scale_name": "major",
			"kind": "diatonic",
			"Soprano": 72, "Alto": 67, "Tenor": 64, "Bass": 48
		}
	]

func _save(path, chords):
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string(JSON.print(chords, "\t"))
	file.close()
```

---

### 7.2 Example 2: Progressive Fractalization

**Goal:** Two successive passes for progressive enrichment.

```gdscript
extends Node

const TAG = "Example2"

func _ready():
	LogBus.set_verbose(true)

	var Planner = load("res://addons/musiclib/satb_fractalizer/planner/Planner.gd")
	var planner = Planner.new()

	var chords = _load_json("res://chords.json")

	# === PASS 1: Eighth notes, simple techniques ===
	var params1 = {
		"time_num": 4,
		"time_den": 4,
		"grid_unit": 0.25,  # Eighth notes
		"time_windows": [
			{"start": 0.0, "end": 4.0},
			{"start": 4.0, "end": 8.0}
		],
		"allowed_techniques": ["passing_tone", "neighbor_tone"],
		"voice_window_pattern": "SA",
		"rng_seed": 42
	}

	LogBus.info(TAG, "=== PASS 1 ===")
	var result1 = planner.apply(chords, params1)
	LogBus.info(TAG, "Chords after pass 1: " + str(result1.chords.size()))

	# === PASS 2: Sixteenth notes, more techniques ===
	var params2 = {
		"time_num": 4,
		"time_den": 4,
		"grid_unit": 0.125,  # Sixteenth notes
		"time_windows": [
			{"start": 0.0, "end": 2.0},
			{"start": 2.0, "end": 4.0},
			{"start": 4.0, "end": 6.0},
			{"start": 6.0, "end": 8.0}
		],
		"allowed_techniques": [
			"passing_tone",
			"chromatic_passing_tone",
			"neighbor_tone",
			"appoggiatura"
		],
		"voice_window_pattern": "SATB",
		"rng_seed": 99
	}

	LogBus.info(TAG, "=== PASS 2 ===")
	var result2 = planner.apply(result1.chords, params2)  # Re-injection!
	LogBus.info(TAG, "Chords after pass 2: " + str(result2.chords.size()))
	LogBus.info(TAG, "Total notes added: " + str(result2.chords.size() - chords.size()))

	_save("res://fractalise_2passes.json", result2.chords)

func _load_json(path):
	var file = File.new()
	file.open(path, File.READ)
	var data = parse_json(file.get_as_text())
	file.close()
	return data

func _save(path, chords):
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string(JSON.print(chords, "\t"))
	file.close()
```

---

### 7.3 Example 3: Baroque Style (Suspensions)

**Goal:** Create a Baroque style by favoring suspensions.

```gdscript
extends Node

const TAG = "ExampleBaroque"

func _ready():
	LogBus.set_verbose(true)

	var Planner = load("res://addons/musiclib/satb_fractalizer/planner/Planner.gd")
	var planner = Planner.new()

	var chords = _load_json("res://chords.json")

	var params = {
		"time_num": 4,
		"time_den": 4,
		"grid_unit": 0.25,
		"time_windows": [
			{"start": 0.0, "end": 2.0},
			{"start": 2.0, "end": 4.0},
			{"start": 4.0, "end": 6.0},
			{"start": 6.0, "end": 8.0}
		],
		"allowed_techniques": [
			"passing_tone",
			"neighbor_tone",
			"suspension",
			"retardation",
			"appoggiatura"
		],
		# Favor suspensions/retardations
		"technique_weights": {
			"passing_tone": 1.0,
			"neighbor_tone": 0.8,
			"suspension": 2.0,      # Double weight
			"retardation": 1.5,     # 50% more likely
			"appoggiatura": 1.2
		},
		"voice_window_pattern": "SATB",
		"rng_seed": 1685  # Bach's birth year!
	}

	var result = planner.apply(chords, params)

	# Analyze applied techniques
	var report = result.metadata.technique_report
	var suspensions = 0
	for window_report in report.time_windows:
		if window_report.applied and window_report.chosen_technique == "suspension":
			suspensions += 1

	LogBus.info(TAG, "Suspensions applied: " + str(suspensions))
	_save("res://baroque_style.json", result.chords)

func _load_json(path):
	var file = File.new()
	file.open(path, File.READ)
	var data = parse_json(file.get_as_text())
	file.close()
	return data

func _save(path, chords):
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string(JSON.print(chords, "\t"))
	file.close()
```

---

### 7.4 Example 4: Specific Voices (Tenor/Bass)

**Goal:** Enrich only the lower voices.

```gdscript
extends Node

const TAG = "LowVoices"

func _ready():
	LogBus.set_verbose(true)

	var Planner = load("res://addons/musiclib/satb_fractalizer/planner/Planner.gd")
	var planner = Planner.new()

	var chords = _load_json("res://chords.json")

	var params = {
		"time_num": 4,
		"time_den": 4,
		"grid_unit": 0.25,
		"time_windows": [
			{"start": 0.0, "end": 2.0},
			{"start": 2.0, "end": 4.0},
			{"start": 4.0, "end": 6.0},
			{"start": 6.0, "end": 8.0}
		],
		"allowed_techniques": ["passing_tone", "neighbor_tone"],
		"voice_window_pattern": "TB",  # Tenor and Bass only
		"rng_seed": 42
	}

	var result = planner.apply(chords, params)

	LogBus.info(TAG, "Lower voices enrichment completed")
	_save("res://voix_graves_enrichies.json", result.chords)

func _load_json(path):
	var file = File.new()
	file.open(path, File.READ)
	var data = parse_json(file.get_as_text())
	file.close()
	return data

func _save(path, chords):
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string(JSON.print(chords, "\t"))
	file.close()
```

---

### 7.5 Example 5: Analyzing Results

**Goal:** Explore metadata to understand what was applied.

```gdscript
extends Node

const TAG = "Analysis"

func _ready():
	LogBus.set_verbose(false)  # Disable verbose logs

	var Planner = load("res://addons/musiclib/satb_fractalizer/planner/Planner.gd")
	var planner = Planner.new()

	var chords = _load_json("res://chords.json")

	var params = {
		"time_num": 4,
		"time_den": 4,
		"grid_unit": 0.25,
		"time_windows": [
			{"start": 0.0, "end": 2.0},
			{"start": 2.0, "end": 4.0},
			{"start": 4.0, "end": 6.0},
			{"start": 6.0, "end": 8.0}
		],
		"allowed_techniques": [
			"passing_tone",
			"neighbor_tone",
			"appoggiatura",
			"suspension"
		],
		"voice_window_pattern": "SATB",
		"rng_seed": 42
	}

	var result = planner.apply(chords, params)

	# === GLOBAL STATS ===
	print("\n=== GLOBAL STATISTICS ===")
	print("Original chords: ", chords.size())
	print("Enriched chords: ", result.chords.size())
	print("Notes added: ", result.chords.size() - chords.size())
	print("Generation depth: ", result.metadata.generation_depth)
	print("Random seed: ", result.metadata.rng_seed)

	# === REPORT BY WINDOW ===
	print("\n=== WINDOW REPORT ===")
	var report = result.metadata.technique_report
	for i in range(report.time_windows.size()):
		var window_report = report.time_windows[i]
		print("\nWindow ", i, " [", window_report.start, " - ", window_report.end, "]")
		print("  Voice processed: ", window_report.voice_chosen)
		if window_report.applied:
			print("  Technique applied: ", window_report.chosen_technique)
			print("  Position: ", window_report.chord_pair_positions)
		else:
			print("  Not applied: ", window_report.reason_if_skipped)

	# === OPERATION HISTORY ===
	print("\n=== HISTORY ===")
	var history = result.metadata.history
	for entry in history:
		if entry.status == "success":
			print("✓ Window ", entry.window_index, " : ", entry.op,
				  " on voice ", entry.voice)
		else:
			print("✗ Window ", entry.window_index, " : ", entry.reason)

	# === COUNT TECHNIQUES ===
	print("\n=== TECHNIQUES USED ===")
	var technique_count = {}
	for entry in history:
		if entry.status == "success" and entry.has("op"):
			var tech = entry.op
			if not technique_count.has(tech):
				technique_count[tech] = 0
			technique_count[tech] += 1

	for tech in technique_count.keys():
		print("  ", tech, " : ", technique_count[tech], " times")

func _load_json(path):
	var file = File.new()
	file.open(path, File.READ)
	var data = parse_json(file.get_as_text())
	file.close()
	return data
```

**Expected output (example):**

```text
=== GLOBAL STATISTICS ===
Original chords: 30
Enriched chords: 34
Notes added: 4
Generation depth: 1
Random seed: 42

=== WINDOW REPORT ===

Window 0 [0.0 - 2.0]
  Voice processed: Soprano
  Technique applied: passing_tone
  Position: [0, 1]

Window 1 [2.0 - 4.0]
  Voice processed: Alto
  Not applied: no_valid_pair

...
```

---

## 8. Advanced Features

### 8.1 Multiple Re-injections

Re-injection enables progressive "fractalization" by applying several passes with increasingly fine subdivisions.

```gdscript
func fractalize_progressively(initial_chords):
	var Planner = load("res://addons/musiclib/satb_fractalizer/planner/Planner.gd")
	var planner = Planner.new()

	var passes = [
		{
			"name": "Pass 1 - Quarter notes",
			"params": {
				"grid_unit": 0.5,
				"allowed_techniques": ["passing_tone"]
			}
		},
		{
			"name": "Pass 2 - Eighth notes",
			"params": {
				"grid_unit": 0.25,
				"allowed_techniques": ["passing_tone", "neighbor_tone"]
			}
		},
		{
			"name": "Pass 3 - Sixteenth notes",
			"params": {
				"grid_unit": 0.125,
				"allowed_techniques": [
					"passing_tone",
					"chromatic_passing_tone",
					"neighbor_tone",
					"appoggiatura"
				]
			}
		}
	]

	var chords = initial_chords
	for pass_data in passes:
		LogBus.info(TAG, "=== " + pass_data.name + " ===")
		var result = planner.apply(chords, pass_data.params)
		chords = result.chords
		LogBus.info(TAG, "Chords: " + str(chords.size()))

	return chords
```

### 8.2 Voice Extraction

Extract individual melodic lines after enrichment:

```gdscript
func extract_soprano_line(chords):
	var line = []
	for chord in chords:
		line.append({
			"pos": chord.pos,
			"pitch": chord.Soprano,
			"role": chord.get("Soprano_role", "unknown")
		})
	return line

func print_line(line):
	for note in line:
		var role_str = note.role if note.role != "chord_tone" else "CHORD"
		print("Pos: ", note.pos, " | Pitch: ", note.pitch, " | Role: ", role_str)
```

### 8.3 Musical Validation

Check progression validity before/after processing:

```gdscript
var VoiceLeading = load("res://addons/musiclib/satb_fractalizer/utils/VoiceLeading.gd")

func validate_progression(chords):
	var violations = []

	for i in range(chords.size() - 1):
		var c1 = chords[i]
		var c2 = chords[i + 1]

		# Check for voice crossings
		if not VoiceLeading.check_no_voice_crossing(
			c1.Soprano, c1.Alto, c1.Tenor, c1.Bass,
			c2.Soprano, c2.Alto, c2.Tenor, c2.Bass
		):
			violations.append("Voice crossing between chords " + str(i) + " and " + str(i+1))

		# Check for parallel intervals (5ths/8ves)
		# (to be implemented as needed)

	return violations
```

### 8.4 MIDI Export (Conceptual)

SATB Fractalizer does not directly write MIDI, but you could export data as follows:

```gdscript
# Pseudo-code – requires an external MIDI library
func export_midi(chords, filename):
	var midi = MIDIFile.new()  # Hypothetical
	midi.add_tempo_track(120)  # 120 BPM

	var tracks = {
		"Soprano": midi.add_track("Soprano"),
		"Alto": midi.add_track("Alto"),
		"Tenor": midi.add_track("Tenor"),
		"Bass": midi.add_track("Bass")
	}

	for chord in chords:
		var pos_ticks = chord.pos * 480  # 480 ticks per beat
		var duration_ticks = chord.length_beats * 480

		tracks["Soprano"].add_note(chord.Soprano, pos_ticks, duration_ticks, 64)
		tracks["Alto"].add_note(chord.Alto, pos_ticks, duration_ticks, 64)
		tracks["Tenor"].add_note(chord.Tenor, pos_ticks, duration_ticks, 64)
		tracks["Bass"].add_note(chord.Bass, pos_ticks, duration_ticks, 64)

	midi.save(filename)
```

### 8.5 Advanced Voice Patterns

Create custom patterns:

```gdscript
# "Dialogue" pattern: Soprano–Alto–Soprano–Alto
params["voice_window_pattern"] = "SASA"

# "Active bass" pattern
params["voice_window_pattern"] = "BBBST"

# "All except bass"
params["voice_window_pattern"] = "SAT"
```

### 8.6 Context-Weighted Techniques

Adapt weights according to harmonic context:

```gdscript
func adapt_weights_by_context(chord_index, total_chords):
	var progress = float(chord_index) / float(total_chords)

	if progress < 0.25:
		# Beginning: simple techniques
		return {
			"passing_tone": 1.5,
			"neighbor_tone": 1.0,
			"appoggiatura": 0.3
		}
	elif progress < 0.75:
		# Middle: more variety
		return {
			"passing_tone": 1.0,
			"chromatic_passing_tone": 0.8,
			"neighbor_tone": 1.0,
			"appoggiatura": 1.0,
			"suspension": 0.6
		}
	else:
		# End: expressive techniques
		return {
			"appoggiatura": 1.5,
			"suspension": 1.2,
			"retardation": 0.8
		}
```

---

## 9. Troubleshooting

### 9.1 Common Issues

#### Issue: No Notes Added

**Symptoms:**

```text
Chords before: 30
Chords after: 30
Notes added: 0
```

**Possible causes:**

1. **Invalid time windows**: windows do not cover the chords
2. **grid_unit too large**: no subdivisions possible
3. **Incompatible techniques**: no applicable technique

**Solutions:**

```gdscript
# Check windows
print("Total duration: ", chords[-1].pos + chords[-1].length_beats)
print("Windows: ", params.time_windows)

# Reduce grid_unit
params["grid_unit"] = 0.125  # Instead of 0.5

# Enable logs
	LogBus.set_verbose(true)
```

---

#### Issue: "no_valid_pair" in Logs

**Symptoms:**

```text
✗ Window 0 : no_valid_pair
```

**Causes:**

* No pair of consecutive chords within the window
* Chords too short to be subdivided

**Solutions:**

```gdscript
# Enlarge windows
"time_windows": [
	{"start": 0.0, "end": 4.0}  # Instead of 2.0
]

# Check durations
for chord in chords:
	if chord.length_beats < params.grid_unit * 2:
		print("Chord too short: ", chord.index)
```

---

#### Issue: Voice Crossings

**Symptoms:**

```text
WARNING: Voice crossing detected
```

**Causes:**

* Passing notes cause voice crossing
* Tessituras too close together

**Solutions:**

```gdscript
# Check initial ordering
for chord in chords:
	if not (chord.Soprano >= chord.Alto >= chord.Tenor >= chord.Bass):
		print("Invalid voice order at chord ", chord.index)

# VoiceLeading validation should normally prevent this
```

---

#### Issue: Non-Reproducible Results

**Symptoms:**
Different results on each run.

**Causes:**

* `rng_seed` not defined (default: timestamp)

**Solutions:**

```gdscript
params["rng_seed"] = 42  # Set a fixed seed
```

---

#### Issue: LogBus Not Found

**Symptoms:**

```text
ERROR: Singleton "LogBus" not found
```

**Causes:**

* LogBus not configured in Autoload

**Solutions:**

1. Project → Project Settings → Autoload
2. Add: Name = `LogBus`, Path = `res://LogBus.gd`
3. Restart Godot

---

### 9.2 Advanced Debugging

#### Enable Detailed Logs

```gdscript
LogBus.set_verbose(true)

# Add custom logs
LogBus.debug(TAG, "Checking window " + str(i))
LogBus.info(TAG, "Selected technique: " + technique)
LogBus.warn(TAG, "No valid pair found")
LogBus.error(TAG, "Critical error")
```

#### Inspect Metadata

```gdscript
func debug_metadata(result):
	print("\n=== METADATA DEBUG ===")
	print(JSON.print(result.metadata, "  "))

	# Detailed history
	for entry in result.metadata.history:
		print("\nEntry:")
		print("  Status: ", entry.status)
		print("  Window: ", entry.window_index)
		if entry.has("op"):
			print("  Operation: ", entry.op)
		if entry.has("reason"):
			print("  Reason: ", entry.reason)
```

#### Validate Input Data

```gdscript
func validate_input(chords):
	for i in range(chords.size()):
		var c = chords[i]

		# Required fields
		var required = ["index", "pos", "length_beats", "key_midi_root",
						"scale_array", "key_alterations", "key_scale_name",
						"kind", "Soprano", "Alto", "Tenor", "Bass"]
		for field in required:
			if not c.has(field):
				print("ERROR: Chord ", i, " missing field '", field, "'")
				return false

		# Voice order
		if not (c.Soprano >= c.Alto and c.Alto >= c.Tenor and c.Tenor >= c.Bass):
			print("ERROR: Invalid voice order at chord ", i)
			return false

		# Positive duration
		if c.length_beats <= 0:
			print("ERROR: Non-positive duration at chord ", i)
			return false

	print("✓ Input validation OK")
	return true
```

---

### 9.3 Performance

#### Optimizing for Large Progressions

For progressions with 100+ chords:

```gdscript
# Disable verbose logs
LogBus.set_verbose(false)

# Use fewer windows
"time_windows": [
	{"start": 0.0, "end": 16.0},
	{"start": 16.0, "end": 32.0}
]

# Limit techniques
"allowed_techniques": ["passing_tone", "neighbor_tone"]

# Use "earliest" selection
"pair_selection_strategy": "earliest"
```

#### Measure Performance

```gdscript
func measure_performance(chords, params):
	var start = OS.get_ticks_msec()

	var result = planner.apply(chords, params)

	var duration = OS.get_ticks_msec() - start
	print("Execution time: ", duration, " ms")
	print("Chords processed: ", chords.size())
	print("Speed: ", float(chords.size()) / (float(duration) / 1000.0), " chords/sec")

	return result
```

---

## 10. Quick Reference

### 10.1 Startup Checklist

* [ ] Godot 3.6 installed
* [ ] Folder `addons/musiclib/satb_fractalizer/` copied
* [ ] LogBus configured in Autoload
* [ ] Progression JSON file prepared
* [ ] Test script created

### 10.2 Minimal Parameter Structure

```gdscript
var params = {
	"time_num": 4,
	"time_den": 4,
	"grid_unit": 0.25,
	"time_windows": [{"start": 0.0, "end": 4.0}],
	"allowed_techniques": ["passing_tone"],
	"voice_window_pattern": "S",
	"rng_seed": 42
}
```

### 10.3 Essential Commands

```gdscript
# Load Planner
var Planner = load("res://addons/musiclib/satb_fractalizer/planner/Planner.gd")
var planner = Planner.new()

# Apply
var result = planner.apply(chords, params)

# Access results
var enriched_chords = result.chords
var metadata = result.metadata

# Logs
LogBus.set_verbose(true)
LogBus.info("TAG", "Message")
```

### 10.4 Techniques by Category

**Stepwise motion:**

* `passing_tone`
* `chromatic_passing_tone`
* `extended_passing_tones`

**Ornaments:**

* `neighbor_tone`
* `chromatic_neighbor_tone`
* `double_neighbor`

**Expressive dissonances:**

* `appoggiatura` (strong beat)
* `suspension`
* `retardation`

**Anticipation / Escape:**

* `anticipation`
* `escape_tone`

**Static:**

* `pedal`

### 10.5 Common Grid Units

| Value  | Notation | Name (English)     |
| ------ | -------- | ------------------ |
| 1.0    | 𝅝       | Whole note         |
| 0.5    | ♩        | Quarter note       |
| 0.25   | ♪        | Eighth note        |
| 0.125  | 𝅘𝅥𝅯   | Sixteenth note     |
| 0.0625 | 𝅘𝅥𝅰   | Thirty-second note |

### 10.6 Common Voice Patterns

| Pattern  | Description               |
| -------- | ------------------------- |
| `"S"`    | Soprano only              |
| `"SA"`   | Soprano → Alto → Soprano… |
| `"SATB"` | Full four-voice rotation  |
| `"TB"`   | Lower voices only         |
| `"SSAA"` | Emphasis on upper voices  |

### 10.7 Key Files

```text
/addons/musiclib/satb_fractalizer/
├── planner/Planner.gd          ← Main entry point
├── core/ProgressionAdapter.gd  ← JSON conversion
├── core/ScaleContext.gd        ← Scale management
└── techniques/                 ← 13 techniques
```

### 10.8 Useful Links

* **GitHub repository**: `laurentVeliscek/SATB_fractalizer`
* **Technical documentation**: `SATB_fractalizer_V2.md` (836 lines)
* **License**: GNU GPL v3.0
* **Godot 3.6**: official 3.x downloads page

---

## Annexes

### A. Example chords.json File

```json
[
  {
    "index": 0,
    "pos": 0.0,
    "length_beats": 2.0,
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
    "pos": 2.0,
    "length_beats": 2.0,
    "key_midi_root": 60,
    "scale_array": [0, 2, 4, 5, 7, 9, 11],
    "key_alterations": {},
    "key_scale_name": "major",
    "kind": "diatonic",
    "Soprano": 72,
    "Alto": 69,
    "Tenor": 65,
    "Bass": 53
  }
]
```

### B. Musical Glossary

| Term                | Definition                                          |
| ------------------- | --------------------------------------------------- |
| **SATB**            | Soprano, Alto, Tenor, Bass (standard vocal quartet) |
| **NCT**             | Non-Chord Tone (note outside current chord)         |
| **Strong beat**     | Main accented beat of the bar                       |
| **Weak beat**       | Unaccented beats (e.g. 2, 3, 4 in 4/4)              |
| **Stepwise motion** | Movement by scale degree (tone or semitone)         |
| **Disjunct motion** | Movement by leap (interval > second)                |
| **Tessitura**       | Comfortable pitch range of a voice                  |
| **Voice crossing**  | Lower voice goes above a higher voice               |

### C. Theory: Beat Strength in 4/4

```text
Bar:    |  1   2   3   4  |
Strength| ██  ░░  ▒▒  ░░ |
        |STR weak mid weak|

Subdivisions (eighth notes):
|  1  +  2  +  3  +  4  + |
| ██ ░░ ░░ ░░ ▒▒ ░░ ░░ ░░|
```

* **Beat 1**: very strong (appoggiaturas possible)
* **Beats 2, 4**: weak (passing tones etc.)
* **Beat 3**: medium-strong (in 4/4)

---

## License

SATB Fractalizer is distributed under the **GNU General Public License v3.0**.

You are free to:

* ✓ Use the software for personal or commercial purposes
* ✓ Modify the source code
* ✓ Distribute the original or modified software

Provided that you:

* ✓ Publish your source code under the same license (copyleft)
* ✓ Include a copy of the GPL-3.0 license
* ✓ Mention the modifications you made

For more details, see the official GPL-3.0 license text.

---

## Support and Contributions

**Report a bug:**
Create an issue on GitHub with:

* Description of the problem
* Minimal input JSON file
* Parameters used
* Godot version

**Contribute:**
Pull requests are welcome! See `CONTRIBUTING.md` (if available).

---

**Manual Version:** 1.0
**Date:** January 2025
**Author:** Documentation generated for SATB Fractalizer v0.4
