import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// ═══════════════════════════════════════════
/// Persistent Media Storage Manager
/// ═══════════════════════════════════════════
///
/// Copies imported media to a persistent app directory
/// so files survive app restarts and OS temp cleanup.

class PersistentMediaStore {
  static Directory? _mediaDir;

  /// Get the persistent media directory (creates if needed)
  static Future<Directory> get mediaDir async {
    if (_mediaDir != null && await _mediaDir!.exists()) return _mediaDir!;

    final appDir = await getApplicationDocumentsDirectory();
    _mediaDir = Directory('${appDir.path}/deen_studio_media');
    if (!await _mediaDir!.exists()) {
      await _mediaDir!.create(recursive: true);
    }
    return _mediaDir!;
  }

  /// Copy a file to persistent storage and return the new path.
  /// If the source is already in the media dir, returns as-is.
  static Future<String> persistFile(String sourcePath) async {
    if (sourcePath.isEmpty) return sourcePath;

    final source = File(sourcePath);
    if (!await source.exists()) return sourcePath;

    // Check if already in persistent storage
    final destDir = await mediaDir;
    if (sourcePath.startsWith(destDir.path)) return sourcePath;

    // Generate unique filename
    final ext = sourcePath.split('.').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond % 10000;
    final fileName = 'media_${timestamp}_$random.$ext';
    final destPath = '${destDir.path}/$fileName';

    // Copy file
    await source.copy(destPath);
    return destPath;
  }

  /// Copy an in-memory byte array to persistent storage
  static Future<String> persistBytes(
    List<int> bytes,
    String extension,
  ) async {
    final destDir = await mediaDir;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond % 10000;
    final fileName = 'media_${timestamp}_$random.$extension';
    final destPath = '${destDir.path}/$fileName';

    final file = File(destPath);
    await file.writeAsBytes(bytes);
    return destPath;
  }

  /// Clean up media files older than [maxAgeDays] (default: 30 days)
  static Future<void> cleanupOldFiles({int maxAgeDays = 30}) async {
    final destDir = await mediaDir;
    if (!await destDir.exists()) return;

    final now = DateTime.now();
    await for (final entity in destDir.list()) {
      if (entity is File) {
        final stat = await entity.stat();
        final age = now.difference(stat.modified);
        if (age.inDays > maxAgeDays) {
          await entity.delete();
        }
      }
    }
  }

  /// Get total size of media directory in MB
  static Future<double> getStorageSizeMB() async {
    final destDir = await mediaDir;
    if (!await destDir.exists()) return 0;

    double totalBytes = 0;
    await for (final entity in destDir.list()) {
      if (entity is File) {
        final stat = await entity.stat();
        totalBytes += stat.size;
      }
    }
    return totalBytes / (1024 * 1024);
  }
}
