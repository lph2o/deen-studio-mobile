import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:deen_studio_01/core/services/persistent_media_store.dart';

/// Service for video manipulation operations (freeze frame, reverse, etc.)
class VideoToolService {

  /// Extract a single frame from a video at the given timestamp and save it as PNG.
  ///
  /// Returns the path to the extracted frame image, or null on failure.
  static Future<String?> freezeFrame({
    required String videoPath,
    required double timestamp,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestampMs = (timestamp * 1000).toInt();
      final tempFile = File('${tempDir.path}/freeze_frame_$timestampMs.png');

      // Delete existing file if present
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      final session = await FFmpegKit.execute(
        '-y -i "${_escapePath(videoPath)}" -ss $timestamp -frames:v 1 "${_escapePath(tempFile.path)}"',
      );
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode) && await tempFile.exists()) {
        // Copy to persistent storage
        return await PersistentMediaStore.persistFile(tempFile.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Reverse a video file (video + audio) and save the result.
  ///
  /// Returns the path to the reversed video, or null on failure.
  /// Reports progress via the [onProgress] callback (0.0 to 1.0).
  static Future<String?> reverseVideo({
    required String videoPath,
    void Function(double progress, String message)? onProgress,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${tempDir.path}/reversed_$timestamp.mp4');

      // Delete existing file if present
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      onProgress?.call(0.0, 'Inversion de la video...');

      // FFmpeg reverse command: vf reverse for video, af areverse for audio
      final session = await FFmpegKit.execute(
        '-y -i "${_escapePath(videoPath)}" -vf reverse -af areverse "${_escapePath(tempFile.path)}"',
      );
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode) && await tempFile.exists()) {
        onProgress?.call(1.0, 'Video inversee avec succes');
        return await PersistentMediaStore.persistFile(tempFile.path);
      } else {
        // If audio reverse fails (no audio), try video-only reverse
        onProgress?.call(0.5, 'Audio indisponible, inversion video seule...');

        final session2 = await FFmpegKit.execute(
          '-y -i "${_escapePath(videoPath)}" -vf reverse -an "${_escapePath(tempFile.path)}"',
        );
        final returnCode2 = await session2.getReturnCode();

        if (ReturnCode.isSuccess(returnCode2) && await tempFile.exists()) {
          onProgress?.call(1.0, 'Video inversee avec succes (sans audio)');
          return await PersistentMediaStore.persistFile(tempFile.path);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Escape a file path for use in FFmpeg command (wrap in quotes, escape internal quotes).
  static String _escapePath(String path) {
    return path.replaceAll('"', '\\"');
  }
}
