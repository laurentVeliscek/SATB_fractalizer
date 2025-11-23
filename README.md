# SATB Fractalizer

Un système de génération algorithmique de notes non-harmoniques (NCT - Non-Chord Tones) pour progressions SATB à quatre voix, conçu pour Godot 3.6.

## 📋 Description

Le **SATB Fractalizer** permet d'enrichir des progressions harmoniques à quatre voix (Soprano, Alto, Ténor, Basse) en y injectant des ornementations mélodiques typiques de l'écriture contrapuntique classique.

### Techniques supportées

**Phase 1 (v0.1)** :
- 🎵 **Notes de passage** (passing tones) - notes conjointes entre deux notes d'accord
- 🎵 **Broderies** (neighbor tones) - ornements autour d'une note stable
- 🎵 **Appogiatures** (appoggiaturas) - dissonances expressives sur temps fort

**À venir** :
- Notes de passage chromatiques, broderies doubles, échappées, anticipations, suspensions, retards, pédales, etc.

---

## ✨ Caractéristiques

- **Basé sur le temps** : grille rythmique précise avec support des subdivisions binaires et triolets
- **Permissions par voix** : contrôle fin des voix modifiables et de leurs tessiture
- **Contexte harmonique** : prise en compte des gammes (majeures, mineures, exotiques) et altérations
- **Alternance de voix** : système de "call & response" configurable entre les voix
- **Planning par fenêtres temporelles** : application progressive des techniques sur des segments de temps définis
- **Validation musicale** : respect des règles de temps forts/faibles, évitement des croisements de voix
- **Format compatible** : entrée/sortie au format JSON standard pour réinjection dans d'autres outils

---

## 🏗️ Architecture

Le projet est structuré en modules GDScript indépendants :

### Core (structures de données)
- **ProgressionAdapter.gd** - Conversion entre format JSON et représentation interne
- **Progression.gd** - Progression complète avec métadonnées et historique
- **Chord.gd** - Accord SATB avec contexte harmonique et temporel
- **Voice.gd** - Voix individuelle avec rôle et métadonnées
- **ScaleContext.gd** - Contexte de gamme (tonalité, mode, altérations)
- **TimeGrid.gd** - Gestion de la métrique et de la grille temporelle
- **Constants.gd** - Constantes globales

### Techniques (opérateurs d'ornementation)
- **TechniqueBase.gd** - Classe abstraite de base pour toutes les techniques
- **PassingTone.gd** - Notes de passage diatoniques
- **NeighborTone.gd** - Broderies supérieures/inférieures
- **Appoggiatura.gd** - Appogiatures expressives

### Planner (orchestration)
- **Planner.gd** - Orchestrateur principal par fenêtres temporelles
- **RhythmPattern.gd** - Sélection intelligente des patterns rythmiques

### Utils (validation et constantes)
- **VoiceLeading.gd** - Validation des règles de conduite des voix

---

## 🚀 Utilisation

### Format d'entrée

Le Fractalizer accepte un **Array de dictionnaires** au format JSON :

```gdscript
var chords = [
    {
        "index": 0,
        "pos": 0,
        "length_beats": 2,
        "key_midi_root": 60,  # C4
        "scale_array": [0, 2, 4, 5, 7, 9, 11],  # major scale
        "key_alterations": {},
        "key_scale_name": "major",
        "kind": "diatonic",
        "Soprano": 72,
        "Alto": 67,
        "Tenor": 64,
        "Bass": 48
    },
    # ... autres accords
]
```

