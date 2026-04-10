import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import '../../../../models/project.dart';
import '../../../../core/models/voice_effect.dart';
import '../../../../core/models/canvas_background.dart';
import '../../../../core/services/quran_animation_export.dart';
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

List<_TextChunk> _chunkWordTimings(List<dynamic> timings, {int wordsPerChunk = 10}) {
  if (timings.isEmpty) return [];
  final chunks = <_TextChunk>[];
  for (int i = 0; i < timings.length; i += wordsPerChunk) {
    final subset = timings.sublist(i, math.min(i + wordsPerChunk, timings.length));
    if (subset.isEmpty) continue;
    final words = subset.map((w) => w['word'] as String).join(' ');
    final start = (subset.first['start'] as num).toDouble();
    final end = (subset.last['end'] as num).toDouble();
    chunks.add(_TextChunk(
      text: words,
      start: start,
      end: end,
      wordTimings: subset,
    ));
  }
  return chunks;
}

List<_TextChunk> _chunkStringProportionally(String text, List<_TextChunk> refChunks) {
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
    chunks.add(_TextChunk(
      text: chunkWords,
      start: ref.start,
      end: ref.end,
    ));
  }
  return chunks;
}

class VideoPreview extends ConsumerStatefulWidget {
  const VideoPreview({super.key});

  @override
  ConsumerState<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends ConsumerState<VideoPreview> with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  String? _lastVideoPath;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentAudioPath;
  final Set<String> _failedAudioPaths = {};
  StreamSubscription<ProcessingState>? _processingStateSubscription;
  Timer? _ticker;
  Timer? _syncThrottle;
  Timer? _playIconTimer;
  bool _showPlayIcon = false;
  final Map<String, AnimationController> _textAnimationControllers = {};
  final Map<String, double> _duckingVolumes = {};
  static const double _duckingAttack = 0.15;
  static const double _duckingRelease = 0.3;

