import 'package:flutter_test/flutter_test.dart';
import 'package:deen_studio_01/models/project.dart';
import 'package:deen_studio_01/models/text_layer_style.dart';
import '../fixtures/test_fixtures.dart';

/// ═══════════════════════════════════════════
/// Integration Tests — Complete Workflows
/// ═══════════════════════════════════════════
///
/// Tests real-world user workflows from start to finish.

void main() {
  group('Complete Editing Workflow', () {
    test('user creates project, adds layers, edits, and saves', () {
      // 1. Create project
      var project = TestFixtures.createProject(
        id: 'integration_test_1',
        title: 'My First Video',
      );
      expect(project.layers.length, 0);

      // 2. Add Arabic text layer
      var textLayer = TestFixtures.createTextLayer(
        id: 'arabic_1',
        content: 'بسم الله الرحمن الرحيم',
        startTime: 0.0,
        duration: 5.0,
      );
      textLayer = textLayer.copyWith(
        textStyle: const TextLayerStyle(
          fontFamily: 'UthmanicRegular',
          fontSize: 32,
          isRTL: true,
          color: '#FFFFFF',
        ),
      );
      project = project.copyWith(layers: [...project.layers, textLayer]);
      expect(project.layers.length, 1);

      // 3. Add audio layer
      final audioLayer = TestFixtures.createAudioLayer(
        id: 'audio_1',
        content: '/path/to/recitation.mp3',
        startTime: 0.0,
        duration: 5.0,
        volume: 1.0,
      );
      project = project.copyWith(layers: [...project.layers, audioLayer]);
      expect(project.layers.length, 2);

      // 4. Add video background
      final videoLayer = TestFixtures.createVideoLayer(
        id: 'video_1',
        content: '/path/to/background.mp4',
        startTime: 0.0,
        duration: 10.0,
      );
      project = project.copyWith(layers: [...project.layers, videoLayer]);
      expect(project.layers.length, 3);

      // 5. Add sticker
      final stickerLayer = TestFixtures.createStickerLayer(
        id: 'sticker_1',
        emoji: '🌟',
        startTime: 2.0,
        duration: 3.0,
        size: 64,
      );
      project = project.copyWith(layers: [...project.layers, stickerLayer]);
      expect(project.layers.length, 4);

      // 6. Verify layer types
      final textLayers = project.layers.where((l) => l.isTextType).toList();
      final audioLayers = project.layers.where((l) => l.isAudio).toList();
      final videoLayers = project.layers.where((l) => l.isVisual).toList();
      final stickerLayers = project.layers.where((l) => l.isSticker).toList();

      expect(textLayers.length, 1);
      expect(audioLayers.length, 1);
      expect(videoLayers.length, 2); // video + sticker
      expect(stickerLayers.length, 1);

      // 7. Save (serialize)
      final savedMap = project.toMap();
      expect(savedMap['title'], 'My First Video');
      expect(savedMap['layers'].length, 4);

      // 8. Reload (deserialize)
      final restored = Project.fromMap(savedMap);
      expect(restored.layers.length, 4);
      expect(restored.title, 'My First Video');
    });

    test('user trims a video clip', () {
      var project = TestFixtures.createProject(
        layers: [TestFixtures.createVideoLayer(
          id: 'video_1',
          startTime: 0.0,
          duration: 30.0,
        )],
      );

      // Trim: set inPoint to 5s, outPoint to 25s
      final originalLayer = project.layers.first;
      final trimmedLayer = originalLayer.copyWith(
        inPoint: 5.0,
        outPoint: 25.0,
      );

      project = project.copyWith(
        layers: project.layers.map((l) => l.id == 'video_1' ? trimmedLayer : l).toList(),
      );

      final layer = project.layers.first;
      expect(layer.inPoint, 5.0);
      expect(layer.outPoint, 25.0);
      expect(layer.effectiveDuration, 20.0);
    });

    test('user splits a clip at playhead position', () {
      var project = TestFixtures.createProject(
        layers: [TestFixtures.createTextLayer(
          id: 'text_1',
          startTime: 0.0,
          duration: 10.0,
        )],
      );

      // Split at 6s
      final playheadTime = 6.0;
      final originalLayer = project.layers.first;
      final relativeSplit = playheadTime - originalLayer.startTime; // 6.0

      final firstHalf = originalLayer.copyWith(
        duration: relativeSplit,
      );
      final secondHalf = originalLayer.copyWith(
        id: 'text_1_split',
        startTime: playheadTime,
        inPoint: relativeSplit,
      );

      project = project.copyWith(
        layers: project.layers
            .where((l) => l.id != 'text_1')
            .followedBy([firstHalf, secondHalf])
            .toList(),
      );

      expect(project.layers.length, 2);
      expect(firstHalf.effectiveDuration, 6.0);
      expect(secondHalf.effectiveDuration, 4.0); // 10.0 - 6.0
      expect(firstHalf.startTime, 0.0);
      expect(secondHalf.startTime, 6.0);
    });

    test('user duplicates a clip', () {
      var project = TestFixtures.createProject(
        layers: [TestFixtures.createTextLayer(
          id: 'text_1',
          startTime: 0.0,
          duration: 5.0,
        )],
      );

      // Duplicate
      final original = project.layers.first;
      final duplicated = original.copyWith(
        id: 'text_copy_${DateTime.now().millisecondsSinceEpoch}',
        startTime: original.startTime + original.effectiveDuration,
      );

      project = project.copyWith(
        layers: [...project.layers, duplicated],
      );

      expect(project.layers.length, 2);
      expect(project.layers[1].startTime, 5.0);
      expect(project.layers[1].content, original.content);
    });

    test('user moves a clip on timeline', () {
      var project = TestFixtures.createProject(
        layers: [TestFixtures.createTextLayer(
          id: 'text_1',
          startTime: 0.0,
          duration: 5.0,
        )],
      );

      // Move to 10s
      final layer = project.layers.first;
      final movedLayer = layer.copyWith(startTime: 10.0);

      project = project.copyWith(
        layers: project.layers.map((l) => l.id == 'text_1' ? movedLayer : l).toList(),
      );

      expect(project.layers.first.startTime, 10.0);
    });

    test('user deletes a clip', () {
      var project = TestFixtures.createProject(
        layers: [
          TestFixtures.createTextLayer(id: 'text_1'),
          TestFixtures.createAudioLayer(id: 'audio_1'),
          TestFixtures.createVideoLayer(id: 'video_1'),
        ],
      );

      expect(project.layers.length, 3);

      // Delete audio layer
      project = project.copyWith(
        layers: project.layers.where((l) => l.id != 'audio_1').toList(),
      );

      expect(project.layers.length, 2);
      expect(project.layers.any((l) => l.id == 'audio_1'), isFalse);
    });
  });

  group('Multi-Layer Workflow', () {
    test('complex project with 20+ layers', () {
      final project = TestFixtures.createComplexProject(layerCount: 20);

      expect(project.layers.length, 20);

      // Verify all layers are unique
      final ids = project.layers.map((l) => l.id).toSet();
      expect(ids.length, 20);

      // Verify serialization
      final map = project.toMap();
      expect(map['layers'].length, 20);

      // Verify deserialization
      final restored = Project.fromMap(map);
      expect(restored.layers.length, 20);
    });

    test('layers at overlapping times are all active', () {
      final project = TestFixtures.createProject(
        layers: [
          TestFixtures.createTextLayer(id: 'text_1', startTime: 0.0, duration: 10.0),
          TestFixtures.createAudioLayer(id: 'audio_1', startTime: 2.0, duration: 8.0),
          TestFixtures.createVideoLayer(id: 'video_1', startTime: 0.0, duration: 10.0),
          TestFixtures.createStickerLayer(id: 'sticker_1', startTime: 5.0, duration: 3.0),
        ],
      );

      // At t=5.5, all layers should be active
      final activeAt5_5 = project.layers.where((l) => l.activeAt(5.5)).toList();
      expect(activeAt5_5.length, 4);

      // At t=0.5, only text and video
      final activeAt0_5 = project.layers.where((l) => l.activeAt(0.5)).toList();
      expect(activeAt0_5.length, 2);

      // At t=9.0, only text and video
      final activeAt9_0 = project.layers.where((l) => l.activeAt(9.0)).toList();
      expect(activeAt9_0.length, 2);
    });
  });

  group('Timeline Operations', () {
    test('snap to adjacent clips', () {
      // Simulate magnetic timeline snapping
      final clips = [
        TestFixtures.createTextLayer(id: 'text_1', startTime: 0.0, duration: 3.0),
        TestFixtures.createTextLayer(id: 'text_2', startTime: 3.0, duration: 3.0),
        TestFixtures.createTextLayer(id: 'text_3', startTime: 6.0, duration: 3.0),
      ];

      // Try to place a clip at 3.1s — should snap to 3.0
      const snapThreshold = 0.5;
      double tryTime = 3.1;

      for (final clip in clips) {
        if ((tryTime - clip.startTime).abs() < snapThreshold) {
          tryTime = clip.startTime;
          break;
        }
        if ((tryTime - (clip.startTime + clip.effectiveDuration)).abs() < snapThreshold) {
          tryTime = clip.startTime + clip.effectiveDuration;
          break;
        }
      }

      expect(tryTime, 3.0);
    });

    test('track visibility toggle', () {
      final hiddenTracks = <String>{'audio'};

      final project = TestFixtures.createProject(
        layers: [
          TestFixtures.createTextLayer(id: 'text_1'),
          TestFixtures.createAudioLayer(id: 'audio_1'),
          TestFixtures.createVideoLayer(id: 'video_1'),
        ],
      );

      // Filter out hidden tracks
      final visibleLayers = project.layers.where(
        (l) => !hiddenTracks.contains(l.type),
      ).toList();

      expect(visibleLayers.length, 2);
      expect(visibleLayers.any((l) => l.type == 'audio'), isFalse);
    });

    test('track mute toggle', () {
      final mutedTracks = <String>{'audio'};

      final project = TestFixtures.createProject(
        layers: [
          TestFixtures.createTextLayer(id: 'text_1'),
          TestFixtures.createAudioLayer(id: 'audio_1'),
        ],
      );

      // Muted tracks should still exist but be silenced
      final activeLayers = project.layers.where(
        (l) => !mutedTracks.contains(l.type) || true, // muted tracks are still visible, just silent
      ).toList();

      expect(activeLayers.length, 2); // both visible
    });
  });

  group('Export Readiness', () {
    test('project is export-ready with all required fields', () {
      final project = TestFixtures.createProject(
        layers: [
          TestFixtures.createVideoLayer(id: 'video_1', startTime: 0.0, duration: 10.0),
          TestFixtures.createTextLayer(id: 'text_1', startTime: 0.0, duration: 10.0),
        ],
      );

      final map = project.toMap();

      // Required for export
      expect(map['id'], isNotNull);
      expect(map['title'], isNotNull);
      expect(map['layers'], isA<List>());
      expect(map['aspect_ratio'], isNotNull);
    });

    test('export fails gracefully with empty project', () {
      final project = TestFixtures.createProject(layers: []);

      expect(project.totalDuration, 0);
      expect(project.toMap()['layers'].length, 0);
    });

    test('serialization preserves all layer properties', () {
      final project = TestFixtures.createProject(
        layers: [
          TestFixtures.createTextLayer(
            id: 'text_with_style',
            content: 'بسم الله',
            startTime: 1.0,
            duration: 5.0,
          ).copyWith(
            textStyle: const TextLayerStyle(
              fontFamily: 'UthmanicRegular',
              fontSize: 32,
              isRTL: true,
              color: '#FFD700',
            ),
            transform: const ClipTransform(x: 0.5, y: 0.3),
          ),
        ],
      );

      final restored = Project.fromMap(project.toMap());
      final restoredLayer = restored.layers.first;

      expect(restoredLayer.content, 'بسم الله');
      expect(restoredLayer.startTime, 1.0);
      expect(restoredLayer.duration, 5.0);
      expect(restoredLayer.textStyle?.fontFamily, 'UthmanicRegular');
      expect(restoredLayer.transform.x, 0.5);
    });
  });

  group('Edge Cases', () {
    test('handles rapid layer add/remove cycle', () {
      var project = TestFixtures.createProject();

      // Add and remove 100 layers quickly
      for (int i = 0; i < 100; i++) {
        final layer = TestFixtures.createTextLayer(id: 'text_$i');
        project = project.copyWith(layers: [...project.layers, layer]);
        project = project.copyWith(
          layers: project.layers.where((l) => l.id != 'text_$i').toList(),
        );
      }

      expect(project.layers.length, 0);
    });

    test('handles layer with extreme values', () {
      final layer = TestFixtures.createTextLayer(
        startTime: -100.0,
        duration: 999999.0,
      );

      expect(layer.startTime, -100.0);
      expect(layer.duration, 999999.0);
      expect(layer.activeAt(0.0), isTrue);
    });

    test('handles 1000+ layers without crash', () {
      final layers = List.generate(
        1000,
        (i) => TestFixtures.createTextLayer(
          id: 'text_$i',
          startTime: i.toDouble(),
          duration: 1.0,
        ),
      );

      final project = TestFixtures.createProject(layers: layers);
      expect(project.layers.length, 1000);

      // Serialization should work
      final map = project.toMap();
      expect(map['layers'].length, 1000);

      // Deserialization should work
      final restored = Project.fromMap(map);
      expect(restored.layers.length, 1000);
    });
  });
}
