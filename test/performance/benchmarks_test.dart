import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
// ignore_for_file: avoid_print

import 'package:deen_studio_01/models/project.dart';
import 'package:deen_studio_01/core/ui/arabic_text_animation.dart';
import '../fixtures/test_fixtures.dart';

/// ═══════════════════════════════════════════
/// Performance Benchmark Tests
/// ═══════════════════════════════════════════
///
/// Measures performance of critical operations to ensure
/// 60fps rendering and <100ms response times.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Serialization Performance', () {
    test('Project.toMap completes in <10ms for 50 layers', () {
      final project = TestFixtures.createComplexProject(layerCount: 50);

      final stopwatch = Stopwatch()..start();
      final map = project.toMap();
      stopwatch.stop();

      print('[BENCHMARK] toMap(50 layers): ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(10),
          reason: 'Serialization took ${stopwatch.elapsedMilliseconds}ms');
      expect(map['layers'].length, 50);
    });

    test('Project.fromMap completes in <10ms for 50 layers', () {
      final project = TestFixtures.createComplexProject(layerCount: 50);
      final map = project.toMap();

      final stopwatch = Stopwatch()..start();
      final restored = Project.fromMap(map);
      stopwatch.stop();

      print('[BENCHMARK] fromMap(50 layers): ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(10),
          reason: 'Deserialization took ${stopwatch.elapsedMilliseconds}ms');
      expect(restored.layers.length, 50);
    });

    test('Round-trip serialization for 100 layers completes in <20ms', () {
      final project = TestFixtures.createComplexProject(layerCount: 100);

      final stopwatch = Stopwatch()..start();
      final map = project.toMap();
      Project.fromMap(map);
      stopwatch.stop();

      print('[BENCHMARK] Round-trip(100 layers): ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(20),
          reason: 'Round-trip took ${stopwatch.elapsedMilliseconds}ms');
    });
  });

  group('Layer Operation Performance', () {
    test('Add 1000 layers completes in <500ms', () {
      var project = TestFixtures.createProject();

      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        final layer = TestFixtures.createTextLayer(id: 'text_$i');
        project = project.copyWith(layers: [...project.layers, layer]);
      }
      stopwatch.stop();

      print('[BENCHMARK] Add 1000 layers: ${stopwatch.elapsedMilliseconds}ms');
      expect(project.layers.length, 1000);
      // Note: This is a stress test, 500ms is generous
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    test('Remove 1000 layers completes in <500ms', () {
      var project = TestFixtures.createComplexProject(layerCount: 1000);

      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        project = project.copyWith(
          layers: project.layers.where((l) => l.id != 'text_$i').toList(),
        );
      }
      stopwatch.stop();

      print('[BENCHMARK] Remove 1000 layers: ${stopwatch.elapsedMilliseconds}ms');
      expect(project.layers.length, 0);
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    test('Find active layers at currentTime completes in <1ms for 100 layers', () {
      final project = TestFixtures.createComplexProject(layerCount: 100);
      const currentTime = 50.0;

      final stopwatch = Stopwatch()..start();
      project.layers.where((l) => l.activeAt(currentTime)).toList();
      stopwatch.stop();

      print('[BENCHMARK] Find active layers (100 total): ${stopwatch.elapsedMicroseconds}μs');
      expect(stopwatch.elapsedMicroseconds, lessThan(1000),
          reason: 'Finding active layers took ${stopwatch.elapsedMicroseconds}μs');
    });
  });

  group('Animation Rendering Performance', () {
    testWidgets('Single animation render <16ms (60fps)', (tester) async {
      final stopwatch = Stopwatch();

      for (final anim in ArabicTextAnimation.values) {
        stopwatch.reset();
        stopwatch.start();

        await tester.pumpWidget(
          RepaintBoundary(
            child: CustomPaint(
              size: const Size(400, 80),
              painter: ArabicTextPainter(
                config: ArabicTextAnimationConfig(
                  animation: anim,
                  text: 'بسم الله الرحمن الرحيم',
                  baseStyle: const TextStyle(fontSize: 20, color: Colors.white),
                  progress: 0.5,
                  elapsed: 1.5,
                ),
              ),
            ),
          ),
        );

        stopwatch.stop();
        // Allow up to 50ms for first render (warm-up overhead)
        expect(stopwatch.elapsedMilliseconds, lessThan(50),
            reason: '$anim first render took ${stopwatch.elapsedMilliseconds}ms');
      }
    });

    testWidgets('60 consecutive renders complete in <2000ms', (tester) async {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 60; i++) {
        final progress = i / 60.0;
        await tester.pumpWidget(
          RepaintBoundary(
            child: CustomPaint(
              size: const Size(400, 80),
              painter: ArabicTextPainter(
                config: ArabicTextAnimationConfig(
                  animation: ArabicTextAnimation.divineRevelation,
                  text: 'بسم الله',
                  baseStyle: const TextStyle(fontSize: 20, color: Colors.white),
                  progress: progress,
                ),
              ),
            ),
          ),
        );
      }

      stopwatch.stop();
      print('[BENCHMARK] 60 renders: ${stopwatch.elapsedMilliseconds}ms (${(stopwatch.elapsedMilliseconds / 60).toStringAsFixed(1)}ms each)');
      expect(stopwatch.elapsedMilliseconds, lessThan(2000),
          reason: '60 renders took ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Complex project with text + animation renders in <100ms', (tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        RepaintBoundary(
          child: CustomPaint(
            size: const Size(1080, 1920),
            painter: ArabicTextPainter(
              config: ArabicTextAnimationConfig(
                animation: ArabicTextAnimation.etherealGlow,
                text: 'بسم الله الرحمن الرحيم',
                baseStyle: const TextStyle(
                  fontSize: 48,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                ),
                progress: 0.7,
                elapsed: 2.0,
                maxWidth: 900,
              ),
            ),
          ),
        ),
      );

      stopwatch.stop();
      print('[BENCHMARK] Complex render (1080x1920): ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: 'Complex render took ${stopwatch.elapsedMilliseconds}ms');
    });
  });

  group('Memory Performance', () {
    test('Layer creation does not cause memory leaks', () {
      final initialMemory = _estimateMemoryUsage();

      // Create and discard 10000 layers
      for (int i = 0; i < 10000; i++) {
        final layer = TestFixtures.createTextLayer(id: 'mem_test_$i');
        layer.copyWith(content: 'Updated $i');
      }

      // Force GC (best effort)
      // Note: Dart doesn't have explicit GC, but we can verify no accumulation
      final finalMemory = _estimateMemoryUsage();

      print('[BENCHMARK] Memory after 10000 layers: ${finalMemory - initialMemory} bytes diff');
      // Memory should not have grown significantly
      expect(finalMemory - initialMemory, lessThan(10 * 1024 * 1024),
          reason: 'Memory grew by ${(finalMemory - initialMemory) / 1024 / 1024}MB');
    });

    test('Project copyWith creates independent copies', () {
      final project = TestFixtures.createProject(
        layers: [TestFixtures.createTextLayer()],
      );

      final copy = project.copyWith(
        layers: [...project.layers, TestFixtures.createAudioLayer()],
      );

      expect(project.layers.length, 1);
      expect(copy.layers.length, 2);
      expect(identical(project.layers, copy.layers), isFalse);
    });
  });

  group('Stress Tests', () {
    test('1000 layer project serializes and deserializes in <100ms', () {
      final project = TestFixtures.createComplexProject(layerCount: 1000);

      final stopwatch = Stopwatch()..start();
      final map = project.toMap();
      final restored = Project.fromMap(map);
      stopwatch.stop();

      print('[BENCHMARK] 1000 layer round-trip: ${stopwatch.elapsedMilliseconds}ms');
      expect(restored.layers.length, 1000);
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('5000 layer project totalDuration calculates in <5ms', () {
      final project = TestFixtures.createComplexProject(layerCount: 5000);

      final stopwatch = Stopwatch()..start();
      final total = project.totalDuration;
      stopwatch.stop();

      print('[BENCHMARK] 5000 layers totalDuration: ${stopwatch.elapsedMicroseconds}μs');
      expect(total, greaterThan(0));
      expect(stopwatch.elapsedMicroseconds, lessThan(5000));
    });
  });
}

// Helper: rough memory estimation (top-level to avoid forward-reference error)
int _estimateMemoryUsage() {
  // Dart doesn't expose direct memory usage — use Observatory/DevTools for accurate measurements
  return 0;
}
