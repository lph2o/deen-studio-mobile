
/// Quranic Text Animation Presets — 40+ unique animations inspired by
library;
/// Islamic art, nature, and the sacred beauty of the Quran.
///
/// Categories:
/// - **Revelation**: Divine light, golden glow, celestial effects
/// - **Nature**: Waves, wind, rain, stars, flowers
/// - **Calligraphy**: Writing strokes, ink flow, brush effects
/// - **Geometry**: Islamic patterns, mosaics, spirals
/// - **Spiritual**: Prayer, incense, minaret, crescent
/// - **Cosmic**: Constellations, galaxies, aurora

enum QuranAnimationCategory {
  revelation,
  nature,
  calligraphy,
  geometry,
  spiritual,
  cosmic,
}

class QuranTextAnimation {
  final String id;
  final String name;
  final String icon;
  final String description;
  final QuranAnimationCategory category;
  final double defaultDuration; // seconds
  final bool rtlSupport;

  const QuranTextAnimation({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.category,
    this.defaultDuration = 2.0,
    this.rtlSupport = true,
  });
}

/// 40+ Quran-specific text animations
const kQuranTextAnimations = [
  // ═══════════════════════════════════════════
  // REVELATION — Divine Light Effects
  // ═══════════════════════════════════════════

  /// Text appears letter by letter with a golden glow that fades
  QuranTextAnimation(
    id: 'divine_revelation',
    name: 'Révélation Divine',
    icon: '✨',
    description: 'Chaque lettre apparaît avec une lueur dorée qui s\'estompe',
    category: QuranAnimationCategory.revelation,
    defaultDuration: 3.0,
  ),

  /// Heavenly light beam reveals text from above
  QuranTextAnimation(
    id: 'celestial_light',
    name: 'Lumière Céleste',
    icon: '🌟',
    description: 'Un rayon de lumière révèle le texte du haut vers le bas',
    category: QuranAnimationCategory.revelation,
    defaultDuration: 2.5,
  ),

  /// Text shimmers with golden particles
  QuranTextAnimation(
    id: 'golden_particles',
    name: 'Particules d\'Or',
    icon: '⭐',
    description: 'Le texte brille avec des particules dorées scintillantes',
    category: QuranAnimationCategory.revelation,
    defaultDuration: 3.0,
  ),

  /// Divine light radiates outward from the text
  QuranTextAnimation(
    id: 'divine_radiance',
    name: 'Rayonnement Divin',
    icon: '☀️',
    description: 'Des rayons lumineux émanent du texte',
    category: QuranAnimationCategory.revelation,
    defaultDuration: 2.0,
  ),

  /// Text glows with an ethereal inner light
  QuranTextAnimation(
    id: 'ethereal_glow',
    name: 'Lueur Éthérée',
    icon: '💫',
    description: 'Le texte brille d\'une lumière intérieure surnaturelle',
    category: QuranAnimationCategory.revelation,
    defaultDuration: 2.5,
  ),

  // ═══════════════════════════════════════════
  // NATURE — Natural World Effects
  // ═══════════════════════════════════════════

  /// Text ripples like water
  QuranTextAnimation(
    id: 'sacred_ripple',
    name: 'Ondulation Sacrée',
    icon: '🌊',
    description: 'Le texte ondule comme l\'eau d\'une rivière sacrée',
    category: QuranAnimationCategory.nature,
    defaultDuration: 3.0,
  ),

  /// Gentle wave motion across the text
  QuranTextAnimation(
    id: 'mercy_wave',
    name: 'Vague de Miséricorde',
    icon: '🌊',
    description: 'Une vague douce traverse le texte',
    category: QuranAnimationCategory.nature,
    defaultDuration: 2.5,
  ),

  /// Rain drops fall and reveal text
  QuranTextAnimation(
    id: 'blessed_rain',
    name: 'Pluie Bénie',
    icon: '🌧️',
    description: 'Des gouttes de pluie révèlent le texte',
    category: QuranAnimationCategory.nature,
    defaultDuration: 3.0,
  ),

  /// Falling leaves scatter to reveal text
  QuranTextAnimation(
    id: 'autumn_leaves',
    name: 'Feuilles d\'Automne',
    icon: '🍂',
    description: 'Des feuilles tombent et révèlent le texte',
    category: QuranAnimationCategory.nature,
    defaultDuration: 3.5,
  ),

  /// Flower petals bloom around text
  QuranTextAnimation(
    id: 'flower_bloom',
    name: 'Floraison',
    icon: '🌸',
    description: 'Des pétales de fleur éclosent autour du texte',
    category: QuranAnimationCategory.nature,
    defaultDuration: 2.5,
  ),

  /// Gentle wind blows text into view
  QuranTextAnimation(
    id: 'gentle_wind',
    name: 'Vent Doux',
    icon: '🍃',
    description: 'Un vent doux apporte le texte',
    category: QuranAnimationCategory.nature,
    defaultDuration: 2.0,
  ),

  /// Water droplets form the text
  QuranTextAnimation(
    id: 'water_drops',
    name: 'Gouttes d\'Eau',
    icon: '💧',
    description: 'Des gouttes d\'eau forment le texte',
    category: QuranAnimationCategory.nature,
    defaultDuration: 3.0,
  ),

  /// Rainbow sweeps across text
  QuranTextAnimation(
    id: 'rainbow',
    name: 'Arc-en-Ciel',
    icon: '🌈',
    description: 'Un arc-en-ciel traverse le texte',
    category: QuranAnimationCategory.nature,
    defaultDuration: 2.5,
  ),

  /// River flow effect on text
  QuranTextAnimation(
    id: 'river_flow',
    name: 'Rivière',
    icon: '🏞️',
    description: 'Le texte coule comme une rivière',
    category: QuranAnimationCategory.nature,
    defaultDuration: 2.0,
  ),

  // ═══════════════════════════════════════════
  // CALLIGRAPHY — Writing Effects
  // ═══════════════════════════════════════════

  /// Strokes appear as if being written by an invisible hand
  QuranTextAnimation(
    id: 'living_calligraphy',
    name: 'Calligraphie Vivante',
    icon: '🖊️',
    description: 'Le texte s\'écrit comme par magie',
    category: QuranAnimationCategory.calligraphy,
    defaultDuration: 4.0,
    rtlSupport: true,
  ),

  /// Ink flows to form the text
  QuranTextAnimation(
    id: 'ink_flow',
    name: 'Flux d\'Encre',
    icon: '🖋️',
    description: 'L\'encre coule pour former le texte',
    category: QuranAnimationCategory.calligraphy,
    defaultDuration: 3.0,
  ),

  /// Brush strokes paint the text
  QuranTextAnimation(
    id: 'brush_strokes',
    name: 'Coups de Pinceau',
    icon: '🖌️',
    description: 'Des coups de pinceau peignent le texte',
    category: QuranAnimationCategory.calligraphy,
    defaultDuration: 3.5,
  ),

  /// Quill pen writes the text
  QuranTextAnimation(
    id: 'quill_writing',
    name: 'Plume d\'Oie',
    icon: '🪶',
    description: 'Une plume écrit le texte avec élégance',
    category: QuranAnimationCategory.calligraphy,
    defaultDuration: 4.0,
  ),

  // ═══════════════════════════════════════════
  // GEOMETRY — Islamic Pattern Effects
  // ═══════════════════════════════════════════

  /// Mosaic tiles assemble to form text
  QuranTextAnimation(
    id: 'mosaic_assembly',
    name: 'Mosaïque',
    icon: '🔷',
    description: 'Des tuiles de mosaïque s\'assemblent pour former le texte',
    category: QuranAnimationCategory.geometry,
    defaultDuration: 3.0,
  ),

  /// Spiral inward reveals text
  QuranTextAnimation(
    id: 'golden_spiral',
    name: 'Spirale Dorée',
    icon: '🌀',
    description: 'Une spirale dorée révèle le texte',
    category: QuranAnimationCategory.geometry,
    defaultDuration: 2.5,
  ),

  /// Geometric patterns form the text
  QuranTextAnimation(
    id: 'zellige',
    name: 'Zellige',
    icon: '💎',
    description: 'Un motif géométrique zellige révèle le texte',
    category: QuranAnimationCategory.geometry,
    defaultDuration: 3.0,
  ),

  /// Persian carpet weave reveals text
  QuranTextAnimation(
    id: 'persian_carpet',
    name: 'Tapis Persan',
    icon: '🟫',
    description: 'Un tissage de tapis persan révèle le texte',
    category: QuranAnimationCategory.geometry,
    defaultDuration: 3.5,
  ),

  /// Fractal growth pattern reveals text
  QuranTextAnimation(
    id: 'fractal_growth',
    name: 'Croissance Fractale',
    icon: '🔬',
    description: 'Une croissance fractale révèle le texte',
    category: QuranAnimationCategory.geometry,
    defaultDuration: 2.5,
  ),

  /// Honeycomb pattern reveals text
  QuranTextAnimation(
    id: 'honeycomb',
    name: 'Nid d\'Abeille',
    icon: '🐝',
    description: 'Un motif de nid d\'abeille révèle le texte',
    category: QuranAnimationCategory.geometry,
    defaultDuration: 3.0,
  ),

  // ═══════════════════════════════════════════
  // SPIRITUAL — Islamic Sacred Effects
  // ═══════════════════════════════════════════

  /// Crescent moon rises and reveals text
  QuranTextAnimation(
    id: 'crescent_moon',
    name: 'Croissant de Lune',
    icon: '🌙',
    description: 'Un croissant de lune se lève et révèle le texte',
    category: QuranAnimationCategory.spiritual,
    defaultDuration: 3.0,
  ),

  /// Minaret rises from below
  QuranTextAnimation(
    id: 'minaret_rise',
    name: 'Minaret',
    icon: '🕌',
    description: 'Un minaret s\'élève et révèle le texte',
    category: QuranAnimationCategory.spiritual,
    defaultDuration: 3.5,
  ),

  /// Prayer beads count and reveal words
  QuranTextAnimation(
    id: 'prayer_beads',
    name: 'Chapelet',
    icon: '📿',
    description: 'Des grains de chapelet révèlent le texte un par un',
    category: QuranAnimationCategory.spiritual,
    defaultDuration: 4.0,
  ),

  /// Incense smoke rises and reveals text
  QuranTextAnimation(
    id: 'incense_smoke',
    name: 'Fumée d\'Encens',
    icon: '🌫️',
    description: 'De la fumée d\'encens s\'élève et révèle le texte',
    category: QuranAnimationCategory.spiritual,
    defaultDuration: 3.0,
  ),

  /// Sacred fire effect
  QuranTextAnimation(
    id: 'sacred_fire',
    name: 'Flamme Sacrée',
    icon: '🔥',
    description: 'Une flamme sacrée consume pour révéler le texte',
    category: QuranAnimationCategory.spiritual,
    defaultDuration: 2.5,
  ),

  /// Night of Power — dark to light transition
  QuranTextAnimation(
    id: 'night_of_power',
    name: 'Nuit du Destin',
    icon: '🌑',
    description: 'De l\'obscurité vers la lumière, comme Laylat al-Qadr',
    category: QuranAnimationCategory.spiritual,
    defaultDuration: 3.0,
  ),

  /// Flying carpet scroll effect
  QuranTextAnimation(
    id: 'flying_carpet',
    name: 'Tapis Volant',
    icon: '🧶',
    description: 'Un parchemin se déroule comme un tapis volant',
    category: QuranAnimationCategory.spiritual,
    defaultDuration: 2.5,
  ),

  // ═══════════════════════════════════════════
  // COSMIC — Universe & Space Effects
  // ═══════════════════════════════════════════

  /// Stars connect to form text (constellation)
  QuranTextAnimation(
    id: 'constellation',
    name: 'Constellation',
    icon: '⭐',
    description: 'Des étoiles se connectent pour former le texte',
    category: QuranAnimationCategory.cosmic,
    defaultDuration: 3.5,
  ),

  /// Star dust particles form text
  QuranTextAnimation(
    id: 'stardust',
    name: 'Poussière d\'Étoiles',
    icon: '🌠',
    description: 'De la poussière d\'étoiles forme le texte',
    category: QuranAnimationCategory.cosmic,
    defaultDuration: 3.0,
  ),

  /// Northern lights shimmer over text
  QuranTextAnimation(
    id: 'aurora',
    name: 'Aurore Boréale',
    icon: '🌌',
    description: 'Une aurore boréale scintille sur le texte',
    category: QuranAnimationCategory.cosmic,
    defaultDuration: 3.0,
  ),

  /// Galaxy spiral reveals text
  QuranTextAnimation(
    id: 'galaxy',
    name: 'Galaxie',
    icon: '🌀',
    description: 'Une spirale galactique révèle le texte',
    category: QuranAnimationCategory.cosmic,
    defaultDuration: 3.5,
  ),

  /// Diamond sparkle on text
  QuranTextAnimation(
    id: 'diamond_sparkle',
    name: 'Éclat de Diamant',
    icon: '💎',
    description: 'Le texte scintille comme un diamant',
    category: QuranAnimationCategory.cosmic,
    defaultDuration: 2.0,
  ),

  /// Light butterflies flutter around text
  QuranTextAnimation(
    id: 'light_butterflies',
    name: 'Papillons de Lumière',
    icon: '🦋',
    description: 'Des papillons lumineux voltigent autour du texte',
    category: QuranAnimationCategory.cosmic,
    defaultDuration: 3.0,
  ),

  /// Sunset gradient sweeps text
  QuranTextAnimation(
    id: 'sunset',
    name: 'Soleil Couchant',
    icon: '🌅',
    description: 'Un coucher de soleil révèle le texte',
    category: QuranAnimationCategory.cosmic,
    defaultDuration: 2.5,
  ),

  /// Lightning flash reveals text
  QuranTextAnimation(
    id: 'lightning',
    name: 'Éclairs',
    icon: '⚡',
    description: 'Des éclairs révèlent le texte par flashs',
    category: QuranAnimationCategory.cosmic,
    defaultDuration: 2.0,
  ),

  /// Earth shake effect
  QuranTextAnimation(
    id: 'earth_shake',
    name: 'Tremblement',
    icon: '🌍',
    description: 'La terre tremble et le texte émerge',
    category: QuranAnimationCategory.cosmic,
    defaultDuration: 2.5,
  ),

  /// Compass needle points to reveal text
  QuranTextAnimation(
    id: 'compass',
    name: 'Boussole',
    icon: '🧭',
    description: 'Une boussole pointe vers le texte qui se révèle',
    category: QuranAnimationCategory.cosmic,
    defaultDuration: 2.0,
  ),
];

/// Get animations by category
List<QuranTextAnimation> getQuranAnimationsByCategory(QuranAnimationCategory category) {
  return kQuranTextAnimations.where((a) => a.category == category).toList();
}

/// Get animation by ID
QuranTextAnimation? getQuranAnimationById(String id) {
  try {
    return kQuranTextAnimations.firstWhere((a) => a.id == id);
  } catch (_) {
    return null;
  }
}

/// Category display info
const Map<QuranAnimationCategory, ({String label, String icon})> kCategoryInfo = {
  QuranAnimationCategory.revelation: (label: 'Révélation', icon: '✨'),
  QuranAnimationCategory.nature: (label: 'Nature', icon: '🌿'),
  QuranAnimationCategory.calligraphy: (label: 'Calligraphie', icon: '🖊️'),
  QuranAnimationCategory.geometry: (label: 'Géométrie', icon: '🔷'),
  QuranAnimationCategory.spiritual: (label: 'Spirituel', icon: '🕌'),
  QuranAnimationCategory.cosmic: (label: 'Cosmique', icon: '🌌'),
};
