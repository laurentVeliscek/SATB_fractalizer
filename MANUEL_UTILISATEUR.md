# Manuel Utilisateur - SATB Fractalizer

**Version 0.4**
**Plateforme : Godot 3.6**
**Licence : GNU GPL v3.0**

---

## Table des matières

1. [Introduction](#1-introduction)
2. [Installation et Configuration](#2-installation-et-configuration)
3. [Premiers Pas](#3-premiers-pas)
4. [Format des Données](#4-format-des-données)
5. [Paramètres de Configuration](#5-paramètres-de-configuration)
6. [Techniques de Composition](#6-techniques-de-composition)
7. [Exemples Pratiques](#7-exemples-pratiques)
8. [Fonctionnalités Avancées](#8-fonctionnalités-avancées)
9. [Résolution de Problèmes](#9-résolution-de-problèmes)
10. [Référence Rapide](#10-référence-rapide)

---

## 1. Introduction

### 1.1 Qu'est-ce que SATB Fractalizer ?

**SATB Fractalizer** est un outil de composition musicale algorithmique conçu pour enrichir des progressions harmoniques à quatre voix (Soprano, Alto, Ténor, Basse) en y insérant des ornementations mélodiques appelées **Notes de Passage** ou **Non-Chord Tones (NCTs)**.

### 1.2 Objectifs

- **Transformer** des progressions d'accords simples en textures contrapuntiques élaborées
- **Ajouter** des techniques d'ornementation mélodique classiques entre les notes d'accords
- **Maintenir** la validité musicale grâce aux règles de conduite des voix
- **Permettre** une "fractalisation" progressive par passes successives (ré-injection)

### 1.3 Concept Clé

Le système opère sur des progressions d'accords basées sur le temps, en insérant des notes décoratives entre les notes structurelles tout en respectant les règles de la théorie musicale classique.

### 1.4 À qui s'adresse ce manuel ?

- Compositeurs et arrangeurs utilisant Godot pour la génération musicale
- Développeurs intégrant la génération algorithmique dans leurs projets
- Chercheurs en musicologie computationnelle
- Étudiants en composition assistée par ordinateur

---

## 2. Installation et Configuration

### 2.1 Prérequis

- **Godot Engine 3.6** (pas compatible avec Godot 4.x)
- Connaissances de base en GDScript
- Compréhension des concepts musicaux de base (accords, voix, tonalité)

### 2.2 Installation

#### Étape 1 : Copier les fichiers

Copiez le dossier `/addons/musiclib/satb_fractalizer/` dans votre projet Godot :

```
votre_projet/
└── addons/
    └── musiclib/
        └── satb_fractalizer/
            ├── core/
            ├── techniques/
            ├── planner/
            ├── utils/
            └── tests/
```

#### Étape 2 : Installer LogBus

Le système utilise un singleton de logging appelé `LogBus`.

1. Ouvrez **Paramètres du Projet** → **Autoload**
2. Ajoutez une nouvelle entrée :
   - **Nom** : `LogBus`
   - **Chemin** : `res://LogBus.gd`
3. Cliquez sur **Ajouter**

#### Étape 3 : Vérifier l'installation

Créez un script test :

```gdscript
extends Node

func _ready():
    var Planner = load("res://addons/musiclib/satb_fractalizer/planner/Planner.gd")
    var planner = Planner.new()
    print("SATB Fractalizer chargé avec succès !")
```

### 2.3 Structure du Projet

```
addons/musiclib/satb_fractalizer/
├── core/
│   ├── ProgressionAdapter.gd    # Conversion JSON ↔ Format interne
│   ├── Progression.gd            # Progression complète avec métadonnées
│   ├── Chord.gd                  # Accord SATB avec contexte harmonique
│   ├── Voice.gd                  # Voix individuelle avec métadonnées
│   ├── ScaleContext.gd           # Système de gammes et altérations
│   ├── TimeGrid.gd               # Grille rythmique et force des temps
│   └── Constants.gd              # Constantes globales
├── techniques/
│   ├── TechniqueBase.gd          # Classe de base abstraite
│   └── [13 techniques implémentées]
├── planner/
│   ├── Planner.gd                # Orchestrateur principal
│   └── RhythmPattern.gd          # Sélection intelligente des rythmes
└── utils/
    └── VoiceLeading.gd           # Règles de conduite des voix
```

---

## 3. Premiers Pas

### 3.1 Exemple Minimal

Voici un exemple complet pour enrichir une progression d'accords :

```gdscript
extends Node

const TAG = "MonScript"

func _ready():
    # 1. Activer le logging
    LogBus.set_verbose(true)

    # 2. Charger le Planner
    var Planner = load("res://addons/musiclib/satb_fractalizer/planner/Planner.gd")
    var planner = Planner.new()

    # 3. Charger une progression (fichier JSON)
    var chords = _charger_progression("res://chords.json")

    # 4. Configurer les paramètres
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

    # 5. Appliquer la fractalisation
    var result = planner.apply(chords, params)

    # 6. Sauvegarder le résultat
    _sauvegarder_progression("res://chords_enrichis.json", result.chords)

    # 7. Afficher les statistiques
    LogBus.info(TAG, "Accords originaux : " + str(chords.size()))
    LogBus.info(TAG, "Accords enrichis : " + str(result.chords.size()))
    LogBus.info(TAG, "Notes ajoutées : " + str(result.chords.size() - chords.size()))

func _charger_progression(chemin):
    var file = File.new()
    if file.open(chemin, File.READ) != OK:
        LogBus.error(TAG, "Impossible de lire " + chemin)
        return []
    var contenu = file.get_as_text()
    file.close()
    return parse_json(contenu)

func _sauvegarder_progression(chemin, chords):
    var file = File.new()
    if file.open(chemin, File.WRITE) != OK:
        LogBus.error(TAG, "Impossible d'écrire " + chemin)
        return
    file.store_string(JSON.print(chords, "\t"))
    file.close()
```

### 3.2 Résultat Attendu

Après exécution, vous obtiendrez :
- Un fichier `chords_enrichis.json` avec la progression enrichie
- Des logs détaillant les techniques appliquées
- Des statistiques sur le nombre de notes ajoutées

---

## 4. Format des Données

### 4.1 Format d'Entrée (JSON)

Chaque accord est un objet JSON avec les champs suivants :

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

#### Champs Obligatoires

| Champ | Type | Description |
|-------|------|-------------|
| `index` | int | Position dans la séquence (commence à 0) |
| `pos` | float | Temps de début en battements |
| `length_beats` | float | Durée en battements |
| `key_midi_root` | int | Note fondamentale de la tonalité (MIDI, 60 = Do4) |
| `scale_array` | Array | Intervalles de la gamme (en demi-tons) |
| `key_alterations` | Dict | Altérations : `{"4": 1}` = ♯4, `{"7": -1}` = ♭7 |
| `key_scale_name` | String | Nom de la gamme : `"major"`, `"minor"`, etc. |
| `kind` | String | Type d'accord : `"diatonic"`, `"chromatic"`, etc. |
| `Soprano` | int | Hauteur MIDI de la soprano |
| `Alto` | int | Hauteur MIDI de l'alto |
| `Tenor` | int | Hauteur MIDI du ténor |
| `Bass` | int | Hauteur MIDI de la basse |

#### Gammes Courantes

```json
// Majeur (Do majeur)
"scale_array": [0, 2, 4, 5, 7, 9, 11]

// Mineur naturel (La mineur)
"scale_array": [0, 2, 3, 5, 7, 8, 10]

// Mineur harmonique
"scale_array": [0, 2, 3, 5, 7, 8, 11]

// Mineur mélodique
"scale_array": [0, 2, 3, 5, 7, 9, 11]
```

### 4.2 Format de Sortie

Le Planner retourne un dictionnaire avec deux clés :

```gdscript
{
    "chords": [...],      # Tableau d'accords enrichis
    "metadata": {         # Informations de suivi
        "generation_depth": 1,
        "rng_seed": 42,
        "global_params": {...},
        "history": [...],
        "technique_report": {...}
    }
}
```

#### Structure des Accords Enrichis

Les accords en sortie contiennent :
- **Accords originaux** (potentiellement avec durées ajustées)
- **Nouveaux accords décoratifs** avec `"kind": "decorative"`
- **Métadonnées vocales** montrant les rôles : `"chord_tone"`, `"passing_tone"`, etc.

Exemple de voix avec métadonnées :

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

### 4.3 Ré-injection

Le tableau `chords` en sortie peut être directement utilisé comme entrée pour une nouvelle passe :

```gdscript
var result1 = planner.apply(chords, params1)
var result2 = planner.apply(result1.chords, params2)  # Deuxième passe
var result3 = planner.apply(result2.chords, params3)  # Troisième passe
```

---

## 5. Paramètres de Configuration

### 5.1 Paramètres Essentiels

#### time_num / time_den
```gdscript
"time_num": 4,        # Numérateur de la métrique
"time_den": 4         # Dénominateur de la métrique
```
- Définit la métrique (4/4, 3/4, 6/8, etc.)
- Affecte le calcul de la force des temps (temps forts/faibles)

#### grid_unit
```gdscript
"grid_unit": 0.25     # Subdivision minimale en battements
```
- **0.25** = croches (8th notes)
- **0.125** = doubles-croches (16th notes)
- **0.5** = noires (quarter notes)
- Détermine la finesse des subdivisions possibles

#### time_windows
```gdscript
"time_windows": [
    {"start": 0.0, "end": 4.0},                    # Mesures 1-4
    {"start": 4.0, "end": 8.0, "iteration": 2},    # Mesures 5-8, 2 itérations
    {"start": 8.0, "end": 12.0, "iteration": 3}    # Mesures 9-12, 3 itérations
]
```
- Définit les segments temporels où appliquer les techniques
- Chaque fenêtre traite **une seule voix** (déterminée par le pattern)
- **Paramètre optionnel `iteration`** (défaut = 1) : nombre d'opérations à effectuer sur la fenêtre
  - `"iteration": 1` : Une seule technique appliquée (comportement par défaut)
  - `"iteration": 2` : Deux techniques appliquées successivement (peuvent être différentes)
  - `"iteration": 3` : Trois techniques appliquées successivement
  - À chaque itération, une technique est sélectionnée aléatoirement (ou par poids) parmi `allowed_techniques`

**Exemple d'utilisation de `iteration` :**
```gdscript
# Fenêtre avec 3 itérations = jusqu'à 3 techniques appliquées successivement
{"start": 0.0, "end": 2.0, "iteration": 3}

# Peut produire : passing_tone → neighbor_tone → chromatic_passing_tone
# Ou toute autre combinaison selon les poids et la sélection aléatoire
```

#### allowed_techniques
```gdscript
"allowed_techniques": [
    "passing_tone",
    "neighbor_tone",
    "appoggiatura",
    "suspension"
]
```
- Liste des techniques autorisées pour cette passe
- Voir section [6. Techniques de Composition](#6-techniques-de-composition)

#### voice_window_pattern
```gdscript
"voice_window_pattern": "SATB"
```
- Contrôle quelle voix est modifiée dans chaque fenêtre
- **"SA"** : Fenêtre 0 = Soprano, Fenêtre 1 = Alto, Fenêtre 2 = Soprano...
- **"SATB"** : Rotation complète des quatre voix
- **"SSAA"** : Plus d'activité pour Soprano/Alto
- **"TB"** : Seulement Ténor et Basse

### 5.2 Paramètres Avancés

#### rng_seed
```gdscript
"rng_seed": 42        # Graine aléatoire (null = horodatage)
```
- Permet de reproduire exactement les mêmes résultats
- Utile pour le débogage et la comparaison

#### triplet_allowed
```gdscript
"triplet_allowed": true   # Active les triolets de noire
```
- **Autorise les subdivisions en triolets**
- **Règle importante** : Seules les **noires (1.0 beat)** sont divisées en triolets
- Les blanches (2.0 beats) et valeurs supérieures restent binaires
- Un triolet divise une noire en **3 notes égales** de 0.333... battement chacune

**Fonctionnement :**
- Si `grid_unit = 0.25` (croche) et qu'un espace d'1 noire est disponible
- Le système peut créer un triolet : 3 notes de 0.333... beats chacune
- Les triolets sont identifiés par `"triplet": true` dans les métadonnées du chord

**Exemple :**
```gdscript
# Avec grid_unit = 0.25 (croches) et triplet_allowed = true
# Un espace de 1.0 beat peut être divisé en :
# - 2 croches (binaire) : [0.5, 0.5]
# - 4 croches (binaire) : [0.25, 0.25, 0.25, 0.25]
# - 3 triolets (ternaire) : [0.333..., 0.333..., 0.333...] ← NOUVEAU !
```

**Force des temps pour triolets :**
- Première note du triolet (sur le temps) : force normale (forte/moyenne/faible selon position)
- Deuxième et troisième notes : toujours faibles

#### pair_selection_strategy
```gdscript
"pair_selection_strategy": "earliest"  # ou "longest"
```
- **"earliest"** : Choisit la première paire d'accords valide
- **"longest"** : Choisit la paire avec la plus longue durée

#### technique_weights
```gdscript
"technique_weights": {
    "passing_tone": 1.0,              # Poids normal
    "chromatic_passing_tone": 0.3,    # Moins probable
    "appoggiatura": 1.5,              # Plus probable
    "suspension": 0.8
}
```
- Contrôle la probabilité de sélection de chaque technique
- Poids par défaut = 1.0
- Permet de créer des styles musicaux spécifiques

### 5.3 Exemple de Configuration Complète

```gdscript
var params = {
    # Métrique et grille
    "time_num": 4,
    "time_den": 4,
    "grid_unit": 0.125,

    # Fenêtres temporelles
    "time_windows": [
        {"start": 0.0, "end": 2.0},
        {"start": 2.0, "end": 4.0},
        {"start": 4.0, "end": 6.0},
        {"start": 6.0, "end": 8.0}
    ],

    # Techniques autorisées
    "allowed_techniques": [
        "passing_tone",
        "chromatic_passing_tone",
        "neighbor_tone",
        "appoggiatura",
        "suspension"
    ],

    # Pondération des techniques
    "technique_weights": {
        "passing_tone": 1.0,
        "chromatic_passing_tone": 0.5,
        "neighbor_tone": 1.0,
        "appoggiatura": 1.2,
        "suspension": 0.8
    },

    # Pattern de voix
    "voice_window_pattern": "SATB",

    # Stratégie et reproductibilité
    "pair_selection_strategy": "longest",
    "triplet_allowed": false,
    "rng_seed": 12345
}
```

---

## 6. Techniques de Composition

### 6.1 Vue d'Ensemble

SATB Fractalizer implémente **13 techniques classiques** de notes de passage (Non-Chord Tones) issues de la tradition baroque et classique.

### 6.2 Techniques Implémentées

#### 1. Passing Tone (Note de Passage)
```
ID: "passing_tone"
Force: FAIBLE (weak beat)
```
**Description :** Note conjointe entre deux notes d'accord.

**Exemple :**
```
Do → Ré → Mi
(C)  (PT) (E)
```

**Règles :**
- Mouvement conjoint (par degré)
- Placée sur temps faible
- Relie deux notes d'accord

---

#### 2. Chromatic Passing Tone (Note de Passage Chromatique)
```
ID: "chromatic_passing_tone"
Force: FAIBLE
```
**Description :** Note chromatique remplissant un intervalle d'un ton.

**Exemple :**
```
Do → Do♯ → Ré
(C)  (CPT) (D)
```

**Règles :**
- Comble un intervalle de ton entier
- Note chromatique (hors gamme)
- Temps faible

---

#### 3. Extended Passing Tones (Notes de Passage Étendues)
```
ID: "extended_passing_tones"
Force: FAIBLE
```
**Description :** Chaîne de 2 à 3 notes de passage.

**Exemple :**
```
Do → Ré → Mi → Fa → Sol
(C)  (PT) (PT) (PT) (G)
```

**Règles :**
- 2-3 notes de passage consécutives
- Toutes conjointes
- Comble de grands intervalles

---

#### 4. Neighbor Tone (Note de Broderie)
```
ID: "neighbor_tone"
Force: FAIBLE
```
**Description :** Ornement autour d'une note stable (supérieur ou inférieur).

**Exemple :**
```
Do → Ré → Do    (broderie supérieure)
(C)  (NT) (C)

Do → Si → Do    (broderie inférieure)
(C)  (NT) (C)
```

**Règles :**
- Retour à la même note
- Distance d'un degré
- Temps faible

---

#### 5. Chromatic Neighbor Tone (Broderie Chromatique)
```
ID: "chromatic_neighbor_tone"
Force: FAIBLE
```
**Description :** Broderie utilisant une note chromatique.

**Exemple :**
```
Do → Do♯ → Do
(C)  (CNT) (C)
```

---

#### 6. Double Neighbor (Double Broderie)
```
ID: "double_neighbor"
Force: FAIBLE
```
**Description :** Deux broderies successives autour d'une note.

**Exemple :**
```
Do → Ré → Si → Do
(C)  (UN) (LN) (C)
```
**Patterns :** Supérieur-Inférieur ou Inférieur-Supérieur

---

#### 7. Appoggiatura (Appoggiature)
```
ID: "appoggiatura"
Force: FORTE (strong beat) ⚠️
```
**Description :** Dissonance sur temps fort, résolution par degré.

**Exemple :**
```
Ré → Do
(APP forte) → (résolution)
```

**Règles :**
- **DOIT** être sur temps fort (différence clé avec passing tone)
- Résolution conjointe descendante ou ascendante
- Crée une tension expressive

---

#### 8. Escape Tone (Échappée)
```
ID: "escape_tone"
Force: FAIBLE
```
**Description :** Degré conjoint puis saut vers une note d'accord.

**Exemple :**
```
Do → Ré → Sol
(C)  (ET-degré) → (G-saut)
```

**Règles :**
- Départ par degré conjoint
- Arrivée par saut (intervalle disjoint)

---

#### 9. Anticipation (Anticipation)
```
ID: "anticipation"
Force: FAIBLE
```
**Description :** Anticipe une note du prochain accord.

**Exemple :**
```
Accord 1: Do - Mi - Sol
Accord 2: Fa - La - Do

Alto: Mi → La (anticipe le La de l'accord suivant)
              (ANT)
```

**Règles :**
- La note anticipée DOIT être présente dans l'accord suivant
- Temps faible
- Crée une attente mélodique

---

#### 10. Suspension
```
ID: "suspension"
Force: MIXTE (préparation + résolution)
```
**Description :** Note préparée, maintenue, puis résolue vers le bas.

**Exemple :**
```
Accord 1: Do (préparation)
Accord 2: Do (suspension - maintenue) → Si (résolution)
```

**Règles :**
- **Préparation** : Note d'accord dans l'accord précédent
- **Suspension** : Note maintenue (devient dissonante)
- **Résolution** : Descend par degré conjoint

---

#### 11. Retardation (Retard)
```
ID: "retardation"
Force: MIXTE
```
**Description :** Comme la suspension, mais résolution **ascendante**.

**Exemple :**
```
Accord 1: Si (préparation)
Accord 2: Si (retard) → Do (résolution ascendante)
```

**Règles :**
- Identique à la suspension
- Mais résolution **vers le haut**

---

#### 12. Pedal (Point d'Orgue/Pédale)
```
ID: "pedal"
Force: TOUTES
```
**Description :** Note tenue sur plusieurs accords.

**Exemple :**
```
Basse: Do - Do - Do - Do
Accords: I  - IV - V  - I
```

**Règles :**
- Généralement à la basse
- Traverse plusieurs changements harmoniques
- Crée une stabilité tonale

---

#### 13. Neighbor Tone Forced (Broderie Forcée)
```
ID: "neighbor_tone_forced"
Force: FAIBLE
```
**Description :** Variante de la broderie avec contraintes spécifiques.

---

### 6.3 Tableau Récapitulatif

| Technique | ID | Force Temps | Mouvement | Caractéristique |
|-----------|----|----|-----------|-----------------|
| Note de Passage | `passing_tone` | Faible | Conjoint | Entre 2 notes d'accord |
| NP Chromatique | `chromatic_passing_tone` | Faible | Conjoint | Chromatique |
| NP Étendues | `extended_passing_tones` | Faible | Conjoint | 2-3 notes |
| Broderie | `neighbor_tone` | Faible | Conjoint | Retour même note |
| Broderie Chrom. | `chromatic_neighbor_tone` | Faible | Conjoint | Chromatique |
| Double Broderie | `double_neighbor` | Faible | Conjoint | Sup+Inf ou Inf+Sup |
| Broderie Forcée | `neighbor_tone_forced` | Faible | Conjoint | Variante |
| Appoggiature | `appoggiatura` | **Forte** ⚠️ | Conjoint | Dissonance expressive |
| Échappée | `escape_tone` | Faible | Conjoint+Saut | Degré puis saut |
| Anticipation | `anticipation` | Faible | Variable | Anticipe l'accord suivant |
| Suspension | `suspension` | Mixte | Descend | Préparée-Tenue-Résolue ↓ |
| Retard | `retardation` | Mixte | Monte | Préparée-Tenue-Résolue ↑ |
| Pédale | `pedal` | Toutes | Statique | Note tenue |

### 6.4 Conseils de Sélection

**Style Baroque :**
```gdscript
"allowed_techniques": [
    "suspension",
    "passing_tone",
    "neighbor_tone",
    "appoggiatura"
]
```

**Style Classique :**
```gdscript
"allowed_techniques": [
    "passing_tone",
    "neighbor_tone",
    "appoggiatura",
    "anticipation"
]
```

**Style Chromatique :**
```gdscript
"allowed_techniques": [
    "chromatic_passing_tone",
    "chromatic_neighbor_tone",
    "appoggiatura"
]
```

---

## 7. Exemples Pratiques

### 7.1 Exemple 1 : Enrichissement Simple

**Objectif :** Ajouter des notes de passage et des broderies à une progression basique.

```gdscript
extends Node

const TAG = "Exemple1"

func _ready():
    LogBus.set_verbose(true)

    var Planner = load("res://addons/musiclib/satb_fractalizer/planner/Planner.gd")
    var planner = Planner.new()

    # Charger une progression (4 accords en Do majeur)
    var chords = _creer_progression_simple()

    # Configuration simple
    var params = {
        "time_num": 4,
        "time_den": 4,
        "grid_unit": 0.25,  # Croches
        "time_windows": [
            {"start": 0.0, "end": 4.0},
            {"start": 4.0, "end": 8.0}
        ],
        "allowed_techniques": ["passing_tone", "neighbor_tone"],
        "voice_window_pattern": "SA",  # Soprano puis Alto
        "rng_seed": 100
    }

    var result = planner.apply(chords, params)

    LogBus.info(TAG, "Accords avant: " + str(chords.size()))
    LogBus.info(TAG, "Accords après: " + str(result.chords.size()))
    LogBus.info(TAG, "Notes ajoutées: " + str(result.chords.size() - chords.size()))

    # Sauvegarder
    _sauvegarder("res://exemple1_resultat.json", result.chords)

func _creer_progression_simple():
    # I - IV - V - I en Do majeur
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

func _sauvegarder(chemin, chords):
    var file = File.new()
    file.open(chemin, File.WRITE)
    file.store_string(JSON.print(chords, "\t"))
    file.close()
```

---

### 7.2 Exemple 2 : Fractalisation Progressive

**Objectif :** Deux passes successives pour enrichir progressivement.

```gdscript
extends Node

const TAG = "Exemple2"

func _ready():
    LogBus.set_verbose(true)

    var Planner = load("res://addons/musiclib/satb_fractalizer/planner/Planner.gd")
    var planner = Planner.new()

    var chords = _charger_json("res://chords.json")

    # === PASSE 1 : Croches, techniques simples ===
    var params1 = {
        "time_num": 4,
        "time_den": 4,
        "grid_unit": 0.25,  # Croches
        "time_windows": [
            {"start": 0.0, "end": 4.0},
            {"start": 4.0, "end": 8.0}
        ],
        "allowed_techniques": ["passing_tone", "neighbor_tone"],
        "voice_window_pattern": "SA",
        "rng_seed": 42
    }

    LogBus.info(TAG, "=== PASSE 1 ===")
    var result1 = planner.apply(chords, params1)
    LogBus.info(TAG, "Accords après passe 1: " + str(result1.chords.size()))

    # === PASSE 2 : Doubles-croches, plus de techniques ===
    var params2 = {
        "time_num": 4,
        "time_den": 4,
        "grid_unit": 0.125,  # Doubles-croches
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

    LogBus.info(TAG, "=== PASSE 2 ===")
    var result2 = planner.apply(result1.chords, params2)  # Ré-injection !
    LogBus.info(TAG, "Accords après passe 2: " + str(result2.chords.size()))
    LogBus.info(TAG, "Total notes ajoutées: " + str(result2.chords.size() - chords.size()))

    _sauvegarder("res://fractalise_2passes.json", result2.chords)

func _charger_json(chemin):
    var file = File.new()
    file.open(chemin, File.READ)
    var data = parse_json(file.get_as_text())
    file.close()
    return data

func _sauvegarder(chemin, chords):
    var file = File.new()
    file.open(chemin, File.WRITE)
    file.store_string(JSON.print(chords, "\t"))
    file.close()
```

---

### 7.3 Exemple 3 : Style Baroque (Suspensions)

**Objectif :** Créer un style baroque en favorisant les suspensions.

```gdscript
extends Node

const TAG = "ExempleBaroque"

func _ready():
    LogBus.set_verbose(true)

    var Planner = load("res://addons/musiclib/satb_fractalizer/planner/Planner.gd")
    var planner = Planner.new()

    var chords = _charger_json("res://chords.json")

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
        # Favoriser les suspensions/retards
        "technique_weights": {
            "passing_tone": 1.0,
            "neighbor_tone": 0.8,
            "suspension": 2.0,      # Double poids
            "retardation": 1.5,     # 50% plus probable
            "appoggiatura": 1.2
        },
        "voice_window_pattern": "SATB",
        "rng_seed": 1685  # Année de naissance de Bach !
    }

    var result = planner.apply(chords, params)

    # Analyser les techniques appliquées
    var report = result.metadata.technique_report
    var suspensions = 0
    for window_report in report.time_windows:
        if window_report.applied and window_report.chosen_technique == "suspension":
            suspensions += 1

    LogBus.info(TAG, "Suspensions appliquées: " + str(suspensions))
    _sauvegarder("res://baroque_style.json", result.chords)

func _charger_json(chemin):
    var file = File.new()
    file.open(chemin, File.READ)
    var data = parse_json(file.get_as_text())
    file.close()
    return data

func _sauvegarder(chemin, chords):
    var file = File.new()
    file.open(chemin, File.WRITE)
    file.store_string(JSON.print(chords, "\t"))
    file.close()
```

---

### 7.4 Exemple 4 : Voix Spécifiques (Ténor/Basse)

**Objectif :** N'enrichir que les voix graves.

```gdscript
extends Node

const TAG = "VoixGraves"

func _ready():
    LogBus.set_verbose(true)

    var Planner = load("res://addons/musiclib/satb_fractalizer/planner/Planner.gd")
    var planner = Planner.new()

    var chords = _charger_json("res://chords.json")

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
        "voice_window_pattern": "TB",  # Seulement Ténor et Basse
        "rng_seed": 42
    }

    var result = planner.apply(chords, params)

    LogBus.info(TAG, "Enrichissement des voix graves terminé")
    _sauvegarder("res://voix_graves_enrichies.json", result.chords)

func _charger_json(chemin):
    var file = File.new()
    file.open(chemin, File.READ)
    var data = parse_json(file.get_as_text())
    file.close()
    return data

func _sauvegarder(chemin, chords):
    var file = File.new()
    file.open(chemin, File.WRITE)
    file.store_string(JSON.print(chords, "\t"))
    file.close()
```

---

### 7.5 Exemple 5 : Analyser les Résultats

**Objectif :** Explorer les métadonnées pour comprendre ce qui a été appliqué.

```gdscript
extends Node

const TAG = "Analyse"

func _ready():
    LogBus.set_verbose(false)  # Désactiver les logs verbeux

    var Planner = load("res://addons/musiclib/satb_fractalizer/planner/Planner.gd")
    var planner = Planner.new()

    var chords = _charger_json("res://chords.json")

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

    # === ANALYSE DES MÉTADONNÉES ===

    print("\n=== STATISTIQUES GLOBALES ===")
    print("Accords originaux : ", chords.size())
    print("Accords enrichis : ", result.chords.size())
    print("Notes ajoutées : ", result.chords.size() - chords.size())
    print("Profondeur de génération : ", result.metadata.generation_depth)
    print("Graine aléatoire : ", result.metadata.rng_seed)

    # === RAPPORT PAR FENÊTRE ===
    print("\n=== RAPPORT PAR FENÊTRE ===")
    var report = result.metadata.technique_report
    for i in range(report.time_windows.size()):
        var window_report = report.time_windows[i]
        print("\nFenêtre ", i, " [", window_report.start, " - ", window_report.end, "]")
        print("  Voix traitée : ", window_report.voice_chosen)
        if window_report.applied:
            print("  Technique appliquée : ", window_report.chosen_technique)
            print("  Position : ", window_report.chord_pair_positions)
        else:
            print("  Non appliquée : ", window_report.reason_if_skipped)

    # === HISTORIQUE DES OPÉRATIONS ===
    print("\n=== HISTORIQUE ===")
    var history = result.metadata.history
    for entry in history:
        if entry.status == "success":
            print("✓ Fenêtre ", entry.window_index, " : ", entry.op,
                  " sur voix ", entry.voice)
        else:
            print("✗ Fenêtre ", entry.window_index, " : ", entry.reason)

    # === COMPTER LES TECHNIQUES ===
    print("\n=== TECHNIQUES UTILISÉES ===")
    var technique_count = {}
    for entry in history:
        if entry.status == "success" and entry.has("op"):
            var tech = entry.op
            if not technique_count.has(tech):
                technique_count[tech] = 0
            technique_count[tech] += 1

    for tech in technique_count.keys():
        print("  ", tech, " : ", technique_count[tech], " fois")

func _charger_json(chemin):
    var file = File.new()
    file.open(chemin, File.READ)
    var data = parse_json(file.get_as_text())
    file.close()
    return data
```

**Sortie attendue :**
```
=== STATISTIQUES GLOBALES ===
Accords originaux : 30
Accords enrichis : 34
Notes ajoutées : 4
Profondeur de génération : 1
Graine aléatoire : 42

=== RAPPORT PAR FENÊTRE ===

Fenêtre 0 [0.0 - 2.0]
  Voix traitée : Soprano
  Technique appliquée : passing_tone
  Position : [0, 1]

Fenêtre 1 [2.0 - 4.0]
  Voix traitée : Alto
  Non appliquée : no_valid_pair

...
```

---

### 7.6 Exemple 6 : Utiliser les Triolets

**Objectif :** Activer les triolets pour créer des subdivisions ternaires.

```gdscript
extends Node

const TAG = "ExempleTriolets"

func _ready():
    LogBus.set_verbose(true)

    var Planner = load("res://addons/musiclib/satb_fractalizer/planner/Planner.gd")
    var planner = Planner.new()

    var chords = _charger_json("res://chords.json")

    # Configuration avec triolets activés
    var params = {
        "time_num": 4,
        "time_den": 4,
        "grid_unit": 0.25,  # Croches
        "time_windows": [
            {"start": 0.0, "end": 1.0},  # Une noire
            {"start": 1.0, "end": 2.0},  # Une noire
            {"start": 2.0, "end": 3.0},  # Une noire
            {"start": 3.0, "end": 4.0}   # Une noire
        ],
        "allowed_techniques": ["passing_tone", "neighbor_tone"],
        "voice_window_pattern": "SATB",
        "triplet_allowed": true,  # ← ACTIVER LES TRIOLETS
        "rng_seed": 42
    }

    LogBus.info(TAG, "=== Application avec triolets ===")
    var result = planner.apply(chords, params)

    # Analyser les triolets
    var triplet_chords = []
    for chord in result.chords:
        if chord.get("kind", "") == "decorative":
            var metadata = chord.get("metadata", {})
            if metadata.get("triplet", false):
                triplet_chords.append(chord)

    LogBus.info(TAG, "Accords originaux : " + str(chords.size()))
    LogBus.info(TAG, "Accords enrichis : " + str(result.chords.size()))
    LogBus.info(TAG, "Triolets trouvés : " + str(triplet_chords.size()))

    # Afficher les triolets
    for chord in triplet_chords:
        print("\nTriolet détecté :")
        print("  Position : ", chord.pos)
        print("  Durée : ", chord.length_beats, " (attendu : ~0.333)")
        print("  Voix modifiée : ", chord.metadata.get("modified_voice", "?"))

    _sauvegarder("res://avec_triolets.json", result.chords)

func _charger_json(chemin):
    var file = File.new()
    file.open(chemin, File.READ)
    var data = parse_json(file.get_as_text())
    file.close()
    return data

func _sauvegarder(chemin, chords):
    var file = File.new()
    file.open(chemin, File.WRITE)
    file.store_string(JSON.print(chords, "\t"))
    file.close()
```

**Résultat attendu :**
- Les fenêtres d'une noire (1.0 beat) peuvent être divisées en triolets
- Chaque note du triolet dure ~0.333 battement
- Les métadonnées indiquent `"triplet": true`

**Comparaison binaire vs. ternaire :**

Sans triolets (`triplet_allowed: false`) :
```
Noire → [0.5, 0.5]  (2 croches)
Noire → [0.25, 0.25, 0.25, 0.25]  (4 double-croches)
```

Avec triolets (`triplet_allowed: true`) :
```
Noire → [0.333..., 0.333..., 0.333...]  (triolet de croches)
```

---

## 8. Fonctionnalités Avancées

### 8.1 Ré-injection Multiple

La ré-injection permet de "fractaliser" progressivement une progression en appliquant plusieurs passes avec des subdivisions de plus en plus fines.

```gdscript
func fractaliser_progressivement(chords_initiaux):
    var Planner = load("res://addons/musiclib/satb_fractalizer/planner/Planner.gd")
    var planner = Planner.new()

    var passes = [
        {
            "name": "Passe 1 - Noires",
            "params": {
                "grid_unit": 0.5,
                "allowed_techniques": ["passing_tone"]
            }
        },
        {
            "name": "Passe 2 - Croches",
            "params": {
                "grid_unit": 0.25,
                "allowed_techniques": ["passing_tone", "neighbor_tone"]
            }
        },
        {
            "name": "Passe 3 - Doubles-croches",
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

    var chords = chords_initiaux
    for passe in passes:
        LogBus.info(TAG, "=== " + passe.name + " ===")
        var result = planner.apply(chords, passe.params)
        chords = result.chords
        LogBus.info(TAG, "Accords: " + str(chords.size()))

    return chords
```

### 8.2 Analyse des Voix

Extraire les lignes mélodiques individuelles après enrichissement :

```gdscript
func extraire_ligne_soprano(chords):
    var ligne = []
    for chord in chords:
        ligne.append({
            "pos": chord.pos,
            "pitch": chord.Soprano,
            "role": chord.get("Soprano_role", "unknown")
        })
    return ligne

func afficher_ligne(ligne):
    for note in ligne:
        var role_str = note.role if note.role != "chord_tone" else "CHORD"
        print("Pos: ", note.pos, " | Pitch: ", note.pitch, " | Role: ", role_str)
```

### 8.3 Validation Musicale

Vérifier la validité d'une progression avant/après traitement :

```gdscript
var VoiceLeading = load("res://addons/musiclib/satb_fractalizer/utils/VoiceLeading.gd")

func valider_progression(chords):
    var violations = []

    for i in range(chords.size() - 1):
        var c1 = chords[i]
        var c2 = chords[i + 1]

        # Vérifier les croisements de voix
        if not VoiceLeading.check_no_voice_crossing(
            c1.Soprano, c1.Alto, c1.Tenor, c1.Bass,
            c2.Soprano, c2.Alto, c2.Tenor, c2.Bass
        ):
            violations.append("Croisement de voix entre accords " + str(i) + " et " + str(i+1))

        # Vérifier les intervalles parallèles (quintes/octaves)
        # (à implémenter selon vos besoins)

    return violations
```

### 8.4 Export MIDI (Conceptuel)

SATB Fractalizer ne génère pas directement de fichiers MIDI, mais voici comment vous pourriez exporter les données :

```gdscript
# Pseudo-code - nécessite une bibliothèque MIDI externe
func exporter_midi(chords, filename):
    var midi = MIDIFile.new()  # Hypothétique
    midi.add_tempo_track(120)  # 120 BPM

    var tracks = {
        "Soprano": midi.add_track("Soprano"),
        "Alto": midi.add_track("Alto"),
        "Tenor": midi.add_track("Tenor"),
        "Bass": midi.add_track("Bass")
    }

    for chord in chords:
        var pos_ticks = chord.pos * 480  # 480 ticks par battement
        var duration_ticks = chord.length_beats * 480

        tracks["Soprano"].add_note(chord.Soprano, pos_ticks, duration_ticks, 64)
        tracks["Alto"].add_note(chord.Alto, pos_ticks, duration_ticks, 64)
        tracks["Tenor"].add_note(chord.Tenor, pos_ticks, duration_ticks, 64)
        tracks["Bass"].add_note(chord.Bass, pos_ticks, duration_ticks, 64)

    midi.save(filename)
```

### 8.5 Patterns de Voix Avancés

Créer des patterns personnalisés :

```gdscript
# Pattern "dialogue" : Soprano-Alto-Soprano-Alto
params["voice_window_pattern"] = "SASA"

# Pattern "basse active"
params["voice_window_pattern"] = "BBBST"

# Pattern "toutes sauf basse"
params["voice_window_pattern"] = "SAT"
```

### 8.6 Techniques Pondérées par Contexte

Adapter les poids selon le contexte harmonique :

```gdscript
func adapter_poids_selon_contexte(chord_index, total_chords):
    var progression = float(chord_index) / float(total_chords)

    if progression < 0.25:
        # Début : techniques simples
        return {
            "passing_tone": 1.5,
            "neighbor_tone": 1.0,
            "appoggiatura": 0.3
        }
    elif progression < 0.75:
        # Milieu : plus de variété
        return {
            "passing_tone": 1.0,
            "chromatic_passing_tone": 0.8,
            "neighbor_tone": 1.0,
            "appoggiatura": 1.0,
            "suspension": 0.6
        }
    else:
        # Fin : techniques expressives
        return {
            "appoggiatura": 1.5,
            "suspension": 1.2,
            "retardation": 0.8
        }
```

---

## 9. Résolution de Problèmes

### 9.1 Problèmes Courants

#### Problème : Aucune Note Ajoutée

**Symptômes :**
```
Accords avant: 30
Accords après: 30
Notes ajoutées: 0
```

**Causes possibles :**
1. **Fenêtres temporelles invalides** : Les fenêtres ne couvrent pas les accords
2. **Grid unit trop grand** : Pas de subdivision possible
3. **Techniques incompatibles** : Aucune technique ne peut s'appliquer

**Solutions :**
```gdscript
# Vérifier les fenêtres
print("Durée totale : ", chords[-1].pos + chords[-1].length_beats)
print("Fenêtres : ", params.time_windows)

# Réduire grid_unit
params["grid_unit"] = 0.125  # Au lieu de 0.5

# Activer les logs
LogBus.set_verbose(true)
```

---

#### Problème : "no_valid_pair" dans les Logs

**Symptômes :**
```
✗ Fenêtre 0 : no_valid_pair
```

**Causes :**
- Aucune paire d'accords consécutifs dans la fenêtre
- Accords trop courts pour être subdivisés

**Solutions :**
```gdscript
# Élargir les fenêtres
"time_windows": [
    {"start": 0.0, "end": 4.0}  # Au lieu de 2.0
]

# Vérifier les durées
for chord in chords:
    if chord.length_beats < params.grid_unit * 2:
        print("Accord trop court : ", chord.index)
```

---

#### Problème : Croisements de Voix

**Symptômes :**
```
WARNING: Voice crossing detected
```

**Causes :**
- Notes de passage créent des croisements
- Tessitures trop proches

**Solutions :**
```gdscript
# Vérifier l'ordre initial
for chord in chords:
    if not (chord.Soprano >= chord.Alto >= chord.Tenor >= chord.Bass):
        print("Ordre invalide dès l'accord ", chord.index)

# La validation VoiceLeading devrait prévenir cela automatiquement
```

---

#### Problème : Résultats Non Reproductibles

**Symptômes :**
Résultats différents à chaque exécution.

**Causes :**
- `rng_seed` non défini (utilise l'horodatage)

**Solutions :**
```gdscript
params["rng_seed"] = 42  # Fixer une graine
```

---

#### Problème : LogBus Non Trouvé

**Symptômes :**
```
ERROR: Singleton "LogBus" not found
```

**Causes :**
- LogBus non configuré dans Autoload

**Solutions :**
1. Projet → Paramètres du Projet → Autoload
2. Ajouter : Nom = `LogBus`, Chemin = `res://LogBus.gd`
3. Redémarrer Godot

---

### 9.2 Débogage Avancé

#### Activer les Logs Détaillés

```gdscript
LogBus.set_verbose(true)

# Ajouter des logs personnalisés
LogBus.debug(TAG, "Vérification de la fenêtre " + str(i))
LogBus.info(TAG, "Technique sélectionnée : " + technique)
LogBus.warn(TAG, "Aucune paire valide trouvée")
LogBus.error(TAG, "Erreur critique")
```

#### Inspecter les Métadonnées

```gdscript
func debug_metadata(result):
    print("\n=== DEBUG MÉTADONNÉES ===")
    print(JSON.print(result.metadata, "  "))

    # Historique détaillé
    for entry in result.metadata.history:
        print("\nEntrée:")
        print("  Status: ", entry.status)
        print("  Window: ", entry.window_index)
        if entry.has("op"):
            print("  Operation: ", entry.op)
        if entry.has("reason"):
            print("  Reason: ", entry.reason)
```

#### Valider les Données d'Entrée

```gdscript
func valider_entree(chords):
    for i in range(chords.size()):
        var c = chords[i]

        # Champs obligatoires
        var required = ["index", "pos", "length_beats", "key_midi_root",
                        "scale_array", "key_alterations", "key_scale_name",
                        "kind", "Soprano", "Alto", "Tenor", "Bass"]
        for field in required:
            if not c.has(field):
                print("ERROR: Accord ", i, " manque le champ '", field, "'")
                return false

        # Ordre des voix
        if not (c.Soprano >= c.Alto and c.Alto >= c.Tenor and c.Tenor >= c.Bass):
            print("ERROR: Ordre des voix invalide à l'accord ", i)
            return false

        # Durée positive
        if c.length_beats <= 0:
            print("ERROR: Durée négative ou nulle à l'accord ", i)
            return false

    print("✓ Validation entrée OK")
    return true
```

---

### 9.3 Performances

#### Optimiser pour de Grandes Progressions

Pour des progressions de 100+ accords :

```gdscript
# Désactiver les logs verbeux
LogBus.set_verbose(false)

# Utiliser moins de fenêtres
"time_windows": [
    {"start": 0.0, "end": 16.0},
    {"start": 16.0, "end": 32.0}
]

# Limiter les techniques
"allowed_techniques": ["passing_tone", "neighbor_tone"]

# Utiliser "earliest" pour la sélection
"pair_selection_strategy": "earliest"
```

#### Mesurer les Performances

```gdscript
func mesurer_performance(chords, params):
    var debut = OS.get_ticks_msec()

    var result = planner.apply(chords, params)

    var duree = OS.get_ticks_msec() - debut
    print("Temps d'exécution : ", duree, " ms")
    print("Accords traités : ", chords.size())
    print("Vitesse : ", float(chords.size()) / (float(duree) / 1000.0), " accords/sec")

    return result
```

---

## 10. Référence Rapide

### 10.1 Checklist de Démarrage

- [ ] Godot 3.6 installé
- [ ] Dossier `addons/musiclib/satb_fractalizer/` copié
- [ ] LogBus configuré dans Autoload
- [ ] Fichier JSON de progression préparé
- [ ] Script de test créé

### 10.2 Structure Minimale de Paramètres

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

### 10.3 Commandes Essentielles

```gdscript
# Charger le Planner
var Planner = load("res://addons/musiclib/satb_fractalizer/planner/Planner.gd")
var planner = Planner.new()

# Appliquer
var result = planner.apply(chords, params)

# Accéder aux résultats
var chords_enrichis = result.chords
var metadata = result.metadata

# Logs
LogBus.set_verbose(true)
LogBus.info("TAG", "Message")
```

### 10.4 Techniques par Catégorie

**Mouvement Conjoint :**
- `passing_tone`
- `chromatic_passing_tone`
- `extended_passing_tones`

**Ornements :**
- `neighbor_tone`
- `chromatic_neighbor_tone`
- `double_neighbor`

**Dissonances Expressives :**
- `appoggiatura` (temps fort)
- `suspension`
- `retardation`

**Anticipation/Échappée :**
- `anticipation`
- `escape_tone`

**Statique :**
- `pedal`

### 10.5 Grid Units Courants

| Valeur | Notation | Nom Français |
|--------|----------|--------------|
| 1.0 | 𝅝 | Ronde |
| 0.5 | ♩ | Noire |
| 0.25 | ♪ | Croche |
| 0.125 | 𝅘𝅥𝅯 | Double-croche |
| 0.0625 | 𝅘𝅥𝅰 | Triple-croche |

### 10.6 Voice Patterns Courants

| Pattern | Description |
|---------|-------------|
| `"S"` | Soprano uniquement |
| `"SA"` | Soprano → Alto → Soprano... |
| `"SATB"` | Rotation complète |
| `"TB"` | Voix graves uniquement |
| `"SSAA"` | Emphase sur voix aiguës |

### 10.7 Fichiers Clés

```
/addons/musiclib/satb_fractalizer/
├── planner/Planner.gd          ← Point d'entrée principal
├── core/ProgressionAdapter.gd   ← Conversion JSON
├── core/ScaleContext.gd         ← Gestion des gammes
└── techniques/                  ← 13 techniques
```

### 10.8 Liens Utiles

- **Dépôt GitHub** : [laurentVeliscek/SATB_fractalizer](https://github.com/laurentVeliscek/SATB_fractalizer)
- **Documentation Technique** : `SATB_fractalizer_V2.md` (836 lignes)
- **Licence** : GNU GPL v3.0
- **Godot 3.6** : [https://godotengine.org/download/3.x](https://godotengine.org/download/3.x)

---

## Annexes

### A. Exemple de Fichier chords.json

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

### B. Glossaire Musical

| Terme | Définition |
|-------|------------|
| **SATB** | Soprano, Alto, Ténor, Basse (quatuor vocal standard) |
| **NCT** | Non-Chord Tone (note hors accord) |
| **Temps fort** | Premier temps de la mesure (plus accentué) |
| **Temps faible** | Temps non accentués (2, 3, 4 en 4/4) |
| **Mouvement conjoint** | Progression par degré (intervalle d'un ton ou demi-ton) |
| **Mouvement disjoint** | Progression par saut (intervalle > seconde) |
| **Tessiture** | Étendue de notes confortable pour une voix |
| **Croisement de voix** | Voix inférieure monte au-dessus d'une voix supérieure |

### C. Théorie : Force des Temps en 4/4

```
Mesure :  |  1   2   3   4  |
Force :   | ▓▓  ░░  ▒▒  ░░ |
          |FORT faible moyen faible|

Subdivisions (croches) :
|  1  +  2  +  3  +  4  + |
| ▓▓ ░░ ░░ ░░ ▒▒ ░░ ░░ ░░|
```

- **Temps 1** : Très fort (appoggiaturas possibles)
- **Temps 2, 4** : Faibles (notes de passage)
- **Temps 3** : Moyennement fort (en 4/4)

---

## Licence

SATB Fractalizer est distribué sous **GNU General Public License v3.0**.

Vous êtes libre de :
- ✓ Utiliser le logiciel à des fins personnelles ou commerciales
- ✓ Modifier le code source
- ✓ Distribuer le logiciel original ou modifié

À condition de :
- ✓ Publier votre code source sous la même licence (copyleft)
- ✓ Inclure une copie de la licence GPL-3.0
- ✓ Mentionner les modifications apportées

Pour plus de détails : [https://www.gnu.org/licenses/gpl-3.0.html](https://www.gnu.org/licenses/gpl-3.0.html)

---

## Support et Contributions

**Rapporter un Bug :**
Créez une issue sur GitHub avec :
- Description du problème
- Fichier JSON d'entrée minimal
- Paramètres utilisés
- Version de Godot

**Contribuer :**
Les pull requests sont les bienvenues ! Consultez `CONTRIBUTING.md` (si disponible).

---

**Version du Manuel :** 1.0
**Date :** Janvier 2025
**Auteur :** Documentation générée pour SATB Fractalizer v0.4
