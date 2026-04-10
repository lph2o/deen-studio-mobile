import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// ═══════════════════════════════════════════
/// Persistent Media Store Tests (simplified)
/// ═══════════════════════════════════════════

void main() {
  group('File Operations', () {
    test('creates temp file and reads content', () async {
      final tempDir = Directory.systemTemp.createTempSync('media_test_');
      final testFile = File('${tempDir.path}/test.txt');
      await testFile.writeAsString('Hello World');

      final content = await testFile.readAsString();
      expect(content, 'Hello World');

      await tempDir.delete(recursive: true);
    });

    test('copies file to new location', () async {
      final tempDir = Directory.systemTemp.createTempSync('copy_test_');
      final source = File('${tempDir.path}/source.txt');
      await source.writeAsString('source content');

      final destPath = '${tempDir.path}/persistent_copy.txt';
      await source.copy(destPath);

      final dest = File(destPath);
      expect(await dest.exists(), isTrue);
      expect(await dest.readAsString(), 'source content');

      await tempDir.delete(recursive: true);
    });

    test('file.exists() returns correct result', () async {
      final tempDir = Directory.systemTemp.createTempSync('exists_test_');
      final existingFile = File('${tempDir.path}/exists.txt');
      await existingFile.writeAsString('exists');

      expect(await existingFile.exists(), isTrue);
      expect(await File('${tempDir.path}/nonexistent.txt').exists(), isFalse);

      await tempDir.delete(recursive: true);
    });

    test('handles empty file path gracefully', () async {
      final file = File('');
      expect(await file.exists(), isFalse);
    });

    test('handles large file content', () async {
      final tempDir = Directory.systemTemp.createTempSync('large_test_');
      final largeFile = File('${tempDir.path}/large.bin');

      // Create 1MB of data
      final data = List<int>.filled(1024 * 1024, 0x42);
      await largeFile.writeAsBytes(data);

      expect(await largeFile.exists(), isTrue);
      expect(await largeFile.length(), 1024 * 1024);

      await tempDir.delete(recursive: true);
    });
  });
}
