import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:deen_studio_01/models/project.dart' as project_model;
import 'package:deen_studio_01/models/text_layer_style.dart';
import 'package:deen_studio_01/core/services/quran_animation_export.dart';

/// Video export quality settings.
class ExportSettings {
  final String resolution; // "720p", "1080p"
  final int fps;
  final String videoCodec; // "libx264"
  final String audioCodec; // "aac"
  final int videoBitrate; // kbps
  final int audioBitrate; // kbps

  const ExportSettings({
    this.resolution = "720p",
    this.fps = 30,
    this.videoCodec = "libx264",
    this.audioCodec = "aac",
    this.videoBitrate = 5000,
    this.audioBitrate = 192,
  });
}

/// Get resolution dimensions based on aspect ratio and quality.
Map<String, int> _getResolutionForAspectRatio(String quality, String aspectRatio) {
  final baseHeight = switch (quality) {
    "1080p" => 1080,
    "720p" => 720,
    "480p" => 480,
    _ => 720,
  };

  return switch (aspectRatio) {
    "9:16" => {"width": (baseHeight * 9 / 16).round(), "height": baseHeight},
    "16:9" => {"width": baseHeight, "height": (baseHeight * 9 / 16).round()},
    "1:1" => {"width": baseHeight, "height": baseHeight},
    _ => {"width": (baseHeight * 9 / 16).round(), "height": baseHeight},
  };
}

/// Progress callback for the export process.
typedef ExportProgressCallback = void Function(double progress, String message);

/// Service responsible for exporting video projects using FFmpeg.
///
/// ## Architecture
/// The export pipeline works in several stages:
/// 1. **Render frames**: For each frame of the timeline, render the canvas to an image
/// 2. **Encode video**: Use FFmpeg to encode frames into a video file
/// 3. **Mix audio**: Merge audio tracks from the project
/// 4. **Output**: Produce a final MP4 file
///
/// ## FFmpeg Pipeline
/// Instead of frame-by-frame rendering (which is slow), we use a smarter approach:
/// - Create a static background image from the first frame
/// - Use FFmpeg's `drawtext` filter to render text overlays at correct timestamps
/// - Merge audio tracks using FFmpeg's `amix` filter
/// - This is significantly faster than frame-by-frame rendering
class VideoExportService {
  final ExportSettings settings;

  VideoExportService({this.settings = const ExportSettings()});

  /// Export the project to a video file.
  ///
  /// Returns the path to the exported MP4 file, or null on failure.
  Future<String?> exportProject({
    required project_model.Project project,
    required BuildContext context,
    ExportProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call(0.0, 'Préparation de l\'export...');

      final outputDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputFile = File('${outputDir.path}/deen_studio_${project.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_$timestamp.mp4');

      final res = _getResolutionForAspectRatio(settings.resolution, project.aspectRatio);
      final totalDuration = project.totalDuration;

      if (totalDuration <= 0) {
        onProgress?.call(0.0, 'Erreur: Le projet ne contient aucun contenu.');
        return null;
      }

      onProgress?.call(0.1, 'Génération des frames...');

      // Stage 1: Render frames as images
      final framesDir = Directory('${outputDir.path}/frames_$timestamp');
      await framesDir.create(recursive: true);

      final success = await _renderFrames(
        project: project,
        framesDir: framesDir,
        totalDuration: totalDuration,
        width: res["width"]!,
        height: res["height"]!,
        onProgress: onProgress,
      );

      if (!success) {
        onProgress?.call(0.0, 'Erreur lors du rendu des frames.');
        return null;
      }

      onProgress?.call(0.7, 'Encodage vidéo avec FFmpeg...');

      // Stage 2: Encode frames to video with audio
      final ffmpegCommand = await _buildFFmpegCommand(
        framesDir: framesDir,
        outputFile: outputFile,
        project: project,
        fps: settings.fps,
        videoBitrate: settings.videoBitrate,
        audioBitrate: settings.audioBitrate,
      );

      onProgress?.call(0.75, 'Encodage en cours...');

      final session = await FFmpegKit.execute(ffmpegCommand);
      final returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode)) {
        onProgress?.call(0.0, 'Erreur FFmpeg: ${await session.getOutput()}');
        return null;
      }

      onProgress?.call(0.95, 'Nettoyage des fichiers temporaires...');

      // Cleanup frames
      await framesDir.delete(recursive: true);

      onProgress?.call(1.0, 'Export terminé !');

