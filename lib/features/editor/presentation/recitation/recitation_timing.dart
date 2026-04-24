import '../../../../models/project.dart';

/// Utilities for robust ayah-to-ayah audio transitions.
class RecitationTiming {
  static const int _kMaxSeekMs = 2147483647;

  /// Boundary window grows with playback speed to keep transitions reliable
  /// when verses switch quickly.
  static double boundaryWindowSeconds(double playbackSpeed) {
    final speed = playbackSpeed.clamp(0.25, 4.0);
    return (0.12 * speed).clamp(0.08, 0.30);
  }

  /// Returns true when the current playhead is near any audio layer boundary
  /// (start or end). In that zone we should bypass coarse throttling.
  static bool shouldPrioritizeSync({
    required List<Layer> audioLayers,
    required double currentTime,
    required double playbackSpeed,
  }) {
    if (audioLayers.isEmpty) return false;
    final w = boundaryWindowSeconds(playbackSpeed);
    for (final layer in audioLayers) {
      final start = layer.startTime;
      final end = layer.startTime + layer.effectiveDuration;
      if ((currentTime - start).abs() <= w || (currentTime - end).abs() <= w) {
        return true;
      }
    }
    return false;
  }

  /// During active playback, when we switch right after a verse boundary,
  /// starting from zero prevents skipping the first spoken word.
  static Duration computeSwitchSeekPosition({
    required bool isPlaying,
    required double currentTime,
    required double layerStartTime,
    required double playbackSpeed,
  }) {
    final offsetMs = ((currentTime - layerStartTime) * 1000).round();
    final boundaryMs = (boundaryWindowSeconds(playbackSpeed) * 1000).round();
    final nearLayerStart = offsetMs >= 0 && offsetMs <= boundaryMs;

    if (isPlaying && nearLayerStart) {
      return Duration.zero;
    }

    return Duration(milliseconds: offsetMs.clamp(0, _kMaxSeekMs));
  }

  /// Computes a text clock anchored to the real audio position when possible.
  /// Falls back to timeline time if audio is not ready.
  static double computeEffectiveRecitationTime({
    required double fallbackTimelineTime,
    required bool isAudioReady,
    required Duration audioPosition,
    required double audioLayerStartTime,
    required double audioLayerDuration,
  }) {
    if (!isAudioReady) return fallbackTimelineTime;

    final posSec = audioPosition.inMicroseconds / 1000000.0;
    final start = audioLayerStartTime;
    final end = audioLayerStartTime + audioLayerDuration;
    final effective = start + posSec;
    return effective.clamp(start, end);
  }

  /// Returns true when drift correction should be delayed right after a verse switch
  /// to avoid clipping the first spoken word.
  static bool shouldDelayDriftCorrectionAfterSwitch({
    required DateTime now,
    required DateTime? lastSwitchAt,
    required double currentTime,
    required double layerStartTime,
    required double playbackSpeed,
  }) {
    if (lastSwitchAt == null) return false;
    final sinceSwitchMs = now.difference(lastSwitchAt).inMilliseconds;
    if (sinceSwitchMs > 500) return false;

    final offsetMs = ((currentTime - layerStartTime) * 1000).round();
    final boundaryMs = (boundaryWindowSeconds(playbackSpeed) * 1000).round() + 80;
    return offsetMs >= 0 && offsetMs <= boundaryMs;
  }
}
