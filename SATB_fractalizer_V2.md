# Melodic Techniques (Non-Chord Tones) – Algorithmic Spec V2
## SATB + Time + Voice & Technique Permissions + Rhythmic Strategy + Voice Alternation (No-Dead-End Design)

This document defines how to inject **non-chord tones (NCTs)** into a **time-based SATB progression**, with:

- explicit **harmony** (4-part SATB, scale, degree, function),
- explicit **time** (start/duration, meter, grid),
- explicit **voice permissions** (which voices may be modified),
- explicit **technique filters** (which techniques are allowed/forbidden),
- a **rhythmic placement strategy** (binary grid + optional triplets),
- a **voice alternation pattern** (per-window call-and-response between voices),
- a **no-dead-end** design (when something can't be applied, we skip and log *why*).

All techniques are operators of the form:

```text
TechniqueOp: (Progression, TechniqueParams) → Progression
```

The **output** `Progression` has the *same structure* as the input and can be **re-injected** as input for further passes.

---

## 0. Technique List (IDs)

All techniques are identified by string IDs:

* `"passing_tone"`
* `"neighbor_tone"`           (simple upper/lower neighbor / broderie)
* `"double_neighbor"`         (changing tones / upper-lower or lower-upper)
* `"appoggiatura"`
* `"escape_tone"`
* `"anticipation"`
* `"suspension"`
* `"retardation"`
* `"pedal"`
* `"chromatic_passing_tone"`  ← chromatic passing note
* `"chromatic_neighbor_tone"` ← chromatic broderie (new)
* `"extended_passing_tones"`  ← 2–3 diatonic passing notes chain

These IDs are used in:

* technique parameters (`allowed_techniques`, `forbidden_techniques`),
* per-voice `technique`,
* per-chord `techniques_applied`,
* global `technique_report`.

---

## 1. Core Data Model

### 1.1 Meter, Time Units & Grid

Times are in **beats** (or any uniform unit).

```jsonc
{
	"time_num": 4,             // time signature numerator (e.g. 4 for 4/4)
	"time_den": 4,             // time signature denominator (e.g. 4 for 4/4)
	"time_unit": "beat"        // convention: 1.0 = one beat
}
```

We also define a **time grid**:

* `grid_unit` = global smallest **binary** subdivision (e.g. double 8th = 0.25 beat).
* All `start_time` and `end_time` values must be **multiples of `grid_unit`**.
* We work in **cells**:

```text
cell_index = time / grid_unit
```

For two chords A and B:

```text
span_start = start_time(A)
span_end   = start_time(B)
span       = span_end - span_start
n_cells    = span / grid_unit     // must be integer
```

No chord may overlap another:

```text
end_time_k = start_time_k + duration_k
end_time_k <= start_time_{k+1}
```

> **Note**: `min_note_duration` is typically a multiple of `grid_unit`
> (often equal to `grid_unit` itself).

#### 1.1.1 Strong and Weak Beats

Beat strength is crucial for proper NCT placement:

```jsonc
{
	"beat_strength_map": {
		// For 4/4 time:
		// 0: downbeat (strongest)
		// 1: weak
		// 2: medium-strong
		// 3: weak
		"0.0": "strong",      // beat 1 (downbeat)
		"1.0": "weak",        // beat 2
		"2.0": "medium",      // beat 3
		"3.0": "weak",        // beat 4
		"0.5": "weak",        // half-beat subdivisions are weak
		"1.5": "weak",
		"2.5": "weak",
		"3.5": "weak"
	}
}
```

**Important rules**:
- **Passing tones, neighbor tones, anticipation, escape tones**: must occur on **weak beats** (or weak subdivisions)
- **Appoggiatura**: must occur on **strong beats** (or strong subdivisions)
- **Suspension/Retardation**: prepared on previous chord, sounded (potentially on strong beat), resolved preferably on **weak beat**

---

### 1.2 Pitch Representation

```text
Pitch = int    // e.g. MIDI: 60 = C4, 61 = C#4, etc.
```

---

### 1.3 Scale Context

```jsonc
{
	"root": 60,                      // pitch of scale tonic (e.g. C4)
	"steps": [0, 2, 4, 5, 7, 9, 11], // semitone offsets from root (major scale)
	"mode": "major",                 // "major", "natural_minor", "harmonic_minor", "melodic_minor", "exotic", ...
	"name": "C major",               // optional label
	"melodic_minor_context": {       // for minor modes only
		"ascending": [0, 2, 3, 5, 7, 9, 11],   // raised 6th and 7th
		"descending": [0, 2, 3, 5, 7, 8, 10]   // natural 6th and 7th
	},
	"accidentals": {                 // optional explicit altered notes
		"raised_4": 66              // #4 in C major = F# (MIDI 66)
	}
}
```

**Important for minor modes**:
- When generating passing tones or neighbor tones in **minor mode**, use the **melodic minor scale** (ascending/descending context) to avoid the augmented second interval.
- Example: In A minor (natural), avoid B♭→C♯ (augmented second). Use melodic minor instead.

---

### 1.4 Voice Permissions, Roles & Range

We track:

1. **Whether a voice is allowed to be modified**.
2. **The role** of each note (chord tone / NCT type).
3. **The valid pitch range** for each voice.
4. **Voice crossing prevention**.

#### 1.4.1 Voice Permission Map & Range

At progression level:

```jsonc
{
	"default_allowed_voices": ["S", "A"], // voices modifiable by default
	"voice_policy": {
		"S": { 
			"modifiable": true,
			"min_pitch": 60,      // C4 (Middle C)
			"max_pitch": 81       // A5
		},
		"A": { 
			"modifiable": true,
			"min_pitch": 55,      // G3
			"max_pitch": 74       // D5
		},
		"T": { 
			"modifiable": false,
			"min_pitch": 48,      // C3
			"max_pitch": 67       // G4
		},
		"B": { 
			"modifiable": false,
			"min_pitch": 40,      // E2
			"max_pitch": 60       // C4
		}
	}
}
```

**Voice crossing rule**:
- At any given time point, voices must respect the order: `pitch(S) >= pitch(A) >= pitch(T) >= pitch(B)`
- When inserting a NCT, verify that it doesn't cross adjacent voices
- Distance from anchor note: NCTs should typically stay within a reasonable interval (e.g., max perfect 4th or 5th) from their anchor chord tone, configurable per technique

At chord level (optional override):

```jsonc
{
	"voice_constraints": {
		"S": { "modifiable": true },
		"A": { "modifiable": true },
		"T": { "modifiable": false },
		"B": { "modifiable": false }
	}
}
```

#### 1.4.2 Voice Role Metadata

Each voice:

```jsonc
{
	"pitch": 64,                         // actual pitch
	"scale_degree": 3,                   // diatonic degree (optional)
	"role": "chord_tone",                // "chord_tone", "passing_tone", "neighbor_tone",
	                                     // "appoggiatura", "escape_tone", "anticipation",
	                                     // "suspension", "retardation", "pedal", "other_nct"
	"technique": null,                   // one of the technique IDs (§0), or null
	"direction": "ascending",            // "ascending", "descending", "static" (if relevant)
	"accented": false,                   // strong beat? (derived from meter & start_time)
	"locked": false,                     // if true, this note instance should not be changed
	"metadata": {
		"prepared_from_voice": "A",
		"resolves_to_voice": "A",
		"alteration": "#4",             // explicit non-diatonic info
		"beat_strength": "weak"         // "strong", "medium", "weak"
	}
}
```

---

### 1.5 Time-Based SATB Chord

```jsonc
{
	"id": 3,                               // unique chord ID
	"start_time": 4.0,                     // in beats, multiple of grid_unit
	"duration": 1.0,                       // in beats, multiple of grid_unit
	"voices": {
		"S": { /* VoiceRole */ },
		"A": { /* VoiceRole */ },
		"T": { /* VoiceRole */ },
		"B": { /* VoiceRole */ }
	},
	"harmonic_root": 67,                   // harmonic root pitch (e.g. G)
	"harmonic_scale": { /* ScaleContext */ },
	"harmonic_degree": 5,                  // degree in the scale (e.g. 5 = V)
	"function": "V",                       // optional harmonic function
	"role": "structural",                  // "structural" or "decorative"
	"voice_constraints": {                 // local voice permission overrides
		"S": { "modifiable": true },
		"A": { "modifiable": true },
		"T": { "modifiable": false },
		"B": { "modifiable": false }
	},
	"techniques_applied": [                // technique IDs affecting this chord
		"passing_tone"
	],
	"metadata": {
		"generated_by": "apply_passing_tone",
		"generation_depth": 2,
		"comments": "PT in Alto between beat 2 and 3"
	}
}
```

**Harmonic scale inheritance**:
- Each SATB chord carries its own `harmonic_scale`
- When creating NCTs between ChordA and ChordB, the NCTs inherit the `harmonic_scale` of **ChordA** (the chord immediately preceding them)
- This scale context remains valid until a new SATB chord with its own `harmonic_scale` is encountered
- This allows proper handling of modulations: if ChordA is in C major and ChordB is in G major, passing tones between them use C major scale

---

### 1.6 Progression

```jsonc
{
	"chords": [ /* Chord[], sorted by start_time */ ],
	"meter": {
		"time_num": 4,
		"time_den": 4,
		"time_unit": "beat",
		"grid_unit": 0.25              // e.g. double 8th = 0.25 beat
	},
	"global_scale": { /* ScaleContext */ },
	"default_allowed_voices": ["S", "A"],
	"voice_policy": {
		"S": { "modifiable": true, "min_pitch": 60, "max_pitch": 81 },
		"A": { "modifiable": true, "min_pitch": 55, "max_pitch": 74 },
		"T": { "modifiable": false, "min_pitch": 48, "max_pitch": 67 },
		"B": { "modifiable": false, "min_pitch": 40, "max_pitch": 60 }
	},
	"metadata": {
		"min_note_duration": 0.25,       // ≥ grid_unit
		"version": "2.0",
		"triplet_allowed": false,        // global default (can be overridden in params)
		"voice_window_pattern": "SA",    // optional, e.g. "SAST" (see §6.3)
		"history": [
			{
				"op": "apply_passing_tone",
				"params": {
					"from_index": 1,
					"to_index": 2,
					"time_window": { "start": 2.0, "end": 3.0 },
					"allowed_voices": ["S", "A"],
					"forbidden_techniques": ["chromatic_passing_tone"]
				},
				"timestamp": "...",
				"status": "success"
			}
		],
		"technique_report": {
			"time_windows": [
				{
					"start": 0.0,
					"end": 2.0,
					"window_index": 0,
					"pattern_voice": "S",
					"candidate_techniques": [
						"passing_tone",
						"neighbor_tone"
					],
					"candidate_voices": ["S"],   // only pattern voice used
					"chosen_technique": "passing_tone",
					"chosen_span": { "from": 0, "to": 1 },
					"applied": true,
					"reason_if_skipped": null
				}
			]
		}
	}
}
```

---

## 2. Triplet Handling

**Definition**:
- A triplet is a complete rhythmic group of **3 equal notes** occupying the time normally taken by 2 notes of the same value
- Triplet duration = **2 × min_note_duration**
- Example: if `min_note_duration = 0.25` (eighth note), a triplet of eighth notes occupies 0.5 beats (one quarter note duration)

**Rules**:
1. Triplets are **complete units only** – we never manipulate isolated thirds of beats
2. A triplet can only be inserted if the available span exactly equals `2 × min_note_duration`
3. Triplets are controlled by the `triplet_allowed` parameter (boolean)
4. When `triplet_allowed = true`, the rhythm pattern chooser may select triplet subdivisions
5. Triplets are represented as an array of 3 equal durations in the rhythmic pattern

**Example**:
```jsonc
{
	"min_note_duration": 0.25,     // eighth note
	"triplet_allowed": true,
	"span_cells": 2,               // span = 0.5 beats (2 × 0.25)
	"chosen_pattern": {
		"pattern": [0.166667, 0.166667, 0.166667],  // 3 equal parts
		"triplet": true,
		"note_count": 3
	}
}
```

**In `choose_rhythm_pattern()`**:
- Check if `n_cells × grid_unit == 2 × min_note_duration`
- If yes and `triplet_allowed`, add triplet pattern as candidate
- Each note in the triplet has duration `(2 × min_note_duration) / 3`

---

## 3. Rhythm Pattern Selection

The function `choose_rhythm_pattern(...)` is called to determine how to subdivide a time span between two chords.

**Signature**:
```text
choose_rhythm_pattern(
	n_cells: int,
	grid_unit: float,
	min_note_duration: float,
	technique_id: String,
	triplet_allowed: bool,
	beat_positions: Array,  // cell indices of strong beats
	params: Dictionary
) → { pattern: Array<float>, triplet: bool } or null
```

**Parameters**:
- `n_cells`: number of grid cells in the span
- `grid_unit`: duration of one grid cell
- `min_note_duration`: minimum allowed note duration
- `technique_id`: the NCT technique being applied (affects rhythm preference)
- `triplet_allowed`: whether triplets are permitted
- `beat_positions`: array of cell indices that fall on strong beats (for syncopation detection)
- `params`: dictionary with optional weights and preferences

**Output**:
- A dictionary with:
  - `pattern`: array of durations (in grid cells or fractional cells for triplets)
  - `triplet`: boolean indicating if this is a triplet pattern
- Or `null` if no suitable pattern exists

**Musical principles** (implemented in the function provided earlier):
1. **Avoid excessive syncopation**: detect when notes cross strong beats
2. **Technique-specific preferences**:
   - Passing tones → equal subdivisions
   - Appoggiatura → long-short (tension-resolution)
   - Anticipation → short at the end
   - Suspension → long-short
3. **Favor simplicity**: 2-3 notes preferred over 4+
4. **Scoring system**: each pattern gets a score based on musical criteria

---

## 4. Technique Parameters & Pair Selection Strategy

```jsonc
{
	"technique_id": "passing_tone",
	"from_index": 1,                  // index of ChordA
	"to_index": 2,                    // index of ChordB
	"time_window": {
		"start": 2.0,                 // window start
		"end": 4.0                    // window end
	},
	"voice": null,                    // if null, use pattern voice (§6.3)
	"allowed_voices": ["S", "A"],     // fallback if voice=null
	"pair_selection_strategy": "earliest",  // "earliest" or "longest"
	"allowed_techniques": null,       // list of technique IDs or null (all)
	"forbidden_techniques": [],       // list of technique IDs to exclude
	"preferred_techniques": [],       // optional priority order for planner
	"technique_weights": {            // probability weights (override defaults)
		"passing_tone": 1.0,
		"chromatic_passing_tone": 0.3,
		"appoggiatura": 0.7,
		"suspension": 0.5
	},
	"triplet_allowed": null,          // if null → use progression.metadata.triplet_allowed
	"user_tags": ["some_tag"]         // trace/debug tags
}
```

### 4.1 Chord Pair Selection Strategy

When a time window contains multiple consecutive chord pairs, we must select one pair to modify. Two strategies are available:

**"earliest"** (default):
- Select the chord pair whose `span_start` is earliest in the window
- If multiple pairs start at the same time, choose the first one by index
- Use case: progressive fractalisation from beginning to end

**"longest"**:
- Select the chord pair with the longest effective span within the window
- Effective span = `min(pair_end, window_end) - max(pair_start, window_start)`
- Use case: maximize rhythmic subdivision opportunities

The strategy is specified in the `pair_selection_strategy` parameter.

> **Important constraint**:
> At planner level, **only one voice is modified per time window**, and only one technique is applied in that window.

---

## 5. Techniques (Time, Voice & Rhythm-Aware)

For each technique:

* resolve `voice` (after voice pattern, see §6.3),
* choose a **chord pair `(ChordA, ChordB)`** inside the window using the pair selection strategy (see §6.4),
* resolve technique filters,
* compute span and `n_cells` for that pair,
* call `choose_rhythm_pattern(...)`,
* if a pattern is found, compute precise start times and durations for each inserted chord (on the grid),
* assign pitches & roles according to the specific technique.

The detailed pitch logic for each technique is:

### 5.1 Passing Tone (`passing_tone`)
- **Beat strength**: WEAK
- **Motion**: conjoint (step-wise), ascending or descending
- **Multiple**: can chain 2-3 consecutive passing tones if diatonic and conjoint
- **Resolution**: must resolve to a chord tone
- **Avoid**: parallel octaves/fifths (handled by single-voice modification)

### 5.2 Chromatic Passing Tone (`chromatic_passing_tone`)
- **Beat strength**: WEAK
- **Context**: between two chord tones a whole tone apart
- **Motion**: fills the semitone gap chromatically
- **Example**: C → C# → D (ascending) or D → C# → C (descending)

### 5.3 Extended Passing Tones (`extended_passing_tones`)
- **Beat strength**: WEAK
- **Count**: 2-3 diatonic passing notes
- **Final approach**: last passing note must be close to target (tone or semitone)
- **Motion**: conjoint chain from source to target chord tone

### 5.4 Neighbor Tone / Broderie (`neighbor_tone`)
- **Beat strength**: WEAK
- **Motion**: conjoint, returns to same note
- **Types**: upper or lower neighbor
- **Variants**: can be diatonic or chromatic (`chromatic_neighbor_tone`)
- **Simultaneity**: if neighbor tone sounds with its anchor note in another voice, ensure sufficient distance (avoid adjacent voices)

### 5.5 Double Neighbor (`double_neighbor`)
- **Beat strength**: WEAK
- **Motion**: upper-lower or lower-upper around an anchor note
- **Pattern**: anchor → neighbor1 → neighbor2 → anchor
- **Example**: C → D → B → C or C → B → D → C

### 5.6 Appoggiatura (`appoggiatura`)
- **Beat strength**: STRONG ← critical difference
- **Motion**: conjoint, can be ascending or descending
- **Preparation**: not required (can arrive unprepared)
- **Resolution**: must resolve by step to a chord tone
- **Simultaneity**: preferably avoid sounding with resolution note; if simultaneous, ensure sufficient distance
- **Rhythm preference**: long-short (tension-resolution)

### 5.7 Escape Tone (`escape_tone`)
- **Beat strength**: WEAK
- **Motion**: step away, then leap to chord tone
- **Interpretation**: can be viewed as unresolved passing tone, neighbor, or anticipation
- **Preference**: target note (after leap) should ideally be part of the next chord (indirect anticipation)

### 5.8 Anticipation (`anticipation`)
- **Beat strength**: WEAK
- **Motion**: conjoint, anticipates a note of the following chord
- **Direction**: ascending or descending
- **Simultaneity**: preferably avoid sounding with anticipated note; if simultaneous, ensure sufficient distance
- **Rhythm preference**: short note at the end of the span

### 5.9 Suspension (`suspension`)
- **Preparation**: must be part of the previous chord (ChordA)
- **Sounding**: held into the next chord (ChordB) where it becomes dissonant
- **Resolution**: preferably on WEAK beat, typically descending by step
- **Simultaneity**: preferably avoid sounding with resolution note; if simultaneous, ensure sufficient distance

### 5.10 Retardation (`retardation`)
- **Similar to suspension** but resolves **upward** (ascending)
- Less common than suspension
- Same rules for preparation and resolution

### 5.11 Pedal (`pedal`)
- **Duration**: sustained note across multiple chords
- **Voices**: typically in bass, but can occur in upper voices
- **Dissonance**: creates dissonance when underlying harmony changes
- **Resolution**: not required to resolve (structural anchoring effect)

---

## 6. Planner, Time Windows, Voice Alternation & Technique Report

A higher-level planner orchestrates techniques over time windows.

### 6.1 Time Windows

Planner defines windows:

```jsonc
{
	"time_windows": [
		{ "start": 0.0, "end": 2.0 },  // window 0
		{ "start": 2.0, "end": 4.0 },  // window 1
		{ "start": 4.0, "end": 6.0 },  // window 2
		...
	]
}
```

Granularity can be per 2 beats, per bar, or any custom segmentation.

### 6.2 Window Processing Loop (One Voice per Window)

For each window with index `w` (starting at 0):

1. Determine **pattern voice** (if pattern is set, see §6.3).

2. Determine the **set of chord pairs `(Chord_i, Chord_{i+1})`** whose span intersects the window (see §6.4).

3. Build a technique candidate set:

   * start from global list (§0),
   * filter by `allowed_techniques` / `forbidden_techniques`,
   * optionally sort by `preferred_techniques` or use `technique_weights` for probabilistic selection.

4. For the **chosen voice** of this window and each candidate chord pair `(ChordA, ChordB)`:

   * check voice permissions & locks in all chords touched (A, B, and potential new chords),
   * check harmonic/melodic preconditions (beat strength, scale context, range),
   * compute span & `n_cells` for that pair in the intersection with the window,
   * call `choose_rhythm_pattern(...)`.

5. Collect all **applicable** `(technique, span)` pairs for this voice.

   * If none are applicable →:

     ```jsonc
     {
       "applied": false,
       "reason_if_skipped": "no_applicable_technique"
     }
     ```

     and the progression is unchanged for this window.

   * If some are applicable:

     * pick one pair `(technique, (ChordA, ChordB))` according to your strategy:
       - random selection
       - weighted random based on `technique_weights`
       - heuristic (e.g., prefer simpler techniques first)
       - style-based (e.g., Baroque vs Romantic preferences)
     * call `apply_<technique>(progression, params)` with:

       * `voice = pattern_voice_for_window(w)`,
       * `time_window = current window`,
       * `from_index = index(A)`, `to_index = index(B)`,
       * `pair_selection_strategy` (if needed)
     * replace progression with returned one,
     * record the choice in `metadata.history` and `technique_report.time_windows`.

> **Guarantee**:
> For each window, **at most one voice** is modified, **exactly one chord pair** is chosen (if any), and **at most one technique** is applied.

---

### 6.3 Voice Alternation Pattern (Call & Response)

To create a **call-and-response** effect between voices, the planner can use a **voice window pattern**:

```jsonc
"voice_window_pattern": "SAST"
```

**Definition**:

* Let `pattern = "SAST"` (string of characters, each ∈ {"S","A","T","B"}).
* Let `L = len(pattern)` (here 4).
* For time window with index `w` (0-based), the **pattern voice** is:

```text
pattern_voice = pattern[w mod L]
```

So the voice sequence over windows is:

```text
w = 0  → 'S' (Soprano)
w = 1  → 'A' (Alto)
w = 2  → 'S' (Soprano)
w = 3  → 'T' (Tenor)
w = 4  → 'S'
w = 5  → 'A'
w = 6  → 'S'
w = 7  → 'T'
...
```

This creates an **alternation** like:

* window 0: Soprano gets the NCT phrase,
* window 1: Alto answers,
* window 2: Soprano again,
* window 3: Tenor, etc.

**Interaction with permissions**:

* The planner **forces** `voice = pattern_voice` for this window.
* It still checks:

  * `voice_policy[pattern_voice].modifiable == true`,
  * chord-level `voice_constraints[pattern_voice].modifiable == true`,
  * current note not `locked` in the chords touched by the chosen span,
  * pitch range constraints (`min_pitch`, `max_pitch`),
  * voice crossing prevention.

If any of these is violated, the window is **skipped**:

* `applied = false`,
* `reason_if_skipped = "pattern_voice_not_available"`.

**Fallback behavior**: SKIP (no fallback to other voices)

No other voice is used as fallback, to preserve the pattern and avoid multiple voices being altered in the same window.

**Result**:

* **Only one voice per window** is eligible for NCT insertion.
* There is **no simultaneous NCT injection in two voices** in the same window.
* The alternation is fully controllable and reproducible via the pattern string.

---

### 6.4 Selection of Chord Pairs Inside a Window

A single time window may contain **several chords** and therefore **several consecutive pairs**:

```text
Chord1 ---- Chord2 ---- Chord3 ---- Chord4
```

Window `[Wstart, Wend]` can intersect:

* the span `Chord1 → Chord2`,
* and/or `Chord2 → Chord3`,
* and/or `Chord3 → Chord4`.

To avoid ambiguity, we define the following convention:

1. **Chord adjacency**
   A chord pair `(Chord_i, Chord_{i+1})` is always **adjacent in the global progression**, i.e. `i+1` is the next index in `progression.chords`.

2. **Span of a chord pair**
   For a pair `(Chord_i, Chord_{i+1})`:

   ```text
   pair_start = Chord_i.start_time
   pair_end   = Chord_{i+1}.start_time
   ```

3. **Intersection with window**
   A pair is considered **inside the window** if:

   ```text
   max(pair_start, Wstart) < min(pair_end, Wend)
   ```

   The **effective working span** for the technique is:

   ```text
   span_start = max(pair_start, Wstart)
   span_end   = min(pair_end, Wend)
   ```

   This is exactly the interval that will be subdivided by the rhythmic pattern.

4. **One chord pair per window**
   Even if a window intersects multiple chord pairs, the planner selects **at most one pair** `(ChordA, ChordB)` for this window using the `pair_selection_strategy`:

   * **"earliest"**: select the pair with the earliest `pair_start` in the window
   * **"longest"**: select the pair with the longest effective span

   This strategy is specified in the technique parameters (§4.1).

   > **Only one chord span is modified per window.**

5. **Local modification only**
   All new chords created by the technique are inserted **between** `ChordA` and `ChordB`:

   * `ChordA` may have its duration shortened to end at the first new chord.
   * The last new chord ends at `ChordB.start_time`.
   * Other chords in the window (before `ChordA` or after `ChordB`) remain untouched.

6. **Multiple windows over the same chords**
   Since windows are processed sequentially (and the progression is updated after each window), later windows will see the **updated list of chords** and may choose:

   * a different pair,
   * or the same pair again (if still valid),
   * according to their own span and pattern voice.

**Implication**:

* The algorithm works correctly and deterministically even when **several SATB chords lie inside the same window**, because:

  * it always operates on a **single adjacent chord pair**,
  * the effective time span is the intersection of that pair with the window,
  * and other chords in the window are not modified in that pass.

---

## 7. Voice Leading Validation Rules

Before applying any technique, validate:

1. **Range constraints**: All generated pitches must fall within `[min_pitch, max_pitch]` for the voice
2. **Voice crossing**: No voice should cross another voice at any time point
3. **Simultaneity constraints**: When a NCT sounds simultaneously with its resolution/anchor note in another voice:
   - Preferably avoid this in adjacent voices (S-A, A-T, T-B)
   - If unavoidable, ensure consonant interval or large distance
4. **Scale context**: Use appropriate scale (melodic minor for minor modes to avoid augmented 2nd)
5. **Beat strength**: Verify that the technique respects strong/weak beat requirements
6. **Conjoint motion**: For techniques requiring step-wise motion, verify intervals are seconds (major or minor)

**Important**: All validation must happen **before** inserting the NCT. If validation fails, skip the technique for this window with appropriate `reason_if_skipped`.

---

## 8. Summary of Key Amendments

### From original V1 to V2:

1. **Triplet clarification** (§2): Complete units only, duration = 2 × min_note_duration
2. **Pair selection strategy** (§4.1): Explicit "earliest" or "longest" parameter
3. **Rhythm pattern function** (§3): Detailed musical scoring algorithm provided
4. **Parallel fifths/octaves removal**: Impossible with single-voice modification
5. **Voice range constraints** (§1.4.1): `min_pitch` / `max_pitch` added to voice policy
6. **Voice crossing prevention** (§1.4.1 & §7): Explicit rule added
7. **Harmonic scale inheritance** (§1.5): NCTs inherit scale from preceding chord (ChordA)
8. **Technique weights** (§4): Probabilistic selection via `technique_weights` dictionary
9. **Fallback behavior** (§6.3): Skip when pattern voice unavailable (no fallback)
10. **Beat strength integration** (§1.1.1 & §5): Strong/weak beat map and per-technique rules
11. **Melodic minor for minor modes** (§1.3): Avoid augmented 2nd with proper scale
12. **Chromatic neighbor tone** (§0): Added as new technique variant
13. **Simultaneity guidelines** (§5 & §7): Distance and consonance rules when NCT sounds with anchor/resolution
14. **Pre-validation** (§7): All checks happen before application (no post-validation)

---

This spec now fully encodes:

* SATB + time + harmonic context,
* voice and technique permissions with range constraints,
* a musical rhythmic grid with triplets (complete units),
* **voice alternation per window** via a simple pattern string,
* **explicit chord pair selection strategy** (earliest or longest),
* **strong/weak beat awareness** for proper NCT placement,
* **voice crossing prevention** and simultaneity guidelines,
* **harmonic scale inheritance** for modulation handling,
* **weighted probabilistic technique selection**,
* and a planner that guarantees:

  * at most one technique per window,
  * at most one modified voice per window,
  * no algorithmic dead ends (every skipped window comes with an explicit reason),
  * musically informed rhythm patterns that avoid excessive syncopation.
