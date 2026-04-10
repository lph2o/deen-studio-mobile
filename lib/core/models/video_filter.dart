/// A cinematic filter preset that can be applied to video/image layers.
///
/// Each filter adjusts brightness, contrast, saturation, warmth, vignette,
/// and optional tint overlay to achieve a specific look.
class VideoFilter {
  final String id;
  final String name;
  final double brightness;    // 1.0 = neutral
  final double contrast;      // 1.0 = neutral
  final double saturation;    // 1.0 = neutral
  final double warmth;        // 0.0 = neutral, positive = warmer, negative = cooler
  final double vignette;      // 0.0 = none, 1.0 = full
  final String? tint;         // hex color for tint overlay (e.g. 'FFD700')

  const VideoFilter({
    required this.id,
    required this.name,
    this.brightness = 1.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
    this.warmth = 0.0,
    this.vignette = 0.0,
    this.tint,
  });

  bool get isNone => id == 'none';

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'brightness': brightness,
    'contrast': contrast,
    'saturation': saturation,
    'warmth': warmth,
    'vignette': vignette,
    if (tint != null) 'tint': tint,
  };

  factory VideoFilter.fromMap(Map<String, dynamic> m) => VideoFilter(
    id: m['id'] ?? 'none',
    name: m['name'] ?? 'Original',
    brightness: (m['brightness'] ?? 1.0).toDouble(),
    contrast: (m['contrast'] ?? 1.0).toDouble(),
    saturation: (m['saturation'] ?? 1.0).toDouble(),
    warmth: (m['warmth'] ?? 0.0).toDouble(),
    vignette: (m['vignette'] ?? 0.0).toDouble(),
    tint: m['tint'],
  );
}

