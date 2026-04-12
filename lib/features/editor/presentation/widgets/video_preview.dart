import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import '../../../../models/project.dart';
import '../../../../core/models/voice_effect.dart';
import '../../../../core/models/canvas_background.dart';
import '../../../../core/services/quran_animation_export.dart';
import '../../../../models/text_layer_style.dart';
import '../recitation/recitation_timing.dart';
import 'package:google_fonts/google_fonts.dart';
import '../editor_state.dart';

class _TextChunk {
  final String text;
  final double start;
  final double end;
  final List<dynamic>? wordTimings;

  _TextChunk({
    required this.text,
    required this.start,
    required this.end,
    this.wordTimings,
  });

  double get duration => end - start;
}

const double _kQuranTextHorizontalPadding = 16.0;

_TextChunk _pickChunkAtTime(List<_TextChunk> chunks, double time) {
  if (chunks.isEmpty) {
    return _TextChunk(text: '', start: 0, end: 0);
  }
  if (time <= chunks.first.start) return chunks.first;
  if (time >= chunks.last.end) return chunks.last;
  return chunks.firstWhere(
    (c) => time >= c.start && time < c.end,
    orElse: () => chunks.first,
  );
}

List<_TextChunk> _chunkWordTimings(
  List<dynamic> timings, {
  int wordsPerChunk = 10,
}) {
  if (timings.isEmpty) return [];
  final chunks = <_TextChunk>[];
  for (int i = 0; i < timings.length; i += wordsPerChunk) {
    final subset = timings.sublist(
      i,
      math.min(i + wordsPerChunk, timings.length),
    );
    if (subset.isEmpty) continue;
    final words = subset.map((w) => w['word'] as String).join(' ');
    final start = (subset.first['start'] as num).toDouble();
    final end = (subset.last['end'] as num).toDouble();
    chunks.add(
      _TextChunk(text: words, start: start, end: end, wordTimings: subset),
    );
  }
  return chunks;
}

List<_TextChunk> _chunkStringProportionally(
  String text,
  List<_TextChunk> refChunks,
) {
  if (refChunks.isEmpty || text.isEmpty) return [];
  final words = text.split(RegExp(r'\s+'));
  final chunks = <_TextChunk>[];
  final wordsPerRefChunk = (words.length / refChunks.length).ceil();

  if (wordsPerRefChunk <= 0) return chunks;

  for (int i = 0; i < refChunks.length; i++) {
    final ref = refChunks[i];
    final startIndex = math.min(i * wordsPerRefChunk, words.length);
    final endIndex = math.min((i + 1) * wordsPerRefChunk, words.length);
    if (startIndex >= words.length) break;
    final chunkWords = words.sublist(startIndex, endIndex).join(' ');
    chunks.add(_TextChunk(text: chunkWords, start: ref.start, end: ref.end));
  }
  return chunks;
}

class VideoPreview extends ConsumerStatefulWidget {
  const VideoPreview({super.key});

  @override
  ConsumerState<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends ConsumerState<VideoPreview>
    with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  String? _lastVideoPath;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentAudioPath;
  final Set<String> _failedAudioPaths = {};
  StreamSubscription<ProcessingState>? _processingStateSubscription;
  late Ticker _playbackTicker;
  ValueNotifier<double> get _playbackTime => ref.read(playbackTimeProvider);
  DateTime _lastEditorStateUpdateTime = DateTime.now();
  Timer? _syncThrottle;
  Timer? _playIconTimer;
  bool _showPlayIcon = false;
  final Map<String, AnimationController> _textAnimationControllers = {};
  final Map<String, double> _duckingVolumes = {};
  static const double _duckingAttack = 0.15;
  static const double _duckingRelease = 0.3;

  // Performance optimization state: tracking last applied values to avoid redundant bridge calls.
  double? _lastAppliedAudioVolume;
  double? _lastAppliedAudioSpeed;
  bool? _lastAppliedAudioPlaying;
  bool? _lastAppliedVideoPlaying;
  String? _preWarmingVideoPath;
  DateTime? _lastAudioSwitchAt;
  double _initialPlaybackTime = 0.0;

  // Drag state for canvas layers
  String? _draggingLayerId;
  Offset _dragStart = Offset.zero;
  Offset _layerStartOffset = Offset.zero;

  // Cinematic mode particle animation
  AnimationController? _cinematicController;
  late Animation<double> _cinematicAnimation;

  @override
  void initState() {
    super.initState();
    _processingStateSubscription = _audioPlayer.processingStateStream.listen((
      state,
    ) {
      if (state == ProcessingState.completed) {
        _currentAudioPath = null;
      }
    }, onError: (error) => debugPrint('[Audio] Player error: $error'));
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _initializeVideoController(),
    );

    // Cinematic particle controller — slow 8-second cycle
    _cinematicController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _cinematicAnimation = CurvedAnimation(
      parent: _cinematicController!,
      curve: Curves.linear,
    );

