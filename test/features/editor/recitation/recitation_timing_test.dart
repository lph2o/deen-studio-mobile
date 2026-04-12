import 'package:flutter_test/flutter_test.dart';
import 'package:deen_studio_01/features/editor/presentation/recitation/recitation_timing.dart';
import 'package:deen_studio_01/models/project.dart';

Layer _audioLayer({
  required String id,
  required double start,
  required double duration,
}) {
  return Layer(
    id: id,
    type: 'audio',
    content: '/tmp/$id.mp3',
    startTime: start,
    duration: duration,
    style: const {},
  );
}

void main() {
  group('RecitationTiming.computeSwitchSeekPosition', () {
    test('starts at zero near verse boundary to preserve first word', () {
      final seek = RecitationTiming.computeSwitchSeekPosition(
        isPlaying: true,
        currentTime: 10.09,
        layerStartTime: 10.0,
        playbackSpeed: 1.0,
      );
      expect(seek, Duration.zero);
    });

    test('keeps offset when not near boundary (scrub or late switch)', () {
      final seek = RecitationTiming.computeSwitchSeekPosition(
        isPlaying: true,
        currentTime: 11.2,
        layerStartTime: 10.0,
        playbackSpeed: 1.0,
      );
      expect(seek.inMilliseconds, 1200);
    });

    test('speed-adaptive boundary window for fast recitation', () {
      final slow = RecitationTiming.computeSwitchSeekPosition(
        isPlaying: true,
        currentTime: 5.15,
        layerStartTime: 5.0,
        playbackSpeed: 1.0,
      );
      final fast = RecitationTiming.computeSwitchSeekPosition(
        isPlaying: true,
        currentTime: 5.15,
        layerStartTime: 5.0,
        playbackSpeed: 1.5,
      );

      expect(slow.inMilliseconds, 150);
      expect(fast, Duration.zero);
    });
  });

  group('RecitationTiming.shouldPrioritizeSync', () {
    test('prioritizes sync around consecutive verse boundaries', () {
      final layers = [
        _audioLayer(id: 'a1', start: 0.0, duration: 2.8),
        _audioLayer(id: 'a2', start: 2.8, duration: 3.1),
        _audioLayer(id: 'a3', start: 5.9, duration: 4.0),
      ];

      expect(
        RecitationTiming.shouldPrioritizeSync(
          audioLayers: layers,
          currentTime: 2.79,
          playbackSpeed: 1.0,
        ),
        isTrue,
      );
      expect(
        RecitationTiming.shouldPrioritizeSync(
          audioLayers: layers,
          currentTime: 4.2,
          playbackSpeed: 1.0,
        ),
        isFalse,
      );
    });

    test('works with different reciter timing profiles', () {
      final reciters = <String, List<double>>{
        'ar.alafasy': [3.2, 3.7, 2.9],
        'ar.husary': [4.1, 4.6, 3.8],
        'ar.minshawi': [5.0, 5.4, 4.7],
      };

      for (final entry in reciters.entries) {
        final durations = entry.value;
        double start = 0.0;
        final layers = <Layer>[];
        for (int i = 0; i < durations.length; i++) {
          layers.add(_audioLayer(id: '${entry.key}_$i', start: start, duration: durations[i]));
          start += durations[i];
        }
        final secondBoundary = durations[0];
        final shouldPrioritize = RecitationTiming.shouldPrioritizeSync(
          audioLayers: layers,
          currentTime: secondBoundary + 0.05,
          playbackSpeed: 1.0,
        );
        expect(shouldPrioritize, isTrue, reason: 'Boundary missed for ${entry.key}');
      }
    });

    test('prioritization window scales with playback speed', () {
      final layers = [
        _audioLayer(id: 'a1', start: 0.0, duration: 3.0),
        _audioLayer(id: 'a2', start: 3.0, duration: 3.0),
      ];

      final at = 3.16;
      final normal = RecitationTiming.shouldPrioritizeSync(
        audioLayers: layers,
        currentTime: at,
        playbackSpeed: 1.0,
      );
      final faster = RecitationTiming.shouldPrioritizeSync(
        audioLayers: layers,
        currentTime: at,
        playbackSpeed: 1.5,
      );

      expect(normal, isFalse);
      expect(faster, isTrue);
    });
  });

  group('RecitationTiming.computeEffectiveRecitationTime', () {
    test('uses audio clock when source is ready', () {
      final t = RecitationTiming.computeEffectiveRecitationTime(
        fallbackTimelineTime: 12.0,
        isAudioReady: true,
        audioPosition: const Duration(milliseconds: 420),
        audioLayerStartTime: 10.0,
        audioLayerDuration: 3.0,
      );
      expect(t, closeTo(10.42, 0.001));
    });

    test('falls back to timeline when audio is not ready', () {
      final t = RecitationTiming.computeEffectiveRecitationTime(
        fallbackTimelineTime: 8.75,
        isAudioReady: false,
        audioPosition: const Duration(milliseconds: 300),
        audioLayerStartTime: 8.0,
        audioLayerDuration: 4.0,
      );
      expect(t, 8.75);
    });

    test('clamps time inside layer bounds', () {
      final t = RecitationTiming.computeEffectiveRecitationTime(
        fallbackTimelineTime: 2.0,
        isAudioReady: true,
        audioPosition: const Duration(seconds: 10),
        audioLayerStartTime: 1.0,
        audioLayerDuration: 3.0,
      );
      expect(t, 4.0);
    });
  });

  group('RecitationTiming.shouldDelayDriftCorrectionAfterSwitch', () {
    test('delays correction near boundary right after switch', () {
      final now = DateTime(2026, 4, 12, 12, 0, 0, 350);
      final shouldDelay = RecitationTiming.shouldDelayDriftCorrectionAfterSwitch(
        now: now,
        lastSwitchAt: DateTime(2026, 4, 12, 12, 0, 0, 100),
        currentTime: 20.10,
        layerStartTime: 20.0,
        playbackSpeed: 1.0,
      );
      expect(shouldDelay, isTrue);
    });

    test('does not delay correction after grace period', () {
      final now = DateTime(2026, 4, 12, 12, 0, 1, 0);
      final shouldDelay = RecitationTiming.shouldDelayDriftCorrectionAfterSwitch(
        now: now,
        lastSwitchAt: DateTime(2026, 4, 12, 12, 0, 0, 100),
        currentTime: 20.10,
        layerStartTime: 20.0,
        playbackSpeed: 1.0,
      );
      expect(shouldDelay, isFalse);
    });
  });
}
