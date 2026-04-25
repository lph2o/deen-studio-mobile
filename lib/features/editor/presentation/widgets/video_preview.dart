import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/utils/color_filters.dart';
import '../../../../models/project.dart';
import '../../../../core/models/voice_effect.dart';
import '../../../../core/models/canvas_background.dart';
import '../../../../core/services/quran_animation_export.dart';
import '../../../../models/text_layer_style.dart';
import '../recitation/recitation_timing.dart';
import 'package:google_fonts/google_fonts.dart';
import '../editor_state.dart';
import 'glyph_deformation_renderer.dart';
import '../../../../core/theme.dart';

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
  Offset _layerStartOffset = Offset.zero;
  Offset _dragStart = Offset.zero;
  double _layerStartScale = 1.0;

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
        (l) => l.content == _currentAudioPath && l.activeAt(fallbackTimelineTime),
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
      audioPosition: _audioPlayer.position - Duration(milliseconds: ((anchor.inPoint ?? 0.0) * 1000).round()),
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
      if (!_failedAudioPaths.contains(audioPath)) {
        _failedAudioPaths.add(audioPath);
      }
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
        final inPoint = activeLayer.inPoint ?? 0.0;
        final expectedPosition = RecitationTiming.computeSwitchSeekPosition(
          isPlaying: state.isPlaying,
          currentTime: currentTime,
          layerStartTime: activeLayer.startTime,
          playbackSpeed: playbackSpeed,
        );
        // Add inPoint so we seek to the correct chapter position
        final seekWithInPoint = expectedPosition + Duration(milliseconds: (inPoint * 1000).round());
        await _audioPlayer.setFilePath(audioPath);
        await _audioPlayer.seek(seekWithInPoint);
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
        final inPoint = activeLayer.inPoint ?? 0.0;
        final expectedPosition = Duration(
          milliseconds: ((currentTime - activeLayer.startTime + inPoint) * 1000).toInt(),
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
          // Massive drift > 1.5s, force a resync
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
    if (activeLayer.noiseGateThreshold > 0) {
      baseVolume *= (1.0 - activeLayer.noiseGateThreshold * 0.5);
    }
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

  // ignore: unused_element
  Matrix4 _getLayerTransform(Layer layer, double currentTime) {
    if (layer.keyframes.isNotEmpty) {
      final notifier = ref.read(editorProvider.notifier);
      final transform = notifier.getTransformAtTime(layer.id, currentTime);
      return Matrix4.translationValues(transform.x, transform.y, 0.0)
        ..multiply(Matrix4.rotationZ(transform.rotation * math.pi / 180))
        ..multiply(Matrix4.diagonal3Values(transform.scaleX, transform.scaleY, 1.0));
    }
    final scale = layer.style['scale']?.toDouble() ?? 1.0;
    final rotation = layer.style['rotation']?.toDouble() ?? 0.0;
    final offsetX = layer.style['offsetX']?.toDouble() ?? 0.0;
    final offsetY = layer.style['offsetY']?.toDouble() ?? 0.0;
    return Matrix4.translationValues(offsetX, offsetY, 0.0)
      ..multiply(Matrix4.rotationZ(rotation * math.pi / 180))
      ..multiply(Matrix4.diagonal3Values(scale, scale, 1.0));
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
    if (mask.type == MaskType.none) return child;
    if (mask.value == 0) return const SizedBox.shrink(); // Hide completely if size is 0

    return ClipPath(
      clipper: MaskClipper(mask),
      child: child,
    );
  }

  Widget _buildCanvasBackground(Project project, double width, double height) {
    final bg = kCanvasBackgrounds.firstWhere(
      (b) => b.id == project.canvasBackgroundId,
      orElse: () => kCanvasBackgrounds.first,
    );
    return bg.buildBackground();
  }

  Widget _buildVideoLayer(Layer layer, double width, double height) {
    Widget videoWidget = _VideoLayerRenderer(
      width: width,
      height: height,
      controller: _videoController,
      isInitialized: _isVideoInitialized,
      applyMask: _applyMask,
      applyBlendMode: _applyBlendMode,
    );

    // Opacity: merge style['opacity'] and transform.opacity
    final styleOpacity = (layer.style['opacity'] as num?)?.toDouble() ?? 1.0;
    final finalOpacity = (styleOpacity * layer.transform.opacity).clamp(0.0, 1.0);

    // ── Color Matrix (preset + dynamic adjustments) ──────────────────────────
    List<double> currentMatrix = ColorMatrixUtils.forId(layer.filterId);

    double blurSigma = 0.0;
    double vignetteIntensity = 0.0;

    for (final effect in layer.effects) {
      if (!effect.enabled) continue;
      final val = (effect.params['value'] as num?)?.toDouble() ?? 0.0;
      switch (effect.type) {
        case 'brightness':
          currentMatrix = ColorMatrixUtils.multiply(currentMatrix, ColorMatrixUtils.brightness(val));
          break;
        case 'contrast':
          currentMatrix = ColorMatrixUtils.multiply(currentMatrix, ColorMatrixUtils.contrast(val));
          break;
        case 'saturation':
          currentMatrix = ColorMatrixUtils.multiply(currentMatrix, ColorMatrixUtils.saturation(val));
          break;
        case 'grayscale':
          currentMatrix = ColorMatrixUtils.multiply(currentMatrix, ColorMatrixUtils.grayscalePreset);
          break;
        case 'blur':
          blurSigma = (val * 20.0).clamp(0.0, 20.0);
          break;
        case 'vignette':
          vignetteIntensity = val.clamp(0.0, 1.0);
          break;
      }
    }

    // Apply ColorGrading (HSL + Wheels)
    if (layer.colorGrading.hue != 0) {
      currentMatrix = ColorMatrixUtils.multiply(currentMatrix, ColorMatrixUtils.hue(layer.colorGrading.hue));
    }
    if (layer.colorGrading.saturation != 0) {
      currentMatrix = ColorMatrixUtils.multiply(currentMatrix, ColorMatrixUtils.saturation(1.0 + (layer.colorGrading.saturation / 100.0)));
    }
    if (layer.colorGrading.lightness != 0) {
      currentMatrix = ColorMatrixUtils.multiply(currentMatrix, ColorMatrixUtils.brightness(layer.colorGrading.lightness / 100.0));
    }
    // Apply Curves
    if (!layer.colorGrading.isDefault) {
      if (layer.colorGrading.masterCurve.length > 2 || layer.colorGrading.masterCurve[1].y != 0.5) {
        currentMatrix = ColorMatrixUtils.multiply(currentMatrix, ColorMatrixUtils.curveApproximation(layer.colorGrading.masterCurve));
      }
      if (layer.colorGrading.redCurve.length > 2 || layer.colorGrading.redCurve[1].y != 0.5) {
        currentMatrix = ColorMatrixUtils.multiply(currentMatrix, ColorMatrixUtils.curveApproximation(layer.colorGrading.redCurve, channelIndex: 0));
      }
      if (layer.colorGrading.greenCurve.length > 2 || layer.colorGrading.greenCurve[1].y != 0.5) {
        currentMatrix = ColorMatrixUtils.multiply(currentMatrix, ColorMatrixUtils.curveApproximation(layer.colorGrading.greenCurve, channelIndex: 1));
      }
      if (layer.colorGrading.blueCurve.length > 2 || layer.colorGrading.blueCurve[1].y != 0.5) {
        currentMatrix = ColorMatrixUtils.multiply(currentMatrix, ColorMatrixUtils.curveApproximation(layer.colorGrading.blueCurve, channelIndex: 2));
      }
    }

    if (!layer.colorGrading.isDefault) {
      currentMatrix = ColorMatrixUtils.multiply(currentMatrix, ColorMatrixUtils.colorWheels(
        shadowsTint: layer.colorGrading.shadowsTint,
        shadowsAmount: layer.colorGrading.shadowsAmount / 100.0,
        midtonesTint: layer.colorGrading.midtonesTint,
        midtonesAmount: layer.colorGrading.midtonesAmount / 100.0,
        highlightsTint: layer.colorGrading.highlightsTint,
        highlightsAmount: layer.colorGrading.highlightsAmount / 100.0,
      ));
    }

    // Apply color matrix
    videoWidget = ColorFiltered(
      colorFilter: ColorFilter.matrix(currentMatrix),
      child: videoWidget,
    );

    // Apply Gaussian blur
    if (blurSigma > 0) {
      videoWidget = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: videoWidget,
      );
    }

    // Apply vignette overlay
    if (vignetteIntensity > 0) {
      videoWidget = Stack(
        children: [
          videoWidget,
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: vignetteIntensity * 0.85),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Apply rotation and scale from transform
    final rotation = layer.transform.rotation;
    final scaleX = layer.transform.scaleX;
    final scaleY = layer.transform.scaleY;
    if (rotation != 0 || scaleX != 1.0 || scaleY != 1.0) {
      videoWidget = Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationZ(rotation * math.pi / 180)
          ..multiply(Matrix4.diagonal3Values(scaleX, scaleY, 1.0)),
        child: videoWidget,
      );
    }

    return _applyMask(
      _applyBlendMode(
        Opacity(opacity: finalOpacity, child: videoWidget),
        layer.blendMode,
      ),
      layer.mask,
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
    bool isSelected,
    bool isLocked,
  ) {
    final file = File(layer.content);
    if (!file.existsSync()) return const SizedBox.shrink();

    // Opacity: merge style['opacity'] and transform.opacity
    final styleOpacity = (layer.style['opacity'] as num?)?.toDouble() ?? 1.0;
    final finalOpacity = (styleOpacity * layer.transform.opacity).clamp(0.0, 1.0);

    final w = layer.style['width']?.toDouble() ?? previewWidth;
    final h = layer.style['height']?.toDouble() ?? previewHeight;

    // ── Color Matrix (preset + dynamic adjustments) ──────────────────────────
    List<double> currentMatrix = ColorMatrixUtils.forId(layer.filterId);

    double blurSigma = 0.0;
    double vignetteIntensity = 0.0;

    for (final effect in layer.effects) {
      if (!effect.enabled) continue;
      final val = (effect.params['value'] as num?)?.toDouble() ?? 0.0;
      switch (effect.type) {
        case 'brightness':
          currentMatrix = ColorMatrixUtils.multiply(currentMatrix, ColorMatrixUtils.brightness(val));
          break;
        case 'contrast':
          currentMatrix = ColorMatrixUtils.multiply(currentMatrix, ColorMatrixUtils.contrast(val));
          break;
        case 'saturation':
          currentMatrix = ColorMatrixUtils.multiply(currentMatrix, ColorMatrixUtils.saturation(val));
          break;
        case 'grayscale':
          currentMatrix = ColorMatrixUtils.multiply(currentMatrix, ColorMatrixUtils.grayscalePreset);
          break;
        case 'blur':
          blurSigma = (val * 20.0).clamp(0.0, 20.0);
          break;
        case 'vignette':
          vignetteIntensity = val.clamp(0.0, 1.0);
          break;
        // noise requires shader — stored in model, rendered in future phase
      }
    }

    // Apply ColorGrading (HSL + Wheels)
    if (layer.colorGrading.hue != 0) {
      currentMatrix = ColorMatrixUtils.multiply(currentMatrix, ColorMatrixUtils.hue(layer.colorGrading.hue));
    }
    if (layer.colorGrading.saturation != 0) {
      currentMatrix = ColorMatrixUtils.multiply(currentMatrix, ColorMatrixUtils.saturation(1.0 + (layer.colorGrading.saturation / 100.0)));
    }
    if (layer.colorGrading.lightness != 0) {
      currentMatrix = ColorMatrixUtils.multiply(currentMatrix, ColorMatrixUtils.brightness(layer.colorGrading.lightness / 100.0));
    }
    if (!layer.colorGrading.isDefault) {
      if (layer.colorGrading.masterCurve.length > 2 || layer.colorGrading.masterCurve[1].y != 0.5) {
        currentMatrix = ColorMatrixUtils.multiply(currentMatrix, ColorMatrixUtils.curveApproximation(layer.colorGrading.masterCurve));
      }
      if (layer.colorGrading.redCurve.length > 2 || layer.colorGrading.redCurve[1].y != 0.5) {
        currentMatrix = ColorMatrixUtils.multiply(currentMatrix, ColorMatrixUtils.curveApproximation(layer.colorGrading.redCurve, channelIndex: 0));
      }
      if (layer.colorGrading.greenCurve.length > 2 || layer.colorGrading.greenCurve[1].y != 0.5) {
        currentMatrix = ColorMatrixUtils.multiply(currentMatrix, ColorMatrixUtils.curveApproximation(layer.colorGrading.greenCurve, channelIndex: 1));
      }
      if (layer.colorGrading.blueCurve.length > 2 || layer.colorGrading.blueCurve[1].y != 0.5) {
        currentMatrix = ColorMatrixUtils.multiply(currentMatrix, ColorMatrixUtils.curveApproximation(layer.colorGrading.blueCurve, channelIndex: 2));
      }
    }

    if (!layer.colorGrading.isDefault) {
      currentMatrix = ColorMatrixUtils.multiply(currentMatrix, ColorMatrixUtils.colorWheels(
        shadowsTint: layer.colorGrading.shadowsTint,
        shadowsAmount: layer.colorGrading.shadowsAmount / 100.0,
        midtonesTint: layer.colorGrading.midtonesTint,
        midtonesAmount: layer.colorGrading.midtonesAmount / 100.0,
        highlightsTint: layer.colorGrading.highlightsTint,
        highlightsAmount: layer.colorGrading.highlightsAmount / 100.0,
      ));
    }

    // ── Build image ──────────────────────────────────────────────────────────
    Widget imageWidget = Image.file(file, width: w, height: h, fit: BoxFit.contain);

    // Apply color matrix
    imageWidget = ColorFiltered(
      colorFilter: ColorFilter.matrix(currentMatrix),
      child: imageWidget,
    );

    // Apply Gaussian blur
    if (blurSigma > 0) {
      imageWidget = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: imageWidget,
      );
    }

    // Apply vignette overlay
    if (vignetteIntensity > 0) {
      imageWidget = Stack(
        children: [
          imageWidget,
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: vignetteIntensity * 0.85),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Apply rotation and scale from transform
    final rotation = layer.transform.rotation;
    final scaleX = layer.transform.scaleX;
    final scaleY = layer.transform.scaleY;
    if (rotation != 0 || scaleX != 1.0 || scaleY != 1.0) {
      imageWidget = Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationZ(rotation * math.pi / 180)
          ..multiply(Matrix4.diagonal3Values(scaleX, scaleY, 1.0)),
        child: imageWidget,
      );
    }

    return _buildSmartBoundingBoxWrapper(
      layer: layer,
      previewWidth: previewWidth,
      previewHeight: previewHeight,
      isSelected: isSelected,
      isLocked: isLocked,
      defaultX: previewWidth / 2 - w / 2,
      defaultY: previewHeight / 2 - h / 2,
      isProportionalOnly: true,
      fillWidthWhenNoCustom: false,
      child: _applyMask(
        _applyBlendMode(
          Opacity(opacity: finalOpacity, child: imageWidget),
          layer.blendMode,
        ),
        layer.mask,
      ),
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
    final styleOpacity = (layer.style['opacity'] as num?)?.toDouble() ?? 1.0;
    final opacity = (styleOpacity * layer.transform.opacity).clamp(0.0, 1.0);
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
          if (layerProgress < 0.4) {
            stickerWidget = Transform.translate(
              offset: Offset(
                0,
                -20 *
                    math.sin(layerProgress / 0.4 * math.pi * 3) *
                    (1.0 - layerProgress / 0.4),
              ),
              child: stickerWidget,
            );
          }
          break;
        case 3:
          if (layerProgress < 0.5) {
            stickerWidget = Transform.rotate(
              angle:
                  math.sin(layerProgress * math.pi * 4) *
                  0.3 *
                  (1.0 - layerProgress * 2),
              child: stickerWidget,
            );
          }
          break;
        case 4:
          if (layerProgress < 0.3) {
            stickerWidget = Transform.scale(
              scale: 0.5 + 0.5 * (layerProgress / 0.3),
              child: stickerWidget,
            );
          }
          break;
        case 5:
          if (layerProgress < 0.3) {
            stickerWidget = Transform.translate(
              offset: Offset(-50 * (1.0 - layerProgress / 0.3), 0),
              child: stickerWidget,
            );
          }
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
            transform: Matrix4.diagonal3Values(scaleX, scaleY, 1.0)
              ..multiply(Matrix4.rotationZ(layer.transform.rotation * math.pi / 180)),
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
    if (FontCatalogue.isLocal(family)) {
      return baseStyle.copyWith(fontFamily: family);
    }

    try {
      return GoogleFonts.getFont(family, textStyle: baseStyle);
    } catch (_) {
      return baseStyle.copyWith(fontFamily: family);
    }
  }

  double _resolveTextOpacity(Layer layer, TextLayerStyle? style) {
    final legacyOpacity = (layer.style['opacity'] as num?)?.toDouble();
    final unifiedOpacity = style?.opacity ?? legacyOpacity ?? 1.0;
    return unifiedOpacity.clamp(0.0, 1.0);
  }

  Widget _wrapWithCaptionStyle(Widget child, TextLayerStyle? style) {
    if (style == null ||
        style.captionStyleId != 'bubble' ||
        style.backgroundColor == null) {
      return child;
    }

    final alignment = style.textAlign == TextAlign.left
        ? Alignment.centerLeft
        : (style.textAlign == TextAlign.right
              ? Alignment.centerRight
              : Alignment.center);

    return Align(
      alignment: alignment,
      child: IntrinsicWidth(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: style.backgroundPadding * 1.5,
            vertical: style.backgroundPadding,
          ),
          decoration: BoxDecoration(
            color: TextLayerStyle.parseHexColor(
              style.backgroundColor!,
            ).withValues(alpha: style.opacity),
            borderRadius: BorderRadius.circular(style.borderRadius),
          ),
          child: child,
        ),
      ),
    );
  }

  /// Detects if a word is one of the Muqatta'at letters (extended duration)
  bool _isMuqattaat(String word) {
    final clean = word
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '') // Remove Harakat
        .trim();

    const list = [
      'الم',
      'المص',
      'الر',
      'المر',
      'كهيعص',
      'طه',
      'طسم',
      'طس',
      'يس',
      'ص',
      'حم',
      'عسق',
      'ق',
      'ن',
    ];

    // Also check for phonetic versions (case insensitive)
    final phonetic = word
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z\s]'), '')
        .trim();
    const phoneticList = [
      'ALM',
      'ALMR',
      'ALMS',
      'ALR',
      'KHYAS',
      'TH',
      'TSM',
      'TS',
      'YS',
      'HM',
      'ASQ',
    ];

    return list.contains(clean) || phoneticList.contains(phonetic);
  }

  /// Calculates weights for words based on Tajwid rules and character length
  List<double> _calculateWordWeights(String text) {
    final words = text.split(RegExp(r'\s+'));
    return words.map((w) {
      double weight = 0.0;

      // 1. Base phonetic weight (consonants)
      final consonants = w.replaceAll(RegExp(r'[ًٌٍَُِّْٓ]'), '').length;
      weight += consonants * 2.0;

      // 2. Muqatta'at (Special handling for Alif-Lam-Mim-Ra in Ar-Ra'd)
      if (_isMuqattaat(w)) {
        // Alif-Lam-Mim-Ra in Ar-Ra'd (الٓمّٓر) is exceptionally long (9s-10s)
        if (w.contains('الٓمّٓر') || w.contains('ALMR')) return 130.0;
        return 90.0;
      }

      // 3. Tajwid: Madd (Prolongations) ٓ - can be 2, 4, 5 or 6 beats
      final maddCount = 'ٓ'.allMatches(w).length;
      weight += maddCount * 18.0;

      // 4. Tajwid: Shaddah (Doubled letters) ّ - doubling the duration
      final shaddahCount = 'ّ'.allMatches(w).length;
      weight += shaddahCount * 8.0;

      // 5. Tajwid: Ghunnah (Noon/Meem with Shaddah or Tanween)
      // Noon/Meem Mushaddadah are the strongest Ghunnah
      final ghunnahLetters = RegExp(r'[نم]ّ').allMatches(w).length;
      weight += ghunnahLetters * 10.0;

      if (w.contains('ً') || w.contains('ٍ') || w.contains('ٌ')) {
        weight += 4.0;
      }

      // 6. Long vowels (Alif, Waw, Ya)
      final longVowels = RegExp(r'[اوي]').allMatches(w).length;
      weight += longVowels * 3.0;

      // 7. Short vowels (Harakat) - adds rhythmic density
      final harakat = RegExp(r'[َُِ]').allMatches(w).length;
      weight += harakat * 1.5;

      // 8. Sukun (Pause/Stop weight) - often at end of words (Sukun de pause)
      if (w.endsWith('ْ') || !RegExp(r'[ًٌٍَُِ]$').hasMatch(w)) {
        weight += 4.0;
      }

      return weight.clamp(1.0, 500.0);
    }).toList();
  }

  /// Resolves the current word index based on time and word weights
  int _resolveWeightedWordIndex(double progress, List<double> weights) {
    if (weights.isEmpty) return -1;
    final totalWeight = weights.reduce((a, b) => a + b);
    if (totalWeight <= 0) return -1;

    double cumulative = 0;
    final target = progress * totalWeight;
    for (int i = 0; i < weights.length; i++) {
      cumulative += weights[i];
      if (target <= cumulative) return i;
    }
    return weights.length - 1;
  }

  Widget _buildWordByWordBubbleText(
    String text,
    int activeWordIndex,
    TextLayerStyle? style,
    TextStyle baseStyle,
    TextAlign textAlign,
  ) {
    final words = text.split(RegExp(r'\s+'));
    final isBubble = style?.captionStyleId == 'bubble';

    return Wrap(
      alignment: textAlign == TextAlign.left
          ? WrapAlignment.start
          : (textAlign == TextAlign.right
                ? WrapAlignment.end
                : WrapAlignment.center),
      spacing: 8.0,
      runSpacing: 4.0,
      children: words.asMap().entries.map((entry) {
        final word = entry.value;
        final isActive = entry.key == activeWordIndex;
        final isPast = entry.key < activeWordIndex;

        if (isBubble) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: style!.backgroundPadding * (isActive ? 1.4 : 1.2),
              vertical: style.backgroundPadding * 0.6,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? TextLayerStyle.parseHexColor(
                      style.backgroundColor ?? '#000000',
                    ).withValues(alpha: style.opacity)
                  : (isPast
                        ? TextLayerStyle.parseHexColor(
                            style.backgroundColor ?? '#000000',
                          ).withValues(alpha: style.opacity * 0.3)
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(style.borderRadius),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: TextLayerStyle.parseHexColor(
                          style.backgroundColor ?? '#000000',
                        ).withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              style: baseStyle.copyWith(
                color: isActive
                    ? TextLayerStyle.parseHexColor(style.color)
                    : (isPast
                          ? TextLayerStyle.parseHexColor(
                              style.color,
                            ).withValues(alpha: 0.5)
                          : TextLayerStyle.parseHexColor(
                              style.color,
                            ).withValues(alpha: 0.3)),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
              child: Text(word),
            ),
          );
        }

        return Text(
          word,
          style: baseStyle.copyWith(
            color: isActive
                ? AppTheme.primaryColor
                : (isPast
                      ? baseStyle.color?.withValues(alpha: 0.5)
                      : baseStyle.color),
          ),
        );
      }).toList(),
    );
  }

  String _resolveTextAnimation(Layer layer, TextLayerStyle? style) {
    final legacy = layer.style['animation'] as String?;
    if (style == null) return legacy ?? 'fade';

    switch (style.animationPreset) {
      case TextAnimationPreset.none:
        return legacy ?? 'none';
      case TextAnimationPreset.fadeIn:
        return 'fadeIn';
      case TextAnimationPreset.fadeOut:
        return 'fadeOut';
      case TextAnimationPreset.fadeInOut:
        return 'fadeInOut';
      case TextAnimationPreset.slideInLeft:
        return 'slideInLeft';
      case TextAnimationPreset.slideInRight:
        return 'slideInRight';
      case TextAnimationPreset.slideInTop:
        return 'slideInTop';
      case TextAnimationPreset.slideInBottom:
        return 'slideInBottom';
      case TextAnimationPreset.typewriter:
        return 'typewriter';
      case TextAnimationPreset.bounceIn:
        return 'bounceIn';
      case TextAnimationPreset.scaleIn:
        return 'scaleIn';
      case TextAnimationPreset.scaleOut:
        return 'fadeOut';
      case TextAnimationPreset.glitchIn:
        return 'fadeIn';
      case TextAnimationPreset.karaokeRTL:
      case TextAnimationPreset.wordByWord:
      case TextAnimationPreset.wordHighlight:
        return 'typewriter';
    }
  }

  Widget _buildArabicLayer(
    Layer layer,
    double currentTime,
    double previewWidth,
    double previewHeight, {
    String? selectedLayerId,
    bool isLocked = false,
  }) {
    final style = layer.textStyle;
    final scaleFactor = previewWidth / 360.0;
    final baseFontSize = layer.fontSize ?? style?.fontSize ?? 26;
    final fontSize = baseFontSize * scaleFactor * 1.1;
    final colorStr = layer.textColor ?? style?.color;
    final color = colorStr != null ? _parseColor(colorStr) : Colors.white;
    final fontFamily =
        layer.fontFamily ?? style?.fontFamily ?? 'UthmanicRegular';
    final opacity = _resolveTextOpacity(layer, style);
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
    TextSpan? deformationSpan;
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
      // Use slightly larger chunks (10 words) for smooth Tajwid weighting across each verse
      final chunks = _chunkWordTimings(layer.wordTimings, wordsPerChunk: 10);
      if (chunks.isNotEmpty) {
        // Use elapsed time relative to this layer's start —
        // word timings are stored relative (0.0 = start of this ayah),
        // so we must compare them against elapsed, not the absolute clock.
        final elapsedTime = currentTime - layer.startTime;

        // Find chunk that matches the current elapsed time.
        // Use <= c.end (inclusive) to prevent the last chunk from
        // disappearing prematurely before the next verse begins.
        final activeChunk = chunks.firstWhere(
          (c) => elapsedTime >= c.start && elapsedTime <= c.end,
          orElse: () =>
              elapsedTime < chunks.first.start ? chunks.first : chunks.last,
        );

        displayText = activeChunk.text;

        final chunkDuration = activeChunk.duration;
        if (chunkDuration > 0) {
          localProgress = ((elapsedTime - activeChunk.start) / chunkDuration)
              .clamp(0.0, 1.0);
        }

        if (activeChunk.wordTimings != null) {
          final chunkTimings = activeChunk.wordTimings!;
          int currentWordIndex = 0;

          for (int i = 0; i < chunkTimings.length; i++) {
            final wordStart = (chunkTimings[i]['start'] as num).toDouble();
            final wordEnd = (chunkTimings[i]['end'] as num).toDouble();
            if (elapsedTime >= wordStart && elapsedTime <= wordEnd) {
              currentWordIndex = i;
              break;
            }
            if (elapsedTime > wordEnd) currentWordIndex = i + 1;
          }

          // Override index for Muqattaat letters which require special weighting.
          final words = activeChunk.text.split(RegExp(r'\s+'));
          if (words.any((w) => _isMuqattaat(w))) {
            final weights = _calculateWordWeights(activeChunk.text);
            currentWordIndex = _resolveWeightedWordIndex(
              localProgress,
              weights,
            );
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
          final mergedShadows = [...?resolvedStyle.shadows, ...?glowShadows];

          final wordsList = activeChunk.text.split(RegExp(r'\s+'));

          // When using a shader animation, split into TWO layers: base and active
          wordSpans = wordsList.asMap().entries.map((entry) {
            final isActive = entry.key <= currentWordIndex;

            Color textColor;
            if (isShaderDriven) {
              textColor = isActive ? Colors.transparent : color;
            } else {
              textColor = isActive ? const Color(0xFFFFD700) : color;
            }

            return TextSpan(
              text:
                  (style?.isUppercase == true
                      ? entry.value.toUpperCase()
                      : entry.value) +
                  (entry.key < wordsList.length - 1 ? ' ' : ''),
              style: resolvedStyle.copyWith(
                color: textColor,
                shadows: mergedShadows.isEmpty ? null : mergedShadows,
              ),
            );
          }).toList();
          deformationSpan = TextSpan(children: wordSpans);

          // If shader driven, secondary active span list for the ShaderMask top layer
          if (isShaderDriven) {
            final activeSpans = wordsList.asMap().entries.map((entry) {
              final isActive = entry.key <= currentWordIndex;
              final wordText =
                  entry.value + (entry.key < wordsList.length - 1 ? ' ' : '');
              final parsedWord = style?.isUppercase == true
                  ? wordText.toUpperCase()
                  : wordText;
              return TextSpan(
                text: parsedWord,
                style: resolvedStyle.copyWith(
                  color: isActive ? Colors.white : Colors.transparent,
                  shadows: mergedShadows.isEmpty ? null : mergedShadows,
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

          if (style?.captionStyleId == 'bubble') {
            textWidget = _buildWordByWordBubbleText(
              activeChunk.text,
              currentWordIndex,
              style,
              resolvedStyle,
              style?.textAlign ?? TextAlign.center,
            );
          }
        }
      }
    }

    final fallbackSpan = TextSpan(
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
                        ...?resolvedStyle.shadows,
                        Shadow(
                          color: const Color(0xFFE0B0FF).withValues(alpha: 0.8),
                          blurRadius: (math.sin(localProgress * math.pi) * 20)
                              .clamp(0.0, 20.0),
                        ),
                      ]
                    : resolvedStyle.shadows,
              ),
            ),
          ],
    );
    deformationSpan ??= fallbackSpan;
    textWidget ??= RichText(
      text: fallbackSpan,
      textAlign: style?.textAlign ?? TextAlign.center,
      textDirection: TextDirection.rtl,
    );

    if (hasQuranAnimation) {
      final shaderAnimations = ['rainbow', 'sunset', 'aurora'];
      final overlayAnimations = [
        'ethereal_glow',
        'divine_revelation',
        'celestial_light',
        'divine_radiance',
        'sacred_ripple',
        'mercy_wave',
        'incense_smoke',
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
      final glyphDeformationAnimations = [
        'sacred_ripple',
        'mercy_wave',
        'river_flow',
        'ethereal_glow',
        'divine_radiance',
        'divine_revelation',
        'celestial_light',
        'night_of_power',
        'lightning',
        'earth_shake',
        'galaxy',
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

      final isGlyphDeformation = glyphDeformationAnimations.contains(
        quranAnimationId,
      );
      if (isGlyphDeformation && !shaderAnimations.contains(quranAnimationId)) {
        mappedWidget = GlyphDeformationText(
          text: deformationSpan,
          textAlign: style?.textAlign ?? TextAlign.center,
          textDirection: TextDirection.rtl,
          animationId: quranAnimationId,
          progress: localProgress,
          config: style?.animationConfig ?? const AnimationConfig(),
        );
      }

      // 2. Foreground vs Background rendering of the CustomPainter
      final isOverlay = overlayAnimations.contains(quranAnimationId);
      final isGlow = quranAnimationId == 'ethereal_glow';
      final disablePainterForGlyph = isGlyphDeformation;

      mappedWidget = _wrapWithCaptionStyle(mappedWidget, style);

      final wrapperChild = Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _kQuranTextHorizontalPadding,
          ),
          child: CustomPaint(
            painter:
                disablePainterForGlyph ||
                    isOverlay ||
                    isGlow ||
                    shaderAnimations.contains(quranAnimationId)
                ? null // Let Text take precedence, Shader/Glow handles it
                : _QuranAnimationPainter(
                    animationId: quranAnimationId,
                    progress: localProgress,
                    textColor: color,
                    config: style?.animationConfig ?? const AnimationConfig(),
                  ),
            foregroundPainter: disablePainterForGlyph
                ? null
                : (isOverlay || isGlow)
                ? _QuranAnimationPainter(
                    animationId: quranAnimationId,
                    progress: localProgress,
                    textColor: color,
                    config: style?.animationConfig ?? const AnimationConfig(),
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
        isSelected: selectedLayerId == layer.id,
        isLocked: isLocked,
        defaultX: 0,
        defaultY: y - 40,
        defaultWidthRatio: 1.0,
        fillWidthWhenNoCustom: true,
        child: RepaintBoundary(child: _applyMask(wrapperChild, layer.mask)),
      );
    }

    textWidget = _wrapWithCaptionStyle(textWidget, style);

    return _buildSmartBoundingBoxWrapper(
      layer: layer,
      previewWidth: previewWidth,
      previewHeight: previewHeight,
      isSelected: selectedLayerId == layer.id,
      isLocked: isLocked,
      defaultX: 0,
      defaultY: y,
      defaultWidthRatio: 1.0,
      fillWidthWhenNoCustom: true,
      child: RepaintBoundary(
        child: _applyMask(
          Opacity(
            opacity: opacity,
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
    List<Layer> activeLayers, {
    String? selectedLayerId,
    bool isLocked = false,
  }) {
    final style = layer.textStyle;
    final scaleFactor = previewWidth / 360.0;
    final baseFontSize = layer.fontSize ?? style?.fontSize ?? 14;
    final fontSize = baseFontSize * scaleFactor;
    final colorStr = layer.textColor ?? style?.color;
    final color = colorStr != null ? _parseColor(colorStr) : Colors.white70;
    final opacity = _resolveTextOpacity(layer, style);
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
    final fontFamily = layer.fontFamily ?? style?.fontFamily ?? 'Inter';
    final parsedText = style?.isUppercase == true
        ? displayText.toUpperCase()
        : displayText;
    final resolvedStyle = _resolveVideoPreviewTextStyle(
      style,
      fontFamily,
      fontSize,
      color,
    ).copyWith(height: 1.4);

    Widget tWidget;
    final hasAnimation = style?.animationPreset != null && style?.animationPreset != TextAnimationPreset.none;
    if (hasAnimation && arabicLayer != null && arabicLayer.wordTimings.isNotEmpty) {
      final arabicChunks = _chunkWordTimings(
        arabicLayer.wordTimings,
        wordsPerChunk: 10,
      );
      final transChunks = _chunkStringProportionally(
        layer.content,
        arabicChunks,
      );

      if (transChunks.isNotEmpty) {
        final elapsedTime = currentTime - layer.startTime;

        // Find chunk matching elapsed time; use inclusive end to prevent premature disappearance
        final activeChunk = transChunks.firstWhere(
          (c) => elapsedTime >= c.start && elapsedTime <= c.end,
          orElse: () => elapsedTime < transChunks.first.start
              ? transChunks.first
              : transChunks.last,
        );
        final chunkDuration = activeChunk.end - activeChunk.start;

        // Approximate current word index within the chunk using weights
        int currentWordIndex = -1;
        if (chunkDuration > 0) {
          final progress = (elapsedTime - activeChunk.start) / chunkDuration;
          final weights = _calculateWordWeights(activeChunk.text);
          currentWordIndex = _resolveWeightedWordIndex(progress, weights);
        }

        tWidget = _buildWordByWordBubbleText(
          activeChunk.text,
          currentWordIndex,
          style,
          resolvedStyle,
          style?.textAlign ?? TextAlign.center,
        );
      } else {
        tWidget = Text(
          parsedText,
          style: resolvedStyle,
          textAlign: style?.textAlign ?? TextAlign.center,
        );
      }
    } else {
      tWidget = Text(
        parsedText,
        style: resolvedStyle,
        textAlign: style?.textAlign ?? TextAlign.center,
      );
    }

    tWidget = _wrapWithCaptionStyle(tWidget, style);

    return _buildSmartBoundingBoxWrapper(
      layer: layer,
      previewWidth: previewWidth,
      previewHeight: previewHeight,
      isSelected: selectedLayerId == layer.id,
      isLocked: isLocked,
      defaultX: 0,
      defaultY: y,
      defaultWidthRatio: 1.0,
      fillWidthWhenNoCustom: true,
      child: _applyMask(
        _applyBlendMode(
          Opacity(
            opacity: opacity,
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
    List<Layer> activeLayers, {
    String? selectedLayerId,
    bool isLocked = false,
  }) {
    final style = layer.textStyle;
    final scaleFactor = previewWidth / 360.0;
    final baseFontSize = layer.fontSize ?? style?.fontSize ?? 12;
    final fontSize = baseFontSize * scaleFactor;
    final colorStr = layer.textColor ?? style?.color;
    final color = colorStr != null ? _parseColor(colorStr) : Colors.white70;
    final opacity = _resolveTextOpacity(layer, style);
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
    final hasAnimation = style?.animationPreset != null && style?.animationPreset != TextAnimationPreset.none;
    if (hasAnimation && arabicLayer != null && arabicLayer.wordTimings.isNotEmpty) {
      final arabicChunks = _chunkWordTimings(
        arabicLayer.wordTimings,
        wordsPerChunk: 10,
      );
      final transChunks = _chunkStringProportionally(
        layer.content,
        arabicChunks,
      );
      if (transChunks.isNotEmpty) {
        final elapsedTime = currentTime - layer.startTime;
        // Inclusive end to prevent premature disappearance at verse boundary
        final activeChunk = transChunks.firstWhere(
          (c) => elapsedTime >= c.start && elapsedTime <= c.end,
          orElse: () => elapsedTime < transChunks.first.start
              ? transChunks.first
              : transChunks.last,
        );
        displayText = activeChunk.text;
      }
    }

    final fontFamily = layer.fontFamily ?? style?.fontFamily ?? 'Inter';
    final parsedText = style?.isUppercase == true
        ? displayText.toUpperCase()
        : displayText;
    final resolvedStyle = _resolveVideoPreviewTextStyle(
      style,
      fontFamily,
      fontSize,
      color,
    ).copyWith(height: 1.4, fontStyle: FontStyle.italic);

    Widget tWidget;
    if (hasAnimation && arabicLayer != null && arabicLayer.wordTimings.isNotEmpty) {
      final arabicChunks = _chunkWordTimings(
        arabicLayer.wordTimings,
        wordsPerChunk: 10,
      );
      final transChunks = _chunkStringProportionally(
        layer.content,
        arabicChunks,
      );

      if (transChunks.isNotEmpty) {
        final elapsedTime = currentTime - layer.startTime;

        // Find chunk that EXACTLY matches current time
        final activeChunk = transChunks.firstWhere(
          (c) => elapsedTime >= c.start && elapsedTime < c.end,
          orElse: () => elapsedTime < transChunks.first.start
              ? transChunks.first
              : transChunks.last,
        );
        final chunkDuration = activeChunk.end - activeChunk.start;

        // Approximate current word index within the chunk using weights
        int currentWordIndex = -1;
        if (chunkDuration > 0) {
          final progress = (elapsedTime - activeChunk.start) / chunkDuration;
          final weights = _calculateWordWeights(activeChunk.text);
          currentWordIndex = _resolveWeightedWordIndex(progress, weights);
        }

        tWidget = _buildWordByWordBubbleText(
          activeChunk.text,
          currentWordIndex,
          style,
          resolvedStyle,
          style?.textAlign ?? TextAlign.center,
        );
      } else {
        tWidget = Text(
          parsedText,
          style: resolvedStyle,
          textAlign: style?.textAlign ?? TextAlign.center,
        );
      }
    } else {
      tWidget = Text(
        parsedText,
        style: resolvedStyle,
        textAlign: style?.textAlign ?? TextAlign.center,
      );
    }

    tWidget = _wrapWithCaptionStyle(tWidget, style);

    return _buildSmartBoundingBoxWrapper(
      layer: layer,
      previewWidth: previewWidth,
      previewHeight: previewHeight,
      isSelected: selectedLayerId == layer.id,
      isLocked: isLocked,
      defaultX: 0,
      defaultY: y,
      defaultWidthRatio: 1.0,
      fillWidthWhenNoCustom: true,
      child: _applyMask(
        _applyBlendMode(
          Opacity(
            opacity: opacity,
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
    if (project == null) {
      return const Center(
        child: Text(
          'No project loaded',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

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
        _syncAudioPlayersImmediate();
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
  String getTrackKey(Layer layer) {
    if (layer.type == 'arabic') return 'text_arabic_';
    if (layer.type == 'phonetic') return 'text_phonetic_';
    if (layer.type == 'translation') return 'text_translation_';
    return layer.type;
  }

    return ValueListenableBuilder<double>(
      valueListenable: _playbackTime,
      builder: (context, currentTime, child) {
        final hiddenTracks = ref.watch(editorProvider.select((s) => s.hiddenTracks));
        final lockedTracks = ref.watch(editorProvider.select((s) => s.lockedTracks));

        // High-frequency UI logic: only recalculate active parts
        final layers = project.layers;
        final activeLayers = layers
            .where((l) => l.activeAt(currentTime) && !hiddenTracks.contains(getTrackKey(l)))
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
                  l.activeAt(recitationTime) &&
                  !hiddenTracks.contains(getTrackKey(l)),
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
                                  Builder(
                                    builder: (context) {
                                      final activeVideoLayer = project.layers.where(
                                        (l) => l.type == 'video' && l.activeAt(currentTime)
                                      ).firstOrNull;
                                      if (activeVideoLayer != null) {
                                        return RepaintBoundary(
                                          child: _buildVideoLayer(
                                            activeVideoLayer,
                                            previewWidth,
                                            previewHeight,
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),

                                  // Overlays
                                  ...activeLayers
                                      .where((l) => l.type == 'image')
                                      .map(
                                        (layer) => _buildImageLayer(
                                          layer,
                                          currentTime,
                                          previewWidth,
                                          previewHeight,
                                          selectedLayerId == layer.id,
                                          lockedTracks.contains(getTrackKey(layer)),
                                        ),
                                      ),
                                  ...activeLayers
                                      .where((l) => l.type == 'sticker')
                                      .map(
                                        (layer) => _buildDraggableLayer(
                                          layer: layer,
                                          previewWidth: previewWidth,
                                          previewHeight: previewHeight,
                                          isSelected: selectedLayerId == layer.id,
                                          isLocked: lockedTracks.contains(getTrackKey(layer)),
                                          child: _buildStickerLayer(
                                            layer,
                                            currentTime,
                                            previewWidth,
                                            previewHeight,
                                          ),
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
                                          selectedLayerId: selectedLayerId,
                                          isLocked: lockedTracks.contains(getTrackKey(layer)),
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
                                          selectedLayerId: selectedLayerId,
                                          isLocked: lockedTracks.contains(getTrackKey(layer)),
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
                                          selectedLayerId: selectedLayerId,
                                          isLocked: lockedTracks.contains(getTrackKey(layer)),
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
                                          isLocked: lockedTracks.contains(getTrackKey(layer)),
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
    bool isLocked = false,
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

    if (isLocked) {
      return Positioned(
        left: x,
        top: y,
        child: child,
      );
    }

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
    bool isLocked = false,
  }) {
    final style = layer.textStyle;
    final fontSize = layer.fontSize ?? style?.fontSize ?? 20;
    final colorStr = layer.textColor ?? style?.color;
    final color = colorStr != null ? _parseColor(colorStr) : Colors.white;
    final fontFamily = layer.fontFamily ?? style?.fontFamily ?? 'Inter';
    final layerProgress = layer.effectiveDuration > 0
        ? ((currentTime - layer.startTime) / layer.effectiveDuration).clamp(
            0.0,
            1.0,
          )
        : 0.0;
    final opacity = _resolveTextOpacity(layer, style);
    String displayText = layer.content;
    final animation = _resolveTextAnimation(layer, style);
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
        if (layerProgress > 0.7) {
          animOpacity = opacity * ((1.0 - layerProgress) / 0.3).clamp(0.0, 1.0);
        }
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
        if (layerProgress < 0.3) {
          slideOffset = Offset(-previewWidth * (1.0 - layerProgress / 0.3), 0);
        }
        break;
      case 'slideInRight':
        if (layerProgress < 0.3) {
          slideOffset = Offset(previewWidth * (1.0 - layerProgress / 0.3), 0);
        }
        break;
      case 'slideInTop':
        if (layerProgress < 0.3) {
          slideOffset = Offset(0, -previewHeight * (1.0 - layerProgress / 0.3));
        }
        break;
      case 'slideInBottom':
        if (layerProgress < 0.3) {
          slideOffset = Offset(0, previewHeight * (1.0 - layerProgress / 0.3));
        }
        break;
      case 'scaleIn':
        if (layerProgress < 0.3) { 
          animScale = 0.5 + 0.5 * (layerProgress / 0.3);
        }
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

    if (parsedText.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    Widget contentWidget = RichText(
      text: TextSpan(text: parsedText, style: resolvedStyle),
      textAlign: style?.textAlign ?? TextAlign.center,
      softWrap: true,
    );

    contentWidget = _wrapWithCaptionStyle(contentWidget, style);

    // Si on a une largeur custom, on l'utilise, sinon on s'adapte au texte
    Widget sizedContent = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: previewWidth * 0.85),
      child: (customWidth != null && !customWidth.isNaN && customWidth > 10.0)
          ? SizedBox(width: customWidth, child: contentWidget)
          : IntrinsicWidth(child: contentWidget),
    );

    return _buildSmartBoundingBoxWrapper(
      layer: layer,
      previewWidth: previewWidth,
      previewHeight: previewHeight,
      isSelected: isSelected,
      isLocked: isLocked,
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
    bool isProportionalOnly = false,
    bool isLocked = false,
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
    
    // Validate customWidth to prevent BoxConstraints negative width exceptions
    double? customWidth;
    final rawCustomWidth = layer.style['width']?.toDouble();
    if (rawCustomWidth != null && !rawCustomWidth.isNaN && rawCustomWidth > 10.0) {
      customWidth = rawCustomWidth;
    }

    final effectiveWidth = customWidth ??
        (fillWidthWhenNoCustom ? previewWidth * defaultWidthRatio : null);

    // We consistently use IntrinsicWidth if no custom width is set.
    // This ensures the bounding box hugs the text AND prevents any visual shift
    // when toggling between selected and unselected states.
    final Widget sizedContent = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: previewWidth * defaultWidthRatio),
      child: customWidth != null
          ? SizedBox(width: customWidth, child: child)
          : IntrinsicWidth(child: child),
    );

    // ── Locked: No Interaction ───────────────────────────
    if (isLocked) {
      return Positioned(
        left: x,
        top: y,
        child: Transform.scale(scale: scale, child: sizedContent),
      );
    }

    // ── Unselected: simple drag-to-move wrapper ───────────────────────────
    if (!isSelected) {
      return Positioned(
        left: x,
        top: y,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) =>
              ref.read(editorProvider.notifier).setSelectedLayer(layer.id),
          onScaleStart: (details) {
            ref.read(editorProvider.notifier).setSelectedLayer(layer.id);
            _draggingLayerId = layer.id;
            _dragStart = details.focalPoint;
            _layerStartOffset = Offset(x, y);
            _layerStartScale = scale;
          },
          onScaleUpdate: (details) {
            if (_draggingLayerId != layer.id) return;
            final dx = details.focalPoint.dx - _dragStart.dx;
            final dy = details.focalPoint.dy - _dragStart.dy;
            final newX = (_layerStartOffset.dx + dx).clamp(-previewWidth, previewWidth * 2);
            final newY = (_layerStartOffset.dy + dy).clamp(-previewHeight, previewHeight * 2);
            final newScale = (_layerStartScale * details.scale).clamp(0.2, 5.0);
            
            ref.read(editorProvider.notifier).updateLayer(
              layer.copyWith(style: {...layer.style, 'x': newX, 'y': newY, 'scale': newScale}),
            );
          },
          onScaleEnd: (_) => _draggingLayerId = null,
          child: Transform.scale(scale: scale, child: sizedContent),
        ),
      );
    }

    // ── Selected — professional handle system ─────────────────────────────
    // Layout strategy: the Stack's FIRST non-positioned child is
    // Padding(all:kOffset, child: borderedContent) — this gives the Stack its
    // intrinsic size = content + 2*kOffset on each side.
    // Handles are Positioned at the edges (left:0, right:0, top:0, bottom:0)
    // so they sit on the padding area and are fully hittable.
    const double kHandle = 10.0;
    const double kHitArea = 40.0;
    const double kOffset = kHitArea / 2; // = 20px padding on each side
    final borderColor = const Color(0xFF2196F3);

    Widget cornerDot({required bool filled, required void Function(DragUpdateDetails) onPan}) =>
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: onPan,
          child: SizedBox(
            width: kHitArea,
            height: kHitArea,
            child: Center(
              child: Container(
                width: kHandle,
                height: kHandle,
                decoration: BoxDecoration(
                  color: filled ? borderColor : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1.8),
                  boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 1))],
                ),
              ),
            ),
          ),
        );

    Widget edgePill({required void Function(DragUpdateDetails) onPan}) =>
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: onPan,
          child: SizedBox(
            width: kHitArea,
            height: kHitArea,
            child: Center(
              child: Container(
                width: 6,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 3)],
                ),
              ),
            ),
          ),
        );

    // Bordered content — the non-positioned first child that sizes the Stack
    final Widget borderedContent = Padding(
      padding: EdgeInsets.all(kOffset),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor.withValues(alpha: 0.9), width: 1.5),
          borderRadius: BorderRadius.circular(3),
        ),
        child: sizedContent,
      ),
    );

    final Widget selectionBox = Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Sized non-positioned child — gives Stack its intrinsic size ──
        borderedContent,

        // ── Font-size pill — top center (Only if not proportional) ──────
        if (!isProportionalOnly)
          Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (d) {
                final current = (layer.textStyle?.fontSize ?? 26).toDouble();
                final newSize = (current - d.delta.dy * 0.5).clamp(6.0, 200.0);
                final ts = layer.textStyle;
                if (ts == null) return;
                ref.read(editorProvider.notifier).updateLayer(
                  layer.copyWith(textStyle: ts.copyWith(fontSize: newSize)),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.format_size, color: Colors.white, size: 11),
                    const SizedBox(width: 3),
                    Text(
                      '${((layer.textStyle?.fontSize ?? 26) * scale).round()}',
                      style: const TextStyle(
                        color: Colors.white, fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── TOP-LEFT corner ─────────────────────────────────────────────
        Positioned(
          left: 0,
          top: 0,
          child: cornerDot(
            filled: false,
            onPan: (d) {
              final s = (scale + (-d.delta.dx - d.delta.dy) * 0.008).clamp(0.2, 5.0);
              ref.read(editorProvider.notifier).updateLayer(
                layer.copyWith(style: {...layer.style, 'scale': s}),
              );
            },
          ),
        ),

        // ── TOP-RIGHT corner ────────────────────────────────────────────
        Positioned(
          right: 0,
          top: 0,
          child: cornerDot(
            filled: false,
            onPan: (d) {
              final s = (scale + (d.delta.dx - d.delta.dy) * 0.008).clamp(0.2, 5.0);
              ref.read(editorProvider.notifier).updateLayer(
                layer.copyWith(style: {...layer.style, 'scale': s}),
              );
            },
          ),
        ),

        // ── BOTTOM-LEFT corner ──────────────────────────────────────────
        Positioned(
          left: 0,
          bottom: 0,
          child: cornerDot(
            filled: true,
            onPan: (d) {
              final s = (scale + (-d.delta.dx + d.delta.dy) * 0.008).clamp(0.2, 5.0);
              ref.read(editorProvider.notifier).updateLayer(
                layer.copyWith(style: {...layer.style, 'scale': s}),
              );
            },
          ),
        ),

        // ── BOTTOM-RIGHT corner ─────────────────────────────────────────
        Positioned(
          right: 0,
          bottom: 0,
          child: cornerDot(
            filled: true,
            onPan: (d) {
              final s = (scale + (d.delta.dx + d.delta.dy) * 0.008).clamp(0.2, 5.0);
              ref.read(editorProvider.notifier).updateLayer(
                layer.copyWith(style: {...layer.style, 'scale': s}),
              );
            },
          ),
        ),

        // ── RIGHT edge pill — widen box (Only if not proportional) ──────
        if (!isProportionalOnly)
          Positioned(
          right: 0,
          top: kOffset,
          bottom: kOffset,
          child: Center(
            child: edgePill(
              onPan: (d) {
                final current = effectiveWidth ?? previewWidth * defaultWidthRatio;
                final newW = (current + d.delta.dx).clamp(40.0, previewWidth);
                ref.read(editorProvider.notifier).updateLayer(
                  layer.copyWith(style: {...layer.style, 'width': newW}),
                );
              },
            ),
          ),
        ),

        // ── LEFT edge pill — widen box (Only if not proportional) ──────
        if (!isProportionalOnly)
          Positioned(
          left: 0,
          top: kOffset,
          bottom: kOffset,
          child: Center(
            child: edgePill(
              onPan: (d) {
                final current = effectiveWidth ?? previewWidth * defaultWidthRatio;
                final newW = (current - d.delta.dx).clamp(40.0, previewWidth);
                ref.read(editorProvider.notifier).updateLayer(
                  layer.copyWith(style: {...layer.style, 'width': newW}),
                );
              },
            ),
          ),
        ),
      ],
    );

    // Compensate the padding offset so the visible border appears at (x, y)
    return Positioned(
      left: x - kOffset,
      top: y - kOffset,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) =>
            ref.read(editorProvider.notifier).setSelectedLayer(layer.id),
        onScaleStart: (details) {
          ref.read(editorProvider.notifier).setSelectedLayer(layer.id);
          _draggingLayerId = layer.id;
          _dragStart = details.focalPoint;
          _layerStartOffset = Offset(x, y);
          _layerStartScale = scale;
        },
        onScaleUpdate: (details) {
          if (_draggingLayerId != layer.id) return;
          final dx = details.focalPoint.dx - _dragStart.dx;
          final dy = details.focalPoint.dy - _dragStart.dy;
          final newX = (_layerStartOffset.dx + dx).clamp(-previewWidth, previewWidth * 2);
          final newY = (_layerStartOffset.dy + dy).clamp(-previewHeight, previewHeight * 2);
          final newScale = (_layerStartScale * details.scale).clamp(0.2, 5.0);

          ref.read(editorProvider.notifier).updateLayer(
            layer.copyWith(style: {...layer.style, 'x': newX, 'y': newY, 'scale': newScale}),
          );
        },
        onScaleEnd: (_) => _draggingLayerId = null,
        child: Transform.scale(scale: scale, child: selectionBox),
      ),
    );
  }
}



class _QuranAnimationPainter extends CustomPainter {
  final String animationId;
  final double progress;
  final Color textColor;
  final AnimationConfig config;

  _QuranAnimationPainter({
    required this.animationId,
    required this.progress,
    required this.textColor,
    this.config = const AnimationConfig(),
  });

  @override
  void paint(Canvas canvas, Size size) {
    paintQuranAnimation(
      canvas,
      Rect.fromLTWH(0, 0, size.width, size.height),
      animationId,
      progress,
      textColor: textColor,
      config: config,
    );
  }

  @override
  bool shouldRepaint(covariant _QuranAnimationPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.animationId != animationId ||
      oldDelegate.textColor != textColor ||
      oldDelegate.config != config;
}

class MaskClipper extends CustomClipper<Path> {
  final LayerMask mask;
  MaskClipper(this.mask);

  @override
  Path getClip(Size size) {
    Path path = Path();
    final w = size.width, h = size.height;
    final cx = w / 2, cy = h / 2;

    switch (mask.type) {
      case MaskType.rectangle:
        path.addRect(Rect.fromLTWH(0, 0, w, h));
        break;
      case MaskType.circle:
        path.addOval(Rect.fromLTWH(0, 0, w, h));
        break;
      case MaskType.triangle:
        path.moveTo(cx, 0);
        path.lineTo(w, h);
        path.lineTo(0, h);
        path.close();
        break;
      case MaskType.heart:
        path.moveTo(cx, h * 0.3);
        path.cubicTo(cx, 0, 0, 0, 0, h * 0.3);
        path.cubicTo(0, h * 0.6, cx, h, cx, h);
        path.cubicTo(cx, h, w, h * 0.6, w, h * 0.3);
        path.cubicTo(w, 0, cx, 0, cx, h * 0.3);
        path.close();
        break;
      case MaskType.star:
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
        break;
      case MaskType.splitHorizontal:
        path.addRect(Rect.fromLTRB(0, cy - (cy * mask.value), w, cy + (cy * mask.value)));
        break;
      case MaskType.splitVertical:
        path.addRect(Rect.fromLTRB(cx - (cx * mask.value), 0, cx + (cx * mask.value), h));
        break;
      default:
        path.addRect(Rect.fromLTWH(0, 0, w, h));
    }

    // Apply scaling (value) and rotation to the path, except for split masks which use value for width
    final matrix = Matrix4.identity();
    matrix.multiply(Matrix4.translationValues(cx, cy, 0.0));
    if (mask.type != MaskType.splitHorizontal && mask.type != MaskType.splitVertical) {
      matrix.multiply(Matrix4.diagonal3Values(mask.value, mask.value, 1.0));
    }
    matrix.multiply(Matrix4.rotationZ(mask.rotation * math.pi / 180.0));
    matrix.multiply(Matrix4.translationValues(-cx, -cy, 0.0));

    return path.transform(matrix.storage);
  }

  @override
  bool shouldReclip(covariant MaskClipper oldClipper) =>
      oldClipper.mask.type != mask.type ||
      oldClipper.mask.value != mask.value ||
      oldClipper.mask.rotation != mask.rotation;
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