    _playbackTicker = createTicker(_onTick);
  }

  Future<void> _initializeVideoController() async {
    final state = ref.read(editorProvider);
    final project = state.currentProject;
    if (project == null) return;

    // Find either the active video OR the last one in the project
    final activeVideo = project.layers
        .where((l) => l.type == 'video' && l.activeAt(state.currentTime))
        .lastOrNull;
    final lastVideo = project.layers
        .where((l) => l.type == 'video' && l.content.isNotEmpty)
        .lastOrNull;
    final targetVideo = activeVideo ?? lastVideo;

    if (targetVideo == null) return;
    await _initializeVideoControllerByPath(targetVideo.content);
  }

  Future<void> _initializeVideoControllerByPath(String path) async {
    if (_lastVideoPath == path &&
        _videoController != null &&
        _videoController!.value.isInitialized) {
      return;
    }
    try {
      final file = File(path);
      if (!await file.exists()) {
        debugPrint('[VideoSync] File not found for pre-warm: $path');
        return;
      }

      final newController = VideoPlayerController.file(
        file,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await newController.initialize();
      // Ensure the video player never competes with our isolated just_audio engine
      await newController.setVolume(0.0);

      final oldController = _videoController;
      _lastVideoPath = path;
      _videoController = newController;
      _isVideoInitialized = true;
      _lastAppliedVideoPlaying =
          null; // Reset playback tracking for new content

      if (mounted) setState(() {});

      await Future.delayed(const Duration(milliseconds: 100));
      await oldController?.dispose();
    } catch (e) {
      debugPrint('[VideoSync] Initialization failed: $e');
    }
  }

  @override
  void dispose() {
    _playbackTicker.dispose();
    _syncThrottle?.cancel();
    _playIconTimer?.cancel();
    _processingStateSubscription?.cancel();
    _audioPlayer.dispose();
    _videoController?.dispose();
    _cinematicController?.dispose();
    for (final controller in _textAnimationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double _resolveRecitationTime({
    required double fallbackTimelineTime,
    required List<Layer> allLayers,
  }) {
    final audioLayers = allLayers.where((l) => l.type == 'audio').toList();
    if (audioLayers.isEmpty) return fallbackTimelineTime;

    Layer? anchor;
    if (_currentAudioPath != null) {
      anchor = audioLayers.firstWhere(
        (l) => l.content == _currentAudioPath,
        orElse: () => Layer(
          id: '',
          type: '',
          content: '',
          startTime: 0,
          duration: 0,
          style: const {},
        ),
      );
      if (anchor.id.isEmpty) {
        anchor = null;
      }
    }

    anchor ??= audioLayers.firstWhere(
      (l) => l.activeAt(fallbackTimelineTime),
      orElse: () => Layer(
        id: '',
        type: '',
        content: '',
        startTime: 0,
        duration: 0,
        style: const {},
      ),
    );
    if (anchor.id.isEmpty) return fallbackTimelineTime;

    final ready =
        _audioPlayer.processingState == ProcessingState.ready ||
        _audioPlayer.processingState == ProcessingState.completed;
    final sourceMatches = _currentAudioPath == anchor.content;

    return RecitationTiming.computeEffectiveRecitationTime(
      fallbackTimelineTime: fallbackTimelineTime,
      isAudioReady: ready && sourceMatches,
      audioPosition: _audioPlayer.position,
      audioLayerStartTime: anchor.startTime,
      audioLayerDuration: anchor.effectiveDuration,
    );
  }

  Future<void> _syncAudioPlayers() async {
    final state = ref.read(editorProvider);
    final project = state.currentProject;
    if (project == null) return;
    final audioLayers = project.layers.where((l) => l.type == 'audio').toList();
    final currentTime = _playbackTime.value;
    Layer? activeLayer;
    for (final layer in audioLayers) {
      if (currentTime >= layer.startTime &&
          currentTime < layer.startTime + layer.effectiveDuration) {
        activeLayer = layer;
        break;
      }
    }
    if (state.mutedTracks.contains('audio')) {
      if (_audioPlayer.playing) await _audioPlayer.pause();
      return;
    }
    if (activeLayer == null) {
      if (_audioPlayer.playing) await _audioPlayer.pause();
      return;
    }
    final audioPath = activeLayer.content;
    if (audioPath.isEmpty) {
      if (_audioPlayer.playing) await _audioPlayer.pause();
      return;
    }
    final file = File(audioPath);
    if (!await file.exists()) {
      if (!_failedAudioPaths.contains(audioPath))
        _failedAudioPaths.add(audioPath);
      if (_audioPlayer.playing) await _audioPlayer.pause();
      return;
    }
    if (_currentAudioPath != audioPath) {
      try {
        debugPrint('[Audio] Switching to: ${audioPath.split('/').last}');
        if (_audioPlayer.playing) await _audioPlayer.pause();
        await _audioPlayer.stop();
        _currentAudioPath = audioPath;
        var playbackSpeed =
            (activeLayer.style['speed'] as num?)?.toDouble() ?? 1.0;
        if (activeLayer.voiceEffectId != 'none') {
          final voiceEffect = findVoiceEffectById(activeLayer.voiceEffectId);
          if (voiceEffect.id != 'none') {
            playbackSpeed *= voiceEffect.speed;
          }
        }
        playbackSpeed = playbackSpeed.clamp(0.25, 4.0);
        final expectedPosition = RecitationTiming.computeSwitchSeekPosition(
          isPlaying: state.isPlaying,
          currentTime: currentTime,
          layerStartTime: activeLayer.startTime,
          playbackSpeed: playbackSpeed,
        );
        await _audioPlayer.setFilePath(audioPath);
        await _audioPlayer.seek(expectedPosition);
        _lastAudioSwitchAt = DateTime.now();
      } catch (e) {
        _failedAudioPaths.add(audioPath);
        debugPrint('[Audio] Failed to load: $e');
        return;
      }
    } else {
      final isReady =
          _audioPlayer.processingState == ProcessingState.ready ||
          _audioPlayer.processingState == ProcessingState.completed;
      if (isReady) {
        final expectedPosition = Duration(
          milliseconds: ((currentTime - activeLayer.startTime) * 1000).toInt(),
        );
        final drift = (_audioPlayer.position - expectedPosition).inMilliseconds
            .abs();
        final isPlaying = ref.read(editorProvider).isPlaying;
        final speed =
            (activeLayer.style['speed'] as num?)?.toDouble().clamp(0.25, 4.0) ??
            1.0;
        final delayCorrection =
            RecitationTiming.shouldDelayDriftCorrectionAfterSwitch(
              now: DateTime.now(),
              lastSwitchAt: _lastAudioSwitchAt,
              currentTime: currentTime,
              layerStartTime: activeLayer.startTime,
              playbackSpeed: speed,
            );
        // Optimization: keep playing uninterrupted; only correct significant drift,
        // and never during the immediate post-switch window.
        if (isPlaying && !delayCorrection && drift > 1500) {
          // Massive drift > 1.5s, force a resync (usually happens if video lagged hard but audio kept going)
          await _audioPlayer.seek(expectedPosition);
        } else if (!isPlaying && drift > 150) {
          // Scrubbing validation: precise sync when paused
          await _audioPlayer.seek(expectedPosition);
        }
      }
    }
    double baseVolume =
        (activeLayer.style['volume'] as num?)?.toDouble() ?? 1.0;
    // Optimization: Cache speech layers for this sync cycle to avoid O(N) filtering inside math
    final speechLayers = audioLayers
        .where((l) => l.style['role'] == 'speech' || l.style['role'] == 'voice')
        .toList();
    final anySpeechActive = speechLayers.any(
      (l) =>
          currentTime >= l.startTime &&
          currentTime < l.startTime + l.effectiveDuration,
    );
    final isMusicLayer =
        activeLayer.style['role'] == 'music' ||
        activeLayer.style['role'] == 'background';

    final targetDucking =
        isMusicLayer && anySpeechActive && project.duckingEnabled ? 0.4 : 1.0;
    final currentDuckVol = _duckingVolumes[activeLayer.id] ?? 1.0;

    // Smooth volume transition (Ducking)
    if ((targetDucking - currentDuckVol).abs() > 0.001) {
      final duckingSpeed = targetDucking < currentDuckVol
          ? _duckingAttack
          : _duckingRelease;
      final duckLerp = (0.05 / duckingSpeed).clamp(
        0.0,
        1.0,
      ); // Based on 50ms ticker
      final smoothDuckVol =
          currentDuckVol + (targetDucking - currentDuckVol) * duckLerp;
      _duckingVolumes[activeLayer.id] = smoothDuckVol;
      baseVolume *= smoothDuckVol;
    } else {
      baseVolume *= currentDuckVol;
    }
    if (activeLayer.noiseGateThreshold > 0)
      baseVolume *= (1.0 - activeLayer.noiseGateThreshold * 0.5);
    final fadeInSec = (activeLayer.style['fadeIn'] as num?)?.toDouble() ?? 0.0;
    final fadeOutSec =
        (activeLayer.style['fadeOut'] as num?)?.toDouble() ?? 0.0;
    final layerElapsed = currentTime - activeLayer.startTime;
    final layerRemaining = activeLayer.effectiveDuration - layerElapsed;
    double effectiveVolume = baseVolume;
    if (fadeInSec > 0 && layerElapsed < fadeInSec) {
      effectiveVolume = (layerElapsed / fadeInSec) * baseVolume;
    } else if (fadeOutSec > 0 && layerRemaining < fadeOutSec) {
      effectiveVolume = (layerRemaining / fadeOutSec) * baseVolume;
    }
    // 1. Volume Optimization: Only update if changed by at least 1%
    final volumeDiff = (effectiveVolume - (_lastAppliedAudioVolume ?? -1.0))
        .abs();
    if (volumeDiff > 0.01) {
      await _audioPlayer.setVolume(effectiveVolume);
      _lastAppliedAudioVolume = effectiveVolume;
    }

    // 2. Speed Optimization: Only update if changed by at least 1%
    double speed = (activeLayer.style['speed'] as num?)?.toDouble() ?? 1.0;
    if (activeLayer.voiceEffectId != 'none') {
      final voiceEffect = findVoiceEffectById(activeLayer.voiceEffectId);
      if (voiceEffect.id != 'none') speed *= voiceEffect.speed;
    }
    speed = speed.clamp(0.25, 4.0);
    final speedDiff = (speed - (_lastAppliedAudioSpeed ?? -1.0)).abs();
    if (speedDiff > 0.01) {
      await _audioPlayer.setSpeed(speed);
      _lastAppliedAudioSpeed = speed;
    }

    // 3. Playback State Optimization
    final currentIsPlaying = ref.read(editorProvider).isPlaying;
    if (currentIsPlaying) {
      final isReady =
          _audioPlayer.processingState == ProcessingState.ready ||
          _audioPlayer.processingState == ProcessingState.completed;
      if (isReady &&
          (!_audioPlayer.playing || _lastAppliedAudioPlaying != true)) {
        await _audioPlayer.play();
        _lastAppliedAudioPlaying = true;
      }
    } else {
      if (_audioPlayer.playing || _lastAppliedAudioPlaying != false) {
        await _audioPlayer.pause();
        _lastAppliedAudioPlaying = false;
      }
    }
  }

  DateTime _lastAudioSyncTime = DateTime.now();
  bool _isAudioSyncing = false;

  void _syncAudioPlayersImmediate() async {
    if (_isAudioSyncing) return;
    _lastAudioSyncTime = DateTime.now();
    _isAudioSyncing = true;
    try {
      await _syncAudioPlayers();
    } finally {
      _isAudioSyncing = false;
    }
  }

  void _syncAudioPlayersThrottled() async {
    if (_isAudioSyncing) return;

    final now = DateTime.now();
    // Throttled to 10Hz to prevent spamming just_audio MethodChannel and starving Android's underlying AudioTrack.
    if (now.difference(_lastAudioSyncTime).inMilliseconds < 100) return;
    _lastAudioSyncTime = now;

    _syncAudioPlayersImmediate();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final state = ref.read(editorProvider);
    final isPlaying = state.isPlaying;

    // We expect playhead updates coming from outside when PAUSED
    if (!isPlaying) {
      if (_playbackTicker.isActive) _stopPlayback();
      return;
    }

    final total = state.currentProject?.totalDuration ?? 30.0;
    final layers = state.currentProject?.layers ?? [];

    // Find relevant video layer
    final activeVideoLayer = layers
        .where((l) => l.type == 'video' && l.activeAt(_playbackTime.value))
        .firstOrNull;

    // MASTER CLOCK: Pure Hardware Synthetic Time
    // We completely decouple from video decoder jitter.
    // The UI must run flawlessly at 60fps regardless of video decoding speed.
    double next = _initialPlaybackTime + (elapsed.inMicroseconds / 1000000.0);

    if (next >= total) {
      ref.read(editorProvider.notifier).pause();
      _stopPlayback();
      return;
    }

    _playbackTime.value = next.clamp(0.0, total);

    // Throttle the global Riverpod state update to 250ms to save UI main thread and VideoPlayer texture binding.
    final now = DateTime.now();
    if (now.difference(_lastEditorStateUpdateTime).inMilliseconds > 250) {
      _lastEditorStateUpdateTime = now;
      ref.read(editorProvider.notifier).setCurrentTime(next.clamp(0.0, total));
    }

    final audioLayers = layers.where((l) => l.type == 'audio').toList();
    Layer? activeAudioLayer;
    for (final layer in audioLayers) {
      if (next >= layer.startTime &&
          next < layer.startTime + layer.effectiveDuration) {
        activeAudioLayer = layer;
        break;
      }
    }
    var speedHint =
        (activeAudioLayer?.style['speed'] as num?)?.toDouble() ?? 1.0;
    if (activeAudioLayer != null && activeAudioLayer.voiceEffectId != 'none') {
      final voiceEffect = findVoiceEffectById(activeAudioLayer.voiceEffectId);
      if (voiceEffect.id != 'none') {
        speedHint *= voiceEffect.speed;
      }
    }
    speedHint = speedHint.clamp(0.25, 4.0);
    final priorityAudioSync = RecitationTiming.shouldPrioritizeSync(
      audioLayers: audioLayers,
      currentTime: next,
      playbackSpeed: speedHint,
    );
    if (priorityAudioSync) {
      _syncAudioPlayersImmediate();
    } else {
      _syncAudioPlayersThrottled();
    }

    // Handle video controller playback state
    if (_isVideoInitialized &&
        _videoController != null &&
        _videoController!.value.isInitialized) {
      if (activeVideoLayer != null) {
        final isActive = activeVideoLayer.activeAt(next);
        if (isActive &&
            (!_videoController!.value.isPlaying ||
                _lastAppliedVideoPlaying != true)) {
          _videoController!.play();
          _lastAppliedVideoPlaying = true;
        } else if (!isActive &&
            (_videoController!.value.isPlaying ||
                _lastAppliedVideoPlaying != false)) {
          _videoController!.pause();
          _lastAppliedVideoPlaying = false;
        }
      } else {
        if (_lastAppliedVideoPlaying != false) {
          _videoController!.pause();
          _lastAppliedVideoPlaying = false;
        }
      }

      final isMidVideo = activeVideoLayer != null;
      if (!isMidVideo) {
        final comingUp = layers
            .where(
              (l) =>
                  l.type == 'video' &&
                  l.startTime > next &&
                  l.startTime < next + 2.0,
            )
            .firstOrNull;
        if (comingUp != null && _preWarmingVideoPath != comingUp.content) {
          _preWarmingVideoPath = comingUp.content;
          _initializeVideoControllerByPath(comingUp.content);
        }
      }
    }
  }

  void _startPlayback() {
    if (!_playbackTicker.isActive) {
      _playbackTicker.start();
    }

    // Sync video controller position once before starting, then let it play freely
    final state = ref.read(editorProvider);
    final project = state.currentProject;

    _initialPlaybackTime = state.currentTime;
    _playbackTime.value = state.currentTime;

    if (_isVideoInitialized &&
        _videoController != null &&
        _videoController!.value.isInitialized) {
      final videoLayer = project?.layers
          .where((l) => l.type == 'video' && l.content.isNotEmpty)
          .lastOrNull;
      if (videoLayer != null && videoLayer.activeAt(state.currentTime)) {
        final inPoint = videoLayer.inPoint ?? 0;
        final videoPosition =
            (inPoint + (state.currentTime - videoLayer.startTime)).clamp(
              0.0,
              double.infinity,
            );
        final durationMs = _videoController!.value.duration.inMilliseconds;
        final seekMs = (videoPosition * 1000).toInt().clamp(
          0,
          durationMs > 0 ? durationMs - 1 : 0,
        );
        _videoController!.seekTo(Duration(milliseconds: seekMs)).then((_) {
          _videoController?.play();
        });
      }
    }
  }

  void _stopPlayback() {
    if (_playbackTicker.isActive) {
      _playbackTicker.stop();
    }
    _syncThrottle?.cancel();

    if (_isVideoInitialized &&
        _videoController != null &&
        _videoController!.value.isInitialized) {
      _videoController!.pause();
      _lastAppliedVideoPlaying = false;

      final state = ref.read(editorProvider);
      final project = state.currentProject;
      if (project == null) return;

      final videoLayers = project.layers
          .where((l) => l.type == 'video' && l.content.isNotEmpty)
          .toList();
      if (videoLayers.isEmpty) return;

      final videoLayer = videoLayers.firstWhere(
        (l) => l.activeAt(state.currentTime),
        orElse: () => videoLayers.last,
      );

      final inPoint = videoLayer.inPoint ?? 0;
      final videoPosition =
          (inPoint + (state.currentTime - videoLayer.startTime)).clamp(
            0.0,
            double.infinity,
          );
      final durationMs = _videoController!.value.duration.inMilliseconds;
      final targetMs = (videoPosition * 1000).toInt().clamp(
        0,
        durationMs > 0 ? durationMs - 1 : 0,
      );

      // Optimization: Only seek if the drift is significant (>100ms) to avoid stuttering on micro-stops
      final currentMs = _videoController!.value.position.inMilliseconds;
      if ((currentMs - targetMs).abs() > 100) {
        _videoController!.seekTo(Duration(milliseconds: targetMs));
      }
    }
    _audioPlayer.pause();
  }

  void _flashPlayIcon() {
    setState(() => _showPlayIcon = true);
    _playIconTimer?.cancel();
    _playIconTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showPlayIcon = false);
    });
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  Matrix4 _getLayerTransform(Layer layer, double currentTime) {
    if (layer.keyframes.isNotEmpty) {
      final notifier = ref.read(editorProvider.notifier);
      final transform = notifier.getTransformAtTime(layer.id, currentTime);
      // ignore: deprecated_member_use
      return Matrix4.identity()
        ..translate(transform.x, transform.y)
        ..rotateZ(transform.rotation * math.pi / 180)
        ..scale(transform.scaleX, transform.scaleY);
    }
    final scale = layer.style['scale']?.toDouble() ?? 1.0;
    final rotation = layer.style['rotation']?.toDouble() ?? 0.0;
    final offsetX = layer.style['offsetX']?.toDouble() ?? 0.0;
    final offsetY = layer.style['offsetY']?.toDouble() ?? 0.0;
    // ignore: deprecated_member_use
    return Matrix4.identity()
      ..translate(offsetX, offsetY)
      ..rotateZ(rotation * math.pi / 180)
      ..scale(scale);
  }

  Widget _applyBlendMode(Widget child, String blendModeName) {
    if (blendModeName == 'srcOver' || blendModeName.isEmpty) return child;
    final blendMode = BlendMode.values.byName(blendModeName);
    // Expertise: ShaderMask is extremely expensive on mobile.
    // We only apply it if absolutely necessary (non-standard blend mode).
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Colors.white, Colors.white],
      ).createShader(bounds),
      blendMode: blendMode,
      child: child,
    );
  }

  Widget _applyMask(Widget child, LayerMask mask) {
    if (mask.type == MaskType.none || mask.value == 0) return child;
    switch (mask.type) {
      case MaskType.rectangle:
        return ClipRRect(
          borderRadius: BorderRadius.circular(mask.value * 50),
          child: child,
        );
      case MaskType.circle:
        return ClipOval(child: child);
      case MaskType.triangle:
        return ClipPath(clipper: _TriangleClipper(), child: child);
      case MaskType.heart:
        return ClipPath(clipper: _HeartClipper(), child: child);
      case MaskType.star:
        return ClipPath(clipper: _StarClipper(), child: child);
      case MaskType.splitHorizontal:
        return ClipPath(
          clipper: _SplitClipper(axis: Axis.horizontal, value: mask.value),
          child: child,
        );
      case MaskType.splitVertical:
        return ClipPath(
          clipper: _SplitClipper(axis: Axis.vertical, value: mask.value),
          child: child,
        );
      default:
        return child;
    }
  }

  Widget _buildCanvasBackground(Project project, double width, double height) {
    final bg = kCanvasBackgrounds.firstWhere(
      (b) => b.id == project.canvasBackgroundId,
      orElse: () => kCanvasBackgrounds.first,
    );
    return bg.buildBackground();
  }

  Widget _buildVideoLayer(double width, double height) {
    return _VideoLayerRenderer(
      width: width,
      height: height,
      controller: _videoController,
      isInitialized: _isVideoInitialized,
      applyMask: _applyMask,
      applyBlendMode: _applyBlendMode,
    );
  }

  // All subsequent methods will reside inside _VideoPreviewState.

  /// Master Video Layer - Performance isolated.
  /// Only rebuilds when time or structural state specifically requires it.

  // All subsequent methods (Image, Sticker, Arabic, etc.) now correctly reside
  // within _VideoPreviewState because we've moved the renderer class out of the way.

  Widget _buildImageLayer(
    Layer layer,
    double currentTime,
    double previewWidth,
    double previewHeight,
  ) {
    final file = File(layer.content);
    if (!file.existsSync()) return const SizedBox.shrink();
    final opacity = (layer.style['opacity'] as num?)?.toDouble() ?? 1.0;
    final w = layer.style['width']?.toDouble() ?? previewWidth;
    final h = layer.style['height']?.toDouble() ?? previewHeight;
    return _applyMask(
      _applyBlendMode(
        Opacity(
          opacity: opacity,
          child: Transform(
            transform: _getLayerTransform(layer, currentTime),
            child: Image.file(file, width: w, height: h, fit: BoxFit.contain),
          ),
        ),
        layer.blendMode,
      ),
      layer.mask,
    );
  }

  Widget _buildStickerLayer(
    Layer layer,
    double currentTime,
    double previewWidth,
    double previewHeight,
  ) {
    final emoji = layer.content;
    if (emoji.isEmpty) return const SizedBox.shrink();
    final layerProgress =
        (currentTime - layer.startTime) / layer.effectiveDuration;
    final opacity = (layer.style['opacity'] as num?)?.toDouble() ?? 1.0;
    final size = layer.style['size']?.toDouble() ?? 48.0;
    final tx = layer.transform.x;
    final ty = layer.transform.y;
    final scaleX = layer.transform.scaleX;
    final scaleY = layer.transform.scaleY;
    final x = tx * previewWidth - (size * scaleX) / 2;
    final y = ty * previewHeight - (size * scaleY) / 2;
    double animOpacity = opacity;
    const fadeInDuration = 0.2;
    const fadeOutDuration = 0.2;
    if (layerProgress < fadeInDuration / layer.effectiveDuration) {
      animOpacity =
          opacity *
          (layerProgress / (fadeInDuration / layer.effectiveDuration));
    } else if (layerProgress >
        1.0 - fadeOutDuration / layer.effectiveDuration) {
      animOpacity =
          opacity *
          ((1.0 - layerProgress) / (fadeOutDuration / layer.effectiveDuration));
    }
    final stickerAnim = layer.style['animation'] as int?;
    Widget stickerWidget = Text(
      emoji,
      style: TextStyle(fontSize: size, height: 1.0),
    );
    if (stickerAnim != null && stickerAnim > 0) {
      switch (stickerAnim) {
        case 2:
          if (layerProgress < 0.4)
            stickerWidget = Transform.translate(
              offset: Offset(
                0,
                -20 *
                    math.sin(layerProgress / 0.4 * math.pi * 3) *
                    (1.0 - layerProgress / 0.4),
              ),
              child: stickerWidget,
            );
          break;
        case 3:
          if (layerProgress < 0.5)
            stickerWidget = Transform.rotate(
              angle:
                  math.sin(layerProgress * math.pi * 4) *
                  0.3 *
                  (1.0 - layerProgress * 2),
              child: stickerWidget,
            );
          break;
        case 4:
          if (layerProgress < 0.3)
            stickerWidget = Transform.scale(
              scale: 0.5 + 0.5 * (layerProgress / 0.3),
              child: stickerWidget,
            );
          break;
        case 5:
          if (layerProgress < 0.3)
            stickerWidget = Transform.translate(
              offset: Offset(-50 * (1.0 - layerProgress / 0.3), 0),
              child: stickerWidget,
            );
          break;
      }
    }
    return Positioned(
      left: x,
      top: y,
      child: _applyMask(
        // ignore: deprecated_member_use
        AnimatedOpacity(
          opacity: animOpacity.clamp(0.0, 1.0),
          duration: const Duration(milliseconds: 100),
          child: Transform(
            transform: Matrix4.identity()
              ..scale(scaleX, scaleY)
              ..rotateZ(layer.transform.rotation * math.pi / 180),
            alignment: Alignment.center,
            child: stickerWidget,
          ),
        ),
        layer.mask,
      ),
    );
  }

  TextStyle _resolveVideoPreviewTextStyle(
    TextLayerStyle? style,
    String fallbackFont,
    double fontSize,
    Color color,
  ) {
    final baseStyle =
        style
            ?.toFlutterTextStyle(overrideColor: color)
            .copyWith(fontSize: fontSize) ??
        TextStyle(
          fontFamily: fallbackFont,
          fontSize: fontSize,
          color: color,
          height: 1.4,
        );

    final family = style?.fontFamily ?? fallbackFont;
    if (FontCatalogue.isLocal(family))
      return baseStyle.copyWith(fontFamily: family);

    try {
      return GoogleFonts.getFont(family, textStyle: baseStyle);
    } catch (_) {
      return baseStyle.copyWith(fontFamily: family);
    }
  }

  Widget _buildArabicLayer(
    Layer layer,
    double currentTime,
    double previewWidth,
    double previewHeight,
  ) {
    final style = layer.textStyle;
    final scaleFactor = previewWidth / 360.0;
    final baseFontSize = style?.fontSize ?? 26;
    final fontSize = baseFontSize * scaleFactor * 1.1;
    final color = style != null ? _parseColor(style.color) : Colors.white;
    final fontFamily =
        style?.fontFamily ?? layer.fontFamily ?? 'UthmanicRegular';
    final opacity = (layer.style['opacity'] as num?)?.toDouble() ?? 1.0;
    final transformY = layer.transform.y;
    final styleY = (layer.style['y'] as num?)?.toDouble();
    final hasLegacyQuranAutoY =
        layer.style['x'] == null &&
        (styleY == 300.0 || styleY == 600.0 || styleY == 750.0);
    final y = hasLegacyQuranAutoY
        ? (transformY * previewHeight)
        : (styleY ?? (transformY * previewHeight));
    final quranAnimationId = style?.quranAnimationId;
    final hasQuranAnimation =
        quranAnimationId != null &&
        quranAnimationId.isNotEmpty &&
        quranAnimationId != 'none';
    final hasWordTimings = layer.wordTimings.isNotEmpty;

    String displayText = layer.content;
    List<TextSpan>? wordSpans;
    Widget? textWidget;
    double localProgress =
        (currentTime - layer.startTime) / layer.effectiveDuration;
    final resolvedStyle = _resolveVideoPreviewTextStyle(
      style,
      fontFamily,
      fontSize,
      color,
    ).copyWith(height: 1.6);

    if (hasWordTimings) {
      final chunks = _chunkWordTimings(layer.wordTimings, wordsPerChunk: 10);
      if (chunks.isNotEmpty) {
        final activeChunk = _pickChunkAtTime(chunks, currentTime);

        displayText = activeChunk.text;

        final chunkDuration = activeChunk.duration;
        if (chunkDuration > 0) {
          localProgress = ((currentTime - activeChunk.start) / chunkDuration)
              .clamp(0.0, 1.0);
        }

        if (activeChunk.wordTimings != null) {
          final chunkTimings = activeChunk.wordTimings!;
          int currentWordIndex = 0;
          for (int i = 0; i < chunkTimings.length; i++) {
            final wordStart = (chunkTimings[i]['start'] as num).toDouble();
            final wordEnd = (chunkTimings[i]['end'] as num).toDouble();
            if (currentTime >= wordStart && currentTime < wordEnd) {
              currentWordIndex = i;
              break;
            }
            if (currentTime >= wordEnd) currentWordIndex = i + 1;
          }

          final isEtherealGlow = quranAnimationId == 'ethereal_glow';
          final isRainbow = quranAnimationId == 'rainbow';
          final isSunset = quranAnimationId == 'sunset';
          final isAurora = quranAnimationId == 'aurora';
          final isShaderDriven = isRainbow || isSunset || isAurora;

          final glowIntensity = (math.sin(localProgress * math.pi) * 20).clamp(
            0.0,
            20.0,
          );
          final glowShadows = isEtherealGlow
              ? [
                  Shadow(
                    color: const Color(0xFFE0B0FF).withValues(alpha: 0.8),
                    blurRadius: glowIntensity,
                  ),
                ]
              : null;

          final words = activeChunk.text.split(RegExp(r'\s+'));

          // When using a shader animation, we split into TWO layers: base and active
          // This solves the multi-line bleed by making the karaoke literally draw the shader!
          wordSpans = words.asMap().entries.map((entry) {
            final isActive = entry.key <= currentWordIndex;

            Color textColor;
            if (isShaderDriven) {
              textColor = isActive
                  ? Colors.transparent
                  : color; // Active is handled by shader overlay
            } else {
              textColor = isActive
                  ? const Color(0xFFFFD700)
                  : color; // Standard Gold karaoke
            }

            return TextSpan(
              text: entry.value + (entry.key < words.length - 1 ? ' ' : ''),
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: fontSize,
                color: textColor,
                height: 1.6,
                shadows: glowShadows,
              ),
            );
          }).toList();

          // If shader driven, we need a secondary active span list for the ShaderMask Top Layer
          if (isShaderDriven) {
            final activeSpans = words.asMap().entries.map((entry) {
              final isActive = entry.key <= currentWordIndex;
              final wordText =
                  entry.value + (entry.key < words.length - 1 ? ' ' : '');
              final parsedWord = style?.isUppercase == true
                  ? wordText.toUpperCase()
                  : wordText;
              return TextSpan(
                text: parsedWord,
                style: resolvedStyle.copyWith(
                  color: isActive
                      ? Colors.white
                      : Colors
                            .transparent, // Only color the active words to mask the Shader
                  shadows: glowShadows,
                ),
              );
            }).toList();

            textWidget = Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                RichText(
                  text: TextSpan(children: wordSpans),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) {
                    if (isRainbow) {
                      return const LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          Color(0xFFFF0000),
                          Color(0xFFFF7F00),
                          Color(0xFFFFFF00),
                          Color(0xFF00FF00),
                          Color(0xFF0000FF),
                          Color(0xFF4B0082),
                          Color(0xFF9400D3),
                        ],
                      ).createShader(bounds);
                    } else if (isSunset) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFF4500),
                          Color(0xFFFF8C00),
                          Color(0xFFFFD700),
                        ],
                      ).createShader(bounds);
                    } else if (isAurora) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF00FF88),
                          Color(0xFF00DDFF),
                          Color(0xFF8800FF),
                        ],
                      ).createShader(bounds);
                    }
                    return const LinearGradient(
                      colors: [Colors.white, Colors.white],
                    ).createShader(bounds);
                  },
                  child: RichText(
                    text: TextSpan(children: activeSpans),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            );
          }
        }
      }
    }

    textWidget ??= RichText(
      text: TextSpan(
        children:
            wordSpans ??
            [
              TextSpan(
                text: style?.isUppercase == true
                    ? displayText.toUpperCase()
                    : displayText,
                style: resolvedStyle.copyWith(
                  shadows: quranAnimationId == 'ethereal_glow'
                      ? [
                          Shadow(
                            color: const Color(
                              0xFFE0B0FF,
                            ).withValues(alpha: 0.8),
                            blurRadius: (math.sin(localProgress * math.pi) * 20)
                                .clamp(0.0, 20.0),
                          ),
                        ]
                      : resolvedStyle.shadows,
                ),
              ),
            ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    );

    if (hasQuranAnimation) {
      final shaderAnimations = ['rainbow', 'sunset', 'aurora'];
      final overlayAnimations = [
        'golden_particles',
        'stardust',
        'diamond_sparkle',
        'blessed_rain',
        'water_drops',
        'autumn_leaves',
        'flower_bloom',
        'gentle_wind',
        'light_butterflies',
        'lightning',
        'brush_strokes',
        'ink_flow',
        'quill_writing',
        'living_calligraphy',
      ];

      Widget mappedWidget = textWidget;

      // 1. Shader Mask Category - FALLBACK for texts without wordTimings (using simple sweeps)
      if (shaderAnimations.contains(quranAnimationId) && wordSpans == null) {
        mappedWidget = ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            if (quranAnimationId == 'rainbow') {
              final sweep = localProgress * bounds.width;
              return const LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Color(0xFFFF0000),
                  Color(0xFFFF7F00),
                  Color(0xFFFFFF00),
                  Color(0xFF00FF00),
                  Color(0xFF0000FF),
                  Color(0xFF4B0082),
                  Color(0xFF9400D3),
                ],
              ).createShader(
                Rect.fromLTRB(
                  bounds.right - sweep,
                  bounds.top,
                  bounds.right,
                  bounds.bottom,
                ),
              );
            } else if (quranAnimationId == 'sunset') {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFF4500),
                  Color(0xFFFF8C00),
                  Color(0xFFFFD700),
                ],
              ).createShader(
                Rect.fromLTWH(
                  0,
                  0,
                  bounds.width,
                  bounds.height * localProgress,
                ),
              );
            } else if (quranAnimationId == 'aurora') {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF00FF88),
                  Color(0xFF00DDFF),
                  Color(0xFF8800FF),
                ],
              ).createShader(
                Rect.fromLTWH(
                  0,
                  0,
                  bounds.width,
                  bounds.height * localProgress,
                ),
              );
            }
            return const LinearGradient(
              colors: [Colors.white, Colors.white],
            ).createShader(bounds);
          },
          child: mappedWidget,
        );
      }

      // 2. Foreground vs Background rendering of the CustomPainter
      final isOverlay = overlayAnimations.contains(quranAnimationId);
      final isGlow = quranAnimationId == 'ethereal_glow';

      final wrapperChild = Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _kQuranTextHorizontalPadding,
          ),
          child: CustomPaint(
            painter:
                isOverlay ||
                    isGlow ||
                    shaderAnimations.contains(quranAnimationId)
                ? null // Let Text take precedence, Shader/Glow handles it
                : _QuranAnimationPainter(
                    animationId: quranAnimationId,
                    progress: localProgress,
                    textColor: color,
                  ),
            foregroundPainter: isOverlay
                ? _QuranAnimationPainter(
                    animationId: quranAnimationId,
                    progress: localProgress,
                    textColor: color,
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: mappedWidget,
            ),
          ),
        ),
      );

      return _buildSmartBoundingBoxWrapper(
        layer: layer,
        previewWidth: previewWidth,
        previewHeight: previewHeight,
        isSelected: ref.read(editorProvider).selectedLayerId == layer.id,
        defaultX: 0,
        defaultY: y - 40,
        defaultWidthRatio: 1.0,
        fillWidthWhenNoCustom: true,
        child: RepaintBoundary(child: _applyMask(wrapperChild, layer.mask)),
      );
    }

    return _buildSmartBoundingBoxWrapper(
      layer: layer,
      previewWidth: previewWidth,
      previewHeight: previewHeight,
      isSelected: ref.read(editorProvider).selectedLayerId == layer.id,
      defaultX: 0,
      defaultY: y,
      defaultWidthRatio: 1.0,
      fillWidthWhenNoCustom: true,
      child: RepaintBoundary(
        child: _applyMask(
          Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _kQuranTextHorizontalPadding,
              ),
              child: textWidget,
            ),
          ),
          layer.mask,
        ),
      ),
    );
  }

  Widget _buildTranslationLayer(
    Layer layer,
    double currentTime,
    double previewWidth,
    double previewHeight,
    List<Layer> activeLayers,
  ) {
    final style = layer.textStyle;
    final scaleFactor = previewWidth / 360.0;
    final baseFontSize = style?.fontSize ?? 14;
    final fontSize = baseFontSize * scaleFactor;
    final color = style != null ? _parseColor(style.color) : Colors.white70;
    final opacity = (layer.style['opacity'] as num?)?.toDouble() ?? 1.0;
    final transformY = layer.transform.y;
    final styleY = (layer.style['y'] as num?)?.toDouble();
    final hasLegacyQuranAutoY =
        layer.style['x'] == null &&
        (styleY == 300.0 || styleY == 600.0 || styleY == 750.0);
    final y = hasLegacyQuranAutoY
        ? (transformY * previewHeight)
        : (styleY ?? (transformY * previewHeight));

    String displayText = layer.content;
    final arabicLayer = activeLayers
        .where(
          (l) =>
              l.type == 'arabic' && (l.startTime - layer.startTime).abs() < 0.1,
        )
        .firstOrNull;
    if (arabicLayer != null && arabicLayer.wordTimings.isNotEmpty) {
      final arabicChunks = _chunkWordTimings(
        arabicLayer.wordTimings,
        wordsPerChunk: 10,
      );
      final transChunks = _chunkStringProportionally(
        layer.content,
        arabicChunks,
      );
      if (transChunks.isNotEmpty) {
        final activeChunk = _pickChunkAtTime(transChunks, currentTime);
        displayText = activeChunk.text;
      }
    }

    final fontFamily = style?.fontFamily ?? layer.fontFamily ?? 'Inter';
    final parsedText = style?.isUppercase == true
        ? displayText.toUpperCase()
        : displayText;
    final resolvedStyle = _resolveVideoPreviewTextStyle(
      style,
      fontFamily,
      fontSize,
      color,
    ).copyWith(height: 1.4);

    Widget tWidget = Text(
      parsedText,
      style: resolvedStyle,
      textAlign: TextAlign.center,
    );

    return _buildSmartBoundingBoxWrapper(
      layer: layer,
      previewWidth: previewWidth,
      previewHeight: previewHeight,
      isSelected: ref.read(editorProvider).selectedLayerId == layer.id,
      defaultX: 0,
      defaultY: y,
      defaultWidthRatio: 1.0,
      fillWidthWhenNoCustom: true,
      child: _applyMask(
        _applyBlendMode(
          Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _kQuranTextHorizontalPadding,
              ),
              child: tWidget,
            ),
          ),
          layer.blendMode,
        ),
        layer.mask,
      ),
    );
  }

  Widget _buildPhoneticLayer(
    Layer layer,
    double currentTime,
    double previewWidth,
    double previewHeight,
    List<Layer> activeLayers,
  ) {
    final style = layer.textStyle;
    final scaleFactor = previewWidth / 360.0;
    final baseFontSize = style?.fontSize ?? 12;
    final fontSize = baseFontSize * scaleFactor;
    final color = style != null ? _parseColor(style.color) : Colors.white70;
    final opacity = (layer.style['opacity'] as num?)?.toDouble() ?? 1.0;
    final transformY = layer.transform.y;
    final styleY = (layer.style['y'] as num?)?.toDouble();
    final hasLegacyQuranAutoY =
        layer.style['x'] == null &&
        (styleY == 300.0 || styleY == 600.0 || styleY == 750.0);
    final y = hasLegacyQuranAutoY
        ? (transformY * previewHeight)
        : (styleY ?? (transformY * previewHeight));

    String displayText = layer.content;
    final arabicLayer = activeLayers
        .where(
          (l) =>
              l.type == 'arabic' && (l.startTime - layer.startTime).abs() < 0.1,
        )
        .firstOrNull;
    if (arabicLayer != null && arabicLayer.wordTimings.isNotEmpty) {
      final arabicChunks = _chunkWordTimings(
        arabicLayer.wordTimings,
        wordsPerChunk: 10,
      );
      final transChunks = _chunkStringProportionally(
        layer.content,
        arabicChunks,
      );
      if (transChunks.isNotEmpty) {
        final activeChunk = _pickChunkAtTime(transChunks, currentTime);
        displayText = activeChunk.text;
      }
    }

    final fontFamily = style?.fontFamily ?? layer.fontFamily ?? 'Inter';
    final parsedText = style?.isUppercase == true
        ? displayText.toUpperCase()
        : displayText;
    final resolvedStyle = _resolveVideoPreviewTextStyle(
      style,
      fontFamily,
      fontSize,
      color,
    ).copyWith(height: 1.4, fontStyle: FontStyle.italic);

    Widget tWidget = Text(
      parsedText,
      style: resolvedStyle,
      textAlign: TextAlign.center,
    );

    return _buildSmartBoundingBoxWrapper(
      layer: layer,
      previewWidth: previewWidth,
      previewHeight: previewHeight,
      isSelected: ref.read(editorProvider).selectedLayerId == layer.id,
      defaultX: 0,
      defaultY: y,
      defaultWidthRatio: 1.0,
      fillWidthWhenNoCustom: true,
      child: _applyMask(
        _applyBlendMode(
          Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _kQuranTextHorizontalPadding,
              ),
              child: tWidget,
            ),
          ),
          layer.blendMode,
        ),
        layer.mask,
      ),
    );
  }

  // _buildTextLayer removed — replaced by _buildDraggableTextLayer which also handles drag+drop

  Widget _buildFilterOverlay(List<Layer> activeLayers, double currentTime) {
    final videoLayer = activeLayers.firstWhere(
      (l) => l.type == 'video',
      orElse: () => Layer(
        id: '',
        type: '',
        content: '',
        startTime: 0,
        duration: 0,
        style: {},
      ),
    );
    final filterId = videoLayer.filterId;
    if (filterId == 'none' || filterId.isEmpty) return const SizedBox.shrink();
    final intensity =
        (videoLayer.style['filterIntensity'] as num?)?.toDouble() ?? 1.0;
    Color filterColor;
    switch (filterId) {
      case 'cinematic':
        filterColor = const Color(
          0xFFFFE0B2,
        ).withValues(alpha: intensity * 0.15);
        break;
      case 'vintage':
        filterColor = const Color(
          0xFFD7CCC8,
        ).withValues(alpha: intensity * 0.2);
        break;
      case 'cold':
        filterColor = const Color(
          0xFFB3E5FC,
        ).withValues(alpha: intensity * 0.15);
        break;
      case 'warm':
        filterColor = const Color(
          0xFFFFCC80,
        ).withValues(alpha: intensity * 0.15);
        break;
      case 'dramatic':
      case 'noir':
        filterColor = Colors.black.withValues(alpha: intensity * 0.3);
        break;
      default:
        return const SizedBox.shrink();
    }
    return Positioned.fill(child: Container(color: filterColor));
  }

  @override
  Widget build(BuildContext context) {
    // Structural selection: only rebuild when core project properties change.
    final project = ref.watch(editorProvider.select((s) => s.currentProject));
    if (project == null)
      return const Center(
        child: Text(
          'No project loaded',
          style: TextStyle(color: Colors.white70),
        ),
      );

    // Watch for video content changes only
    ref.listen<String?>(
      editorProvider.select((s) {
        final time = s.currentTime;
        final layers = s.currentProject?.layers ?? [];
        // Find the active video layer, or the next upcoming one, or just the last used one
        final activeVideo = layers
            .where((l) => l.type == 'video' && l.activeAt(time))
            .firstOrNull;
        if (activeVideo != null) return activeVideo.content;

        final comingUp = layers
            .where((l) => l.type == 'video' && l.startTime > time)
            .firstOrNull;
        if (comingUp != null) return comingUp.content;

        final lastVideo = layers
            .where((l) => l.type == 'video' && l.content.isNotEmpty)
            .lastOrNull;
        return lastVideo?.content;
      }),
      (previous, next) {
        if (next != null && next != _lastVideoPath) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _initializeVideoController(),
          );
        }
      },
    );

    final isPlaying = ref.watch(editorProvider.select((s) => s.isPlaying));

    // Reverse sync: Update _playbackTime when scrubbing manually on the timeline (only if paused or significantly drifted)
    ref.listen<double>(editorProvider.select((s) => s.currentTime), (
      previous,
      next,
    ) {
      if (!isPlaying && (_playbackTime.value - next).abs() > 0.05) {
        _playbackTime.value = next;
        // Synchronize video player visually for scrubbing
        if (_isVideoInitialized &&
            _videoController != null &&
            _videoController!.value.isInitialized) {
          final activeVideo = project.layers
              .where((l) => l.type == 'video' && l.activeAt(next))
              .firstOrNull;
          if (activeVideo != null) {
            final inPoint = activeVideo.inPoint ?? 0;
            final seekMs = ((next - activeVideo.startTime + inPoint) * 1000)
                .toInt();
            _videoController!.seekTo(Duration(milliseconds: seekMs));
          }
        }
      }
    });

    final cinematicMode = ref.watch(
      editorProvider.select((s) => s.cinematicMode),
    );
    final aspectRatioStr = project.aspectRatio;

    // Handle playback trigger
    if (isPlaying && !_playbackTicker.isActive) {
      Future(() => _startPlayback());
    } else if (!isPlaying && _playbackTicker.isActive) {
      Future(() => _stopPlayback());
    }

    // High-frequency UI (everything that depends on currentTime) is scoped here
    // Structural selection (like selected layer) relies on Riverpod
    return ValueListenableBuilder<double>(
      valueListenable: _playbackTime,
      builder: (context, currentTime, child) {
        // High-frequency UI logic: only recalculate active parts
        final layers = project.layers;
        final activeLayers = layers
            .where((l) => l.activeAt(currentTime))
            .toList();
        final recitationTime = _resolveRecitationTime(
          fallbackTimelineTime: currentTime,
          allLayers: layers,
        );
        final activeRecitationLayers = layers
            .where(
              (l) =>
                  (l.type == 'arabic' ||
                      l.type == 'translation' ||
                      l.type == 'phonetic') &&
                  l.activeAt(recitationTime),
            )
            .toList();
        activeLayers.sort((a, b) => a.startTime.compareTo(b.startTime));
        activeRecitationLayers.sort(
          (a, b) => a.startTime.compareTo(b.startTime),
        );

        final selectedLayerId = ref.watch(
          editorProvider.select((s) => s.selectedLayerId),
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final ratioParts = aspectRatioStr.split(':');
            final targetRatio = ratioParts.length == 2
                ? double.parse(ratioParts[0]) / double.parse(ratioParts[1])
                : 9 / 16;
            final containerRatio = constraints.maxWidth / constraints.maxHeight;

            double previewWidth, previewHeight;
            if (containerRatio > targetRatio) {
              previewHeight = constraints.maxHeight;
              previewWidth = constraints.maxHeight * targetRatio;
            } else {
              previewWidth = constraints.maxWidth;
              previewHeight = constraints.maxWidth / targetRatio;
            }

            return GestureDetector(
              onTap: () {
                ref.read(editorProvider.notifier).setSelectedLayer(null);
                _flashPlayIcon();
                if (isPlaying) {
                  ref.read(editorProvider.notifier).pause();
                } else {
                  ref.read(editorProvider.notifier).togglePlay();
                }
              },
              child: Container(
                color: const Color(0xFF0D0D0F),
                child: Center(
                  child: SizedBox(
                    width: previewWidth,
                    height: previewHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRect(
                          child: Container(
                            width: previewWidth,
                            height: previewHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  _buildCanvasBackground(
                                    project,
                                    previewWidth,
                                    previewHeight,
                                  ),

                                  // Master Video Layer - Performance isolated with RepaintBoundary
                                  if (project.layers.any(
                                    (l) =>
                                        l.type == 'video' &&
                                        l.activeAt(currentTime),
                                  ))
                                    RepaintBoundary(
                                      child: _buildVideoLayer(
                                        previewWidth,
                                        previewHeight,
                                      ),
                                    ),

                                  // Overlays
                                  ...activeLayers
                                      .where((l) => l.type == 'image')
                                      .map(
                                        (layer) => _buildDraggableLayer(
                                          layer: layer,
                                          previewWidth: previewWidth,
                                          previewHeight: previewHeight,
                                          isSelected:
                                              selectedLayerId == layer.id,
                                          child: _buildImageLayer(
                                            layer,
                                            currentTime,
                                            previewWidth,
                                            previewHeight,
                                          ),
                                        ),
                                      ),
                                  ...activeLayers
                                      .where((l) => l.type == 'sticker')
                                      .map(
                                        (layer) => _buildStickerLayer(
                                          layer,
                                          currentTime,
                                          previewWidth,
                                          previewHeight,
                                        ),
                                      ),
                                  ...activeRecitationLayers
                                      .where((l) => l.type == 'arabic')
                                      .map(
                                        (layer) => _buildArabicLayer(
                                          layer,
                                          recitationTime,
                                          previewWidth,
                                          previewHeight,
                                        ),
                                      ),
                                  ...activeRecitationLayers
                                      .where((l) => l.type == 'translation')
                                      .map(
                                        (layer) => _buildTranslationLayer(
                                          layer,
                                          recitationTime,
                                          previewWidth,
                                          previewHeight,
                                          activeRecitationLayers,
                                        ),
                                      ),
                                  ...activeRecitationLayers
                                      .where((l) => l.type == 'phonetic')
                                      .map(
                                        (layer) => _buildPhoneticLayer(
                                          layer,
                                          recitationTime,
                                          previewWidth,
                                          previewHeight,
                                          activeRecitationLayers,
                                        ),
                                      ),
                                  ...activeLayers
                                      .where((l) => l.type == 'text')
                                      .map(
                                        (layer) => _buildDraggableTextLayer(
                                          layer: layer,
                                          currentTime: currentTime,
                                          previewWidth: previewWidth,
                                          previewHeight: previewHeight,
                                          isSelected:
                                              selectedLayerId == layer.id,
                                        ),
                                      ),
                                  _buildFilterOverlay(
                                    activeLayers,
                                    currentTime,
                                  ),

                                  if (cinematicMode)
                                    Positioned.fill(
                                      child: FadeTransition(
                                        opacity: _cinematicAnimation,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: RadialGradient(
                                              colors: [
                                                Colors.transparent,
                                                Colors.black.withValues(
                                                  alpha: 0.2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ── Play/Pause flash icon ────────────────────────────
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Center(
                              child: AnimatedOpacity(
                                opacity: _showPlayIcon ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 44,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ── Format badge (top-left corner) ──────────────────
                        Positioned(
                          top: 8,
                          left: 8,
                          child: _FormatBadge(
                            aspectRatio: project.aspectRatio,
                            currentTime: currentTime,
                            totalDuration: project.totalDuration,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDraggableLayer({
    required Layer layer,
    required double previewWidth,
    required double previewHeight,
    required bool isSelected,
    required Widget child,
  }) {
    // Calculate the layer's actual rendered size for proper clamping
    final x = layer.style['x']?.toDouble() ?? 0.0;
    final y = layer.style['y']?.toDouble() ?? 0.0;
    final layerW =
        (layer.style['width'] as num?)?.toDouble() ?? previewWidth * 0.5;
    final layerH =
        (layer.style['height'] as num?)?.toDouble() ?? previewHeight * 0.3;
    final maxX = (previewWidth - layerW * 0.1).clamp(0.0, previewWidth);
    final maxY = (previewHeight - layerH * 0.1).clamp(0.0, previewHeight);

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          ref.read(editorProvider.notifier).setSelectedLayer(layer.id);
        },
        onPanStart: (details) {
          ref.read(editorProvider.notifier).setSelectedLayer(layer.id);
          _draggingLayerId = layer.id;
          _dragStart = details.globalPosition;
          _layerStartOffset = Offset(
            layer.style['x']?.toDouble() ?? previewWidth / 2,
            layer.style['y']?.toDouble() ?? previewHeight / 2,
          );
        },
        onPanUpdate: (details) {
          if (_draggingLayerId != layer.id) return;
          final dx = details.globalPosition.dx - _dragStart.dx;
          final dy = details.globalPosition.dy - _dragStart.dy;
          final newX = (_layerStartOffset.dx + dx).clamp(0.0, maxX);
          final newY = (_layerStartOffset.dy + dy).clamp(0.0, maxY);
          final updated = layer.copyWith(
            style: {...layer.style, 'x': newX, 'y': newY},
          );
          ref.read(editorProvider.notifier).updateLayer(updated);
        },
        onPanEnd: (_) => _draggingLayerId = null,
        child: child,
      ),
    );
  }

  /// Builds a text layer with direct canvas drag + tap-to-select + full animation support.
  Widget _buildDraggableTextLayer({
    required Layer layer,
    required double currentTime,
    required double previewWidth,
    required double previewHeight,
    required bool isSelected,
  }) {
    final style = layer.textStyle;
    final fontSize = style?.fontSize ?? 20;
    final color = style != null ? _parseColor(style.color) : Colors.white;
    final fontFamily = style?.fontFamily ?? layer.fontFamily ?? 'Inter';
    final layerProgress = layer.effectiveDuration > 0
        ? ((currentTime - layer.startTime) / layer.effectiveDuration).clamp(
            0.0,
            1.0,
          )
        : 0.0;
    final opacity = (layer.style['opacity'] as num?)?.toDouble() ?? 1.0;
    String displayText = layer.content;
    final animation = layer.style['animation'] as String? ?? 'fade';
    double animOpacity = opacity;
    Offset slideOffset = Offset.zero;
    double animScale = 1.0;
    double? customWidth = layer.style['width']?.toDouble();

    switch (animation) {
      case 'fade':
      case 'fadeIn':
        animOpacity = opacity * (layerProgress / 0.3).clamp(0.0, 1.0);
        break;
      case 'fadeOut':
        if (layerProgress > 0.7)
          animOpacity = opacity * ((1.0 - layerProgress) / 0.3).clamp(0.0, 1.0);
        break;
      case 'fadeInOut':
        if (layerProgress < 0.2) {
          animOpacity = opacity * (layerProgress / 0.2);
        } else if (layerProgress > 0.8) {
          animOpacity = opacity * ((1.0 - layerProgress) / 0.2);
        }
        break;
      case 'typewriter':
        final charCount = (layerProgress * layer.content.length)
            .clamp(0, layer.content.length)
            .toInt();
        displayText = layer.content.substring(0, charCount);
        break;
      case 'slideInLeft':
        if (layerProgress < 0.3)
          slideOffset = Offset(-previewWidth * (1.0 - layerProgress / 0.3), 0);
        break;
      case 'slideInRight':
        if (layerProgress < 0.3)
          slideOffset = Offset(previewWidth * (1.0 - layerProgress / 0.3), 0);
        break;
      case 'slideInTop':
        if (layerProgress < 0.3)
          slideOffset = Offset(0, -previewHeight * (1.0 - layerProgress / 0.3));
        break;
      case 'slideInBottom':
        if (layerProgress < 0.3)
          slideOffset = Offset(0, previewHeight * (1.0 - layerProgress / 0.3));
        break;
      case 'scaleIn':
        if (layerProgress < 0.3) animScale = 0.5 + 0.5 * (layerProgress / 0.3);
      case 'bounceIn':
        if (layerProgress < 0.4) {
          final t = layerProgress / 0.4;
          animScale = 1.0 + 0.2 * math.sin(t * math.pi * 2) * (1.0 - t);
        }
        break;
    }

    final parsedText = style?.isUppercase == true
        ? displayText.toUpperCase()
        : displayText;
    final resolvedStyle = _resolveVideoPreviewTextStyle(
      style,
      fontFamily,
      fontSize,
      color,
    ).copyWith(height: 1.4);

    Widget contentWidget = RichText(
      text: TextSpan(text: parsedText, style: resolvedStyle),
      textAlign: style?.textAlign ?? TextAlign.center,
      softWrap: true,
    );

    // Si on a une largeur custom, on l'utilise, sinon on s'adapte au texte
    Widget sizedContent = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: previewWidth * 0.85),
      child: customWidth != null
          ? SizedBox(width: customWidth, child: contentWidget)
          : IntrinsicWidth(child: contentWidget),
    );

    return _buildSmartBoundingBoxWrapper(
      layer: layer,
      previewWidth: previewWidth,
      previewHeight: previewHeight,
      isSelected: isSelected,
      defaultX: previewWidth / 2,
      defaultY: previewHeight / 2,
      child: _applyMask(
        _applyBlendMode(
          Transform.translate(
            offset: slideOffset,
            child: Transform.scale(
              scale: animScale,
              child: Opacity(
                opacity: animOpacity.clamp(0.0, 1.0),
                child: sizedContent,
              ),
            ),
          ),
          layer.blendMode,
        ),
        layer.mask,
      ),
    );
  }

  /// Universal interactive wrapper for any text layer (Arabic, Translation, Normal Text)
  Widget _buildSmartBoundingBoxWrapper({
    required Layer layer,
    required double previewWidth,
    required double previewHeight,
    required bool isSelected,
    required Widget child,
    double defaultX = 0,
    double defaultY = 0,
    double defaultWidthRatio = 0.85,
    bool fillWidthWhenNoCustom = false,
  }) {
    final styleX = layer.style['x'];
    final styleY = layer.style['y'];
    final transformX = layer.transform.x;
    final transformY = layer.transform.y;

    final x = styleX is num
        ? styleX.toDouble()
        : (transformX >= 0.0 && transformX <= 1.0
              ? (transformX * previewWidth) -
                    (previewWidth * defaultWidthRatio / 2)
              : defaultX);
    final y = styleY is num
        ? styleY.toDouble()
        : (transformY >= 0.0 && transformY <= 1.0
              ? transformY * previewHeight
              : defaultY);
    final scale = layer.style['scale']?.toDouble() ?? 1.0;
    final customWidth = layer.style['width']?.toDouble();

    Widget sizedContent = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: previewWidth * defaultWidthRatio),
      child: customWidth != null
          ? SizedBox(width: customWidth, child: child)
          : (fillWidthWhenNoCustom
                ? SizedBox(
                    width: previewWidth * defaultWidthRatio,
                    child: child,
                  )
                : IntrinsicWidth(child: child)),
    );

    if (isSelected) {
      final borderColor = const Color(0xFF2196F3);
      sizedContent = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: borderColor.withValues(alpha: 0.85),
                width: 1.5 / scale,
              ),
              borderRadius: BorderRadius.circular(3 / scale),
            ),
            child: sizedContent,
          ),
          // Poignée droite (Ajuster la largeur)
          Positioned(
            right: -30 / scale,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) {
                double newW =
                    (customWidth ?? previewWidth * defaultWidthRatio) +
                    (details.delta.dx / scale);
                newW = newW.clamp(50.0, previewWidth);
                ref
                    .read(editorProvider.notifier)
                    .updateLayer(
                      layer.copyWith(style: {...layer.style, 'width': newW}),
                    );
              },
              child: SizedBox(
                width: 60 / scale, // Large zone tactile invisible
                child: Center(
                  child: Container(
                    width: 6 / scale,
                    height: 24 / scale, // Aspect visuel inchangé
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: borderColor, width: 1 / scale),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Poignée en bas à droite (Ajuster l'échelle / zoom)
          Positioned(
            right: -30 / scale,
            bottom: -30 / scale,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) {
                double newScale =
                    scale +
                    (details.delta.dx * 0.01) +
                    (details.delta.dy * 0.01);
                newScale = newScale.clamp(0.2, 5.0);
                ref
                    .read(editorProvider.notifier)
                    .updateLayer(
                      layer.copyWith(
                        style: {...layer.style, 'scale': newScale},
                      ),
                    );
              },
              child: SizedBox(
                width: 60 / scale,
                height: 60 / scale, // Large zone tactile invisible
                child: Center(
                  child: Container(
                    width: 12 / scale,
                    height: 12 / scale, // Aspect visuel inchangé
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: borderColor,
                        width: 1.5 / scale,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) =>
            ref.read(editorProvider.notifier).setSelectedLayer(layer.id),
        onPanStart: (details) {
          ref.read(editorProvider.notifier).setSelectedLayer(layer.id);
          _draggingLayerId = layer.id;
          _dragStart = details.globalPosition;
          _layerStartOffset = Offset(x, y);
        },
        onPanUpdate: (details) {
          if (_draggingLayerId != layer.id) return;
          final dx = details.globalPosition.dx - _dragStart.dx;
          final dy = details.globalPosition.dy - _dragStart.dy;
          final newX = (_layerStartOffset.dx + dx).clamp(
            -previewWidth,
            previewWidth * 2,
          );
          final newY = (_layerStartOffset.dy + dy).clamp(
            -previewHeight,
            previewHeight * 2,
          );
          final updated = layer.copyWith(
            style: {...layer.style, 'x': newX, 'y': newY},
          );
          ref.read(editorProvider.notifier).updateLayer(updated);
        },
        onPanEnd: (_) => _draggingLayerId = null,
        child: Transform.scale(scale: scale, child: sizedContent),
      ),
    );
  }
}

class _QuranAnimationPainter extends CustomPainter {
  final String animationId;
  final double progress;
  final Color textColor;
  _QuranAnimationPainter({
    required this.animationId,
    required this.progress,
    required this.textColor,
  });
  @override
  void paint(Canvas canvas, Size size) {
    paintQuranAnimation(
      canvas,
      Rect.fromLTWH(0, 0, size.width, size.height),
      animationId,
      progress,
      textColor: textColor,
    );
  }

  @override
  bool shouldRepaint(covariant _QuranAnimationPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.animationId != animationId ||
      oldDelegate.textColor != textColor;
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant _TriangleClipper oldClipper) => false;
}

class _HeartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width, h = size.height;
    path.moveTo(w / 2, h * 0.3);
    path.cubicTo(w / 2, 0, 0, 0, 0, h * 0.3);
    path.cubicTo(0, h * 0.6, w / 2, h, w / 2, h);
    path.cubicTo(w / 2, h, w, h * 0.6, w, h * 0.3);
    path.cubicTo(w, 0, w / 2, 0, w / 2, h * 0.3);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _HeartClipper oldClipper) => false;
}

class _StarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final cx = size.width / 2, cy = size.height / 2;
    final outerR = math.min(cx, cy), innerR = outerR * 0.4;
    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = i * math.pi / 5 - math.pi / 2;
      if (i == 0) {
        path.moveTo(cx + r * math.cos(angle), cy + r * math.sin(angle));
      } else {
        path.lineTo(cx + r * math.cos(angle), cy + r * math.sin(angle));
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _StarClipper oldClipper) => false;
}

class _SplitClipper extends CustomClipper<Path> {
  final Axis axis;
  final double value;
  _SplitClipper({required this.axis, required this.value});
  @override
  Path getClip(Size size) {
    final path = Path();
    if (axis == Axis.horizontal) {
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height * value));
    } else {
      path.addRect(Rect.fromLTWH(0, 0, size.width * value, size.height));
    }
    return path;
  }

  @override
  bool shouldReclip(covariant _SplitClipper oldClipper) =>
      oldClipper.axis != axis || oldClipper.value != value;
}

// ── Format Badge ─────────────────────────────────────────────────────────────
/// A compact pill that shows the aspect ratio + current timecode.
/// Positioned in the top-left corner of the canvas.
class _FormatBadge extends StatelessWidget {
  final String aspectRatio;
  final double currentTime;
  final double totalDuration;

  const _FormatBadge({
    required this.aspectRatio,
    required this.currentTime,
    required this.totalDuration,
  });

  String _formatTime(double s) {
    final m = (s / 60).floor();
    final sec = (s % 60).floor();
    final ms = ((s % 1) * 10).floor();
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}.$ms';
  }

  @override
  Widget build(BuildContext context) {
    final progress = totalDuration > 0
        ? (currentTime / totalDuration).clamp(0.0, 1.0)
        : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Aspect ratio chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: const Color(0xFF2196F3).withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              aspectRatio,
              style: const TextStyle(
                color: Color(0xFF90CAF9),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Timecode
          Text(
            _formatTime(currentTime),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '/ ${_formatTime(totalDuration)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 6),
          // Mini progress bar
          SizedBox(
            width: 36,
            height: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF2196F3),
                ),
                minHeight: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
} // End of _VideoPreviewState

/// Master Video Layer - Performance isolated.
/// Only rebuilds when time or structural state specifically requires it.
class _VideoLayerRenderer extends StatelessWidget {
  final double width;
  final double height;
  final VideoPlayerController? controller;
  final bool isInitialized;
  final Widget Function(Widget, LayerMask) applyMask;
  final Widget Function(Widget, String) applyBlendMode;

  const _VideoLayerRenderer({
    required this.width,
    required this.height,
    this.controller,
    required this.isInitialized,
    required this.applyMask,
    required this.applyBlendMode,
  });

  @override
  Widget build(BuildContext context) {
    if (!isInitialized ||
        controller == null ||
        !controller!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    // VideoPlayer handles its own sync internally. We do not pass our synthetic
    // timeline time, which prevents severe Texture rebinding crashes on screen refreshes.
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: AspectRatio(
          aspectRatio: controller!.value.aspectRatio,
          child: VideoPlayer(controller!),
        ),
      ),
    );
  }
}
