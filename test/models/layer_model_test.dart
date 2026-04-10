import 'package:flutter_test/flutter_test.dart';
import 'package:deen_studio_01/models/project.dart';
import '../fixtures/test_fixtures.dart';

/// ═══════════════════════════════════════════
/// Layer Model Tests
/// ═══════════════════════════════════════════

void main() {
  group('Layer Creation', () {
    test('creates text layer with default values', () {
      final layer = TestFixtures.createTextLayer();

      expect(layer.id, 'text_1');
      expect(layer.type, 'text');
      expect(layer.content, 'بسم الله');
      expect(layer.startTime, 0.0);
      expect(layer.duration, 5.0);
      expect(layer.style, isEmpty);
      expect(layer.isTextType, isTrue);
      expect(layer.isAudio, isFalse);
      expect(layer.isVisual, isFalse);
      expect(layer.isSticker, isFalse);
    });

    test('creates audio layer with volume style', () {
      final layer = TestFixtures.createAudioLayer(volume: 0.75);

      expect(layer.type, 'audio');
      expect(layer.isAudio, isTrue);
      expect(layer.style['volume'], 0.75);
    });

    test('creates video layer with stabilization flag', () {
      final layer = TestFixtures.createVideoLayer(stabilized: true);

      expect(layer.type, 'video');
      expect(layer.isVisual, isTrue);
      expect(layer.stabilized, isTrue);
    });

    test('creates sticker layer with emoji content', () {
      final layer = TestFixtures.createStickerLayer(emoji: '❤️', size: 64);

      expect(layer.type, 'sticker');
      expect(layer.isSticker, isTrue);
      expect(layer.content, '❤️');
      expect(layer.style['size'], 64.0);
    });

    test('creates image layer', () {
      final layer = TestFixtures.createImageLayer();

      expect(layer.type, 'image');
      expect(layer.isVisual, isTrue);
      expect(layer.content, '/path/to/image.jpg');
    });
  });

  group('Layer Properties', () {
    test('effectiveDuration returns duration when no in/out points', () {
      final layer = TestFixtures.createTextLayer(duration: 5.0);
      expect(layer.effectiveDuration, 5.0);
    });

    test('effectiveDuration respects inPoint and outPoint', () {
      final layer = TestFixtures.createTextLayer(
        duration: 10.0,
      ).copyWith(
        inPoint: 2.0,
        outPoint: 7.0,
      );
      expect(layer.effectiveDuration, 5.0); // 7.0 - 2.0
    });

    test('activeAt returns true when time is within layer range', () {
      final layer = TestFixtures.createTextLayer(startTime: 5.0, duration: 10.0);

      expect(layer.activeAt(4.9), isFalse); // before
      expect(layer.activeAt(5.0), isTrue);  // start
      expect(layer.activeAt(10.0), isTrue); // middle
      expect(layer.activeAt(14.9), isTrue); // near end
      expect(layer.activeAt(15.0), isFalse); // at end (exclusive)
    });

    test('activeAt works with inPoint/outPoint', () {
      final layer = TestFixtures.createTextLayer(
        startTime: 0.0,
        duration: 10.0,
      ).copyWith(inPoint: 2.0, outPoint: 8.0);

      // effectiveDuration = 8.0 - 2.0 = 6.0
      // active range: 0.0 to 6.0 (startTime to startTime + effectiveDuration)
      expect(layer.effectiveDuration, 6.0);
      expect(layer.activeAt(0.0), isTrue);  // start
      expect(layer.activeAt(3.0), isTrue);  // within range
      expect(layer.activeAt(5.9), isTrue);  // near end
      expect(layer.activeAt(6.0), isFalse); // at end (exclusive)
      expect(layer.activeAt(7.0), isFalse); // beyond effective range
    });
  });

  group('Layer copyWith', () {
    test('creates new layer with updated fields', () {
      final original = TestFixtures.createTextLayer(
        id: 'text_1',
        content: 'Original',
        startTime: 0.0,
        duration: 5.0,
      );

      final updated = original.copyWith(
        content: 'Updated',
        startTime: 10.0,
      );

      expect(updated.content, 'Updated');
      expect(updated.startTime, 10.0);
      expect(updated.duration, 5.0); // unchanged
      expect(updated.id, 'text_1');  // unchanged
    });

    test('preserves original layer immutability', () {
      final original = TestFixtures.createTextLayer(content: 'Original');
      final updated = original.copyWith(content: 'Updated');

      expect(original.content, 'Original');
      expect(updated.content, 'Updated');
      expect(identical(original, updated), isFalse);
    });

    test('updates style map correctly', () {
      final layer = TestFixtures.createAudioLayer();
      final updated = layer.copyWith(
        style: {...layer.style, 'volume': 0.5, 'speed': 1.5},
      );

      expect(updated.style['volume'], 0.5);
      expect(updated.style['speed'], 1.5);
    });

    test('updates transform correctly', () {
      final layer = TestFixtures.createTextLayer();
      final updated = layer.copyWith(
        transform: const ClipTransform(x: 0.5, y: 0.3, scaleX: 1.2, scaleY: 1.2, rotation: 45, opacity: 0.8),
      );

      expect(updated.transform.x, 0.5);
      expect(updated.transform.rotation, 45);
      expect(updated.transform.opacity, 0.8);
    });
  });

  group('Layer Serialization', () {
    test('toMap and fromMap round-trip for text layer', () {
      final original = TestFixtures.createTextLayer(
        id: 'text_roundtrip',
        content: 'بسم الله',
        startTime: 2.5,
        duration: 7.5,
      );

      final map = original.toMap();
      final restored = Layer.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.type, original.type);
      expect(restored.content, original.content);
      expect(restored.startTime, original.startTime);
      expect(restored.duration, original.duration);
      expect(restored.isTextType, original.isTextType);
    });

    test('toMap and fromMap round-trip for audio layer with style', () {
      final original = TestFixtures.createAudioLayer(
        id: 'audio_roundtrip',
        content: '/path/to/song.mp3',
        startTime: 0.0,
        duration: 120.0,
        volume: 0.85,
      );

      final map = original.toMap();
      final restored = Layer.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.type, original.type);
      expect(restored.style['volume'], 0.85);
    });

    test('toMap and fromMap round-trip for video layer', () {
      final original = TestFixtures.createVideoLayer(
        id: 'video_roundtrip',
        stabilized: true,
      );

      final map = original.toMap();
      final restored = Layer.fromMap(map);

      expect(restored.stabilized, isTrue);
    });

    test('toMap and fromMap round-trip for sticker layer', () {
      final original = TestFixtures.createStickerLayer(
        id: 'sticker_roundtrip',
        emoji: '🌟',
        size: 72.0,
      );

      final map = original.toMap();
      final restored = Layer.fromMap(map);

      expect(restored.content, '🌟');
      expect(restored.style['size'], 72.0);
    });

    test('toMap includes wordTimings', () {
      final layer = TestFixtures.createTextLayer().copyWith(
        wordTimings: [
          {'word': 'بسم', 'start': 0.0, 'end': 0.5},
          {'word': 'الله', 'start': 0.5, 'end': 1.0},
        ],
      );

      final map = layer.toMap();
      final restored = Layer.fromMap(map);

      expect(restored.wordTimings.length, 2);
      expect(restored.wordTimings[0]['word'], 'بسم');
    });

    test('toMap includes new fields (wordTimings, stabilized)', () {
      final layer = TestFixtures.createVideoLayer(stabilized: true).copyWith(
        wordTimings: [
          {'word': 'test', 'start': 0.0, 'end': 1.0},
        ],
      );

      final map = layer.toMap();
      expect(map['wordTimings'], isA<List>());
      expect(map['stabilized'], isTrue);
    });
  });

  group('Layer Type Checks', () {
    test('isTextType is true for text layers', () {
      expect(TestFixtures.createTextLayer().isTextType, isTrue);
    });

    test('isAudio is true only for audio type', () {
      expect(TestFixtures.createAudioLayer().isAudio, isTrue);
      expect(TestFixtures.createTextLayer().isAudio, isFalse);
    });

    test('isVisual is true for image, video, and sticker', () {
      expect(TestFixtures.createVideoLayer().isVisual, isTrue);
      expect(TestFixtures.createImageLayer().isVisual, isTrue);
      expect(TestFixtures.createStickerLayer().isVisual, isTrue);
    });
  });

  group('Layer Keyframes', () {
    test('layer with keyframes serializes and deserializes', () {
      final layer = TestFixtures.createTextLayer().copyWith(
        keyframes: [
          const Keyframe(
            time: 0.0,
            transform: ClipTransform(x: 0.5, y: 0.5),
          ),
          const Keyframe(
            time: 2.0,
            transform: ClipTransform(x: 0.7, y: 0.3),
          ),
        ],
      );

      final map = layer.toMap();
      final restored = Layer.fromMap(map);

      expect(restored.keyframes.length, 2);
      expect(restored.keyframes[0].time, 0.0);
      expect(restored.keyframes[1].time, 2.0);
    });

    test('empty keyframes list handled correctly', () {
      final layer = TestFixtures.createTextLayer();
      final map = layer.toMap();
      final restored = Layer.fromMap(map);

      expect(restored.keyframes, isEmpty);
    });
  });

  group('Layer Effects', () {
    test('layer with effects serializes correctly', () {
      final layer = TestFixtures.createVideoLayer().copyWith(
        effects: [
          ClipEffect(
            id: 'effect_1',
            type: 'brightness',
            enabled: true,
            params: {'value': 1.5},
          ),
        ],
      );

      final map = layer.toMap();
      final restored = Layer.fromMap(map);

      expect(restored.effects.length, 1);
      expect(restored.effects[0].type, 'brightness');
      expect(restored.effects[0].params['value'], 1.5);
    });
  });

  group('Layer Edge Cases', () {
    test('handles empty content gracefully', () {
      final layer = TestFixtures.createTextLayer(content: '');
      expect(layer.content, isEmpty);
      expect(layer.activeAt(0.0), isTrue);
    });

    test('handles zero duration', () {
      final layer = TestFixtures.createTextLayer(duration: 0.0);
      expect(layer.effectiveDuration, 0.0);
      expect(layer.activeAt(0.0), isFalse); // 0.0 < 0.0 + 0.0 is false
    });

    test('handles negative start time', () {
      final layer = TestFixtures.createTextLayer(startTime: -5.0, duration: 10.0);
      expect(layer.activeAt(0.0), isTrue);
      expect(layer.activeAt(4.9), isTrue);
    });

    test('handles very large duration', () {
      final layer = TestFixtures.createTextLayer(duration: 99999.0);
      expect(layer.activeAt(50000.0), isTrue);
    });
  });
}
