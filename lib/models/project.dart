import 'dart:math' as math;
import 'package:deen_studio_01/core/models/speed_curve.dart';
import 'text_layer_style.dart';

/// A 2D point with x,y coordinates (used for color curves).
class Point2D {
  final double x;
  final double y;
  const Point2D(this.x, this.y);
  Point2D copyWith({double? x, double? y}) => Point2D(x ?? this.x, y ?? this.y);
  factory Point2D.fromMap(Map<String, dynamic> m) => Point2D(
    (m['x'] ?? 0).toDouble(), (m['y'] ?? 0).toDouble(),
  );
  Map<String, dynamic> toMap() => {'x': x, 'y': y};
  @override
  String toString() => 'Point2D($x, $y)';
  @override
  bool operator ==(Object other) => other is Point2D && other.x == x && other.y == y;
  @override
  int get hashCode => Object.hash(x, y);
}

/// Professional color grading settings for a layer.
class ColorGrading {
  // RGB Curves: each channel has a list of (input, output) points 0-1
  final List<Point2D> redCurve;
  final List<Point2D> greenCurve;
  final List<Point2D> blueCurve;
  final List<Point2D> masterCurve;

  // HSL
  final double hue;          // -180 to +180
  final double saturation;   // -100 to +100
  final double lightness;    // -100 to +100

  // Color Wheels (shadows, midtones, highlights)
  final String shadowsTint;     // hex color
  final double shadowsAmount;   // 0-100
  final String midtonesTint;
  final double midtonesAmount;
  final String highlightsTint;
  final double highlightsAmount;

  const ColorGrading({
    this.redCurve = const [Point2D(0, 0), Point2D(0.5, 0.5), Point2D(1, 1)],
    this.greenCurve = const [Point2D(0, 0), Point2D(0.5, 0.5), Point2D(1, 1)],
    this.blueCurve = const [Point2D(0, 0), Point2D(0.5, 0.5), Point2D(1, 1)],
    this.masterCurve = const [Point2D(0, 0), Point2D(0.5, 0.5), Point2D(1, 1)],
    this.hue = 0,
    this.saturation = 0,
    this.lightness = 0,
    this.shadowsTint = '#808080',
    this.shadowsAmount = 0,
    this.midtonesTint = '#808080',
    this.midtonesAmount = 0,
    this.highlightsTint = '#808080',
    this.highlightsAmount = 0,
  });

  ColorGrading copyWith({
    List<Point2D>? redCurve, List<Point2D>? greenCurve,
    List<Point2D>? blueCurve, List<Point2D>? masterCurve,
    double? hue, double? saturation, double? lightness,
    String? shadowsTint, double? shadowsAmount,
    String? midtonesTint, double? midtonesAmount,
    String? highlightsTint, double? highlightsAmount,
  }) {
    return ColorGrading(
      redCurve: redCurve ?? this.redCurve,
      greenCurve: greenCurve ?? this.greenCurve,
      blueCurve: blueCurve ?? this.blueCurve,
      masterCurve: masterCurve ?? this.masterCurve,
      hue: hue ?? this.hue,
      saturation: saturation ?? this.saturation,
      lightness: lightness ?? this.lightness,
      shadowsTint: shadowsTint ?? this.shadowsTint,
      shadowsAmount: shadowsAmount ?? this.shadowsAmount,
      midtonesTint: midtonesTint ?? this.midtonesTint,
      midtonesAmount: midtonesAmount ?? this.midtonesAmount,
      highlightsTint: highlightsTint ?? this.highlightsTint,
      highlightsAmount: highlightsAmount ?? this.highlightsAmount,
    );
  }

