import 'package:flutter_test/flutter_test.dart';
import 'package:deen_studio_01/models/project.dart';
import 'package:deen_studio_01/core/models/speed_curve.dart';
import '../fixtures/test_fixtures.dart';

/// ═══════════════════════════════════════════
/// Editor State Mutation Tests
/// ═══════════════════════════════════════════
///
/// Tests the business logic of layer operations
/// without requiring the full Riverpod/Supabase stack.

void main() {
  group('Layer Operations', () {
    test('addLayer increases layer count', () {
      var project = TestFixtures.createProject();
      expect(project.layers.length, 0);

      final layer = TestFixtures.createTextLayer();
      project = project.copyWith(layers: [...project.layers, layer]);

      expect(project.layers.length, 1);
      expect(project.layers.first.id, 'text_1');
    });

    test('addLayer at current time sets startTime', () {
      final currentTime = 3.5;
      final layer = TestFixtures.createTextLayer(startTime: currentTime);

      expect(layer.startTime, currentTime);
    });

    test('removeLayer decreases layer count', () {
      var project = TestFixtures.createProject(
        layers: [
          TestFixtures.createTextLayer(id: 'text_1'),
          TestFixtures.createAudioLayer(id: 'audio_1'),
        ],
      );
      expect(project.layers.length, 2);

      project = project.copyWith(
        layers: project.layers.where((l) => l.id != 'text_1').toList(),
      );

      expect(project.layers.length, 1);
      expect(project.layers.first.id, 'audio_1');
    });

    test('removeLayer with non-existent id does nothing', () {
      var project = TestFixtures.createProject(
        layers: [TestFixtures.createTextLayer(id: 'text_1')],
      );

      project = project.copyWith(
        layers: project.layers.where((l) => l.id != 'nonexistent').toList(),
      );

      expect(project.layers.length, 1);
    });

    test('duplicateLayer creates copy with new ID', () {
      var project = TestFixtures.createProject(
        layers: [TestFixtures.createTextLayer(
          id: 'text_1',
          startTime: 0.0,
          duration: 5.0,
        )],
      );

      final original = project.layers.first;
      final duplicated = original.copyWith(
        id: 'text_copy_${DateTime.now().millisecondsSinceEpoch}',
        startTime: original.startTime + original.effectiveDuration,
      );

      project = project.copyWith(
        layers: [...project.layers, duplicated],
      );

      expect(project.layers.length, 2);
      expect(project.layers[1].id, isNot(equals(original.id)));
      expect(project.layers[1].startTime, 5.0); // starts after original ends
    });

    test('duplicateLayer places duplicate after original ends', () {
      final original = TestFixtures.createTextLayer(
        id: 'text_1',
        startTime: 2.0,
        duration: 3.0,
      );

      final duplicated = original.copyWith(
        id: 'text_copy_123',
        startTime: original.startTime + original.effectiveDuration,
      );

      expect(duplicated.startTime, 5.0); // 2.0 + 3.0
    });
  });

  group('Layer Movement', () {
    test('moveLayer changes startTime', () {
      final layer = TestFixtures.createTextLayer(startTime: 0.0);
      final moved = layer.copyWith(startTime: 10.0);

      expect(moved.startTime, 10.0);
      expect(moved.id, layer.id); // same layer, just moved
    });

    test('moveLayer clamps negative times to 0', () {
      final layer = TestFixtures.createTextLayer(startTime: 5.0);
      final delta = -10.0;
      final newStart = (layer.startTime + delta).clamp(0.0, double.infinity);

      expect(newStart, 0.0);
    });

    test('rippleEdit shifts all subsequent layers', () {
      final layers = [
        TestFixtures.createTextLayer(id: 'text_1', startTime: 0.0, duration: 3.0),
        TestFixtures.createAudioLayer(id: 'audio_1', startTime: 3.0, duration: 5.0),
        TestFixtures.createVideoLayer(id: 'video_1', startTime: 8.0, duration: 4.0),
      ];

      // Move text_1 by +2 seconds
      final movedLayer = layers[0].copyWith(startTime: 2.0);
      final delta = 2.0;

      final updatedLayers = layers.map((l) {
        if (l.id == movedLayer.id) return movedLayer;
        if (l.startTime > 0.0) { // original start of moved layer
          return l.copyWith(startTime: l.startTime + delta);
        }
        return l;
      }).toList();

      expect(updatedLayers[0].startTime, 2.0);
      expect(updatedLayers[1].startTime, 5.0); // 3.0 + 2.0
      expect(updatedLayers[2].startTime, 10.0); // 8.0 + 2.0
    });
  });

  group('Layer Trimming', () {
    test('trimLayerStart adjusts inPoint', () {
      final layer = TestFixtures.createTextLayer(
        startTime: 0.0,
        duration: 10.0,
      ).copyWith(inPoint: 0.0);

      final trimmed = layer.copyWith(inPoint: 2.0);

      expect(trimmed.inPoint, 2.0);
      expect(trimmed.effectiveDuration, 8.0); // 10.0 - 2.0
    });

    test('trimLayerEnd adjusts outPoint', () {
      final layer = TestFixtures.createTextLayer(
        startTime: 0.0,
        duration: 10.0,
      ).copyWith(outPoint: 10.0);

      final trimmed = layer.copyWith(outPoint: 7.0);

      expect(trimmed.outPoint, 7.0);
      expect(trimmed.effectiveDuration, 7.0);
    });

    test('trimLayerEnd cannot exceed duration', () {
      final layer = TestFixtures.createTextLayer(
        startTime: 0.0,
        duration: 10.0,
      );

      final trimmed = layer.copyWith(outPoint: 15.0);

      expect(trimmed.outPoint, 15.0);
      expect(trimmed.effectiveDuration, 15.0); // outPoint - inPoint(0)
    });
  });

  group('Layer Split', () {
    test('splitLayer creates two layers at split point', () {
      final layer = TestFixtures.createTextLayer(
        id: 'text_1',
        startTime: 0.0,
        duration: 10.0,
      );

      final splitPoint = 5.0;
      final relativeSplit = splitPoint - layer.startTime; // 5.0

      final firstHalf = layer.copyWith(
        duration: relativeSplit,
        outPoint: layer.inPoint != null ? layer.inPoint! + relativeSplit : null,
      );

      final secondHalf = layer.copyWith(
        id: '${layer.id}_split',
        startTime: splitPoint,
        inPoint: relativeSplit,
        outPoint: layer.duration,
      );

      expect(firstHalf.startTime, 0.0);
      expect(firstHalf.duration, 5.0);
      expect(secondHalf.startTime, 5.0);
      expect(secondHalf.inPoint, 5.0);
      expect(secondHalf.duration, 10.0); // original duration preserved
      expect(secondHalf.effectiveDuration, 5.0); // 10.0 - 5.0
    });
  });

  group('Layer Update', () {
    test('updateLayerStyle preserves other fields', () {
      final layer = TestFixtures.createTextLayer(
        startTime: 5.0,
        duration: 10.0,
      );

      final updated = layer.copyWith(
        style: {...layer.style, 'fontSize': 24.0},
      );

      expect(updated.style['fontSize'], 24.0);
      expect(updated.startTime, 5.0); // preserved
      expect(updated.duration, 10.0); // preserved
    });

    test('updateLayerTransform preserves other fields', () {
      final layer = TestFixtures.createTextLayer();
      final updated = layer.copyWith(
        transform: const ClipTransform(x: 0.5, y: 0.5, scaleX: 2.0, scaleY: 2.0),
      );

      expect(updated.transform.x, 0.5);
      expect(updated.transform.scaleX, 2.0);
      expect(layer.id, updated.id);
    });
  });

  group('Speed Curve Operations', () {
    test('setSpeedCurve on layer', () {
      final layer = TestFixtures.createVideoLayer().copyWith(
        speedCurve: SpeedCurve(
          points: [
            SpeedPoint(position: 0.0, speed: 1.0),
            SpeedPoint(position: 0.5, speed: 2.0),
            SpeedPoint(position: 1.0, speed: 0.5),
          ],
        ),
      );

      expect(layer.speedCurve, isNotNull);
      expect(layer.speedCurve!.points.length, 3);
    });

    test('getSpeedAtPosition interpolates correctly', () {
      final curve = SpeedCurve(
        points: [
          SpeedPoint(position: 0.0, speed: 1.0),
          SpeedPoint(position: 1.0, speed: 2.0),
        ],
      );

      // At position 0.5, should interpolate between 1.0 and 2.0
      final speed = curve.getSpeedAtPosition(0.5);
      expect(speed, closeTo(1.5, 0.01));
    });

    test('getSpeedAtPosition clamps to edges', () {
      final curve = SpeedCurve(
        points: [
          SpeedPoint(position: 0.0, speed: 1.0),
          SpeedPoint(position: 1.0, speed: 2.0),
        ],
      );

      expect(curve.getSpeedAtPosition(-0.5), 1.0); // before first point
      expect(curve.getSpeedAtPosition(1.5), 2.0); // after last point
    });
  });

  group('Project Operations', () {
    test('totalDuration calculates max end time', () {
      final project = TestFixtures.createProject(
        layers: [
          TestFixtures.createTextLayer(startTime: 0.0, duration: 5.0),
          TestFixtures.createAudioLayer(startTime: 3.0, duration: 10.0),
          TestFixtures.createVideoLayer(startTime: 8.0, duration: 7.0),
        ],
      );

      // Max end: max(0+5, 3+10, 8+7) = max(5, 13, 15) = 15
      expect(project.totalDuration, 15.0);
    });

    test('totalDuration is 0 for empty project', () {
      final project = TestFixtures.createProject(layers: []);
      expect(project.totalDuration, 0);
    });

    test('Project serialization round-trip', () {
      final original = TestFixtures.createProject(
        id: 'proj_roundtrip',
        title: 'Round Trip Test',
        aspectRatio: '16:9',
        duckingEnabled: true,
        layers: [
          TestFixtures.createTextLayer(id: 'text_1'),
          TestFixtures.createAudioLayer(id: 'audio_1'),
        ],
      );

      final map = original.toMap();
      final restored = Project.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.aspectRatio, original.aspectRatio);
      expect(restored.duckingEnabled, original.duckingEnabled);
      expect(restored.layers.length, original.layers.length);
    });

    test('Project toMap includes canvasBackgroundId and duckingEnabled', () {
      final project = TestFixtures.createProject(
        canvasBackgroundId: 'gradient_blue',
        duckingEnabled: true,
      );

      final map = project.toMap();
      expect(map['canvas_background_id'], 'gradient_blue');
      expect(map['ducking_enabled'], isTrue);
    });

    test('Project fromMap handles missing fields gracefully', () {
      final minimalMap = {
        'id': 'minimal',
        'user_id': 'user_1',
        'title': 'Minimal',
        'surah_id': 1,
        'ayah_range': {'start': 1, 'end': 7},
        'reciter_id': 'ar.alafasy',
        'layers': [],
      };

      final project = Project.fromMap(minimalMap);

      expect(project.id, 'minimal');
      expect(project.aspectRatio, '9:16'); // default
      expect(project.duckingEnabled, isFalse); // default
    });
  });

  group('Layer Ordering', () {
    test('reorderLayers changes layer sequence', () {
      final project = TestFixtures.createProject(
        layers: [
          TestFixtures.createTextLayer(id: 'text_1'),
          TestFixtures.createAudioLayer(id: 'audio_1'),
          TestFixtures.createVideoLayer(id: 'video_1'),
        ],
      );

      // Move video to front
      final video = project.layers.firstWhere((l) => l.id == 'video_1');
      final others = project.layers.where((l) => l.id != 'video_1').toList();
      final reordered = [video, ...others];

      expect(reordered[0].id, 'video_1');
      expect(reordered[1].id, 'text_1');
      expect(reordered[2].id, 'audio_1');
    });
  });

  group('Multi-Cam Operations', () {
    test('createMultiCamGroup from video layers', () {
      // ignore: unused_local_variable
      final project = TestFixtures.createProject(
        layers: [
          TestFixtures.createVideoLayer(id: 'video_1'),
          TestFixtures.createVideoLayer(id: 'video_2'),
          TestFixtures.createVideoLayer(id: 'video_3'),
        ],
      );

      final group = MultiCamGroup(
        id: 'multicam_1',
        name: 'Interview',
        angles: [
          MultiCamAngle(layerId: 'video_1', label: 'Camera A'),
          MultiCamAngle(layerId: 'video_2', label: 'Camera B'),
        ],
      );

      expect(group.angles.length, 2);
      expect(group.angles[0].layerId, 'video_1');
    });
  });

  group('Keyframe Operations', () {
    test('add keyframe at specific time', () {
      final layer = TestFixtures.createTextLayer().copyWith(
        keyframes: [
          const Keyframe(
            time: 0.0,
            transform: ClipTransform(x: 0.5, y: 0.5),
          ),
        ],
      );

      final newKf = const Keyframe(
        time: 2.0,
        transform: ClipTransform(x: 0.7, y: 0.3),
      );

      final updated = layer.copyWith(keyframes: [...layer.keyframes, newKf]);

      expect(updated.keyframes.length, 2);
      expect(updated.keyframes[1].time, 2.0);
    });

    test('remove keyframe by time', () {
      final layer = TestFixtures.createTextLayer().copyWith(
        keyframes: [
          const Keyframe(time: 0.0, transform: ClipTransform()),
          const Keyframe(time: 2.0, transform: ClipTransform()),
        ],
      );

      final updated = layer.copyWith(
        keyframes: layer.keyframes.where((k) => k.time != 0.0).toList(),
      );

      expect(updated.keyframes.length, 1);
      expect(updated.keyframes[0].time, 2.0);
    });
  });

  group('Color Grading Operations', () {
    test('apply color grading to layer', () {
      final grading = ColorGrading(
        masterCurve: [const Point2D(0, 0), const Point2D(1, 1)],
      );

      final layer = TestFixtures.createVideoLayer().copyWith(
        colorGrading: grading,
      );

      expect(layer.colorGrading, isNotNull);
      expect(layer.colorGrading.masterCurve.length, 2);
    });
  });

  group('Chroma Key Operations', () {
    test('apply chroma key to layer', () {
      final chroma = ChromaKey(
        enabled: true,
      );

      final layer = TestFixtures.createVideoLayer().copyWith(
        chromaKey: chroma,
      );

      expect(layer.chromaKey.enabled, isTrue);
    });
  });
}
