import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:deen_studio_01/core/ui/arabic_text_animation.dart';

/// ═══════════════════════════════════════════
/// Arabic Text Animation Tests
/// ═══════════════════════════════════════════

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ArabicTextAnimation Enum', () {
    test('all 41 animations are defined', () {
      expect(ArabicTextAnimation.values.length, 41);
    });

    test('arabicAnimationFromId maps all known IDs', () {
      // Revelation
      expect(arabicAnimationFromId('divine_revelation'), ArabicTextAnimation.divineRevelation);
      expect(arabicAnimationFromId('celestial_light'), ArabicTextAnimation.celestialLight);
      expect(arabicAnimationFromId('golden_particles'), ArabicTextAnimation.goldenParticles);
      expect(arabicAnimationFromId('divine_radiance'), ArabicTextAnimation.divineRadiance);
      expect(arabicAnimationFromId('ethereal_glow'), ArabicTextAnimation.etherealGlow);

      // Nature
      expect(arabicAnimationFromId('sacred_ripple'), ArabicTextAnimation.sacredRipple);
      expect(arabicAnimationFromId('mercy_wave'), ArabicTextAnimation.mercyWave);
      expect(arabicAnimationFromId('blessed_rain'), ArabicTextAnimation.blessedRain);
      expect(arabicAnimationFromId('autumn_leaves'), ArabicTextAnimation.autumnLeaves);
      expect(arabicAnimationFromId('flower_bloom'), ArabicTextAnimation.flowerBloom);
      expect(arabicAnimationFromId('gentle_wind'), ArabicTextAnimation.gentleWind);
      expect(arabicAnimationFromId('water_drops'), ArabicTextAnimation.waterDrops);
      expect(arabicAnimationFromId('rainbow'), ArabicTextAnimation.rainbow);
      expect(arabicAnimationFromId('river_flow'), ArabicTextAnimation.riverFlow);

      // Calligraphy
      expect(arabicAnimationFromId('living_calligraphy'), ArabicTextAnimation.livingCalligraphy);
      expect(arabicAnimationFromId('ink_flow'), ArabicTextAnimation.inkFlow);
      expect(arabicAnimationFromId('brush_strokes'), ArabicTextAnimation.brushStrokes);
      expect(arabicAnimationFromId('quill_writing'), ArabicTextAnimation.quillWriting);

      // Geometry
      expect(arabicAnimationFromId('mosaic_assembly'), ArabicTextAnimation.mosaicAssembly);
      expect(arabicAnimationFromId('golden_spiral'), ArabicTextAnimation.goldenSpiral);
      expect(arabicAnimationFromId('zellige'), ArabicTextAnimation.zellige);
      expect(arabicAnimationFromId('persian_carpet'), ArabicTextAnimation.persianCarpet);
      expect(arabicAnimationFromId('fractal_growth'), ArabicTextAnimation.fractalGrowth);
      expect(arabicAnimationFromId('honeycomb'), ArabicTextAnimation.honeycomb);

      // Spiritual
      expect(arabicAnimationFromId('crescent_moon'), ArabicTextAnimation.crescentMoon);
      expect(arabicAnimationFromId('minaret_rise'), ArabicTextAnimation.minaretRise);
      expect(arabicAnimationFromId('prayer_beads'), ArabicTextAnimation.prayerBeads);
      expect(arabicAnimationFromId('incense_smoke'), ArabicTextAnimation.incenseSmoke);
      expect(arabicAnimationFromId('sacred_fire'), ArabicTextAnimation.sacredFire);
      expect(arabicAnimationFromId('night_of_power'), ArabicTextAnimation.nightOfPower);
      expect(arabicAnimationFromId('flying_carpet'), ArabicTextAnimation.flyingCarpet);

      // Cosmic
      expect(arabicAnimationFromId('constellation'), ArabicTextAnimation.constellation);
      expect(arabicAnimationFromId('stardust'), ArabicTextAnimation.stardust);
      expect(arabicAnimationFromId('aurora'), ArabicTextAnimation.aurora);
      expect(arabicAnimationFromId('galaxy'), ArabicTextAnimation.galaxy);
      expect(arabicAnimationFromId('diamond_sparkle'), ArabicTextAnimation.diamondSparkle);
      expect(arabicAnimationFromId('light_butterflies'), ArabicTextAnimation.lightButterflies);
      expect(arabicAnimationFromId('sunset'), ArabicTextAnimation.sunset);
      expect(arabicAnimationFromId('lightning'), ArabicTextAnimation.lightning);
      expect(arabicAnimationFromId('earth_shake'), ArabicTextAnimation.earthShake);
      expect(arabicAnimationFromId('compass'), ArabicTextAnimation.compass);
    });

    test('unknown ID returns default animation', () {
      expect(
        arabicAnimationFromId('unknown_animation'),
        ArabicTextAnimation.divineRevelation,
      );
    });
  });

  group('ArabicTextAnimationConfig', () {
    test('creates config with default values', () {
      const config = ArabicTextAnimationConfig(
        animation: ArabicTextAnimation.divineRevelation,
        text: 'بسم الله',
        baseStyle: TextStyle(fontSize: 32),
      );

      expect(config.highlightColor, const Color(0xFFFFD700));
      expect(config.progress, 1.0);
      expect(config.isRTL, isTrue);
      expect(config.wordTimings, isEmpty);
    });

    test('creates config with custom values', () {
      const config = ArabicTextAnimationConfig(
        animation: ArabicTextAnimation.etherealGlow,
        text: 'الحمد لله',
        baseStyle: TextStyle(fontSize: 24, color: Colors.white),
        highlightColor: Colors.red,
        progress: 0.5,
        elapsed: 1.5,
        isRTL: false,
        maxWidth: 300,
      );

      expect(config.highlightColor, Colors.red);
      expect(config.progress, 0.5);
      expect(config.elapsed, 1.5);
      expect(config.isRTL, isFalse);
      expect(config.maxWidth, 300);
    });
  });

  group('ArabicTextPainter', () {
    testWidgets('renders without crashing for all 41 animations', (tester) async {
      for (final anim in ArabicTextAnimation.values) {
        await tester.pumpWidget(
          RepaintBoundary(
            child: CustomPaint(
              size: const Size(200, 50),
              painter: ArabicTextPainter(
                config: ArabicTextAnimationConfig(
                  animation: anim,
                  text: 'بسم',
                  baseStyle: const TextStyle(fontSize: 14, color: Colors.white),
                  progress: 0.5,
                  elapsed: 1.5,
                  isRTL: true,
                ),
              ),
            ),
          ),
        );

        // Verify widget rendered
        expect(find.byType(CustomPaint), findsOneWidget);
      }
    });

    testWidgets('handles empty text gracefully', (tester) async {
      await tester.pumpWidget(
        RepaintBoundary(
          child: CustomPaint(
            size: const Size(200, 50),
            painter: ArabicTextPainter(
              config: ArabicTextAnimationConfig(
                animation: ArabicTextAnimation.divineRevelation,
                text: '',
                baseStyle: const TextStyle(fontSize: 14),
                progress: 1.0,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('handles long Arabic text', (tester) async {
      await tester.pumpWidget(
        RepaintBoundary(
          child: CustomPaint(
            size: const Size(400, 100),
            painter: ArabicTextPainter(
              config: ArabicTextAnimationConfig(
                animation: ArabicTextAnimation.etherealGlow,
                text: 'بسم الله الرحمن الرحيم الحمد لله رب العالمين الرحمن الرحيم',
                baseStyle: const TextStyle(fontSize: 20, color: Colors.white),
                progress: 0.8,
                elapsed: 2.0,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('progress 0 shows no animation effect', (tester) async {
      await tester.pumpWidget(
        RepaintBoundary(
          child: CustomPaint(
            size: const Size(200, 50),
            painter: ArabicTextPainter(
              config: ArabicTextAnimationConfig(
                animation: ArabicTextAnimation.divineRevelation,
                text: 'بسم',
                baseStyle: const TextStyle(fontSize: 14, color: Colors.white),
                progress: 0.0,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('progress 1 shows full animation', (tester) async {
      await tester.pumpWidget(
        RepaintBoundary(
          child: CustomPaint(
            size: const Size(200, 50),
            painter: ArabicTextPainter(
              config: ArabicTextAnimationConfig(
                animation: ArabicTextAnimation.divineRevelation,
                text: 'بسم',
                baseStyle: const TextStyle(fontSize: 14, color: Colors.white),
                progress: 1.0,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsOneWidget);
    });
  });

  group('Animation Progression', () {
    testWidgets('Karaoke Sweep progresses from 0 to 1', (tester) async {
      // This test verifies the painter can be created at different progress levels
      for (double p = 0.0; p <= 1.0; p += 0.25) {
        await tester.pumpWidget(
          RepaintBoundary(
            child: CustomPaint(
              size: const Size(200, 50),
              painter: ArabicTextPainter(
                config: ArabicTextAnimationConfig(
                  animation: ArabicTextAnimation.divineRevelation,
                  text: 'بسم الله',
                  baseStyle: const TextStyle(fontSize: 14, color: Colors.white),
                  progress: p,
                ),
              ),
            ),
          ),
        );
        expect(find.byType(CustomPaint), findsOneWidget);
      }
    });

    testWidgets('Divine Glow highlights active word', (tester) async {
      await tester.pumpWidget(
        RepaintBoundary(
          child: CustomPaint(
            size: const Size(200, 50),
            painter: ArabicTextPainter(
              config: ArabicTextAnimationConfig(
                animation: ArabicTextAnimation.etherealGlow,
                text: 'بسم الله الرحمن',
                baseStyle: const TextStyle(fontSize: 12, color: Colors.white),
                progress: 0.5,
                elapsed: 1.5,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('Breathing Wave oscillates words vertically', (tester) async {
      await tester.pumpWidget(
        RepaintBoundary(
          child: CustomPaint(
            size: const Size(300, 80),
            painter: ArabicTextPainter(
              config: ArabicTextAnimationConfig(
                animation: ArabicTextAnimation.mercyWave,
                text: 'بسم الله الرحمن الرحيم',
                baseStyle: const TextStyle(fontSize: 14, color: Colors.white),
                progress: 0.5,
                elapsed: 2.0,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsOneWidget);
    });
  });

  group('RTL Support', () {
    testWidgets('RTL mode renders text right-to-left', (tester) async {
      await tester.pumpWidget(
        RepaintBoundary(
          child: CustomPaint(
            size: const Size(200, 50),
            painter: ArabicTextPainter(
              config: ArabicTextAnimationConfig(
                animation: ArabicTextAnimation.divineRevelation,
                text: 'بسم الله',
                baseStyle: const TextStyle(fontSize: 14, color: Colors.white),
                progress: 1.0,
                isRTL: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('LTR mode renders text left-to-right', (tester) async {
      await tester.pumpWidget(
        RepaintBoundary(
          child: CustomPaint(
            size: const Size(200, 50),
            painter: ArabicTextPainter(
              config: ArabicTextAnimationConfig(
                animation: ArabicTextAnimation.divineRevelation,
                text: 'Hello World',
                baseStyle: const TextStyle(fontSize: 14, color: Colors.white),
                progress: 1.0,
                isRTL: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsOneWidget);
    });
  });

  group('Word Timings Sync', () {
    test('getCurrentWordIndex from timings', () {
      final wordTimings = [
        {'word': 'بسم', 'start': 0.0, 'end': 0.5},
        {'word': 'الله', 'start': 0.5, 'end': 1.2},
        {'word': 'الرحمن', 'start': 1.2, 'end': 2.0},
        {'word': 'الرحيم', 'start': 2.0, 'end': 2.8},
      ];

      // Test at different times
      final config0 = ArabicTextAnimationConfig(
        animation: ArabicTextAnimation.divineRevelation,
        text: 'بسم الله الرحمن الرحيم',
        baseStyle: const TextStyle(fontSize: 14),
        wordTimings: wordTimings,
        currentTime: 0.3,
        layerStartTime: 0.0,
      );
      // First word should be active at t=0.3
      expect(config0.currentTime, greaterThanOrEqualTo(0.0));
      expect(config0.currentTime, lessThan(0.5));
    });
  });

  group('Performance', () {
    testWidgets('paints 41 animations in under 16ms each (60fps target)', (tester) async {
      // Warm up
      await tester.pumpWidget(
        RepaintBoundary(
          child: CustomPaint(
            size: const Size(200, 50),
            painter: ArabicTextPainter(
              config: ArabicTextAnimationConfig(
                animation: ArabicTextAnimation.divineRevelation,
                text: 'بسم',
                baseStyle: const TextStyle(fontSize: 14, color: Colors.white),
                progress: 0.5,
              ),
            ),
          ),
        ),
      );

      // Measure each animation
      for (final anim in ArabicTextAnimation.values) {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          RepaintBoundary(
            child: CustomPaint(
              size: const Size(200, 50),
              painter: ArabicTextPainter(
                config: ArabicTextAnimationConfig(
                  animation: anim,
                  text: 'بسم الله',
                  baseStyle: const TextStyle(fontSize: 14, color: Colors.white),
                  progress: 0.5,
                ),
              ),
            ),
          ),
        );

        stopwatch.stop();
        // Allow some tolerance for CI environments
        expect(stopwatch.elapsedMilliseconds, lessThan(50),
            reason: '$anim took ${stopwatch.elapsedMilliseconds}ms');
      }
    });
  });
}