// Built-in filter presets
const kBuiltInFilters = [
  VideoFilter(id: 'none', name: 'Original'),
  VideoFilter(
    id: 'cinematic', name: 'Cinema',
    brightness: 0.9, contrast: 1.2, saturation: 0.8,
    warmth: 0.1, vignette: 0.3,
  ),
  VideoFilter(
    id: 'vintage', name: 'Vintage',
    brightness: 1.1, contrast: 0.9, saturation: 0.6,
    warmth: 0.2, tint: 'FFD700',
  ),
  VideoFilter(
    id: 'bw', name: 'Noir & Blanc',
    saturation: 0.0, contrast: 1.3,
  ),
  VideoFilter(
    id: 'warm', name: 'Chaud',
    brightness: 1.05, warmth: 0.3, saturation: 1.2,
  ),
  VideoFilter(
    id: 'cool', name: 'Froid',
    brightness: 1.0, warmth: -0.2, saturation: 0.9, tint: '4169E1',
  ),
  VideoFilter(
    id: 'dramatic', name: 'Dramatique',
    contrast: 1.5, brightness: 0.8, saturation: 0.7, vignette: 0.5,
  ),
  VideoFilter(
    id: 'faded', name: 'Delave',
    contrast: 0.8, brightness: 1.2, saturation: 0.7,
  ),
  VideoFilter(
    id: 'vivid', name: 'Vif',
    saturation: 1.5, contrast: 1.2, brightness: 1.1,
  ),
  VideoFilter(
    id: 'moody', name: 'Sombre',
    brightness: 0.7, contrast: 1.3, saturation: 0.6,
    vignette: 0.4, tint: '2F1B3D',
  ),
  VideoFilter(
    id: 'golden', name: 'Golden Hour',
    brightness: 1.1, warmth: 0.4, saturation: 1.1, vignette: 0.2,
  ),
  VideoFilter(
    id: 'noir', name: 'Film Noir',
    saturation: 0.0, contrast: 1.5, brightness: 0.9, vignette: 0.5,
  ),

  // ── Cinematic ──
  VideoFilter(
    id: 'anamorphic', name: 'Anamorphic',
    brightness: 0.85, contrast: 1.3, saturation: 0.75,
    warmth: 0.15, vignette: 0.4, tint: '1A237E',
  ),
  VideoFilter(
    id: 'blockbuster', name: 'Blockbuster',
    brightness: 0.95, contrast: 1.35, saturation: 0.85,
    warmth: 0.1, vignette: 0.35,
  ),
  VideoFilter(
    id: 'indie', name: 'Indie Film',
    brightness: 1.05, contrast: 0.95, saturation: 0.7,
    warmth: 0.25, vignette: 0.2,
  ),
  VideoFilter(
    id: 'film_grain', name: 'Film Grain',
    brightness: 0.95, contrast: 1.15, saturation: 0.8,
    warmth: 0.15, vignette: 0.3, tint: '8B7355',
  ),

  // ── Vintage ──
  VideoFilter(
    id: 'retro_70s', name: 'Retro 70s',
    brightness: 1.1, contrast: 0.85, saturation: 0.65,
    warmth: 0.3, tint: 'E8A317',
  ),
  VideoFilter(
    id: 'vhs_80s', name: '80s VHS',
    brightness: 1.15, contrast: 0.9, saturation: 0.55,
    warmth: 0.1, tint: '00CED1',
  ),
  VideoFilter(
    id: 'sepia', name: 'Sepia',
    brightness: 1.05, contrast: 0.95, saturation: 0.3,
    warmth: 0.4, tint: '704214',
  ),
  VideoFilter(
    id: 'kodachrome', name: 'Kodachrome',
    brightness: 1.0, contrast: 1.1, saturation: 1.15,
    warmth: 0.2, tint: 'FF6347',
  ),
  VideoFilter(
    id: 'polaroid', name: 'Polaroid',
    brightness: 1.15, contrast: 0.8, saturation: 0.7,
    warmth: 0.25, vignette: 0.15, tint: 'FFF8DC',
  ),
  VideoFilter(
    id: 'faded_film', name: 'Faded Film',
    brightness: 1.1, contrast: 0.85, saturation: 0.6,
    warmth: 0.15, vignette: 0.25,
  ),
  VideoFilter(
    id: 'super8', name: 'Super 8',
    brightness: 1.05, contrast: 1.0, saturation: 0.75,
    warmth: 0.2, vignette: 0.4, tint: 'CD853F',
  ),

  // ── Color ──
  VideoFilter(
    id: 'warm_sunset', name: 'Warm Sunset',
    brightness: 1.05, contrast: 1.1, saturation: 1.3,
    warmth: 0.45, tint: 'FF4500',
  ),
  VideoFilter(
    id: 'cool_ocean', name: 'Cool Ocean',
    brightness: 1.0, contrast: 1.15, saturation: 0.85,
    warmth: -0.3, tint: '006994',
  ),
  VideoFilter(
    id: 'forest', name: 'Forest',
    brightness: 0.95, contrast: 1.1, saturation: 1.2,
    warmth: -0.1, tint: '228B22',
  ),
  VideoFilter(
    id: 'desert', name: 'Desert',
    brightness: 1.1, contrast: 1.05, saturation: 0.9,
    warmth: 0.35, tint: 'EDC9AF',
  ),
  VideoFilter(
    id: 'lavender', name: 'Lavender',
    brightness: 1.05, contrast: 0.95, saturation: 0.8,
    warmth: -0.1, tint: 'E6E6FA',
  ),
  VideoFilter(
    id: 'mint', name: 'Mint',
    brightness: 1.1, contrast: 0.9, saturation: 0.75,
    warmth: -0.15, tint: '98FF98',
  ),
  VideoFilter(
    id: 'rose', name: 'Rose',
    brightness: 1.05, contrast: 1.0, saturation: 1.1,
    warmth: 0.15, tint: 'FF007F',
  ),
  VideoFilter(
    id: 'peach', name: 'Peach',
    brightness: 1.1, contrast: 0.95, saturation: 1.05,
    warmth: 0.3, tint: 'FFDAB9',
  ),
  VideoFilter(
    id: 'coral', name: 'Coral',
    brightness: 1.05, contrast: 1.1, saturation: 1.25,
    warmth: 0.25, tint: 'FF7F50',
  ),

  // ── B&W ──
  VideoFilter(
    id: 'classic_bw', name: 'Classic B&W',
    saturation: 0.0, contrast: 1.1, brightness: 1.0,
  ),
  VideoFilter(
    id: 'high_contrast_bw', name: 'High Contrast B&W',
    saturation: 0.0, contrast: 1.8, brightness: 0.9,
  ),
  VideoFilter(
    id: 'silver', name: 'Silver',
    saturation: 0.0, contrast: 1.2, brightness: 1.1,
    tint: 'C0C0C0',
  ),
  VideoFilter(
    id: 'charcoal', name: 'Charcoal',
    saturation: 0.0, contrast: 1.6, brightness: 0.75,
    vignette: 0.3,
  ),
  VideoFilter(
    id: 'infrared_bw', name: 'Infrared',
    saturation: 0.0, contrast: 1.3, brightness: 1.2,
    tint: 'F0FFF0',
  ),

  // ── Creative ──
  VideoFilter(
    id: 'teal_orange', name: 'Teal & Orange',
    brightness: 0.95, contrast: 1.2, saturation: 1.15,
    warmth: 0.3, tint: '008080',
  ),
  VideoFilter(
    id: 'cyanotype', name: 'Cyanotype',
    brightness: 1.0, contrast: 1.15, saturation: 0.4,
    warmth: -0.4, tint: '0047AB',
  ),
  VideoFilter(
    id: 'cross_process', name: 'Cross Process',
    brightness: 1.05, contrast: 1.1, saturation: 1.2,
    warmth: 0.2, tint: '32CD32',
  ),
  VideoFilter(
    id: 'bleach_bypass', name: 'Bleach Bypass',
    brightness: 0.9, contrast: 1.4, saturation: 0.5,
    vignette: 0.25,
  ),
  VideoFilter(
    id: 'technicolor', name: 'Technicolor',
    brightness: 1.05, contrast: 1.25, saturation: 1.4,
    warmth: 0.2,
  ),
  VideoFilter(
    id: 'kodak_portra', name: 'Kodak Portra',
    brightness: 1.05, contrast: 0.95, saturation: 0.85,
    warmth: 0.25, tint: 'FFE4C4',
  ),
  VideoFilter(
    id: 'fuji_pro', name: 'Fuji Pro',
    brightness: 1.0, contrast: 1.05, saturation: 1.1,
    warmth: 0.1, tint: '90EE90',
  ),
  VideoFilter(
    id: 'lomo', name: 'Lomo',
    brightness: 0.95, contrast: 1.3, saturation: 1.3,
    warmth: 0.15, vignette: 0.5, tint: '8B0000',
  ),
  VideoFilter(
    id: 'candy', name: 'Candy',
    brightness: 1.15, contrast: 1.05, saturation: 1.4,
    warmth: 0.1, tint: 'FF69B4',
  ),
  VideoFilter(
    id: 'neon_tokyo', name: 'Neon Tokyo',
    brightness: 0.85, contrast: 1.4, saturation: 1.5,
    warmth: -0.2, tint: 'FF00FF',
  ),
  VideoFilter(
    id: 'cyberpunk', name: 'Cyberpunk',
    brightness: 0.8, contrast: 1.35, saturation: 1.35,
    warmth: -0.15, tint: '00FF7F',
  ),
  VideoFilter(
    id: 'matrix', name: 'Matrix',
    brightness: 0.85, contrast: 1.2, saturation: 0.6,
    warmth: -0.1, tint: '00FF00',
  ),

  // ── Mood ──
  VideoFilter(
    id: 'happy', name: 'Happy',
    brightness: 1.15, contrast: 1.05, saturation: 1.3,
    warmth: 0.25,
  ),
  VideoFilter(
    id: 'sad', name: 'Sad',
    brightness: 0.85, contrast: 0.9, saturation: 0.6,
    warmth: -0.2, tint: '696969',
  ),
  VideoFilter(
    id: 'scary', name: 'Scary',
    brightness: 0.6, contrast: 1.4, saturation: 0.4,
    warmth: -0.3, vignette: 0.6, tint: '2F0000',
  ),
  VideoFilter(
    id: 'dreamy', name: 'Dreamy',
    brightness: 1.1, contrast: 0.85, saturation: 0.9,
    warmth: 0.2, vignette: 0.15, tint: 'FFB6C1',
  ),
  VideoFilter(
    id: 'ethereal', name: 'Ethereal',
    brightness: 1.2, contrast: 0.8, saturation: 0.75,
    warmth: 0.1, vignette: 0.1, tint: 'F0F8FF',
  ),
  VideoFilter(
    id: 'dark', name: 'Dark',
    brightness: 0.65, contrast: 1.35, saturation: 0.7,
    vignette: 0.5, tint: '1C1C1C',
  ),
  VideoFilter(
    id: 'bright', name: 'Bright',
    brightness: 1.25, contrast: 1.0, saturation: 1.1,
    warmth: 0.15,
  ),
];

/// Find a filter by its id. Returns the 'none' filter if not found.
VideoFilter findFilterById(String id) {
  try {
    return kBuiltInFilters.firstWhere((f) => f.id == id);
  } catch (_) {
    return kBuiltInFilters.first;
  }
}