**Champs requis** :
- `index` : position dans la séquence
- `pos` : temps de départ (en beats)
- `length_beats` : durée (en beats)
- `key_midi_root` : fondamentale de la gamme (MIDI 0-127)
- `scale_array` : intervalles de la gamme en demi-tons depuis la fondamentale
- `key_alterations` : altérations spécifiques `{degré: altération}` (ex: `{"4": 1}` pour #4)
- `key_scale_name` : nom de la gamme ("major", "minor", "harmonic_minor", "melodic_minor", etc.)
- `kind` : type d'accord ("diatonic", "N6", "It+6", "sus4", etc.)
- `Soprano`, `Alto`, `Tenor`, `Bass` : hauteurs MIDI des quatre voix

### Exemple d'utilisation

```gdscript
# Chargement de la progression
var file = File.new()
file.open("res://chords.json", File.READ)
var chords_array = parse_json(file.get_as_text())
file.close()

# Configuration du Fractalizer
var planner_script = load("res://addons/musiclib/satb_fractalizer/planner/Planner.gd")
var planner = planner_script.new()

var params = {
    "time_num": 4,
    "time_den": 4,
    "grid_unit": 0.25,
    "time_windows": [
        {"start": 0.0, "end": 4.0},
        {"start": 4.0, "end": 8.0},
        {"start": 8.0, "end": 12.0}
    ],
    "allowed_techniques": ["passing_tone", "neighbor_tone", "appoggiatura"],
    "voice_window_pattern": "SA",  # Alternance Soprano/Alto
    "triplet_allowed": false
}

# Application des techniques
var enriched_progression = planner.apply(chords_array, params)

# Sauvegarde du résultat (réinjectible)
file.open("res://chords_enriched.json", File.WRITE)
file.store_string(JSON.print(enriched_progression, "\t"))
file.close()
```

### Logging

Le système utilise **LogBus** pour un logging détaillé. Activez le mode verbose pour voir toutes les décisions :

```gdscript
# Dans votre script principal (avant d'utiliser le fractalizer)
LogBus.set_verbose(true)
```

---

## 🎼 Exemples de techniques

### Note de passage (Passing Tone)
```
Accord A : C (Do)
Accord B : E (Mi)
         ↓
Résultat : C → D (note de passage) → E
```

### Broderie (Neighbor Tone)
```
Accord A : C (Do)
Accord B : C (Do, même note)
         ↓
Résultat : C → D (broderie sup.) → C
       ou : C → B (broderie inf.) → C
```

### Appogiature (Appoggiatura)
```
Accord A : C (Do)
Accord B : D (Ré)
         ↓
Résultat : C → E (dissonance sur temps fort) → D (résolution)
```

---

## 📚 Documentation technique

Pour une spécification algorithmique complète, consulter :
- **[SATB_fractalizer_V2.md](./SATB_fractalizer_V2.md)** - Cahier des charges détaillé (modèle de données, règles musicales, algorithmes)

---

## 🎯 Statut du projet

| Technique | Statut | Version |
|-----------|--------|---------|
| Passing Tone | ✅ Implémentée | v0.1 |
| Neighbor Tone | ✅ Implémentée | v0.1 |
| Appoggiatura | ✅ Implémentée | v0.1 |
| Chromatic Passing Tone | ⏳ À venir | v0.2 |
| Double Neighbor | ⏳ À venir | v0.2 |
| Escape Tone | ⏳ À venir | v0.3 |
| Anticipation | ⏳ À venir | v0.3 |
| Suspension | ⏳ À venir | v0.4 |
| Retardation | ⏳ À venir | v0.4 |
| Pedal | ⏳ À venir | v0.5 |
| Extended Passing Tones | ⏳ À venir | v0.5 |

---

## 🛠️ Compatibilité

- **Godot Engine** : 3.6.x
- **Langage** : GDScript (compatible Godot 3.6 - pas de typage fort, pas de lambda, pas d'opérateur ternaire)

### Contraintes Godot 3.6
- ⚠️ Pas de typage statique fort (`var x: int` non utilisé)
- ⚠️ Pas de lambda functions
- ⚠️ Pas d'opérateur ternaire `? :`
- ⚠️ Attention aux références cycliques entre classes
- ✅ Instanciation dans la classe elle-même : `var new_obj = get_script().new()`

---

## 📦 Dépendances

- **LogBus.gd** - Système de logging (doit être configuré en Autoload)
  - Singleton : Project Settings → Autoload → Name: "LogBus", Path: "res://LogBus.gd"

---

## 🧪 Tests

Des scripts de test seront fournis pour valider chaque technique (à venir).

---

## 🤝 Contribution

Les contributions sont les bienvenues ! Pour ajouter une nouvelle technique :

1. Créer une classe héritant de `TechniqueBase.gd`
2. Implémenter la méthode `apply(progression, params)`
3. Respecter les règles de validation (voir `VoiceLeading.gd`)
4. Ajouter des tests
5. Documenter la technique dans ce README

---

## 📝 Licence

[À définir]

---

## 🙏 Remerciements

Basé sur les principes de l'harmonie tonale classique et de la conduite des voix.
