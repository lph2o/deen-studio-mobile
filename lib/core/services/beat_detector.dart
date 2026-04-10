import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

/// Detects audio beats using FFmpeg's astats filter to extract RMS energy levels,
/// then applies a peak-detection algorithm to find beat timestamps.
class BeatDetector {
  /// Analyzes audio and returns list of beat timestamps (in seconds).
  ///
  /// Uses FFmpeg to extract per-frame RMS energy levels, then detects peaks
  /// where the energy significantly exceeds a rolling average threshold.
  static Future<List<double>> detectBeats(String audioFilePath) async {
    final file = File(audioFilePath);
    if (!await file.exists()) {
      return _defaultBeats();
    }

    try {
      // Use FFmpeg astats + ametadata to extract RMS levels
      final command =
          '-i "$audioFilePath" -af "astats=metadata=1:reset=1,ametadata=print:key=lavfi.astats.1.RMS_level:file=-" -f null -';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode)) {
        return _defaultBeats();
      }

      final logs = await session.getLogsAsString();
      if (logs.isEmpty) {
        return _defaultBeats();
      }

      final rmsLevels = _parseRmsLevels(logs);
      if (rmsLevels.isEmpty) {
        return _defaultBeats();
      }

      return _detectPeaks(rmsLevels);
    } catch (e) {
      return _defaultBeats();
    }
  }

  /// Parse RMS level values from FFmpeg ametadata output.
  /// Output lines look like: "lavfi.astats.1.RMS_level=-12.345"
  static List<double> _parseRmsLevels(String output) {
    final levels = <double>[];
    final lines = output.split('\n');
    final pattern = RegExp(r'lavfi\.astats\.\d+\.RMS_level=(-?[\d.]+)');

    for (final line in lines) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        final value = double.tryParse(match.group(1)!);
        if (value != null) {
          // RMS is in dB (negative), convert to positive energy
          levels.add((-value).clamp(0.0, 100.0));
        }
      }
    }

    return levels;
  }

  /// Detect peaks in the RMS energy curve using a rolling average threshold.
  /// A peak is detected when energy exceeds `rollingAvg * (1 + sensitivity)`.
  static List<double> _detectPeaks(List<double> rmsLevels,
      {double sensitivity = 0.3, int windowSize = 10, int minGap = 5}) {
    if (rmsLevels.length < windowSize * 2) {
      return _defaultBeats();
    }

    final beatIndices = <int>[];
    int lastBeatIndex = -minGap;

    for (int i = windowSize; i < rmsLevels.length - windowSize; i++) {
      // Calculate rolling average energy in the window
      double sum = 0;
      int count = 0;
      for (int j = i - windowSize; j <= i + windowSize; j++) {
        if (j >= 0 && j < rmsLevels.length) {
          sum += rmsLevels[j];
          count++;
        }
      }
      final avg = sum / count;

      // Detect peak: current value significantly above average
      if (rmsLevels[i] > avg * (1 + sensitivity) && i - lastBeatIndex >= minGap) {
        beatIndices.add(i);
        lastBeatIndex = i;
      }
    }

    // Convert indices to timestamps
    // FFmpeg astats with reset=1 outputs one value per frame
    // Assuming ~10ms per frame at default analysis
    const frameDuration = 0.01; // 10ms per analysis window
    final beats = beatIndices.map((i) => i * frameDuration).toList();

    if (beats.isEmpty) {
      return _defaultBeats();
    }

    return beats;
  }

  /// Fallback: return simulated beats every 0.5 seconds (120 BPM default).
  static List<double> _defaultBeats() {
    final beats = <double>[];
    for (double t = 0.5; t < 300; t += 0.5) {
      beats.add(t);
    }
    return beats;
  }

  /// Find the nearest beat timestamp to the given time.
  static double snapToBeat(double time, List<double> beats, {double threshold = 0.3}) {
    if (beats.isEmpty) return time;

    double closest = time;
    double minDist = threshold;

    for (final beat in beats) {
      final dist = (time - beat).abs();
      if (dist < minDist) {
        minDist = dist;
        closest = beat;
      }
    }

    return closest;
  }
}