  // Drag state for canvas layers
  String? _draggingLayerId;
  Offset _dragStart = Offset.zero;
  Offset _layerStartOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _processingStateSubscription = _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _currentAudioPath = null;
      }
    }, onError: (error) => debugPrint('[Audio] Player error: $error'));
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeVideoController());
  }

  Future<void> _initializeVideoController() async {
    final state = ref.read(editorProvider);
    final project = state.currentProject;
    if (project == null) return;
    final videoLayer = project.layers.where((l) => l.type == 'video').firstOrNull;
    if (videoLayer == null || videoLayer.content.isEmpty) {
      if (mounted) setState(() => _isVideoInitialized = true);
      return;
    }
    if (_lastVideoPath == videoLayer.content && _videoController != null) return;
    try {
      await _videoController?.dispose();
      final file = File(videoLayer.content);
      if (await file.exists()) {
        _videoController = VideoPlayerController.file(file);
        await _videoController!.initialize();
        _lastVideoPath = videoLayer.content;
        if (mounted) setState(() => _isVideoInitialized = true);
      }
    } catch (e) {
      debugPrint('[VideoPreview] Failed to initialize video: $e');
      if (mounted) setState(() => _isVideoInitialized = true);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    _syncThrottle?.cancel();
    _playIconTimer?.cancel();
    _processingStateSubscription?.cancel();
    _audioPlayer.dispose();
    _videoController?.dispose();
    for (final controller in _textAnimationControllers.values) { controller.dispose(); }
    super.dispose();
  }

  Future<void> _syncAudioPlayers() async {
    final state = ref.read(editorProvider);
    final project = state.currentProject;
    if (project == null) return;
    final audioLayers = project.layers.where((l) => l.type == 'audio').toList();
    final currentTime = state.currentTime;
    Layer? activeLayer;
    for (final layer in audioLayers) {
      if (currentTime >= layer.startTime && currentTime < layer.startTime + layer.effectiveDuration) {
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
      if (!_failedAudioPaths.contains(audioPath)) _failedAudioPaths.add(audioPath);
      if (_audioPlayer.playing) await _audioPlayer.pause();
      return;
    }
    if (_currentAudioPath != audioPath) {
      try {
        debugPrint('[Audio] Switching to: ${audioPath.split('/').last}');
        if (_audioPlayer.playing) await _audioPlayer.pause();
        await _audioPlayer.stop();
        _currentAudioPath = audioPath;
        final expectedPosition = Duration(milliseconds: ((currentTime - activeLayer.startTime) * 1000).toInt());
        await _audioPlayer.setFilePath(audioPath);
        await _audioPlayer.seek(expectedPosition);
      } catch (e) {
        _failedAudioPaths.add(audioPath);
        debugPrint('[Audio] Failed to load: $e');
        return;
      }
    } else {
      final isReady = _audioPlayer.processingState == ProcessingState.ready || _audioPlayer.processingState == ProcessingState.completed;
      if (isReady) {
        final expectedPosition = Duration(milliseconds: ((currentTime - activeLayer.startTime) * 1000).toInt());
        final drift = (_audioPlayer.position - expectedPosition).inMilliseconds.abs();
        if (drift > 500) await _audioPlayer.seek(expectedPosition);
      }
    }
    double baseVolume = (activeLayer.style['volume'] as num?)?.toDouble() ?? 1.0;
    final speechLayers = audioLayers.where((l) => l.style['role'] == 'speech' || l.style['role'] == 'voice');
    final anySpeechActive = speechLayers.any((l) => currentTime >= l.startTime && currentTime < l.startTime + l.effectiveDuration);
    final isMusicLayer = activeLayer.style['role'] == 'music' || activeLayer.style['role'] == 'background';
    final targetDucking = isMusicLayer && anySpeechActive && project.duckingEnabled ? 0.4 : 1.0;
    final currentDuckVol = _duckingVolumes[activeLayer.id] ?? 1.0;
    final duckingSpeed = targetDucking < currentDuckVol ? _duckingAttack : _duckingRelease;
    final duckLerp = (0.2 / duckingSpeed).clamp(0.0, 1.0);
    final smoothDuckVol = currentDuckVol + (targetDucking - currentDuckVol) * duckLerp;
    _duckingVolumes[activeLayer.id] = smoothDuckVol;
    baseVolume *= smoothDuckVol;
    if (activeLayer.noiseGateThreshold > 0) baseVolume *= (1.0 - activeLayer.noiseGateThreshold * 0.5);
    final fadeInSec = (activeLayer.style['fadeIn'] as num?)?.toDouble() ?? 0.0;
    final fadeOutSec = (activeLayer.style['fadeOut'] as num?)?.toDouble() ?? 0.0;
    final layerElapsed = currentTime - activeLayer.startTime;
    final layerRemaining = activeLayer.effectiveDuration - layerElapsed;
    double effectiveVolume = baseVolume;
    if (fadeInSec > 0 && layerElapsed < fadeInSec) { effectiveVolume = (layerElapsed / fadeInSec) * baseVolume; }
    else if (fadeOutSec > 0 && layerRemaining < fadeOutSec) { effectiveVolume = (layerRemaining / fadeOutSec) * baseVolume; }
    effectiveVolume = effectiveVolume.clamp(0.0, 2.0);
    await _audioPlayer.setVolume(effectiveVolume);
    double speed = (activeLayer.style['speed'] as num?)?.toDouble() ?? 1.0;
    if (activeLayer.voiceEffectId != 'none') {
      final voiceEffect = findVoiceEffectById(activeLayer.voiceEffectId);
      if (voiceEffect.id != 'none') speed *= voiceEffect.speed;
    }
    await _audioPlayer.setSpeed(speed.clamp(0.25, 4.0));
    // RACE CONDITION FIX: Capture the freshest state after all previous async yields
    final currentIsPlaying = ref.read(editorProvider).isPlaying;
    if (currentIsPlaying) {
      final isReady = _audioPlayer.processingState == ProcessingState.ready || _audioPlayer.processingState == ProcessingState.completed;
      if (isReady && !_audioPlayer.playing) { await _audioPlayer.play(); }
    } else {
      if (_audioPlayer.playing) await _audioPlayer.pause();
    }
  }

  bool _isAudioSyncing = false;

  void _syncAudioPlayersThrottled() async {
    if (_isAudioSyncing) return;
    _isAudioSyncing = true;
    try {
      await _syncAudioPlayers();
    } finally {
      _isAudioSyncing = false;
    }
  }

  void _startPlayback() {
    _ticker?.cancel();
    _ticker = null;
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final state = ref.read(editorProvider);
      if (!state.isPlaying) {
        _ticker?.cancel();
        _ticker = null;
        return;
      }
      final total = state.currentProject?.totalDuration ?? 30.0;
      final next = state.currentTime + 0.05;
      if (next >= total) {
        ref.read(editorProvider.notifier).pause();
        _ticker?.cancel();
        _ticker = null;
        return;
      }
      ref.read(editorProvider.notifier).setCurrentTime(next);
      _syncAudioPlayersThrottled();
    });
  }

  void _stopPlayback() {
    _ticker?.cancel();
    _ticker = null;
    _syncThrottle?.cancel();
    // Do NOT reset to 0 on stop — stay at current position
    if (_audioPlayer.playing) _audioPlayer.pause();
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
      return Matrix4.identity()..translate(transform.x, transform.y)..rotateZ(transform.rotation * math.pi / 180)..scale(transform.scaleX, transform.scaleY);
    }
    final scale = layer.style['scale']?.toDouble() ?? 1.0;
    final rotation = layer.style['rotation']?.toDouble() ?? 0.0;
    final offsetX = layer.style['offsetX']?.toDouble() ?? 0.0;
    final offsetY = layer.style['offsetY']?.toDouble() ?? 0.0;
    // ignore: deprecated_member_use
    return Matrix4.identity()..translate(offsetX, offsetY)..rotateZ(rotation * math.pi / 180)..scale(scale);
  }

  Widget _applyBlendMode(Widget child, String blendModeName) {
    if (blendModeName == 'srcOver' || blendModeName.isEmpty) return child;
    final blendMode = BlendMode.values.byName(blendModeName);
    return ShaderMask(shaderCallback: (bounds) => LinearGradient(colors: [Colors.white, Colors.white]).createShader(bounds), blendMode: blendMode, child: child);
  }

  Widget _applyMask(Widget child, LayerMask mask) {
    if (mask.type == MaskType.none || mask.value == 0) return child;
    switch (mask.type) {
      case MaskType.rectangle:
        return ClipRRect(borderRadius: BorderRadius.circular(mask.value * 50), child: child);
      case MaskType.circle:
        return ClipOval(child: child);
      case MaskType.triangle:
        return ClipPath(clipper: _TriangleClipper(), child: child);
      case MaskType.heart:
        return ClipPath(clipper: _HeartClipper(), child: child);
      case MaskType.star:
        return ClipPath(clipper: _StarClipper(), child: child);
      case MaskType.splitHorizontal:
        return ClipPath(clipper: _SplitClipper(axis: Axis.horizontal, value: mask.value), child: child);
      case MaskType.splitVertical:
        return ClipPath(clipper: _SplitClipper(axis: Axis.vertical, value: mask.value), child: child);
      default:
        return child;
    }
  }

  Widget _buildCanvasBackground(Project project, double width, double height) {
    final bg = kCanvasBackgrounds.firstWhere((b) => b.id == project.canvasBackgroundId, orElse: () => kCanvasBackgrounds.first);
    return bg.buildBackground();
  }

  Widget _buildVideoLayer(List<Layer> activeLayers, double currentTime, double width, double height) {
    Layer? videoLayer;
    for (final layer in activeLayers) {
      if (layer.type == 'video') {
        videoLayer = layer;
        break;
      }
    }
    if (videoLayer == null || videoLayer.content.isEmpty || !_isVideoInitialized || _videoController == null || !_videoController!.value.isInitialized) {
      return const SizedBox.shrink();
    }
    final inPoint = videoLayer.inPoint ?? 0;
    final videoPosition = inPoint + (currentTime - videoLayer.startTime);
    final durationMs = _videoController!.value.duration.inMilliseconds;
    final seekMs = (videoPosition * 1000).toInt();
    if (seekMs >= 0 && seekMs < durationMs) {
      _videoController!.seekTo(Duration(milliseconds: seekMs));
    }
    final opacity = (videoLayer.style['opacity'] as num?)?.toDouble() ?? 1.0;
    return Positioned.fill(
      child: _applyMask(
        _applyBlendMode(Opacity(opacity: opacity, child: FittedBox(fit: BoxFit.contain, child: AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!)))), videoLayer.blendMode),
        videoLayer.mask,
      ),
    );
  }

  Widget _buildImageLayer(Layer layer, double currentTime, double previewWidth, double previewHeight) {
    final file = File(layer.content);
    if (!file.existsSync()) return const SizedBox.shrink();
    final opacity = (layer.style['opacity'] as num?)?.toDouble() ?? 1.0;
    final w = layer.style['width']?.toDouble() ?? previewWidth;
    final h = layer.style['height']?.toDouble() ?? previewHeight;
    return _applyMask(
      _applyBlendMode(Opacity(opacity: opacity, child: Transform(transform: _getLayerTransform(layer, currentTime), child: Image.file(file, width: w, height: h, fit: BoxFit.contain))), layer.blendMode),
      layer.mask,
    );
  }

  Widget _buildStickerLayer(Layer layer, double currentTime, double previewWidth, double previewHeight) {
    final emoji = layer.content;
    if (emoji.isEmpty) return const SizedBox.shrink();
    final layerProgress = (currentTime - layer.startTime) / layer.effectiveDuration;
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
      animOpacity = opacity * (layerProgress / (fadeInDuration / layer.effectiveDuration));
    } else if (layerProgress > 1.0 - fadeOutDuration / layer.effectiveDuration) {
      animOpacity = opacity * ((1.0 - layerProgress) / (fadeOutDuration / layer.effectiveDuration));
    }
    final stickerAnim = layer.style['animation'] as int?;
    Widget stickerWidget = Text(emoji, style: TextStyle(fontSize: size, height: 1.0));
    if (stickerAnim != null && stickerAnim > 0) {
      switch (stickerAnim) {
        case 2:
          if (layerProgress < 0.4) stickerWidget = Transform.translate(offset: Offset(0, -20 * math.sin(layerProgress / 0.4 * math.pi * 3) * (1.0 - layerProgress / 0.4)), child: stickerWidget);
          break;
        case 3:
          if (layerProgress < 0.5) stickerWidget = Transform.rotate(angle: math.sin(layerProgress * math.pi * 4) * 0.3 * (1.0 - layerProgress * 2), child: stickerWidget);
          break;
        case 4:
          if (layerProgress < 0.3) stickerWidget = Transform.scale(scale: 0.5 + 0.5 * (layerProgress / 0.3), child: stickerWidget);
          break;
        case 5:
          if (layerProgress < 0.3) stickerWidget = Transform.translate(offset: Offset(-50 * (1.0 - layerProgress / 0.3), 0), child: stickerWidget);
          break;
      }
    }
    return Positioned(
      left: x,
      top: y,
      child: _applyMask(
        // ignore: deprecated_member_use
        AnimatedOpacity(opacity: animOpacity.clamp(0.0, 1.0), duration: const Duration(milliseconds: 100), child: Transform(transform: Matrix4.identity()..scale(scaleX, scaleY)..rotateZ(layer.transform.rotation * math.pi / 180), alignment: Alignment.center, child: stickerWidget)),
        layer.mask,
      ),
    );
  }
  Widget _buildArabicLayer(Layer layer, double currentTime, double previewWidth, double previewHeight) {
    final style = layer.textStyle;
    final scaleFactor = previewWidth / 360.0;
    final baseFontSize = style?.fontSize ?? 26;
    final fontSize = baseFontSize * scaleFactor * 1.1;
    final color = style != null ? _parseColor(style.color) : Colors.white;
    final fontFamily = style?.fontFamily ?? layer.fontFamily ?? 'UthmanicRegular';
    final opacity = (layer.style['opacity'] as num?)?.toDouble() ?? 1.0;
    final transformY = layer.transform.y;
    final y = layer.style['y']?.toDouble() ?? (transformY * previewHeight);
    final quranAnimationId = style?.quranAnimationId;
    final hasQuranAnimation = quranAnimationId != null && quranAnimationId.isNotEmpty && quranAnimationId != 'none';
    final hasWordTimings = layer.wordTimings.isNotEmpty;
    
    String displayText = layer.content;
    List<TextSpan>? wordSpans;
    Widget? textWidget;
    double localProgress = (currentTime - layer.startTime) / layer.effectiveDuration;

    if (hasWordTimings) {
      final chunks = _chunkWordTimings(layer.wordTimings, wordsPerChunk: 10);
      if (chunks.isNotEmpty) {
        final activeChunksIter = chunks.where((c) => currentTime >= c.start && currentTime <= c.end);
        final activeChunk = activeChunksIter.isNotEmpty ? activeChunksIter.first : chunks.last;

        displayText = activeChunk.text;
        
        final chunkDuration = activeChunk.duration;
        if (chunkDuration > 0) {
          localProgress = ((currentTime - activeChunk.start) / chunkDuration).clamp(0.0, 1.0);
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

        final glowIntensity = (math.sin(localProgress * math.pi) * 20).clamp(0.0, 20.0);
        final glowShadows = isEtherealGlow 
            ? [Shadow(color: const Color(0xFFE0B0FF).withValues(alpha: 0.8), blurRadius: glowIntensity)]
            : null;

        final words = activeChunk.text.split(RegExp(r'\s+'));
        
        // When using a shader animation, we split into TWO layers: base and active
        // This solves the multi-line bleed by making the karaoke literally draw the shader!
        wordSpans = words.asMap().entries.map((entry) {
          final isActive = entry.key <= currentWordIndex;
          
          Color textColor;
          if (isShaderDriven) {
            textColor = isActive ? Colors.transparent : color; // Active is handled by shader overlay
          } else {
            textColor = isActive ? const Color(0xFFFFD700) : color; // Standard Gold karaoke
          }

          return TextSpan(
            text: entry.value + (entry.key < words.length - 1 ? ' ' : ''), 
            style: TextStyle(
              fontFamily: fontFamily, 
              fontSize: fontSize, 
              color: textColor, 
              height: 1.6,
              shadows: glowShadows,
            )
          );
        }).toList();

        // If shader driven, we need a secondary active span list for the ShaderMask Top Layer
        if (isShaderDriven) {
          final activeSpans = words.asMap().entries.map((entry) {
            final isActive = entry.key <= currentWordIndex;
            return TextSpan(
              text: entry.value + (entry.key < words.length - 1 ? ' ' : ''), 
              style: TextStyle(
                fontFamily: fontFamily, fontSize: fontSize, height: 1.6,
                color: isActive ? Colors.white : Colors.transparent, // Only color the active words to mask the Shader
                shadows: glowShadows,
              )
            );
          }).toList();
          
          textWidget = Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              RichText(text: TextSpan(children: wordSpans), textAlign: TextAlign.center, textDirection: TextDirection.rtl),
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) {
                  if (isRainbow) {
                    return const LinearGradient(
                      begin: Alignment.centerRight, end: Alignment.centerLeft,
                      colors: [Color(0xFFFF0000), Color(0xFFFF7F00), Color(0xFFFFFF00), Color(0xFF00FF00), Color(0xFF0000FF), Color(0xFF4B0082), Color(0xFF9400D3)],
                    ).createShader(bounds);
                  } else if (isSunset) {
                    return const LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Color(0xFFFF4500), Color(0xFFFF8C00), Color(0xFFFFD700)],
                    ).createShader(bounds);
                  } else if (isAurora) {
                    return const LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Color(0xFF00FF88), Color(0xFF00DDFF), Color(0xFF8800FF)],
                    ).createShader(bounds);
                  }
                  return const LinearGradient(colors: [Colors.white, Colors.white]).createShader(bounds);
                },
                child: RichText(text: TextSpan(children: activeSpans), textAlign: TextAlign.center, textDirection: TextDirection.rtl),
              )
            ],
          );
        }
      }
    }
  }

    textWidget ??= RichText(
      text: TextSpan(
        children: wordSpans ?? [
          TextSpan(
            text: displayText, 
            style: TextStyle(
              fontFamily: fontFamily, 
              fontSize: fontSize, 
              color: color, 
              height: 1.6,
              shadows: quranAnimationId == 'ethereal_glow' 
                  ? [Shadow(color: const Color(0xFFE0B0FF).withValues(alpha: 0.8), blurRadius: (math.sin(localProgress * math.pi) * 20).clamp(0.0, 20.0))] 
                  : null
            )
          )
        ]
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    );

    if (hasQuranAnimation) {
      final shaderAnimations = ['rainbow', 'sunset', 'aurora'];
      final overlayAnimations = ['golden_particles', 'stardust', 'diamond_sparkle', 'blessed_rain', 'water_drops', 'autumn_leaves', 'flower_bloom', 'gentle_wind', 'light_butterflies', 'lightning', 'brush_strokes', 'ink_flow', 'quill_writing', 'living_calligraphy'];
      
      Widget mappedWidget = textWidget;

      // 1. Shader Mask Category - FALLBACK for texts without wordTimings (using simple sweeps)
      if (shaderAnimations.contains(quranAnimationId) && wordSpans == null) {
        mappedWidget = ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            if (quranAnimationId == 'rainbow') {
              final sweep = localProgress * bounds.width;
              return const LinearGradient(
                begin: Alignment.centerRight, end: Alignment.centerLeft,
                colors: [Color(0xFFFF0000), Color(0xFFFF7F00), Color(0xFFFFFF00), Color(0xFF00FF00), Color(0xFF0000FF), Color(0xFF4B0082), Color(0xFF9400D3)],
              ).createShader(Rect.fromLTRB(bounds.right - sweep, bounds.top, bounds.right, bounds.bottom));
            } else if (quranAnimationId == 'sunset') {
              return const LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFFFF4500), Color(0xFFFF8C00), Color(0xFFFFD700)],
              ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height * localProgress));
            } else if (quranAnimationId == 'aurora') {
              return const LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFF00FF88), Color(0xFF00DDFF), Color(0xFF8800FF)],
              ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height * localProgress));
            }
            return const LinearGradient(colors: [Colors.white, Colors.white]).createShader(bounds);
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
          padding: const EdgeInsets.symmetric(horizontal: 16), 
          child: CustomPaint(
            painter: isOverlay || isGlow || shaderAnimations.contains(quranAnimationId) 
                ? null // Let Text take precedence, Shader/Glow handles it
                : _QuranAnimationPainter(animationId: quranAnimationId, progress: localProgress, textColor: color),
            foregroundPainter: isOverlay
                ? _QuranAnimationPainter(animationId: quranAnimationId, progress: localProgress, textColor: color)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20), 
              child: mappedWidget
            ),
          )
        )
      );
      
      return _buildSmartBoundingBoxWrapper(
        layer: layer, previewWidth: previewWidth, previewHeight: previewHeight, 
        isSelected: ref.read(editorProvider).selectedLayerId == layer.id,
        defaultY: y - 40,
        defaultWidthRatio: 1.0,
        child: _applyMask(wrapperChild, layer.mask)
      );
    }
    
    return _buildSmartBoundingBoxWrapper(
      layer: layer, previewWidth: previewWidth, previewHeight: previewHeight, 
      isSelected: ref.read(editorProvider).selectedLayerId == layer.id,
      defaultY: y,
      defaultWidthRatio: 1.0,
      child: _applyMask(Opacity(opacity: opacity.clamp(0.0, 1.0), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: textWidget)), layer.mask)
    );
  }

  Widget _buildTranslationLayer(Layer layer, double currentTime, double previewWidth, double previewHeight, List<Layer> activeLayers) {
    final style = layer.textStyle;
    final scaleFactor = previewWidth / 360.0;
    final baseFontSize = style?.fontSize ?? 14;
    final fontSize = baseFontSize * scaleFactor;
    final color = style != null ? _parseColor(style.color) : Colors.white70;
    final opacity = (layer.style['opacity'] as num?)?.toDouble() ?? 1.0;
    final transformY = layer.transform.y;
    final y = layer.style['y']?.toDouble() ?? (transformY * previewHeight);

    String displayText = layer.content;
    final arabicLayer = activeLayers.where((l) => l.type == 'arabic' && (l.startTime - layer.startTime).abs() < 0.1).firstOrNull;
    if (arabicLayer != null && arabicLayer.wordTimings.isNotEmpty) {
      final arabicChunks = _chunkWordTimings(arabicLayer.wordTimings, wordsPerChunk: 10);
      final transChunks = _chunkStringProportionally(layer.content, arabicChunks);
      if (transChunks.isNotEmpty) {
        final activeChunksIter = transChunks.where((c) => currentTime >= c.start && currentTime <= c.end);
        final activeChunk = activeChunksIter.isNotEmpty ? activeChunksIter.first : transChunks.last;
        displayText = activeChunk.text;
      }
    }

    Widget tWidget = Text(displayText, style: TextStyle(fontFamily: style?.fontFamily ?? layer.fontFamily, fontSize: fontSize, color: color, height: 1.4), textAlign: TextAlign.center);

    return _buildSmartBoundingBoxWrapper(
      layer: layer, previewWidth: previewWidth, previewHeight: previewHeight, 
      isSelected: ref.read(editorProvider).selectedLayerId == layer.id,
      defaultY: y,
      defaultWidthRatio: 1.0,
      child: _applyMask(_applyBlendMode(Opacity(opacity: opacity.clamp(0.0, 1.0), child: tWidget), layer.blendMode), layer.mask)
    );
  }

  Widget _buildPhoneticLayer(Layer layer, double currentTime, double previewWidth, double previewHeight, List<Layer> activeLayers) {
    final style = layer.textStyle;
    final scaleFactor = previewWidth / 360.0;
    final baseFontSize = style?.fontSize ?? 12;
    final fontSize = baseFontSize * scaleFactor;
    final color = style != null ? _parseColor(style.color) : Colors.white70;
    final opacity = (layer.style['opacity'] as num?)?.toDouble() ?? 1.0;
    final transformY = layer.transform.y;
    final y = layer.style['y']?.toDouble() ?? (transformY * previewHeight);

    String displayText = layer.content;
    final arabicLayer = activeLayers.where((l) => l.type == 'arabic' && (l.startTime - layer.startTime).abs() < 0.1).firstOrNull;
    if (arabicLayer != null && arabicLayer.wordTimings.isNotEmpty) {
      final arabicChunks = _chunkWordTimings(arabicLayer.wordTimings, wordsPerChunk: 10);
      final transChunks = _chunkStringProportionally(layer.content, arabicChunks);
      if (transChunks.isNotEmpty) {
        final activeChunksIter = transChunks.where((c) => currentTime >= c.start && currentTime <= c.end);
        final activeChunk = activeChunksIter.isNotEmpty ? activeChunksIter.first : transChunks.last;
        displayText = activeChunk.text;
      }
    }

    Widget tWidget = Text(displayText, style: TextStyle(fontFamily: style?.fontFamily ?? layer.fontFamily, fontSize: fontSize, color: color, height: 1.4, fontStyle: FontStyle.italic), textAlign: TextAlign.center);

    return _buildSmartBoundingBoxWrapper(
      layer: layer, previewWidth: previewWidth, previewHeight: previewHeight, 
      isSelected: ref.read(editorProvider).selectedLayerId == layer.id,
      defaultY: y,
      defaultWidthRatio: 1.0,
      child: _applyMask(_applyBlendMode(Opacity(opacity: opacity.clamp(0.0, 1.0), child: tWidget), layer.blendMode), layer.mask)
    );
  }

  // _buildTextLayer removed — replaced by _buildDraggableTextLayer which also handles drag+drop

  Widget _buildFilterOverlay(List<Layer> activeLayers, double currentTime) {
    final videoLayer = activeLayers.firstWhere((l) => l.type == 'video', orElse: () => Layer(id: '', type: '', content: '', startTime: 0, duration: 0, style: {}));
    final filterId = videoLayer.filterId;
    if (filterId == 'none' || filterId.isEmpty) return const SizedBox.shrink();
    final intensity = (videoLayer.style['filterIntensity'] as num?)?.toDouble() ?? 1.0;
    Color filterColor;
    switch (filterId) {
      case 'cinematic': filterColor = const Color(0xFFFFE0B2).withValues(alpha: intensity * 0.15); break;
      case 'vintage': filterColor = const Color(0xFFD7CCC8).withValues(alpha: intensity * 0.2); break;
      case 'cold': filterColor = const Color(0xFFB3E5FC).withValues(alpha: intensity * 0.15); break;
      case 'warm': filterColor = const Color(0xFFFFCC80).withValues(alpha: intensity * 0.15); break;
      case 'dramatic':
      case 'noir': filterColor = Colors.black.withValues(alpha: intensity * 0.3); break;
      default: return const SizedBox.shrink();
    }
    return Positioned.fill(child: Container(color: filterColor));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorProvider);

    // Watch for dynamically added Video layers to auto-initialize the controller
    ref.listen<String?>(
      editorProvider.select((s) => s.currentProject?.layers.where((l) => l.type == 'video').firstOrNull?.content),
      (previous, next) {
        if (next != null && next != _lastVideoPath) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _initializeVideoController());
        }
      },
    );

    final project = state.currentProject;
    if (project == null) return const Center(child: Text('No project loaded', style: TextStyle(color: Colors.white70)));
    final currentTime = state.currentTime;
    final isPlaying = state.isPlaying;
    if (isPlaying && _ticker == null) { Future(() => _startPlayback()); }
    else if (!isPlaying && _ticker != null) { Future(() => _stopPlayback()); }
    final activeLayers = state.activeLayers.where((l) => currentTime >= l.startTime && currentTime < l.startTime + l.effectiveDuration).toList();
    activeLayers.sort((a, b) => a.startTime.compareTo(b.startTime));
    final selectedLayerId = state.selectedLayerId;

    return LayoutBuilder(
      builder: (context, constraints) {
        final ratioParts = project.aspectRatio.split(':');
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
            // Tap on empty canvas area = deselect layer
            ref.read(editorProvider.notifier).setSelectedLayer(null);
            // Flash play/pause icon
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
                    // ── Canvas ──────────────────────────────────────────
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
                              // Background
                              _buildCanvasBackground(project, previewWidth, previewHeight),
                              // Video
                              _buildVideoLayer(activeLayers, currentTime, previewWidth, previewHeight),
                              // Image layers — with drag support
                              ...activeLayers.where((l) => l.type == 'image').map(
                                (layer) => _buildDraggableLayer(
                                  layer: layer,
                                  previewWidth: previewWidth,
                                  previewHeight: previewHeight,
                                  isSelected: selectedLayerId == layer.id,
                                  child: _buildImageLayer(layer, currentTime, previewWidth, previewHeight),
                                ),
                              ),
                              // Stickers
                              ...activeLayers.where((l) => l.type == 'sticker').map(
                                (layer) => _buildStickerLayer(layer, currentTime, previewWidth, previewHeight),
                              ),
                              // Arabic
                              ...activeLayers.where((l) => l.type == 'arabic').map(
                                (layer) => _buildArabicLayer(layer, currentTime, previewWidth, previewHeight),
                              ),
                              // Translation
                              ...activeLayers.where((l) => l.type == 'translation').map(
                                (layer) => _buildTranslationLayer(layer, currentTime, previewWidth, previewHeight, activeLayers),
                              ),
                              // Phonetic
                              ...activeLayers.where((l) => l.type == 'phonetic').map(
                                (layer) => _buildPhoneticLayer(layer, currentTime, previewWidth, previewHeight, activeLayers),
                              ),
                              // Text layers — with drag support
                              ...activeLayers.where((l) => l.type == 'text').map(
                                (layer) => _buildDraggableTextLayer(
                                  layer: layer,
                                  currentTime: currentTime,
                                  previewWidth: previewWidth,
                                  previewHeight: previewHeight,
                                  isSelected: selectedLayerId == layer.id,
                                ),
                              ),
                              // Filter overlay
                              _buildFilterOverlay(activeLayers, currentTime),
                              // Selection handles overlay
                              if (selectedLayerId != null)
                                ..._buildSelectionOverlay(
                                  activeLayers,
                                  selectedLayerId,
                                  previewWidth,
                                  previewHeight,
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
                                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
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
    final layerW = (layer.style['width'] as num?)?.toDouble() ?? previewWidth * 0.5;
    final layerH = (layer.style['height'] as num?)?.toDouble() ?? previewHeight * 0.3;
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
        ? ((currentTime - layer.startTime) / layer.effectiveDuration).clamp(0.0, 1.0)
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
        if (layerProgress > 0.7) animOpacity = opacity * ((1.0 - layerProgress) / 0.3).clamp(0.0, 1.0);
        break;
      case 'fadeInOut':
        if (layerProgress < 0.2) { animOpacity = opacity * (layerProgress / 0.2); }
        else if (layerProgress > 0.8) { animOpacity = opacity * ((1.0 - layerProgress) / 0.2); }
        break;
      case 'typewriter':
        final charCount = (layerProgress * layer.content.length).clamp(0, layer.content.length).toInt();
        displayText = layer.content.substring(0, charCount);
        break;
      case 'slideInLeft':
        if (layerProgress < 0.3) slideOffset = Offset(-previewWidth * (1.0 - layerProgress / 0.3), 0);
        break;
      case 'slideInRight':
        if (layerProgress < 0.3) slideOffset = Offset(previewWidth * (1.0 - layerProgress / 0.3), 0);
        break;
      case 'slideInTop':
        if (layerProgress < 0.3) slideOffset = Offset(0, -previewHeight * (1.0 - layerProgress / 0.3));
        break;
      case 'slideInBottom':
        if (layerProgress < 0.3) slideOffset = Offset(0, previewHeight * (1.0 - layerProgress / 0.3));
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

    Widget contentWidget = RichText(
      text: TextSpan(
        text: displayText,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize,
          color: color,
          height: 1.4,
          fontWeight: style?.fontWeight,
          fontStyle: style?.isItalic == true ? FontStyle.italic : FontStyle.normal,
          shadows: style != null && style.shadowBlur > 0
              ? [Shadow(color: _parseColor(style.shadowColor), offset: Offset(style.shadowOffsetX, style.shadowOffsetY), blurRadius: style.shadowBlur)]
              : [],
        ),
      ),
      textAlign: TextAlign.center,
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
  }) {
    final x = layer.style['x']?.toDouble() ?? defaultX;
    final y = layer.style['y']?.toDouble() ?? defaultY;
    final scale = layer.style['scale']?.toDouble() ?? 1.0;
    final customWidth = layer.style['width']?.toDouble();
    
    Widget sizedContent = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: previewWidth * defaultWidthRatio),
      child: customWidth != null 
          ? SizedBox(width: customWidth, child: child)
          : IntrinsicWidth(child: child),
    );

    if (isSelected) {
      final borderColor = const Color(0xFF2196F3);
      sizedContent = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor.withValues(alpha: 0.85), width: 1.5 / scale),
              borderRadius: BorderRadius.circular(3 / scale),
            ),
            child: sizedContent,
          ),
          // Poignée droite (Ajuster la largeur)
          Positioned(
            right: -15 / scale, top: 0, bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) {
                double newW = (customWidth ?? previewWidth * defaultWidthRatio) + (details.delta.dx / scale);
                newW = newW.clamp(50.0, previewWidth);
                ref.read(editorProvider.notifier).updateLayer(
                  layer.copyWith(style: {...layer.style, 'width': newW})
                );
              },
              child: SizedBox(
                width: 30 / scale,
                child: Center(
                  child: Container(
                    width: 6 / scale, height: 24 / scale,
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: borderColor, width: 1 / scale), borderRadius: BorderRadius.circular(2)),
                  )
                )
              ),
            ),
          ),
          // Poignée en bas à droite (Ajuster l'échelle / zoom)
          Positioned(
            right: -10 / scale, bottom: -10 / scale,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) {
                double newScale = scale + (details.delta.dx * 0.01) + (details.delta.dy * 0.01);
                newScale = newScale.clamp(0.2, 5.0);
                ref.read(editorProvider.notifier).updateLayer(
                  layer.copyWith(style: {...layer.style, 'scale': newScale})
                );
              },
              child: SizedBox(
                width: 20 / scale, height: 20 / scale,
                child: Center(
                  child: Container(
                    width: 12 / scale, height: 12 / scale,
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: borderColor, width: 1.5 / scale), shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)]),
                  )
                )
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
        onTapDown: (_) => ref.read(editorProvider.notifier).setSelectedLayer(layer.id),
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
          final newX = (_layerStartOffset.dx + dx).clamp(-previewWidth, previewWidth * 2);
          final newY = (_layerStartOffset.dy + dy).clamp(-previewHeight, previewHeight * 2);
          final updated = layer.copyWith(
            style: {...layer.style, 'x': newX, 'y': newY},
          );
          ref.read(editorProvider.notifier).updateLayer(updated);
        },
        onPanEnd: (_) => _draggingLayerId = null,
        child: Transform.scale(
          scale: scale,
          child: sizedContent,
        ),
      ),
    );
  }
  List<Widget> _buildSelectionOverlay(
    List<Layer> activeLayers,
    String selectedId,
    double previewWidth,
    double previewHeight,
  ) {
    final selected = activeLayers.where((l) => l.id == selectedId).firstOrNull;
    if (selected == null) return [];
    if (selected.type == 'video' || selected.type == 'audio') return [];

    double left, top, width, height;
    if (selected.type == 'image') {
      left = (selected.style['x']?.toDouble() ?? 0) - 4;
      top = (selected.style['y']?.toDouble() ?? 0) - 4;
      width = (selected.style['width']?.toDouble() ?? previewWidth) + 8;
      height = (selected.style['height']?.toDouble() ?? previewHeight) + 8;
    } else {
      return [];
    }

    const handleSize = 10.0;
    const borderColor = Color(0xFF2196F3);

    Widget corner(double l, double t) => Positioned(
          left: l - handleSize / 2,
          top: t - handleSize / 2,
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: borderColor, width: 1.5),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)],
            ),
          ),
        );

    return [
      // Dashed selection border
      Positioned(
        left: left,
        top: top,
        child: IgnorePointer(
          child: Container(
            width: width.clamp(20, previewWidth),
            height: height.clamp(20, previewHeight),
            decoration: BoxDecoration(
              border: Border.all(
                color: borderColor.withValues(alpha: 0.85),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
      // Corner handles
      corner(left, top),
      corner(left + width.clamp(20, previewWidth), top),
      corner(left, top + height.clamp(20, previewHeight)),
      corner(left + width.clamp(20, previewWidth), top + height.clamp(20, previewHeight)),
    ];
  }
}

class _QuranAnimationPainter extends CustomPainter {
  final String animationId;
  final double progress;
  final Color textColor;
  _QuranAnimationPainter({required this.animationId, required this.progress, required this.textColor});
  @override
  void paint(Canvas canvas, Size size) {
    paintQuranAnimation(canvas, Rect.fromLTWH(0, 0, size.width, size.height), animationId, progress, textColor: textColor);
  }
  @override
  bool shouldRepaint(covariant _QuranAnimationPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.animationId != animationId || oldDelegate.textColor != textColor;
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..moveTo(size.width / 2, 0)..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
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
      if (i == 0) { path.moveTo(cx + r * math.cos(angle), cy + r * math.sin(angle)); }
      else { path.lineTo(cx + r * math.cos(angle), cy + r * math.sin(angle)); }
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
    if (axis == Axis.horizontal) { path.addRect(Rect.fromLTWH(0, 0, size.width, size.height * value)); }
    else { path.addRect(Rect.fromLTWH(0, 0, size.width * value, size.height)); }
    return path;
  }
  @override
  bool shouldReclip(covariant _SplitClipper oldClipper) => oldClipper.axis != axis || oldClipper.value != value;
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

  String _fmt(double s) {
    final m = (s / 60).floor();
    final sec = (s % 60).floor();
    final ms = ((s % 1) * 10).floor();
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}.$ms';
  }

  @override
  Widget build(BuildContext context) {
    final progress = totalDuration > 0 ? (currentTime / totalDuration).clamp(0.0, 1.0) : 0.0;
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
              border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.5)),
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
            _fmt(currentTime),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '/ ${_fmt(totalDuration)}',
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
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                minHeight: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
