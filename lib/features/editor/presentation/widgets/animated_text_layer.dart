import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:deen_studio_01/models/project.dart';
import 'package:deen_studio_01/models/text_layer_style.dart';
import 'package:deen_studio_01/core/models/quran_text_animations.dart';
import 'package:deen_studio_01/features/editor/presentation/widgets/quran_animation_painters.dart';

/// Animated text widget that renders text with the specified animation preset.
///
/// ## Supported Animations
/// - **fade**: Simple opacity animation
/// - **slideIn**: Slides text from a direction
/// - **scale**: Scales text in/out
/// - **typewriter**: Reveals text character by character
/// - **bounce**: Bounce entrance
/// - **glitch**: Glitch effect on entrance
/// - **karaoke**: Highlights words sequentially (RTL support)
/// - **wordByWord**: Shows words one at a time
///
/// ## Usage
/// The widget uses an `AnimationController` provided via the `vsync` parameter.
/// The `progress` value (0.0 to 1.0) determines the animation state.
class AnimatedTextLayer extends StatefulWidget {
  final Layer layer;
  final TextLayerStyle style;
  final Widget textWidget;
  final double currentTime;
  final double layerStartTime;
  final double layerDuration;
  final double maxWidth;

  const AnimatedTextLayer({
    super.key,
    required this.layer,
    required this.style,
    required this.textWidget,
    required this.currentTime,
    required this.layerStartTime,
    required this.layerDuration,
    required this.maxWidth,
  });

  @override
  State<AnimatedTextLayer> createState() => _AnimatedTextLayerState();
}

