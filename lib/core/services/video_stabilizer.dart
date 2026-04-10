import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

/// Service for video stabilization using FFmpeg's vidstabdetect + vidstabtransform filters.
///
/// Uses a two-pass approach:
/// 1. Detect transforms (vidstabdetect) - analyzes shakiness and writes transform data
/// 2. Apply stabilization (vidstabtransform) - applies smoothing based on detected transforms
class VideoStabilizer {
  /// Stabilize a shaky video file.
  ///
  /// [inputPath] - path to the input video file
  /// [outputPath] - path for the stabilized output file
  /// [shakiness] - how shaky the video is (1-10, default 5)
  /// [accuracy] - detection accuracy (1-15, default 15)
  /// [smoothing] - number of frames for smoothing (default 10)
  /// [onProgress] - optional progress callback (0.0 to 1.0)
  ///
  /// Returns the output path on success, null on failure.
  static Future<String?> stabilize(String inputPath, String outputPath, {
    int shakiness = 5,
    int accuracy = 15,
    int smoothing = 10,
    void Function(double progress, String message)? onProgress,
  }) async {
    try {
      final inputFile = File(inputPath);
      if (!await inputFile.exists()) {
        onProgress?.call(0.0, 'Video file not found');
        return null;
      }

      // Use a temporary directory for the transform file
      final tempDir = Directory.systemTemp;
      final trfPath = '${tempDir.path}/transforms_${DateTime.now().millisecondsSinceEpoch}.trf';

      // Pass 1: Detect transforms
      onProgress?.call(0.0, 'Analyzing video shakiness...');
      final detectCmd = '-y -i "${_escapePath(inputPath)}" -vf vidstabdetect=shakiness=$shakiness:accuracy=$accuracy:result="${_escapePath(trfPath)}" -f null -';
      final detectSession = await FFmpegKit.execute(detectCmd);
      final detectReturnCode = await detectSession.getReturnCode();

      if (!ReturnCode.isSuccess(detectReturnCode)) {
        onProgress?.call(0.0, 'Transform detection failed');
        return null;
      }

      // Check if transforms were detected
      final trfFile = File(trfPath);
      if (!await trfFile.exists()) {
        onProgress?.call(0.0, 'No shakiness detected - video is already stable');
        return null;
      }
      final trfBytes = await trfFile.readAsBytes();
      if (trfBytes.isEmpty) {
        onProgress?.call(0.0, 'No shakiness detected - video is already stable');
        return null;
      }

      // Pass 2: Apply stabilization
      onProgress?.call(0.5, 'Applying stabilization...');
      final transformCmd = '-y -i "${_escapePath(inputPath)}" -vf vidstabtransform=smoothing=$smoothing:input="${_escapePath(trfPath)}" -c:a copy "${_escapePath(outputPath)}"';
      final transformSession = await FFmpegKit.execute(transformCmd);
      final transformReturnCode = await transformSession.getReturnCode();

      // Cleanup transform file
      if (await trfFile.exists()) {
        await trfFile.delete();
      }

      if (ReturnCode.isSuccess(transformReturnCode)) {
        final outputFile = File(outputPath);
        if (await outputFile.exists()) {
          onProgress?.call(1.0, 'Stabilization complete');
          return outputPath;
        }
      }

      onProgress?.call(0.0, 'Stabilization failed');
      return null;
    } catch (e) {
      onProgress?.call(0.0, 'Error: $e');
      return null;
    }
  }

  /// Escape a file path for use in FFmpeg command.
  static String _escapePath(String path) {
    return path.replaceAll('"', '\\"');
  }
}
