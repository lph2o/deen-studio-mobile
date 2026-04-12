# Audio/Text Sync + First-Word Transition Fix

Date: 2026-04-12

## Contexte

Deux défauts apparaissaient en récitation Quran:
- décalage audio/animation texte arabe pendant la lecture continue;
- saut du premier mot au passage vers le verset suivant.

## Cause Racine

- L'animation texte utilisait principalement l'horloge timeline UI (`currentTime`) plutôt que la position audio réelle.
- Au switch de verset, un `seek` pouvait intervenir dans la zone de démarrage, ce qui coupait l'attaque du premier mot.
- La sélection de chunk texte utilisait un fallback vers le dernier chunk quand aucun chunk n'était strictement actif, ce qui amplifiait les erreurs aux frontières temporelles.

## Modifications

### 1) Timing centralisé récitation

- Ajout de `RecitationTiming` dans:
  - `lib/features/editor/presentation/recitation/recitation_timing.dart`
- Nouvelles responsabilités:
  - fenêtre de priorité près des frontières de verset;
  - calcul du `seek` de transition;
  - calcul d'un temps de récitation effectif basé sur la position audio réelle;
  - délai court de correction de drift juste après un switch.

### 2) Intégration dans VideoPreview

Fichier:
- `lib/features/editor/presentation/widgets/video_preview.dart`

Changements:
- ajout d'une horloge `recitationTime` dérivée de la position `just_audio` quand la source est prête;
- rendu des layers `arabic/translation/phonetic` piloté par `recitationTime`;
- protection anti-coupure du premier mot:
  - mémorisation instant du switch audio;
  - blocage temporaire des corrections de drift dans la fenêtre post-switch;
- sélection de chunk robuste avec clamp temporel:
  - avant premier chunk -> premier chunk;
  - après dernier chunk -> dernier chunk;
  - entre deux bornes -> chunk actif.

### 3) Tests unitaires

Fichier:
- `test/features/editor/recitation/recitation_timing_test.dart`

Ajouts:
- transitions boundary (anti-saut du premier mot);
- profils de récitateurs avec durées différentes;
- comportement multi-vitesses;
- calcul `effectiveRecitationTime`;
- fenêtre de protection post-switch.

## Impact attendu

- Synchronisation audio-texte plus stable, car le texte suit l'horloge audio réelle.
- Disparition du saut systématique du premier mot au verset suivant.
- Préservation du comportement existant hors zones de transition (pas de régression visée).

## Validation

Validation statique:
- diagnostics IDE sans nouvelles erreurs bloquantes sur les fichiers modifiés.

Validation runtime recommandée:
- lecture de plusieurs séquences courtes/longues de versets;
- test à 0.75x, 1.0x, 1.25x, 1.5x;
- vérification visuelle que le premier mot de chaque verset est bien entendu et surligné.
