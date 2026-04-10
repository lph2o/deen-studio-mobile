/// A voice effect preset that modifies audio playback characteristics.
class VoiceEffect {
  final String id;
  final String name;
  final String icon;
  final double speed;     // playback speed multiplier
  final double pitch;     // pitch shift (simulated via speed for now)
  final double reverb;    // 0.0-1.0 (simulated via volume reduction)
  final double echo;      // 0.0-1.0 (simulated via volume reduction)

  const VoiceEffect({
    required this.id,
    required this.name,
    required this.icon,
    this.speed = 1.0,
    this.pitch = 1.0,
    this.reverb = 0.0,
    this.echo = 0.0,
  });
}

/// Built-in voice effects available for audio layers.
const kVoiceEffects = [
  VoiceEffect(id: 'none', name: 'Normal', icon: '\u{1F3A4}'),
  VoiceEffect(id: 'chipmunk', name: 'Chipmunk', icon: '\u{1F43F}\u{FE0F}', speed: 1.5, pitch: 1.5),
  VoiceEffect(id: 'deep', name: 'Voix grave', icon: '\u{1F479}', speed: 0.75, pitch: 0.75),
  VoiceEffect(id: 'robot', name: 'Robot', icon: '\u{1F916}', speed: 0.9, pitch: 0.5),
  VoiceEffect(id: 'giant', name: 'Geant', icon: '\u{1F5FF}', speed: 0.6, pitch: 0.6),
  VoiceEffect(id: 'echo', name: 'Echo', icon: '\u{1F3D4}\u{FE0F}', speed: 1.0, echo: 0.5),
  VoiceEffect(id: 'reverb', name: 'Reverberation', icon: '\u{1F3B5}', speed: 1.0, reverb: 0.5),
  VoiceEffect(id: 'radio', name: 'Radio', icon: '\u{1F4FB}', speed: 1.0, pitch: 0.8),
  VoiceEffect(id: 'alien', name: 'Alien', icon: '\u{1F47D}', speed: 1.1, pitch: 1.8),
  VoiceEffect(id: 'ghost', name: 'Ghost', icon: '\u{1F47B}', speed: 0.7, pitch: 0.4, reverb: 0.6),
  VoiceEffect(id: 'megaphone', name: 'Megaphone', icon: '\u{1F4E2}', speed: 1.0, pitch: 0.9),
  VoiceEffect(id: 'underwater', name: 'Underwater', icon: '\u{1F30A}', speed: 0.8, pitch: 0.6, reverb: 0.4),
  VoiceEffect(id: 'telephone', name: 'Telephone', icon: '\u{1F4DE}', speed: 1.0, pitch: 1.2),
  VoiceEffect(id: 'nightcore', name: 'Nightcore', icon: '\u{2728}', speed: 1.3, pitch: 1.3),
  VoiceEffect(id: 'slowed_reverb', name: 'Slowed + Reverb', icon: '\u{1F3A7}', speed: 0.85, pitch: 0.85, reverb: 0.5),
];

/// Look up a voice effect by its ID.
VoiceEffect findVoiceEffectById(String id) {
  return kVoiceEffects.firstWhere(
    (e) => e.id == id,
    orElse: () => kVoiceEffects.first,
  );
}
