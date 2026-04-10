/// A single point on a speed curve, defining the playback speed at a relative
/// position within a clip.
class SpeedPoint {
  /// Relative position in the clip (0.0 = start, 1.0 = end)
  final double position;

  /// Playback speed multiplier (0.1x to 10.0x)
  final double speed;

  const SpeedPoint({required this.position, required this.speed});

  SpeedPoint copyWith({double? position, double? speed}) {
    return SpeedPoint(
      position: position ?? this.position,
      speed: speed ?? this.speed,
    );
  }

  factory SpeedPoint.fromMap(Map<String, dynamic> m) => SpeedPoint(
        position: (m['position'] ?? 0.0).toDouble(),
        speed: (m['speed'] ?? 1.0).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'position': position,
        'speed': speed,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpeedPoint &&
          runtimeType == other.runtimeType &&
          position == other.position &&
          speed == other.speed;

  @override
  int get hashCode => position.hashCode ^ speed.hashCode;
}

/// A curve defining variable playback speed across a clip's duration.
///
/// Speed is interpolated between [points] based on the current playback
/// position. When no curve is set, constant speed from style['speed'] is used.
class SpeedCurve {
  final List<SpeedPoint> points;

  SpeedCurve({this.points = const []});

  /// Get the speed at a given relative position (0.0-1.0) in the clip.
  ///
  /// Returns:
  /// - 1.0 if there are no points (default constant speed)
  /// - The exact speed if position matches a point
  /// - Linearly interpolated speed between the two nearest points otherwise
  double getSpeedAtPosition(double position) {
    if (points.isEmpty) return 1.0;

    // Clamp position to valid range
    position = position.clamp(0.0, 1.0);

    // Check if position matches a point exactly
    for (final point in points) {
      if ((point.position - position).abs() < 0.0001) {
        return point.speed;
      }
    }

    // Find the two surrounding points
    SpeedPoint? before;
    SpeedPoint? after;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].position <= position && points[i + 1].position > position) {
        before = points[i];
        after = points[i + 1];
        break;
      }
    }

    // Before the first point: use the first point's speed
    if (position < points.first.position) {
      return points.first.speed;
    }

    // After the last point: use the last point's speed
    if (position > points.last.position) {
      return points.last.speed;
    }

    // Linear interpolation between surrounding points
    if (before != null && after != null) {
      final t = (position - before.position) / (after.position - before.position);
      return before.speed + (after.speed - before.speed) * t;
    }

    // Fallback (should not reach here with valid data)
    return 1.0;
  }

  SpeedCurve copyWith({List<SpeedPoint>? points}) {
    return SpeedCurve(points: points ?? this.points);
  }

  factory SpeedCurve.fromMap(Map<String, dynamic> m) {
    final pointsData = m['points'] as List?;
    return SpeedCurve(
      points: pointsData != null
          ? pointsData
              .map((p) => SpeedPoint.fromMap(Map<String, dynamic>.from(p)))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toMap() => {
        'points': points.map((p) => p.toMap()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpeedCurve &&
          runtimeType == other.runtimeType &&
          _pointsEqual(points, other.points);

  static bool _pointsEqual(List<SpeedPoint> a, List<SpeedPoint> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    int result = 17;
    for (final point in points) {
      result = 31 * result + point.hashCode;
    }
    return result;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Presets
  // ──────────────────────────────────────────────────────────────────────────

  /// Fast at start and end, normal in the middle — classic montage feel.
  static final curveMontage = SpeedCurve(points: const [
    SpeedPoint(position: 0.0, speed: 3.0),
    SpeedPoint(position: 0.1, speed: 1.0),
    SpeedPoint(position: 0.9, speed: 1.0),
    SpeedPoint(position: 1.0, speed: 3.0),
  ]);

  /// Slow in the middle, normal at start and end — dramatic slow motion.
  static final curveSlowMo = SpeedCurve(points: const [
    SpeedPoint(position: 0.0, speed: 1.0),
    SpeedPoint(position: 0.3, speed: 0.25),
    SpeedPoint(position: 0.7, speed: 0.25),
    SpeedPoint(position: 1.0, speed: 1.0),
  ]);

  /// Gradual acceleration from slow to fast.
  static final curveRampUp = SpeedCurve(points: const [
    SpeedPoint(position: 0.0, speed: 0.25),
    SpeedPoint(position: 1.0, speed: 3.0),
  ]);
}
