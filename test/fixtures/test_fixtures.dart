/// ═══════════════════════════════════════════
/// Test Fixtures — Sample data for all tests
/// ═══════════════════════════════════════════
library;

import 'package:deen_studio_01/models/project.dart';

class TestFixtures {
  // ── Layers ────────────────────────────────────────────────────────

  static Layer createTextLayer({
    String id = 'text_1',
    String content = 'بسم الله',
    double startTime = 0.0,
    double duration = 5.0,
    Map<String, dynamic> style = const {},
  }) {
    return Layer(
      id: id,
      type: 'text',
      content: content,
      startTime: startTime,
      duration: duration,
      style: style,
    );
  }

  static Layer createAudioLayer({
    String id = 'audio_1',
    String content = '/path/to/audio.mp3',
    double startTime = 0.0,
    double duration = 10.0,
    double? volume,
  }) {
    return Layer(
      id: id,
      type: 'audio',
      content: content,
      startTime: startTime,
      duration: duration,
      style: volume != null ? {'volume': volume} : {},
    );
  }

  static Layer createVideoLayer({
    String id = 'video_1',
    String content = '/path/to/video.mp4',
    double startTime = 0.0,
    double duration = 15.0,
    bool stabilized = false,
  }) {
    return Layer(
      id: id,
      type: 'video',
      content: content,
      startTime: startTime,
      duration: duration,
      stabilized: stabilized,
      style: {},
    );
  }

  static Layer createImageLayer({
    String id = 'image_1',
    String content = '/path/to/image.jpg',
    double startTime = 0.0,
    double duration = 5.0,
  }) {
    return Layer(
      id: id,
      type: 'image',
      content: content,
      startTime: startTime,
      duration: duration,
      style: {},
    );
  }

  static Layer createStickerLayer({
    String id = 'sticker_1',
    String emoji = '😀',
    double startTime = 2.0,
    double duration = 3.0,
    double size = 48.0,
  }) {
    return Layer(
      id: id,
      type: 'sticker',
      content: emoji,
      startTime: startTime,
      duration: duration,
      style: {'size': size},
    );
  }

  // ── Project ───────────────────────────────────────────────────────

  static Project createProject({
    String id = 'test_project',
    String title = 'Test Project',
    int surahId = 1,
    String reciterId = 'ar.alafasy',
    List<Layer>? layers,
    String aspectRatio = '9:16',
    String canvasBackgroundId = 'black',
    bool duckingEnabled = false,
  }) {
    return Project(
      id: id,
      userId: 'user_123',
      title: title,
      surahId: surahId,
      ayahRange: AyahRange(start: 1, end: 7),
      reciterId: reciterId,
      layers: layers ?? [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      aspectRatio: aspectRatio,
      canvasBackgroundId: canvasBackgroundId,
      duckingEnabled: duckingEnabled,
    );
  }

  // ── Complex project for stress tests ──────────────────────────────

  static Project createComplexProject({int layerCount = 50}) {
    final layers = <Layer>[];

    // Add text layers
    for (int i = 0; i < layerCount ~/ 4; i++) {
      layers.add(createTextLayer(
        id: 'arabic_$i',
        content: 'Text $i',
        startTime: i.toDouble() * 3,
        duration: 3.0,
      ));
    }

    // Add audio layers
    for (int i = 0; i < layerCount ~/ 4; i++) {
      layers.add(createAudioLayer(
        id: 'audio_$i',
        startTime: i.toDouble() * 3,
        duration: 3.0,
      ));
    }

    // Add video layers
    for (int i = 0; i < layerCount ~/ 4; i++) {
      layers.add(createVideoLayer(
        id: 'video_$i',
        startTime: i.toDouble() * 3,
        duration: 3.0,
      ));
    }

    // Add image layers
    for (int i = 0; i < layerCount - layers.length; i++) {
      layers.add(createImageLayer(
        id: 'image_$i',
        startTime: i.toDouble() * 3,
        duration: 3.0,
      ));
    }

    return createProject(
      id: 'complex_project',
      layers: layers,
    );
  }
}