  factory ColorGrading.fromMap(Map<String, dynamic> m) {
    List<Point2D> parsePoints(dynamic list) {
      if (list is! List) return const [Point2D(0, 0), Point2D(0.5, 0.5), Point2D(1, 1)];
      return list.map((e) => Point2D.fromMap(Map<String, dynamic>.from(e))).toList();
    }
    return ColorGrading(
      redCurve: parsePoints(m['redCurve']),
      greenCurve: parsePoints(m['greenCurve']),
      blueCurve: parsePoints(m['blueCurve']),
      masterCurve: parsePoints(m['masterCurve']),
      hue: (m['hue'] ?? 0).toDouble(),
      saturation: (m['saturation'] ?? 0).toDouble(),
      lightness: (m['lightness'] ?? 0).toDouble(),
      shadowsTint: m['shadowsTint'] ?? '#808080',
      shadowsAmount: (m['shadowsAmount'] ?? 0).toDouble(),
      midtonesTint: m['midtonesTint'] ?? '#808080',
      midtonesAmount: (m['midtonesAmount'] ?? 0).toDouble(),
      highlightsTint: m['highlightsTint'] ?? '#808080',
      highlightsAmount: (m['highlightsAmount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'redCurve': redCurve.map((p) => p.toMap()).toList(),
    'greenCurve': greenCurve.map((p) => p.toMap()).toList(),
    'blueCurve': blueCurve.map((p) => p.toMap()).toList(),
    'masterCurve': masterCurve.map((p) => p.toMap()).toList(),
    'hue': hue, 'saturation': saturation, 'lightness': lightness,
    'shadowsTint': shadowsTint, 'shadowsAmount': shadowsAmount,
    'midtonesTint': midtonesTint, 'midtonesAmount': midtonesAmount,
    'highlightsTint': highlightsTint, 'highlightsAmount': highlightsAmount,
  };

  bool get isDefault =>
      redCurve.length == 3 && redCurve[0] == const Point2D(0, 0) &&
      redCurve[1] == const Point2D(0.5, 0.5) && redCurve[2] == const Point2D(1, 1) &&
      greenCurve.length == 3 && greenCurve[0] == const Point2D(0, 0) &&
      greenCurve[1] == const Point2D(0.5, 0.5) && greenCurve[2] == const Point2D(1, 1) &&
      blueCurve.length == 3 && blueCurve[0] == const Point2D(0, 0) &&
      blueCurve[1] == const Point2D(0.5, 0.5) && blueCurve[2] == const Point2D(1, 1) &&
      masterCurve.length == 3 && masterCurve[0] == const Point2D(0, 0) &&
      masterCurve[1] == const Point2D(0.5, 0.5) && masterCurve[2] == const Point2D(1, 1) &&
      hue == 0 && saturation == 0 && lightness == 0 &&
      shadowsTint == '#808080' && shadowsAmount == 0 &&
      midtonesTint == '#808080' && midtonesAmount == 0 &&
      highlightsTint == '#808080' && highlightsAmount == 0;
}

/// Chroma key (green screen) settings for a layer.
class ChromaKey {
  final bool enabled;
  final String keyColor;     // hex, default green: '#00FF00'
  final double similarity;   // 0.0-1.0, how close colors must match
  final double smoothness;   // 0.0-1.0, edge feathering
  final double spill;        // 0.0-1.0, color spill removal

  const ChromaKey({
    this.enabled = false,
    this.keyColor = '#00FF00',
    this.similarity = 0.4,
    this.smoothness = 0.1,
    this.spill = 0.5,
  });

  ChromaKey copyWith({
    bool? enabled, String? keyColor,
    double? similarity, double? smoothness, double? spill,
  }) {
    return ChromaKey(
      enabled: enabled ?? this.enabled,
      keyColor: keyColor ?? this.keyColor,
      similarity: similarity ?? this.similarity,
      smoothness: smoothness ?? this.smoothness,
      spill: spill ?? this.spill,
    );
  }

  factory ChromaKey.fromMap(Map<String, dynamic> m) => ChromaKey(
    enabled: m['enabled'] ?? false,
    keyColor: m['keyColor'] ?? '#00FF00',
    similarity: (m['similarity'] ?? 0.4).toDouble(),
    smoothness: (m['smoothness'] ?? 0.1).toDouble(),
    spill: (m['spill'] ?? 0.5).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'keyColor': keyColor,
    'similarity': similarity,
    'smoothness': smoothness,
    'spill': spill,
  };
}

/// Mask shape types for layer clipping.
enum MaskType {
  none,
  rectangle,
  circle,
  triangle,
  heart,
  star,
  splitHorizontal,
  splitVertical,
}

/// A mask applied to a layer to control its visible area.
class LayerMask {
  final MaskType type;
  final double value;     // 0.0–1.0, controls mask size/position
  final double feather;   // 0.0–1.0, blur edge softness
  final double rotation;  // degrees

  const LayerMask({
    this.type = MaskType.none,
    this.value = 1.0,
    this.feather = 0.0,
    this.rotation = 0.0,
  });

  LayerMask copyWith({
    MaskType? type,
    double? value,
    double? feather,
    double? rotation,
  }) {
    return LayerMask(
      type: type ?? this.type,
      value: value ?? this.value,
      feather: feather ?? this.feather,
      rotation: rotation ?? this.rotation,
    );
  }

  factory LayerMask.fromMap(Map<String, dynamic> m) => LayerMask(
    type: MaskType.values.byName(m['type'] ?? 'none'),
    value: (m['value'] ?? 1.0).toDouble(),
    feather: (m['feather'] ?? 0.0).toDouble(),
    rotation: (m['rotation'] ?? 0.0).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'value': value,
    'feather': feather,
    'rotation': rotation,
  };
}

// Supported blend modes (mapped to Flutter's BlendMode enum by name).
const kBlendModes = [
  'srcOver',        // normal
  'multiply',
  'screen',
  'overlay',
  'darken',
  'lighten',
  'difference',
  'colorDodge',
  'colorBurn',
  'hardLight',
  'softLight',
];

/// Normalized position (0.0–1.0) and transform for a layer on the canvas.
class ClipTransform {
  final double x;       // 0.5 = center
  final double y;       // 0.5 = center
  final double scaleX;
  final double scaleY;
  final double rotation; // degrees
  final double opacity;  // 0.0–1.0

  const ClipTransform({
    this.x = 0.5,
    this.y = 0.5,
    this.scaleX = 1.0,
    this.scaleY = 1.0,
    this.rotation = 0.0,
    this.opacity = 1.0,
  });

  ClipTransform copyWith({
    double? x, double? y,
    double? scaleX, double? scaleY,
    double? rotation, double? opacity,
  }) {
    return ClipTransform(
      x: x ?? this.x, y: y ?? this.y,
      scaleX: scaleX ?? this.scaleX, scaleY: scaleY ?? this.scaleY,
      rotation: rotation ?? this.rotation, opacity: opacity ?? this.opacity,
    );
  }

  factory ClipTransform.fromMap(Map<String, dynamic> m) => ClipTransform(
    x: (m['x'] ?? 0.5).toDouble(), y: (m['y'] ?? 0.5).toDouble(),
    scaleX: (m['scaleX'] ?? 1.0).toDouble(), scaleY: (m['scaleY'] ?? 1.0).toDouble(),
    rotation: (m['rotation'] ?? 0.0).toDouble(), opacity: (m['opacity'] ?? 1.0).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'x': x, 'y': y, 'scaleX': scaleX, 'scaleY': scaleY,
    'rotation': rotation, 'opacity': opacity,
  };
}

/// Easing functions for keyframe interpolation.
class Easing {
  static double linear(double t) => t;
  static double easeIn(double t) => t * t;
  static double easeOut(double t) => 1 - math.pow(1 - t, 2).toDouble();
  static double easeInOut(double t) => t < 0.5 ? 2 * t * t : 1 - math.pow(-2 * t + 2, 2) / 2;

  static double Function(double) resolver(String name) {
    switch (name) {
      case 'easeIn': return easeIn;
      case 'easeOut': return easeOut;
      case 'easeInOut': return easeInOut;
      default: return linear;
    }
  }
}

/// A keyframe marking a layer's transform at a specific time.
class Keyframe {
  final double time; // seconds
  final ClipTransform transform;
  final String easing; // 'linear', 'easeIn', 'easeOut', 'easeInOut'

  const Keyframe({required this.time, required this.transform, this.easing = 'linear'});

  Keyframe copyWith({double? time, ClipTransform? transform, String? easing}) {
    return Keyframe(
      time: time ?? this.time,
      transform: transform ?? this.transform,
      easing: easing ?? this.easing,
    );
  }

  factory Keyframe.fromMap(Map<String, dynamic> m) => Keyframe(
    time: (m['time'] ?? 0.0).toDouble(),
    transform: ClipTransform.fromMap(m['transform'] ?? {}),
    easing: m['easing'] ?? 'linear',
  );

  Map<String, dynamic> toMap() => {
    'time': time,
    'transform': transform.toMap(),
    'easing': easing,
  };
}

/// A single visual/audio effect applied to a layer.
class ClipEffect {
  final String id;
  final String type; // 'brightness','contrast','saturation','blur','hue','grayscale','vhs','pixelate','sharpen','noise','oldFilm','glitch'
  final bool enabled;
  final Map<String, double> params; // e.g. {'value': 1.2}

  const ClipEffect({
    required this.id,
    required this.type,
    this.enabled = true,
    this.params = const {},
  });

  ClipEffect copyWith({bool? enabled, Map<String, double>? params}) =>
      ClipEffect(id: id, type: type, enabled: enabled ?? this.enabled, params: params ?? this.params);

  factory ClipEffect.fromMap(Map<String, dynamic> m) => ClipEffect(
    id: m['id'] ?? '',
    type: m['type'] ?? 'brightness',
    enabled: m['enabled'] ?? true,
    params: Map<String, double>.from(
      (m['params'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
    ),
  );

  Map<String, dynamic> toMap() => {'id': id, 'type': type, 'enabled': enabled, 'params': params};
}

/// A single angle (camera view) within a multi-cam group.
class MultiCamAngle {
  final String layerId;    // reference to a video layer
  final String label;      // "Cam 1", "Cam 2", etc.
  final double syncOffset; // seconds offset to sync with other angles

  const MultiCamAngle({required this.layerId, required this.label, this.syncOffset = 0.0});

  MultiCamAngle copyWith({String? layerId, String? label, double? syncOffset}) {
    return MultiCamAngle(
      layerId: layerId ?? this.layerId,
      label: label ?? this.label,
      syncOffset: syncOffset ?? this.syncOffset,
    );
  }

  factory MultiCamAngle.fromMap(Map<String, dynamic> m) => MultiCamAngle(
    layerId: m['layerId'] ?? '',
    label: m['label'] ?? 'Cam',
    syncOffset: (m['syncOffset'] ?? 0.0).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'layerId': layerId,
    'label': label,
    'syncOffset': syncOffset,
  };
}

/// A group of video angles that can be switched between during playback.
class MultiCamGroup {
  final String id;
  final String name;
  final List<MultiCamAngle> angles;
  final int activeAngleIndex; // which angle is currently visible

  const MultiCamGroup({
    required this.id,
    required this.name,
    required this.angles,
    this.activeAngleIndex = 0,
  });

  MultiCamGroup copyWith({
    String? id,
    String? name,
    List<MultiCamAngle>? angles,
    int? activeAngleIndex,
  }) {
    return MultiCamGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      angles: angles ?? this.angles,
      activeAngleIndex: activeAngleIndex ?? this.activeAngleIndex,
    );
  }

  factory MultiCamGroup.fromMap(Map<String, dynamic> m) => MultiCamGroup(
    id: m['id'] ?? '',
    name: m['name'] ?? '',
    angles: (m['angles'] as List? ?? [])
        .map((a) => MultiCamAngle.fromMap(Map<String, dynamic>.from(a)))
        .toList(),
    activeAngleIndex: m['activeAngleIndex'] ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'angles': angles.map((a) => a.toMap()).toList(),
    'activeAngleIndex': activeAngleIndex,
  };

  /// Returns the layerId of the currently active angle, or null if no angles.
  String? get activeLayerId {
    if (angles.isEmpty || activeAngleIndex < 0 || activeAngleIndex >= angles.length) return null;
    return angles[activeAngleIndex].layerId;
  }
}

class Project {
  final String id;
  final String userId;
  final String title;
  final int surahId;
  final AyahRange ayahRange;
  final String reciterId;
  final List<Layer> layers;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final String aspectRatio; // "16:9", "9:16", "1:1"
  final String reframeMode; // "none", "auto", "center", "left", "right", "top", "bottom", "custom"
  final String canvasBackgroundId; // id from kCanvasBackgrounds
  final bool duckingEnabled; // audio ducking: lower music when speech is present
  final List<MultiCamGroup> multiCamGroups; // multi-cam angle groups

  Project({
    required this.id,
    required this.userId,
    required this.title,
    required this.surahId,
    required this.ayahRange,
    required this.reciterId,
    required this.layers,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'draft',
    this.aspectRatio = '9:16',
    this.reframeMode = 'none',
    this.canvasBackgroundId = 'black',
    this.duckingEnabled = false,
    this.multiCamGroups = const [],
  });

  Project copyWith({
    String? id, String? userId, String? title, int? surahId,
    AyahRange? ayahRange, String? reciterId, List<Layer>? layers,
    DateTime? createdAt, DateTime? updatedAt, String? status, String? aspectRatio,
    String? reframeMode, String? canvasBackgroundId, bool? duckingEnabled,
    List<MultiCamGroup>? multiCamGroups,
  }) {
    return Project(
      id: id ?? this.id, userId: userId ?? this.userId, title: title ?? this.title,
      surahId: surahId ?? this.surahId, ayahRange: ayahRange ?? this.ayahRange,
      reciterId: reciterId ?? this.reciterId, layers: layers ?? this.layers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      status: status ?? this.status, aspectRatio: aspectRatio ?? this.aspectRatio,
      reframeMode: reframeMode ?? this.reframeMode,
      canvasBackgroundId: canvasBackgroundId ?? this.canvasBackgroundId,
      duckingEnabled: duckingEnabled ?? this.duckingEnabled,
      multiCamGroups: multiCamGroups ?? this.multiCamGroups,
    );
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      title: map['title'] ?? '',
      surahId: map['surah_id'] ?? 0,
      ayahRange: AyahRange.fromMap(map['ayah_range'] ?? {}),
      reciterId: map['reciter_id'] ?? 'ar.alafasy',
      layers: (map['layers'] as List? ?? []).map((l) => Layer.fromMap(l)).toList(),
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : DateTime.now(),
      status: map['status'] ?? 'draft',
      aspectRatio: map['aspect_ratio'] ?? '9:16',
      reframeMode: map['reframe_mode'] ?? 'none',
      canvasBackgroundId: map['canvas_background_id'] ?? 'black',
      duckingEnabled: map['ducking_enabled'] ?? false,
      multiCamGroups: (map['multi_cam_groups'] as List? ?? [])
          .map((g) => MultiCamGroup.fromMap(Map<String, dynamic>.from(g)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId, 'title': title, 'surah_id': surahId,
      'ayah_range': ayahRange.toMap(), 'reciter_id': reciterId,
      'layers': layers.map((l) => l.toMap()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': status, 'aspect_ratio': aspectRatio,
      'reframe_mode': reframeMode,
      'canvas_background_id': canvasBackgroundId,
      'ducking_enabled': duckingEnabled,
      'multi_cam_groups': multiCamGroups.map((g) => g.toMap()).toList(),
    };
  }

  double get totalDuration {
    if (layers.isEmpty) return 0;
    return layers.map((l) => l.startTime + l.duration).reduce((a, b) => a > b ? a : b);
  }
}

class AyahRange {
  final int start;
  final int end;
  AyahRange({required this.start, required this.end});
  factory AyahRange.fromMap(Map<String, dynamic> map) =>
      AyahRange(start: map['start'] ?? 1, end: map['end'] ?? 10);
  Map<String, dynamic> toMap() => {'start': start, 'end': end};
}

class Layer {
  final String id;
  final String type; // 'text','arabic','translation','audio','video','image'
  final String content;
  final double startTime;
  final double duration;
  final Map<String, dynamic> style;
  final ClipTransform transform;
  final List<ClipEffect> effects;
  final List<Keyframe> keyframes;
  // Text-specific
  final String? fontFamily;
  final double? fontSize;
  final String? textColor;
  final String? textAnimation; // 'fade','typewriter','karaoke'
  // In/out points for trimming
  final double? inPoint;
  final double? outPoint;
  final TextLayerStyle? textStyle;
  final LayerMask mask;
  final String blendMode; // blend mode name (maps to BlendMode.values.byName)
  final String filterId;  // video filter preset id (e.g. 'cinematic', 'vintage')
  final String voiceEffectId; // voice effect preset id (e.g. 'chipmunk', 'deep')
  final SpeedCurve? speedCurve; // variable speed within clip (null = constant speed from style['speed'])
  final ColorGrading colorGrading; // advanced color grading (curves + HSL + wheels)
  final ChromaKey chromaKey; // chroma key / green screen settings
  final double noiseGateThreshold; // noise gate for audio layers (0.0 = off, 0.0-1.0)
  final bool beatSync; // snap clip start to nearest audio beat
  final bool stabilized; // video stabilization applied
  /// Word-by-word timing data for Quran recitation sync.
  /// Each entry: {'word': String, 'start': double, 'end': double}
  /// Enables karaoke-style highlighting that follows the recitation.
  final List<Map<String, dynamic>> wordTimings;

  Layer({
    required this.id,
    required this.type,
    required this.content,
    required this.startTime,
    required this.duration,
    required this.style,
    ClipTransform? transform,
    List<ClipEffect>? effects,
    List<Keyframe>? keyframes,
    this.fontFamily,
    this.fontSize,
    this.textColor,
    this.textAnimation,
    this.inPoint,
    this.outPoint,
    this.textStyle,
    this.mask = const LayerMask(),
    this.blendMode = 'srcOver',
    this.filterId = 'none',
    this.voiceEffectId = 'none',
    this.speedCurve,
    this.colorGrading = const ColorGrading(),
    this.chromaKey = const ChromaKey(),
    this.noiseGateThreshold = 0.0,
    this.beatSync = false,
    this.stabilized = false,
    this.wordTimings = const [],
  })  : transform = transform ?? const ClipTransform(),
        effects = effects ?? [],
        keyframes = keyframes ?? [];

  Layer copyWith({
    String? id, String? type, String? content,
    double? startTime, double? duration, Map<String, dynamic>? style,
    ClipTransform? transform, List<ClipEffect>? effects, List<Keyframe>? keyframes,
    String? fontFamily, double? fontSize, String? textColor, String? textAnimation,
    double? inPoint, double? outPoint,
    TextLayerStyle? textStyle,
    LayerMask? mask,
    String? blendMode,
    String? filterId,
    String? voiceEffectId,
    SpeedCurve? speedCurve,
    ColorGrading? colorGrading,
    ChromaKey? chromaKey,
    double? noiseGateThreshold,
    bool? beatSync,
    bool? stabilized,
    List<Map<String, dynamic>>? wordTimings,
  }) {
    return Layer(
      id: id ?? this.id, type: type ?? this.type, content: content ?? this.content,
      startTime: startTime ?? this.startTime, duration: duration ?? this.duration,
      style: style ?? this.style, transform: transform ?? this.transform,
      effects: effects ?? this.effects, keyframes: keyframes ?? this.keyframes,
      fontFamily: fontFamily ?? this.fontFamily, fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor, textAnimation: textAnimation ?? this.textAnimation,
      inPoint: inPoint ?? this.inPoint, outPoint: outPoint ?? this.outPoint,
      textStyle: textStyle ?? this.textStyle,
      mask: mask ?? this.mask,
      blendMode: blendMode ?? this.blendMode,
      filterId: filterId ?? this.filterId,
      voiceEffectId: voiceEffectId ?? this.voiceEffectId,
      speedCurve: speedCurve ?? this.speedCurve,
      colorGrading: colorGrading ?? this.colorGrading,
      chromaKey: chromaKey ?? this.chromaKey,
      noiseGateThreshold: noiseGateThreshold ?? this.noiseGateThreshold,
      beatSync: beatSync ?? this.beatSync,
      stabilized: stabilized ?? this.stabilized,
      wordTimings: wordTimings ?? this.wordTimings,
    );
  }

  factory Layer.fromMap(Map<String, dynamic> map) {
    final style = Map<String, dynamic>.from(map['style'] ?? {});
    // Backward-compat: old records stored type='text' with style['type']='arabic'/'translation'
    String type = map['type'] ?? 'text';
    if (type == 'text' && style.containsKey('type')) {
      type = style['type'] as String? ?? type;
    }
    return Layer(
      id: map['id'] ?? '',
      type: type,
      content: map['content'] ?? '',
      startTime: (map['startTime'] ?? 0).toDouble(),
      duration: (map['duration'] ?? 0).toDouble(),
      style: style,
      transform: map['transform'] != null ? ClipTransform.fromMap(map['transform']) : null,
      effects: (map['effects'] as List? ?? []).map((e) => ClipEffect.fromMap(e)).toList(),
      keyframes: (map['keyframes'] as List? ?? []).map((k) => Keyframe.fromMap(k)).toList(),
      fontFamily: map['fontFamily'],
      fontSize: map['fontSize']?.toDouble(),
      textColor: map['textColor'],
      textAnimation: map['textAnimation'],
      inPoint: map['inPoint']?.toDouble(),
      outPoint: map['outPoint']?.toDouble(),
      textStyle: map['textStyle'] != null ? TextLayerStyle.fromMap(map['textStyle']) : null,
      mask: map['mask'] != null ? LayerMask.fromMap(map['mask']) : const LayerMask(),
      blendMode: map['blendMode'] ?? 'srcOver',
      filterId: map['filterId'] ?? 'none',
      voiceEffectId: map['voiceEffectId'] ?? 'none',
      speedCurve: map['speedCurve'] != null ? SpeedCurve.fromMap(Map<String, dynamic>.from(map['speedCurve'])) : null,
      colorGrading: map['colorGrading'] != null ? ColorGrading.fromMap(Map<String, dynamic>.from(map['colorGrading'])) : const ColorGrading(),
      chromaKey: map['chromaKey'] != null ? ChromaKey.fromMap(Map<String, dynamic>.from(map['chromaKey'])) : const ChromaKey(),
      noiseGateThreshold: (map['noiseGateThreshold'] ?? 0.0).toDouble(),
      beatSync: map['beatSync'] ?? false,
      stabilized: map['stabilized'] ?? false,
      wordTimings: (map['wordTimings'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id, 'type': type, 'content': content,
      'startTime': startTime, 'duration': duration, 'style': style,
      'transform': transform.toMap(),
      'effects': effects.map((e) => e.toMap()).toList(),
      'keyframes': keyframes.map((k) => k.toMap()).toList(),
      if (fontFamily != null) 'fontFamily': fontFamily,
      if (fontSize != null) 'fontSize': fontSize,
      if (textColor != null) 'textColor': textColor,
      if (textAnimation != null) 'textAnimation': textAnimation,
      if (inPoint != null) 'inPoint': inPoint,
      if (outPoint != null) 'outPoint': outPoint,
      if (textStyle != null) 'textStyle': textStyle!.toMap(),
      'mask': mask.toMap(),
      'blendMode': blendMode,
      'filterId': filterId,
      'voiceEffectId': voiceEffectId,
      if (speedCurve != null) 'speedCurve': speedCurve!.toMap(),
      'colorGrading': colorGrading.toMap(),
      'chromaKey': chromaKey.toMap(),
      'noiseGateThreshold': noiseGateThreshold,
      'beatSync': beatSync,
      'stabilized': stabilized,
      'wordTimings': wordTimings,
    };
  }

  bool activeAt(double time) => time >= startTime && time < startTime + effectiveDuration;
  double get effectiveDuration => outPoint != null ? outPoint! - (inPoint ?? 0) : duration;
  bool get isTextType => type == 'text' || type == 'arabic' || type == 'translation' || type == 'phonetic';
  bool get isAudio => type == 'audio';
  bool get isVisual => type == 'image' || type == 'video' || type == 'sticker';
  bool get isSticker => type == 'sticker';
}