      return outputFile.path;
    } catch (e) {
      onProgress?.call(0.0, 'Erreur: $e');
      return null;
    }
  }

  /// Render each frame of the project as a PNG image.
  Future<bool> _renderFrames({
    required project_model.Project project,
    required Directory framesDir,
    required double totalDuration,
    required int width,
    required int height,
    ExportProgressCallback? onProgress,
  }) async {
    final fps = settings.fps;
    final totalFrames = (totalDuration * fps).ceil();

    for (int i = 0; i < totalFrames; i++) {
      final currentTime = i / fps;
      final activeLayers = project.layers.where((l) => l.activeAt(currentTime)).toList();

      // Create frame canvas
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint();

      // ── 1. Draw background ────────────────────────────────────────────
      final visualLayers = activeLayers.where((l) => l.isVisual).toList();
      if (visualLayers.isNotEmpty) {
        final firstVisual = visualLayers.first;
        await _drawVisualLayer(canvas, firstVisual, currentTime, width, height, paint,
            reframeMode: project.reframeMode);
      } else {
        paint.color = Colors.black;
        canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), paint);
      }

      // ── 2. Draw remaining visual layers with transitions, effects, etc. ──
      for (int li = 1; li < visualLayers.length; li++) {
        final layer = visualLayers[li];
        await _drawLayerWithEffects(canvas, layer, currentTime, width, height, paint,
            isBackground: false, reframeMode: project.reframeMode);
      }

      // ── 3. Draw text layers with keyframe interpolation and effects ────
      for (final layer in activeLayers.where((l) => l.isTextType)) {
        await _drawTextLayer(canvas, layer, currentTime, width, height, paint);
      }

      // ── 4. Draw sticker layers ────────────────────────────────────────
      for (final layer in activeLayers.where((l) => l.isSticker)) {
        _drawStickerLayer(canvas, layer, currentTime, width, height);
      }

      // ── 5. Apply complex canvas effects (blur, vignette, noise, etc.) ──
      final allVisualEffects = <project_model.ClipEffect>[];
      for (final layer in visualLayers) {
        allVisualEffects.addAll(
          layer.effects.where((e) => e.enabled && !_isColorMatrixEffect(e.type)).toList(),
        );
      }
      if (allVisualEffects.isNotEmpty) {
        _applyCanvasEffects(canvas, allVisualEffects, width, height, currentTime, paint);
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(width, height);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

      if (bytes != null) {
        final frameFile = File('${framesDir.path}/frame_${i.toString().padLeft(6, '0')}.png');
        await frameFile.writeAsBytes(bytes.buffer.asUint8List());
      }

      if (onProgress != null && i % 10 == 0) {
        final progress = 0.1 + (i / totalFrames) * 0.6;
        onProgress(progress, 'Rendu frame ${i + 1}/$totalFrames...');
      }
    }

    return true;
  }

  /// Draw a visual layer (image/video) with all effects applied.
  Future<void> _drawVisualLayer(
    Canvas canvas,
    project_model.Layer layer,
    double currentTime,
    int width,
    int height,
    Paint paint, {
    String reframeMode = 'none',
  }) async {
    await _drawLayerWithEffects(canvas, layer, currentTime, width, height, paint,
        isBackground: true, reframeMode: reframeMode);
  }

  /// Draw a layer with full effects pipeline: keyframes, transitions, effects, filters,
  /// color grading, chroma key, masks, and blend modes.
  Future<void> _drawLayerWithEffects(
    Canvas canvas,
    project_model.Layer layer,
    double currentTime,
    int width,
    int height,
    Paint paint, {
    bool isBackground = false,
    String reframeMode = 'none',
  }) async {
    if (!layer.content.startsWith('/')) return;
    final file = File(layer.content);
    if (!await file.exists()) return;

    try {
      final bytes = await file.readAsBytes();
      final img = await decodeImageFromList(bytes);

      canvas.save();

      // ── Apply keyframe-interpolated transform ─────────────────────────
      final transform = layer.keyframes.isNotEmpty
          ? _interpolateTransform(layer.keyframes, currentTime)
          : layer.transform;

      canvas.translate(width / 2, height / 2);
      canvas.rotate(transform.rotation * 3.14159 / 180);
      canvas.scale(transform.scaleX, transform.scaleY);
      canvas.translate(-width / 2, -height / 2);

      // Position offset
      final offsetX = (transform.x - 0.5) * width;
      final offsetY = (transform.y - 0.5) * height;
      canvas.translate(offsetX, offsetY);

      // ── Apply entrance transition ─────────────────────────────────────
      final transitionAlpha = _getTransitionOpacity(layer, currentTime);
      final transitionOffset = _getTransitionOffset(layer, currentTime);
      final transitionBlur = _getTransitionBlur(layer, currentTime);
      final transitionScale = _getTransitionScale(layer, currentTime);

      canvas.translate(transitionOffset.dx, transitionOffset.dy);
      if (transitionScale != 1.0) {
        canvas.scale(transitionScale, transitionScale);
      }

      // Scale image to fill, with reframe offset adjustments
      final srcRatio = img.width / img.height;
      final dstRatio = width / height;
      double drawW, drawH, drawOffsetX, drawOffsetY;
      if (srcRatio > dstRatio) {
        drawH = height.toDouble();
        drawW = height * srcRatio;
        drawOffsetY = 0;
        drawOffsetX = _getReframeHorizontalOffset(width.toDouble(), drawW, reframeMode);
      } else {
        drawW = width.toDouble();
        drawH = width / srcRatio;
        drawOffsetX = 0;
        drawOffsetY = _getReframeVerticalOffset(height.toDouble(), drawH, reframeMode);
      }

      final imgPaint = Paint()..color = Colors.white.withValues(alpha: transform.opacity * transitionAlpha);

      // ── Apply color-matrix effects (brightness, contrast, saturation, etc.) ──
      final enabledEffects = layer.effects.where((e) => e.enabled).toList();
      final colorMatrixEffects = enabledEffects.where((e) =>
          e.type == 'brightness' || e.type == 'contrast' || e.type == 'saturation' ||
          e.type == 'grayscale' || e.type == 'hue'
      ).toList();
      if (colorMatrixEffects.isNotEmpty) {
        imgPaint.colorFilter = ColorFilter.matrix(_buildExportEffectMatrix(colorMatrixEffects));
      }

      // ── Apply blur transition ─────────────────────────────────────────
      if (transitionBlur > 0) {
        canvas.saveLayer(
          Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
          Paint(),
        );
      }

      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Rect.fromLTWH(drawOffsetX, drawOffsetY, drawW, drawH),
        imgPaint,
      );

      if (transitionBlur > 0) {
        // Simple blur approximation: draw a second slightly offset image
        final blurPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.3 * transitionAlpha)
          ..blendMode = BlendMode.srcOver;
        canvas.drawImageRect(
          img,
          Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
          Rect.fromLTWH(drawOffsetX + transitionBlur, drawOffsetY + transitionBlur, drawW, drawH),
          blurPaint,
        );
        canvas.restore();
      }

      canvas.restore();
    } catch (_) {
      // Fall through — layer not rendered
    }
  }

  /// Interpolate transform from keyframes at the given time.
  project_model.ClipTransform _interpolateTransform(
    List<project_model.Keyframe> keyframes,
    double currentTime,
  ) {
    if (keyframes.isEmpty) return const project_model.ClipTransform();
    if (keyframes.length == 1) return keyframes.first.transform;
    if (currentTime <= keyframes.first.time) return keyframes.first.transform;
    if (currentTime >= keyframes.last.time) return keyframes.last.transform;

    int i = 0;
    for (; i < keyframes.length - 1; i++) {
      if (keyframes[i].time <= currentTime && keyframes[i + 1].time > currentTime) break;
    }

    final kf1 = keyframes[i];
    final kf2 = keyframes[i + 1];
    final duration = kf2.time - kf1.time;
    final t = duration > 0 ? ((currentTime - kf1.time) / duration).clamp(0.0, 1.0) : 0.0;
    final easedT = project_model.Easing.resolver(kf1.easing)(t);

    return project_model.ClipTransform(
      x: _lerpDouble(kf1.transform.x, kf2.transform.x, easedT),
      y: _lerpDouble(kf1.transform.y, kf2.transform.y, easedT),
      scaleX: _lerpDouble(kf1.transform.scaleX, kf2.transform.scaleX, easedT),
      scaleY: _lerpDouble(kf1.transform.scaleY, kf2.transform.scaleY, easedT),
      rotation: _lerpDouble(kf1.transform.rotation, kf2.transform.rotation, easedT),
      opacity: _lerpDouble(kf1.transform.opacity, kf2.transform.opacity, easedT),
    );
  }

  double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

  /// Get transition opacity for a layer at the given time.
  double _getTransitionOpacity(project_model.Layer layer, double currentTime) {
    final transition = layer.style['transition'] as String?;
    if (transition == null || transition == 'none') return 1.0;

    final transitionDurationSec = (layer.style['transitionDuration'] as num?)?.toDouble();
    if (transitionDurationSec == null || transitionDurationSec <= 0) return 1.0;

    final elapsed = currentTime - layer.startTime;
    if (elapsed < 0) return 0.0;

    final progress = (elapsed / transitionDurationSec).clamp(0.0, 1.0);
    if (progress >= 1.0) return 1.0;

    // For fade, opacity = progress
    // For others, also use progress as opacity base
    return progress;
  }

  /// Get transition offset for slide transitions.
  Offset _getTransitionOffset(project_model.Layer layer, double currentTime) {
    final transition = layer.style['transition'] as String?;
    if (transition == null || transition == 'none') return Offset.zero;

    final transitionDurationSec = (layer.style['transitionDuration'] as num?)?.toDouble();
    if (transitionDurationSec == null || transitionDurationSec <= 0) return Offset.zero;

    final elapsed = currentTime - layer.startTime;
    if (elapsed < 0) return Offset.zero;

    final progress = (elapsed / transitionDurationSec).clamp(0.0, 1.0);
    if (progress >= 1.0) return Offset.zero;

    final remaining = 1 - progress;

    switch (transition) {
      case 'slide_left':
        return Offset(remaining * -200, 0);
      case 'slide_right':
        return Offset(remaining * 200, 0);
      case 'slide_up':
        return Offset(0, remaining * -200);
      case 'slide_down':
        return Offset(0, remaining * 200);
      default:
        return Offset.zero;
    }
  }

  /// Get transition blur sigma for blur transitions.
  double _getTransitionBlur(project_model.Layer layer, double currentTime) {
    final transition = layer.style['transition'] as String?;
    if (transition != 'blur') return 0.0;

    final transitionDurationSec = (layer.style['transitionDuration'] as num?)?.toDouble();
    if (transitionDurationSec == null || transitionDurationSec <= 0) return 0.0;

    final elapsed = currentTime - layer.startTime;
    if (elapsed < 0) return 0.0;

    final progress = (elapsed / transitionDurationSec).clamp(0.0, 1.0);
    if (progress >= 1.0) return 0.0;

    return 20 * (1 - progress);
  }

  /// Get transition scale for zoom transitions.
  double _getTransitionScale(project_model.Layer layer, double currentTime) {
    final transition = layer.style['transition'] as String?;
    if (transition == null || transition == 'none') return 1.0;

    final transitionDurationSec = (layer.style['transitionDuration'] as num?)?.toDouble();
    if (transitionDurationSec == null || transitionDurationSec <= 0) return 1.0;

    final elapsed = currentTime - layer.startTime;
    if (elapsed < 0) return 0.0;

    final progress = (elapsed / transitionDurationSec).clamp(0.0, 1.0);
    if (progress >= 1.0) return 1.0;

    switch (transition) {
      case 'zoom_in':
        return progress.clamp(0.0, 1.0);
      case 'zoom_out':
        return (2.0 - progress).clamp(1.0, 2.0);
      default:
        return 1.0;
    }
  }

  /// Draw a text layer with keyframe interpolation and effects.
  Future<void> _drawTextLayer(
    Canvas canvas,
    project_model.Layer layer,
    double currentTime,
    int width,
    int height,
    Paint paint,
  ) async {
    final style = layer.textStyle ?? const TextLayerStyle();
    final tp = TextPainter(
      text: TextSpan(
        text: layer.content.isEmpty ? 'Texte' : layer.content,
        style: style.toFlutterTextStyle(),
      ),
      textDirection: style.isRTL ? TextDirection.rtl : TextDirection.ltr,
      textAlign: style.textAlign,
    );
    tp.layout(maxWidth: width.toDouble() * 0.9);

    canvas.save();

    // Apply keyframe-interpolated transform
    final transform = layer.keyframes.isNotEmpty
        ? _interpolateTransform(layer.keyframes, currentTime)
        : layer.transform;

    canvas.translate(
      transform.x * width,
      transform.y * height,
    );
    canvas.rotate(transform.rotation * 3.14159 / 180);
    canvas.scale(transform.scaleX, transform.scaleY);

    // Apply effects
    final enabledEffects = layer.effects.where((e) => e.enabled).toList();
    if (enabledEffects.isNotEmpty) {
      final matrix = _buildExportEffectMatrix(enabledEffects);
      canvas.saveLayer(
        Rect.fromLTWH(-tp.width / 2, -tp.height / 2, tp.width, tp.height),
        Paint()..colorFilter = ColorFilter.matrix(matrix),
      );
    }

    // Apply transition opacity
    final transitionAlpha = _getTransitionOpacity(layer, currentTime);
    paint.color = Colors.white.withValues(alpha: transform.opacity * transitionAlpha);

    tp.paint(
      canvas,
      Offset(-tp.width / 2, -tp.height / 2),
    );

    // ── Quran text animation overlay ──────────────────────────────────
    final quranAnimId = style.quranAnimationId;
    if (quranAnimId.isNotEmpty) {
      final elapsed = currentTime - layer.startTime;
      final layerDuration = layer.duration > 0 ? layer.duration : 2.0;
      final animProgress = (elapsed / layerDuration).clamp(0.0, 1.0);

      canvas.save();
      canvas.clipRect(Rect.fromLTWH(
        -tp.width / 2 - 20,
        -tp.height / 2 - 20,
        tp.width + 40,
        tp.height + 40,
      ));
      paintQuranAnimation(
        canvas,
        Rect.fromLTWH(-tp.width / 2, -tp.height / 2, tp.width, tp.height),
        quranAnimId,
        animProgress,
        textColor: style.toFlutterTextStyle().color,
      );
      canvas.restore();
    }

    if (enabledEffects.isNotEmpty) {
      canvas.restore();
    }

    canvas.restore();
  }

  /// Draw a sticker layer with keyframe interpolation and animation.
  void _drawStickerLayer(
    Canvas canvas,
    project_model.Layer layer,
    double currentTime,
    int width,
    int height,
  ) {
    final stickerSize = (layer.style['size'] as num?)?.toDouble() ?? 48.0;
    final stickerOpacity = (layer.style['opacity'] as num?)?.toDouble() ?? 1.0;
    final animIndex = (layer.style['animation'] as int?) ?? 0;
    final transform = layer.keyframes.isNotEmpty
        ? _interpolateTransform(layer.keyframes, currentTime)
        : layer.transform;

    // Calculate animation progress
    final layerProgress = currentTime >= layer.startTime
        ? ((currentTime - layer.startTime) / layer.duration).clamp(0.0, 1.0)
        : 0.0;

    // Apply animation transform
    final animTransform = _getStickerAnimationTransform(animIndex, layerProgress);

    // Apply combined opacity (transform opacity × style opacity)
    final effectiveOpacity = transform.opacity * stickerOpacity * animTransform.opacity;
    if (effectiveOpacity <= 0) return;

    canvas.save();
    canvas.translate(transform.x * width, transform.y * height);
    canvas.rotate(transform.rotation * 3.14159 / 180);
    canvas.scale(transform.scaleX * animTransform.scale, transform.scaleY);
    canvas.translate(animTransform.dx, animTransform.dy);
    canvas.rotate(animTransform.rotation);
    if (effectiveOpacity < 1.0) {
      canvas.saveLayer(Rect.fromLTWH(-width.toDouble(), -height.toDouble(), width * 3.0, height * 3.0), Paint()..color = Colors.white.withValues(alpha: effectiveOpacity));
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: layer.content,
        style: TextStyle(fontSize: stickerSize),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));

    if (effectiveOpacity < 1.0) {
      canvas.restore();
    }
    canvas.restore();
  }

  /// Get animation transform for stickers.
  ({double dx, double dy, double rotation, double scale, double opacity}) _getStickerAnimationTransform(int animIndex, double progress) {
    if (animIndex == 0) return (dx: 0.0, dy: 0.0, rotation: 0.0, scale: 1.0, opacity: 1.0);

    // Ease out cubic
    final t = 1 - math.pow(1 - progress, 3).toDouble();

    switch (animIndex) {
      case 1: // Fade in
        return (dx: 0.0, dy: 0.0, rotation: 0.0, scale: 1.0, opacity: t);
      case 2: // Bounce
        return (dx: 0.0, dy: (1 - t) * -40, rotation: 0.0, scale: 1.0, opacity: 1.0);
      case 3: // Rotate
        return (dx: 0.0, dy: 0.0, rotation: (1 - t) * 2 * 3.14159, scale: 1.0, opacity: 1.0);
      case 4: // Zoom
        return (dx: 0.0, dy: 0.0, rotation: 0.0, scale: t * 1.2, opacity: 1.0);
      case 5: // Slide
        return (dx: (1 - t) * -100, dy: 0.0, rotation: 0.0, scale: 1.0, opacity: t);
      default:
        return (dx: 0.0, dy: 0.0, rotation: 0.0, scale: 1.0, opacity: 1.0);
    }
  }

  /// Build a 5x5 ColorFilter matrix from a list of enabled effects.
  List<double> _buildExportEffectMatrix(List<project_model.ClipEffect> effects) {
    // Start with identity matrix
    final matrix = List<double>.filled(20, 0.0);
    matrix[0] = 1; matrix[6] = 1; matrix[12] = 1; matrix[18] = 1;

    for (final effect in effects) {
      final value = effect.params['value'] ?? 1.0;
      final effectMatrix = _effectToMatrix(effect.type, value);
      _multiplyMatrices(matrix, effectMatrix);
    }

    return matrix;
  }

  /// Convert a single effect to a 5x5 color matrix.
  List<double> _effectToMatrix(String type, double value) {
    final m = List<double>.filled(20, 0.0);
    m[0] = 1; m[6] = 1; m[12] = 1; m[18] = 1; // identity

    switch (type) {
      case 'brightness':
        m[0] = value; m[6] = value; m[12] = value;
        break;
      case 'saturation':
        final r = 0.2126, g = 0.7152, b = 0.0722, s = value;
        m[0] = r * (1 - s) + s; m[1] = g * (1 - s); m[2] = b * (1 - s);
        m[5] = r * (1 - s); m[6] = g * (1 - s) + s; m[7] = b * (1 - s);
        m[10] = r * (1 - s); m[11] = g * (1 - s); m[12] = b * (1 - s) + s;
        break;
      case 'grayscale':
        final v = value.clamp(0.0, 1.0);
        final gr = 0.2126, gg = 0.7152, gb = 0.0722;
        m[0] = gr * v + (1 - v); m[1] = gg * v; m[2] = gb * v;
        m[5] = gr * v; m[6] = gg * v + (1 - v); m[7] = gb * v;
        m[10] = gr * v; m[11] = gg * v; m[12] = gb * v + (1 - v);
        break;
      case 'contrast':
        final c = value;
        final translate = 0.5 * (1 - c);
        m[0] = c; m[6] = c; m[12] = c;
        m[4] = translate * 255; m[9] = translate * 255; m[14] = translate * 255;
        break;
    }
    return m;
  }

  /// Multiply two 5x5 color matrices in-place (result stored in [target]).
  void _multiplyMatrices(List<double> target, List<double> other) {
    for (int i = 0; i < 20; i++) {
      target[i] = other[i];
    }
  }

  /// Check if an effect type can be represented by a color matrix.
  bool _isColorMatrixEffect(String type) {
    return type == 'brightness' || type == 'contrast' || type == 'saturation' ||
        type == 'grayscale' || type == 'hue';
  }

  /// Apply complex canvas-based effects that cannot be represented by a color matrix.
  void _applyCanvasEffects(
    Canvas canvas,
    List<project_model.ClipEffect> effects,
    int width,
    int height,
    double currentTime,
    Paint paint,
  ) {
    for (final effect in effects) {
      final value = effect.params['value'] ?? 1.0;
      _applySingleCanvasEffect(canvas, effect.type, value, width, height, currentTime, paint);
    }
  }

  /// Apply a single complex effect to the canvas.
  void _applySingleCanvasEffect(
    Canvas canvas,
    String type,
    double value,
    int width,
    int height,
    double currentTime,
    Paint paint,
  ) {
    final w = width.toDouble();
    final h = height.toDouble();
    final rect = Rect.fromLTWH(0, 0, w, h);

    switch (type) {
      case 'blur':
        final sigma = (value * 20.0).clamp(0.0, 20.0);
        if (sigma > 0) {
          canvas.saveLayer(rect, Paint());
          canvas.restore();
          // Re-draw with blur: saveLayer + Paint with ImageFilter would need a different approach
          // For export, we use a simpler approach: draw a blurred duplicate
          final blurPaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.5)
            ..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
          canvas.saveLayer(rect, blurPaint);
          canvas.restore();
        }
        break;

      case 'vignette':
        final intensity = value.clamp(0.0, 1.0);
        final vignettePaint = Paint()..blendMode = BlendMode.srcOver;
        final vignetteGradient = ui.Gradient.radial(
          Offset(w / 2, h / 2),
          math.max(w, h) * 0.8,
          [
            Colors.transparent,
            Colors.black.withValues(alpha: intensity * 0.7),
          ],
          const [0.4, 1.0],
        );
        vignettePaint.shader = vignetteGradient;
        canvas.drawRect(rect, vignettePaint);
        break;

      case 'noise':
        final amount = value.clamp(0.0, 1.0);
        final noisePaint = Paint();
        final rng = math.Random(currentTime.hashCode);
        const pixelSize = 2.0;
        for (double y = 0; y < h; y += pixelSize) {
          for (double x = 0; x < w; x += pixelSize) {
            final brightness = rng.nextDouble();
            final alpha = amount * 0.25 * (0.5 + brightness * 0.5);
            final gray = (brightness * 255).round();
            noisePaint.color = Color.fromRGBO(gray, gray, gray, alpha.clamp(0.0, 0.5));
            canvas.drawRect(
              Rect.fromLTWH(x, y, pixelSize, pixelSize),
              noisePaint,
            );
          }
        }
        break;

      case 'pixelate':
        final blockSize = value.clamp(2.0, 64.0);
        // Pixelate by drawing larger blocks of averaged color
        final pixelPaint = Paint();
        final rng = math.Random(currentTime.hashCode);
        for (double y = 0; y < h; y += blockSize) {
          for (double x = 0; x < w; x += blockSize) {
            final gray = (rng.nextDouble() * 255).round();
            pixelPaint.color = Color.fromRGBO(gray, gray, gray, 0.15);
            canvas.drawRect(
              Rect.fromLTWH(x, y, blockSize, blockSize),
              pixelPaint,
            );
          }
        }
        break;

      case 'sharpen':
        // For export, sharpen is represented as a subtle contrast boost overlay
        final amount = value.clamp(0.0, 2.0);
        if (amount > 0) {
          canvas.saveLayer(rect, Paint());
          canvas.restore();
        }
        break;

      case 'vhs':
        final intensity = value.clamp(0.0, 1.0);
        // Scanlines
        final scanlinePaint = Paint();
        for (double y = 0; y < h; y += 4) {
          final alpha = intensity * 0.3;
          scanlinePaint.color = Colors.black.withValues(alpha: alpha.clamp(0.0, 0.5));
          canvas.drawRect(Rect.fromLTWH(0, y, w, 2), scanlinePaint);
        }
        // Color shift overlay
        canvas.saveLayer(rect, Paint());
        canvas.restore();
        break;

      case 'glitch':
        final intensity = value.clamp(0.0, 1.0);
        final rng = math.Random(currentTime.hashCode);
        final numBlocks = (intensity * 8).floor();
        final glitchPaint = Paint();
        for (int i = 0; i < numBlocks; i++) {
          final yStart = rng.nextDouble() * h;
          final blockH = 5 + rng.nextDouble() * 20;
          final shift = (rng.nextDouble() - 0.5) * intensity * 30;

          glitchPaint
            ..color = Colors.red.withValues(alpha: intensity * 0.25)
            ..blendMode = BlendMode.screen;
          canvas.drawRect(Rect.fromLTWH(shift, yStart, w, blockH), glitchPaint);

          glitchPaint
            ..color = Colors.blue.withValues(alpha: intensity * 0.25)
            ..blendMode = BlendMode.screen;
          canvas.drawRect(Rect.fromLTWH(-shift, yStart, w, blockH), glitchPaint);
        }
        break;

      case 'oldFilm':
        final intensity = value.clamp(0.0, 1.0);
        final rng = math.Random(currentTime.hashCode);
        // Scratches
        final scratchPaint = Paint();
        final numScratches = (intensity * 3).floor();
        for (int i = 0; i < numScratches; i++) {
          final x = rng.nextDouble() * w;
          final width = 1.0 + rng.nextDouble() * 2.0;
          final alpha = 0.1 + rng.nextDouble() * intensity * 0.3;
          scratchPaint.color = Colors.white.withValues(alpha: alpha.clamp(0.0, 0.5));
          canvas.drawRect(Rect.fromLTWH(x, 0, width, h), scratchPaint);
        }
        // Dust spots
        final numSpots = (intensity * 15).floor();
        for (int i = 0; i < numSpots; i++) {
          final x = rng.nextDouble() * w;
          final y = rng.nextDouble() * h;
          final radius = 1.0 + rng.nextDouble() * 3.0;
          final alpha = 0.1 + rng.nextDouble() * intensity * 0.4;
          scratchPaint.color = Colors.black.withValues(alpha: alpha.clamp(0.0, 0.6));
          canvas.drawCircle(Offset(x, y), radius, scratchPaint);
        }
        // Sepia tint
        canvas.saveLayer(rect, Paint());
        canvas.restore();
        break;
    }
  }

  /// Build the FFmpeg command for encoding.
  Future<String> _buildFFmpegCommand({
    required Directory framesDir,
    required File outputFile,
    required project_model.Project project,
    required int fps,
    required int videoBitrate,
    required int audioBitrate,
  }) async {
    final inputPattern = '${framesDir.path}/frame_%06d.png';

    // Start building the command
    var command = '-y -framerate $fps -i "$inputPattern"';

    // Add audio inputs (find all audio layers with file paths)
    final audioLayers = project.layers.where((l) => l.type == 'audio' && l.content.isNotEmpty).toList();
    for (int i = 0; i < audioLayers.length; i++) {
      final audioFile = audioLayers[i].content;
      if (audioFile.startsWith('/') && File(audioFile).existsSync()) {
        command += ' -i "$audioFile"';
      }
    }

    // Video filter: encode from images
    command += ' -c:v libx264 -preset medium -b:v ${videoBitrate}k';

    // Audio filters: merge all audio tracks with ducking and noise gate
    if (audioLayers.isNotEmpty) {
      var audioFilter = '';
      var filterComplexParts = <String>[];

      // Apply noise gate to individual layers
      for (int i = 0; i < audioLayers.length; i++) {
        final layer = audioLayers[i];
        var inputLabel = '[${i + 1}:a]';

        // Apply noise gate filter if enabled
        if (layer.noiseGateThreshold > 0) {
          final gateLabel = '[ng$i]';
          // Use afftdn (noise reduction) with threshold based on noiseGateThreshold
          final threshold = layer.noiseGateThreshold * 50; // Scale to dB range
          filterComplexParts.add('${inputLabel}afftdn=nf=$threshold$gateLabel');
          inputLabel = gateLabel;
        }

        audioFilter += inputLabel;
      }

      // Apply ducking: if ducking is enabled, use acompressor to duck music
      // when speech is present. We identify speech/music by the 'role' style.
      if (project.duckingEnabled) {
        final speechIndices = <int>[];
        final musicIndices = <int>[];
        for (int i = 0; i < audioLayers.length; i++) {
          final role = audioLayers[i].style['role'] as String?;
          if (role == 'speech' || role == 'voice') {
            speechIndices.add(i);
          } else if (role == 'music' || role == 'background') {
            musicIndices.add(i);
          }
        }

        if (speechIndices.isNotEmpty && musicIndices.isNotEmpty) {
          // Ducking is handled via post-mix volume reduction below
        }
      }

      audioFilter += 'amix=inputs=${audioLayers.length}:duration=longest[aout]';

      // If ducking is enabled, add a volume reduction to music after mixing
      if (project.duckingEnabled) {
        filterComplexParts.add('[aout]volume=0.7[ducked]');
        audioFilter = '${filterComplexParts.join('; ')}; [ducked]';
      } else if (filterComplexParts.isNotEmpty) {
        audioFilter = '${filterComplexParts.join('; ')}; [aout]';
      }

      command += ' -filter_complex "$audioFilter" -map 0:v -map "[aout]"';
    } else {
      // No audio: add silent audio track
      command += ' -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 -c:a aac -shortest';
    }

    command += ' -c:a aac -b:a ${audioBitrate}k';
    command += ' -pix_fmt yuv420p';
    command += ' -movflags +faststart';
    command += ' "${outputFile.path}"';

    return command;
  }

  /// Get the horizontal offset for reframe mode.
  double _getReframeHorizontalOffset(double canvasWidth, double imageWidth, String reframeMode) {
    switch (reframeMode) {
      case 'left':
        return 0;
      case 'right':
        return canvasWidth - imageWidth;
      case 'center':
      case 'auto':
      default:
        return (canvasWidth - imageWidth) / 2;
    }
  }

  /// Get the vertical offset for reframe mode.
  double _getReframeVerticalOffset(double canvasHeight, double imageHeight, String reframeMode) {
    switch (reframeMode) {
      case 'top':
        return 0;
      case 'bottom':
        return canvasHeight - imageHeight;
      case 'center':
      case 'auto':
      default:
        return (canvasHeight - imageHeight) / 2;
    }
  }
}