class _AnimatedTextLayerState extends State<AnimatedTextLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // Pre-computed random offsets for glitch animation (stable per rebuild)
  double _glitchRedOffsetX = 0;
  double _glitchRedOffsetY = 0;
  double _glitchBlueOffsetX = 0;
  double _glitchBlueOffsetY = 0;

  @override
  void initState() {
    super.initState();
    final inDuration =
        widget.style.animationInDuration *
        widget.style.animationConfig.durationMultiplier;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: inDuration > 0 ? (inDuration * 1000).round() : 500,
      ),
      // Start at 1.0 (fully visible) so text is always visible on first frame
      value: 1.0,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedTextLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update duration if config changed
    if (oldWidget.style.animationConfig.durationMultiplier !=
            widget.style.animationConfig.durationMultiplier ||
        oldWidget.style.animationInDuration !=
            widget.style.animationInDuration) {
      final inDuration =
          widget.style.animationInDuration *
          widget.style.animationConfig.durationMultiplier;
      _controller.duration = Duration(
        milliseconds: inDuration > 0 ? (inDuration * 1000).round() : 500,
      );
    }

    // Calculate progress
    final elapsed = widget.currentTime - widget.layerStartTime;
    final inDuration =
        widget.style.animationInDuration *
        widget.style.animationConfig.durationMultiplier;
    final outDuration =
        widget.style.animationOutDuration *
        widget.style.animationConfig.durationMultiplier;
    final totalDuration = widget.layerDuration;

    if (elapsed <= 0 || elapsed > totalDuration) return;

    double progress;
    if (elapsed < inDuration) {
      progress = elapsed / inDuration;
    } else if (outDuration > 0 && elapsed > totalDuration - outDuration) {
      progress =
          1.0 - ((elapsed - (totalDuration - outDuration)) / outDuration);
    } else {
      progress = 1.0;
    }

    progress = progress.clamp(0.0, 1.0);

    // Direct update — safe because we only change AnimationController value,
    // not the widget tree. This triggers AnimatedBuilder/ValueListenableBuilder.
    if ((_controller.value - progress).abs() > 0.001) {
      try {
        _controller.value = progress;
      } catch (_) {}
    }

    // Recompute glitch offsets when layer changes
    if (widget.style.animationPreset == TextAnimationPreset.glitchIn &&
        (oldWidget.currentTime != widget.currentTime ||
            oldWidget.layer.id != widget.layer.id)) {
      final rng = math.Random();
      _glitchRedOffsetX = rng.nextDouble();
      _glitchRedOffsetY = rng.nextDouble() * 2 - 1;
      _glitchBlueOffsetX = rng.nextDouble();
      _glitchBlueOffsetY = rng.nextDouble() * 2 - 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check for Quran animation first
    final quranAnimId = widget.style.quranAnimationId;
    if (quranAnimId.isNotEmpty) {
      final quranAnim = getQuranAnimationById(quranAnimId);
      if (quranAnim != null) {
        return _buildQuranAnimation(quranAnim);
      }
    }

    final preset = widget.style.animationPreset;

    if (preset == TextAnimationPreset.none) {
      return widget.textWidget;
    }

    // If the layer hasn't started yet or has ended, don't show it
    final elapsed = widget.currentTime - widget.layerStartTime;
    if (elapsed <= 0 || elapsed > widget.layerDuration) {
      return const SizedBox.shrink();
    }

    // Layer is active — show the text widget with animation wrapper
    // The animation is driven by the controller via didUpdateWidget (deferred updates)

    // Typewriter and word-by-word animations need special rendering
    if (preset == TextAnimationPreset.typewriter) {
      return _buildTypewriterAnimation();
    }

    if (preset == TextAnimationPreset.wordByWord ||
        preset == TextAnimationPreset.wordHighlight ||
        preset == TextAnimationPreset.karaokeRTL) {
      return _buildWordAnimation();
    }

    // For all other animations, wrap the text widget in an AnimatedBuilder
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final textWidget = child ?? widget.textWidget;
        final progress = _controller.value;

        switch (preset) {
          case TextAnimationPreset.fadeIn:
            // Fade in: start at 0.3 opacity minimum so text is always readable
            return Opacity(opacity: 0.3 + 0.7 * progress, child: textWidget);

          case TextAnimationPreset.fadeOut:
            return Opacity(opacity: 1.0 - progress, child: textWidget);

          case TextAnimationPreset.fadeInOut:
            // Fade in during first half, fade out during second half
            final elapsed = widget.currentTime - widget.layerStartTime;
            final inDur = widget.style.animationInDuration;
            final outDur = widget.style.animationOutDuration;
            final total = widget.layerDuration;
            double opacity;
            if (elapsed < inDur) {
              opacity = 0.3 + 0.7 * (elapsed / inDur);
            } else if (elapsed > total - outDur) {
              opacity = (total - elapsed) / outDur;
            } else {
              opacity = 1.0;
            }
            return Opacity(opacity: opacity.clamp(0.0, 1.0), child: child);

          case TextAnimationPreset.slideInLeft:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1.0, 0.0),
                end: Offset.zero,
              ).animate(_animation),
              child: textWidget,
            );

          case TextAnimationPreset.slideInRight:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(_animation),
              child: textWidget,
            );

          case TextAnimationPreset.slideInTop:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, -1.0),
                end: Offset.zero,
              ).animate(_animation),
              child: textWidget,
            );

          case TextAnimationPreset.slideInBottom:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(_animation),
              child: textWidget,
            );

          case TextAnimationPreset.bounceIn:
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.0, -0.5),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: Curves.bounceOut,
                    ),
                  ),
              child: textWidget,
            );

          case TextAnimationPreset.scaleIn:
            return ScaleTransition(
              scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
              ),
              child: textWidget,
            );

          case TextAnimationPreset.scaleOut:
            return ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 0.0).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeInBack),
              ),
              child: Opacity(opacity: 1.0 - progress, child: textWidget),
            );

          case TextAnimationPreset.glitchIn:
            return _buildGlitchAnimation(textWidget, progress);

          default:
            return textWidget;
        }
      },
      child: widget.textWidget,
    );
  }

  /// Typewriter animation: reveals text character by character.
  Widget _buildTypewriterAnimation() {
    final text = widget.layer.content.isEmpty ? 'Texte' : widget.layer.content;
    final flutterStyle = widget.style.toFlutterTextStyle();
    final isRTL = widget.style.isRTL;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = _controller.value;
        final charCount = (progress * text.length).round().clamp(
          0,
          text.length,
        );
        final visibleText = isRTL
            ? text.substring(text.length - charCount)
            : text.substring(0, charCount);

        return Text(
          visibleText,
          style: flutterStyle,
          textAlign: widget.style.textAlign,
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        );
      },
    );
  }

  /// Word-by-word animations: karaoke, word-by-word, or word highlight.
  Widget _buildWordAnimation() {
    final text = widget.layer.content.isEmpty ? 'Texte' : widget.layer.content;
    final words = text.split(RegExp(r'\s+'));
    final flutterStyle = widget.style.toFlutterTextStyle();
    final isRTL = widget.style.isRTL;
    final preset = widget.style.animationPreset;

    if (words.isEmpty) return widget.textWidget;

    // Calculate elapsed time relative to the layer's start
    final elapsed = widget.currentTime - widget.layerStartTime;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        int activeWordIndex = 0;
        
        if (widget.layer.wordTimings.isNotEmpty) {
          // Use precise real word timestamps (which are relative to layer start)
          for (int i = widget.layer.wordTimings.length - 1; i >= 0; i--) {
            if ((widget.layer.wordTimings[i]['start'] as double) <= elapsed) {
              activeWordIndex = i;
              break;
            }
          }
          // Clamp just in case words array length differs from timings length due to splits
          activeWordIndex = activeWordIndex.clamp(0, words.length - 1);
        } else {
          // Fallback: linear calculation
          final progress = _controller.value;
          activeWordIndex = (progress * words.length).round().clamp(0, words.length - 1);
        }

        if (preset == TextAnimationPreset.wordByWord) {
          // Show only the active word
          return Text(
            words[activeWordIndex],
            style: flutterStyle,
            textAlign: widget.style.textAlign,
            textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          );
        }

        if (preset == TextAnimationPreset.wordHighlight) {
          // Show all words, highlight the active one
          return Wrap(
            alignment: WrapAlignment.center,
            textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
            children: words.asMap().entries.map((entry) {
              final isHighlighted = entry.key == activeWordIndex;
              return Text(
                '${entry.value} ',
                style: flutterStyle.copyWith(
                  color: isHighlighted
                      ? Theme.of(context).colorScheme.primary
                      : flutterStyle.color?.withValues(alpha: 0.5),
                  fontWeight: isHighlighted
                      ? FontWeight.w700
                      : flutterStyle.fontWeight,
                ),
              );
            }).toList(),
          );
        }

        // Karaoke RTL: sequential word reveal with highlight
        return Wrap(
          alignment: WrapAlignment.center,
          textDirection: TextDirection.rtl,
          children: words.asMap().entries.map((entry) {
            final isHighlighted = entry.key <= activeWordIndex;
            return Text(
              '${entry.value} ',
              style: flutterStyle.copyWith(
                color: isHighlighted
                    ? flutterStyle.color
                    : flutterStyle.color?.withValues(alpha: 0.3),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Glitch animation: random offset and color shifts on entrance.
  Widget _buildGlitchAnimation(Widget child, double progress) {
    final redMagnitude = _glitchRedOffsetX * 4 * (1 - progress * 2);
    final blueMagnitude = _glitchBlueOffsetX * 4 * (1 - progress * 2);

    return Stack(
      children: [
        // Red channel offset
        if (progress < 0.5)
          Transform.translate(
            offset: Offset(redMagnitude, _glitchRedOffsetY),
            child: Opacity(
              opacity: 0.5,
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Colors.red.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ).createShader(bounds),
                child: child,
              ),
            ),
          ),
        // Blue channel offset
        if (progress < 0.5)
          Transform.translate(
            offset: Offset(-blueMagnitude, _glitchBlueOffsetY),
            child: Opacity(
              opacity: 0.5,
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Colors.blue.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ).createShader(bounds),
                child: child,
              ),
            ),
          ),
        // Main text
        Opacity(opacity: progress, child: child),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Quran Animation Builders
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildQuranAnimation(QuranTextAnimation anim) {
    final isRTL = widget.style.isRTL;
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    switch (anim.id) {
      // REVELATION
      case 'divine_revelation':
        return _buildAnimatedTextWithOverlay(
          anim,
          curve: Curves.easeInOut,
          overlay: (progress, size) => CustomPaint(
            size: size,
            painter: ParticlePainter(
              progress: progress,
              particleColor: TextLayerStyle.parseHexColor(
                widget.style.animationConfig.color,
              ),
              particleCount: 40,
              isGolden: true,
              intensity: widget.style.animationConfig.intensity,
              direction: widget.style.animationConfig.direction,
            ),
          ),
          textBuilder: (progress) => ShaderMask(
            shaderCallback: (bounds) => RadialGradient(
              center: Alignment.center,
              radius:
                  progress *
                  0.5 *
                  (0.5 + widget.style.animationConfig.frequency),
              colors: [
                TextLayerStyle.parseHexColor(
                  widget.style.animationConfig.color,
                ).withValues(alpha: progress),
                TextLayerStyle.parseHexColor(widget.style.color),
              ],
            ).createShader(bounds),
            child: _buildTextWidget(textDirection),
          ),
        );

      case 'celestial_light':
        return _buildAnimatedTextWithOverlay(
          anim,
          curve: Curves.easeInOut,
          overlay: (progress, size) => CustomPaint(
            size: size,
            painter: GradientSweepPainter(
              progress: progress,
              colors: [
                TextLayerStyle.parseHexColor(
                  widget.style.animationConfig.color,
                ).withValues(alpha: 0.8),
                TextLayerStyle.parseHexColor(
                  widget.style.animationConfig.color,
                ).withValues(alpha: 0.5),
                const Color(0x00FFFFFF),
              ],
              isVertical:
                  widget.style.animationConfig.direction % 180 < 45 ||
                  widget.style.animationConfig.direction % 180 > 135,
            ),
          ),
          textBuilder: (progress) => ClipPath(
            clipper: _VerticalRevealClipper(progress: progress),
            child: _buildTextWidget(textDirection),
          ),
        );

      case 'golden_particles':
        return _buildAnimatedTextWithOverlay(
          anim,
          curve: Curves.easeOut,
          overlay: (progress, size) => CustomPaint(
            size: size,
            painter: ParticlePainter(
              progress: progress,
              particleColor: TextLayerStyle.parseHexColor(
                widget.style.animationConfig.color,
              ),
              particleCount:
                  (80 * (0.5 + widget.style.animationConfig.frequency)).round(),
              isGolden: true,
              particleSize: 4 * (0.5 + widget.style.animationConfig.intensity),
              intensity: widget.style.animationConfig.intensity,
              direction: widget.style.animationConfig.direction,
            ),
          ),
          textBuilder: (progress) => _buildTextWidget(textDirection),
        );

      case 'divine_radiance':
        return _buildAnimatedTextWithOverlay(
          anim,
          curve: Curves.easeInOut,
          overlay: (progress, size) => CustomPaint(
            size: size,
            painter: ParticlePainter(
              progress: progress,
              particleColor: TextLayerStyle.parseHexColor(
                widget.style.animationConfig.color,
              ),
              particleCount: 20,
              isGolden: true,
              intensity: widget.style.animationConfig.intensity,
              direction: widget.style.animationConfig.direction,
            ),
          ),
          textBuilder: (progress) => ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                TextLayerStyle.parseHexColor(
                  widget.style.animationConfig.color,
                ),
                TextLayerStyle.parseHexColor(widget.style.color),
              ],
            ).createShader(bounds),
            child: _buildTextWidget(textDirection),
          ),
        );

      default:
        // For all other animations, just show text + overlay
        return _buildAnimatedTextWithOverlay(
          anim,
          curve: Curves.easeOut,
          overlay: (progress, size) => const SizedBox.shrink(),
          textBuilder: (progress) => _buildTextWidget(textDirection),
        );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Overlay-based Quran Animations
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAnimatedTextWithOverlay(
    QuranTextAnimation anim, {
    required Curve curve,
    required Widget Function(double progress, Size size) overlay,
    required Widget Function(double progress) textBuilder,
  }) {
    return ValueListenableBuilder<double>(
      valueListenable: _controller,
      builder: (context, controllerValue, _) {
        final progress = controllerValue.clamp(0.0, 1.0);
        return Stack(
          alignment: Alignment.center,
          children: [
            // textBuilder returns the text with ShaderMask/ClipPath effects applied
            textBuilder(progress),
            // Overlay particles/sweeps rendered on top
            overlay(progress, MediaQuery.of(context).size),
          ],
        );
      },
    );
  }

  Widget _buildTextWidget(TextDirection direction) {
    return DefaultTextStyle(
      style: widget.style.toFlutterTextStyle(),
      child: widget.textWidget,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Clip Paths for Progressive Reveal
// ═══════════════════════════════════════════════════════════════════════════

class _VerticalRevealClipper extends CustomClipper<Path> {
  final double progress;
  _VerticalRevealClipper({required this.progress});

  @override
  Path getClip(Size size) {
    final revealedHeight = size.height * progress;
    return Path()..addRect(
      Rect.fromLTWH(
        0,
        size.height - revealedHeight,
        size.width,
        revealedHeight,
      ),
    );
  }

  @override
  bool shouldReclip(covariant _VerticalRevealClipper oldClipper) =>
      oldClipper.progress != progress;
}
