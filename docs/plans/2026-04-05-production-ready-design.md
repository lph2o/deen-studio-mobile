# Deen Studio — Production-Ready Design

**Date:** 2026-04-05  
**Status:** Approved

---

## Overview

Rendre Deen Studio 01 production-ready en implémentant toutes les fonctionnalités manquantes, en sécurisant les credentials, et en ajoutant la documentation nécessaire.

## Tech Stack Decisions

| Feature | Solution | Raison |
|---------|----------|--------|
| Export vidéo | `ffmpeg_kit_flutter` (local) | Gratuit, contrôle total, pas de coût serveur |
| Sous-titres auto | `speech_to_text` (natif) | Gratuit, offline, pas de dépendance externe |
| Text-to-Speech | `flutter_tts` + ElevenLabs | Gratuit par défaut, premium optionnel |
| Env vars | `flutter_dotenv` + `.env` | Déjà dans pubspec, simple et efficace |

## Phases

### P0 — Bloquant production
1. **Export vidéo FFmpeg** : Composer background + text overlays + audio → MP4
2. **Sécuriser credentials** : `.env` pour Supabase URL/anon key

### P1 — Features core
3. **Animations texte** : 16 presets visuels dans la preview
4. **TTS** : flutter_tts + ElevenLabs optionnel
5. **Auto subtitles** : speech_to_text natif

### P2 — Polish & UX
6. **Toolbar tools** : split, volume, speed, transitions
7. **Templates** : Système fonctionnel avec Supabase
8. **Profil/Settings** : Fonctionnels

### P3 — Production readiness
9. App icon + splash screen
10. Tests unitaires + widget tests
11. Documentation
12. Permissions, release signing
13. Nettoyage legacy React

## Architecture

L'architecture feature-first existante est conservée. Chaque nouvelle feature sera ajoutée dans le dossier approprié sous `lib/features/` ou `lib/core/`.

### Export FFmpeg
- Nouveau service : `lib/core/services/video_export_service.dart`
- Utilise `ffmpeg_kit_flutter` pour composer la vidéo
- Pipeline : assets → FFmpeg command → fichier MP4 → partage
- UI : Remplacer le placeholder `_ExportDialog` par un vrai écran d'export (résolution, qualité, progression)

### Animations texte
- Modifier `_TextLayerWidget` dans `video_preview.dart` pour appliquer les animations
- Utiliser `AnimationController` + `Tween` pour chaque preset
- Types : fade, slide, scale, typewriter, bounce, glitch, karaoke, word-by-word

### TTS
- Nouveau widget : `text_to_speech_sheet.dart` (existant, à remplacer)
- `flutter_tts` pour les voix natives
- ElevenLabs via API HTTP (optionnel, configurable dans settings)

### Auto Subtitles
- Nouveau service : `lib/core/services/speech_to_text_service.dart`
- `speech_to_text` package pour la reconnaissance vocale
- Génère des Layer objects avec timestamps

## Dependencies à ajouter

```yaml
# P0
ffmpeg_kit_flutter: ^6.0.3
flutter_dotenv: ^5.2.1  # déjà présent

# P1
speech_to_text: ^7.3.0
flutter_tts: ^4.2.3

# P3
flutter_launcher_icons: ^0.14.1
flutter_native_splash: ^2.4.4
```

## Permissions à ajouter

### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### iOS (Info.plist)
```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>Reconnaissance vocale pour les sous-titres automatiques</string>
<key>NSMicrophoneUsageDescription</key>
<string>Accès au microphone pour les sous-titres automatiques</string>
```
