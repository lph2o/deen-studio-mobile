import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:deen_studio_01/core/services/persistent_media_store.dart';
import 'package:deen_studio_01/models/project.dart';
import 'package:deen_studio_01/models/text_layer_style.dart';
import 'package:deen_studio_01/core/models/speed_curve.dart';
import 'package:deen_studio_01/core/services/beat_detector.dart';
import 'package:deen_studio_01/core/services/video_stabilizer.dart';

class EditorState {
  final Project? currentProject;
  final String? selectedLayerId;
  final double currentTime;
  final bool isPlaying;
  final bool isSaving;
  final double zoomLevel;       // pixels per second on the timeline
  final bool isDraggingTimeline;
  final List<Project> undoStack;
  final List<Project> redoStack;
  final String? activeToolbarCategory;
  final bool isTimelineExpanded;
  final bool isFullScreen;
  final bool rippleEdit;

  // Track control state — sets of track type names (e.g. 'audio', 'video', 'text')
  final Set<String> lockedTracks;
  final Set<String> hiddenTracks;
  final Set<String> mutedTracks;

  // Beat sync state — detected beat timestamps (shared across all audio layers)
  final List<double> beatMarkers;
  final bool beatSyncEnabled;

  EditorState({
    this.currentProject,
    this.selectedLayerId,
    this.currentTime = 0,
    this.isPlaying = false,
    this.isSaving = false,
    this.zoomLevel = 60.0,
    this.isDraggingTimeline = false,
    this.undoStack = const [],
    this.redoStack = const [],
    this.activeToolbarCategory,
    this.isTimelineExpanded = false,
    this.isFullScreen = false,
    this.rippleEdit = false,
    this.lockedTracks = const {},
    this.hiddenTracks = const {},
    this.mutedTracks = const {},
    this.beatMarkers = const [],
    this.beatSyncEnabled = false,
  });

  EditorState copyWith({
    Project? currentProject,
    String? selectedLayerId,
    double? currentTime,
    bool? isPlaying,
    bool? isSaving,
    double? zoomLevel,
    bool? isDraggingTimeline,
    List<Project>? undoStack,
    List<Project>? redoStack,
    String? activeToolbarCategory,
    bool? isTimelineExpanded,
    bool? isFullScreen,
    bool? rippleEdit,
    Set<String>? lockedTracks,
    Set<String>? hiddenTracks,
    Set<String>? mutedTracks,
    List<double>? beatMarkers,
    bool? beatSyncEnabled,
    bool clearSelected = false,
  }) {
    return EditorState(
      currentProject: currentProject ?? this.currentProject,
      selectedLayerId: clearSelected ? null : (selectedLayerId ?? this.selectedLayerId),
      currentTime: currentTime ?? this.currentTime,
      isPlaying: isPlaying ?? this.isPlaying,
      isSaving: isSaving ?? this.isSaving,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      isDraggingTimeline: isDraggingTimeline ?? this.isDraggingTimeline,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      activeToolbarCategory: activeToolbarCategory ?? this.activeToolbarCategory,
      isTimelineExpanded: isTimelineExpanded ?? this.isTimelineExpanded,
      isFullScreen: isFullScreen ?? this.isFullScreen,
      rippleEdit: rippleEdit ?? this.rippleEdit,
      lockedTracks: lockedTracks ?? Set<String>.from(this.lockedTracks),
      hiddenTracks: hiddenTracks ?? Set<String>.from(this.hiddenTracks),
      mutedTracks: mutedTracks ?? Set<String>.from(this.mutedTracks),
      beatMarkers: beatMarkers ?? this.beatMarkers,
      beatSyncEnabled: beatSyncEnabled ?? this.beatSyncEnabled,
    );
  }

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  /// Active layers at the current playhead position, excluding hidden tracks.
  /// Track keys can be either raw types ('audio', 'video', 'image', 'text')
  /// or prefixed keys ('text_arabic_', 'text_phonetic_', 'text_translation_').
  bool _isLayerHidden(Layer layer) {
    // Check for exact type match (audio, video, image, text)
    if (hiddenTracks.contains(layer.type)) return true;
    // Check for prefixed text tracks
    if (layer.type == 'text') {
      if (hiddenTracks.contains('text_arabic_') && layer.id.startsWith('arabic_')) return true;
      if (hiddenTracks.contains('text_phonetic_') && layer.id.startsWith('phonetic_')) return true;
      if (hiddenTracks.contains('text_translation_') && layer.id.startsWith('translation_')) return true;
      // If generic 'text' track is hidden and layer doesn't match any prefix
      if (hiddenTracks.contains('text') &&
          !layer.id.startsWith('arabic_') &&
          !layer.id.startsWith('phonetic_') &&
          !layer.id.startsWith('translation_')) { return true; }
    }
    return false;
  }

  List<Layer> get activeLayers {
    final layers = currentProject?.layers.where((l) =>
      !_isLayerHidden(l) && l.activeAt(currentTime)
    ).toList() ?? [];
    return layers;
  }
}

class EditorNotifier extends Notifier<EditorState> {
  final _supabase = Supabase.instance.client;
  Timer? _saveTimer;
  Timer? _autoSaveTimer;

  @override
  EditorState build() => EditorState();

  // ─────────────────────────────────────────────────────────────────────────
  // PROJECT LOADING
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> loadProject(String id) async {
    if (id == 'new') return;
    final data = await _supabase.from('projects').select().eq('id', id).single();
    state = state.copyWith(currentProject: Project.fromMap(data));
    // Start periodic auto-save as safety net (every 30 seconds)
    _startPeriodicAutoSave();
  }

  void _startPeriodicAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) => _save());
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LAYER MUTATIONS (all push to undoStack & debounce-save)
  // ─────────────────────────────────────────────────────────────────────────

  void addLayer(Layer layer) => _mutate((p) => p.copyWith(
        layers: [...p.layers, layer],
      ));

  void removeLayer(String id) => _mutate((p) => p.copyWith(
        layers: p.layers.where((l) => l.id != id).toList(),
      ));

  void updateLayer(Layer updated) => _mutate((p) => p.copyWith(
        layers: p.layers.map((l) => l.id == updated.id ? updated : l).toList(),
      ));

  void duplicateLayer(String id) {
    final layer = _findLayer(id);
    if (layer == null || layer.id.isEmpty) return;

    // Place the duplicate right after the original ends
    final newStartTime = layer.startTime + layer.effectiveDuration;

    final duplicated = layer.copyWith(
      id: '${layer.type}_copy_${DateTime.now().millisecondsSinceEpoch}',
      startTime: newStartTime,
    );
    _mutate((p) => p.copyWith(
      layers: [...p.layers, duplicated],
    ));
    setSelectedLayer(duplicated.id);
  }

  void moveLayer(String id, double newStartTime) {
    final layer = _findLayer(id);
    if (layer == null) return;
    updateLayer(layer.copyWith(startTime: newStartTime.clamp(0, double.infinity)));
  }

  /// Move a layer and ripple-shift all subsequent layers on all tracks by the same delta.
  void moveLayerWithRipple(String id, double delta) {
    final layer = _findLayer(id);
    if (layer == null) return;

    final newStart = (layer.startTime + delta).clamp(0.0, double.infinity);
    final actualDelta = newStart - layer.startTime;

    if (actualDelta == 0) return;

    // Move ALL layers that start after this layer's original start time
    final updatedLayers = state.currentProject!.layers.map((l) {
      if (l.id == id) return l.copyWith(startTime: newStart);
      if (l.startTime > layer.startTime) {
        return l.copyWith(startTime: l.startTime + actualDelta);
      }
      return l;
    }).toList();

    _mutate((p) => p.copyWith(layers: updatedLayers));
  }

  /// Apply a speed curve to a layer.
  void applySpeedCurve(String layerId, SpeedCurve curve) {
    final layer = _findLayer(layerId);
    if (layer == null) return;
    updateLayer(layer.copyWith(speedCurve: curve));
  }

  /// Toggle ripple edit mode on/off.
  void toggleRippleEdit() {
    state = state.copyWith(rippleEdit: !state.rippleEdit);
  }

  void trimLayer(String id, {double? inPoint, double? outPoint}) {
    final layer = _findLayer(id);
    if (layer == null) return;
    updateLayer(layer.copyWith(inPoint: inPoint, outPoint: outPoint));
  }

  void trimLayerStart(String id, double delta) {
    final layer = _findLayer(id);
    if (layer == null) return;
    
    // New startTime cannot be < 0
    final newStart = (layer.startTime + delta).clamp(0.0, double.infinity);
    final actualDelta = newStart - layer.startTime;
    
    // Adjust inPoint to keep media segment fixed at new start position
    // Or just shift the start without changing crop if it's text.
    // For now, let's just shift text/audio/video start
    final newIn = (layer.inPoint ?? 0) + actualDelta;
    
    updateLayer(layer.copyWith(
      startTime: newStart,
      inPoint: newIn,
    ));
  }

  void trimLayerEnd(String id, double delta) {
    final layer = _findLayer(id);
    if (layer == null) return;
    
    // Current effective duration
    final currentEnd = layer.outPoint ?? layer.duration;
    final newEnd = (currentEnd + delta).clamp((layer.inPoint ?? 0) + 0.1, double.infinity);
    
    updateLayer(layer.copyWith(outPoint: newEnd));
  }

  void splitLayer(String id, double atTime) {
    final layer = _findLayer(id);
    if (layer == null) return;

    final splitOffset = atTime - layer.startTime;
    if (splitOffset <= 0 || splitOffset >= layer.duration) return;

    final first = layer.copyWith(duration: splitOffset);
    final second = layer.copyWith(
      id: '${layer.id}_split_${DateTime.now().millisecondsSinceEpoch}',
      startTime: atTime,
      duration: layer.duration - splitOffset,
    );

    _mutate((p) => p.copyWith(
      layers: p.layers.map((l) => l.id == id ? first : l).toList()..add(second),
    ));
  }

  void updateLayerTransform(String id, ClipTransform transform) {
    final layer = _findLayer(id);
    if (layer == null) return;
    updateLayer(layer.copyWith(transform: transform));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // KEYFRAMES
  // ─────────────────────────────────────────────────────────────────────────

  /// Add a keyframe at the given time with the current transform values.
  void addKeyframe(String layerId, double time, ClipTransform transform, {String easing = 'linear'}) {
    final layer = _findLayer(layerId);
    if (layer == null) return;
    final keyframe = Keyframe(time: time, transform: transform, easing: easing);
    final keyframes = [...layer.keyframes, keyframe]..sort((a, b) => a.time.compareTo(b.time));
    updateLayer(layer.copyWith(keyframes: keyframes));
  }

  /// Remove a keyframe at the given index.
  void removeKeyframe(String layerId, int index) {
    final layer = _findLayer(layerId);
    if (layer == null) return;
    final keyframes = List<Keyframe>.from(layer.keyframes)..removeAt(index);
    updateLayer(layer.copyWith(keyframes: keyframes));
  }

  /// Update a keyframe's easing at the given index.
  void updateKeyframeEasing(String layerId, int index, String easing) {
    final layer = _findLayer(layerId);
    if (layer == null) return;
    final keyframes = List<Keyframe>.from(layer.keyframes);
    keyframes[index] = keyframes[index].copyWith(easing: easing);
    updateLayer(layer.copyWith(keyframes: keyframes));
  }

  /// Get the interpolated transform at a given playback time.
  ClipTransform getTransformAtTime(String layerId, double currentTime) {
    final layer = _findLayer(layerId);
    if (layer == null) return const ClipTransform();
    final keyframes = layer.keyframes;
    if (keyframes.isEmpty) return layer.transform;
    if (keyframes.length == 1) return keyframes.first.transform;

    // Before first keyframe: use first keyframe's transform
    if (currentTime <= keyframes.first.time) return keyframes.first.transform;
    // After last keyframe: use last keyframe's transform
    if (currentTime >= keyframes.last.time) return keyframes.last.transform;

    // Find surrounding keyframes
    int i = 0;
    for (; i < keyframes.length - 1; i++) {
      if (keyframes[i].time <= currentTime && keyframes[i + 1].time > currentTime) break;
    }

    final kf1 = keyframes[i];
    final kf2 = keyframes[i + 1];
    final duration = kf2.time - kf1.time;
    final t = duration > 0 ? ((currentTime - kf1.time) / duration).clamp(0.0, 1.0) : 0.0;

    // Apply easing from the first keyframe
    final easedT = Easing.resolver(kf1.easing)(t);

    return ClipTransform(
      x: _lerp(kf1.transform.x, kf2.transform.x, easedT),
      y: _lerp(kf1.transform.y, kf2.transform.y, easedT),
      scaleX: _lerp(kf1.transform.scaleX, kf2.transform.scaleX, easedT),
      scaleY: _lerp(kf1.transform.scaleY, kf2.transform.scaleY, easedT),
      rotation: _lerp(kf1.transform.rotation, kf2.transform.rotation, easedT),
      opacity: _lerp(kf1.transform.opacity, kf2.transform.opacity, easedT),
    );
  }

  /// Linear interpolation between two doubles.
  double _lerp(double a, double b, double t) => a + (b - a) * t;

  // ─────────────────────────────────────────────────────────────────────────

  void applyEffect(String id, ClipEffect effect) {
    final layer = _findLayer(id);
    if (layer == null) return;
    final effects = [...layer.effects.where((e) => e.id != effect.id), effect];
    updateLayer(layer.copyWith(effects: effects));
  }

  void removeEffect(String id, String effectId) {
    final layer = _findLayer(id);
    if (layer == null) return;
    updateLayer(layer.copyWith(effects: layer.effects.where((e) => e.id != effectId).toList()));
  }

  void updateTextContent(String id, String text) {
    final layer = _findLayer(id);
    if (layer == null) return;
    updateLayer(layer.copyWith(content: text));
  }

  void updateTextStyle(String id, {
    String? fontFamily, double? fontSize, String? color, String? animation,
  }) {
    final layer = _findLayer(id);
    if (layer == null) return;
    updateLayer(layer.copyWith(
      fontFamily: fontFamily, fontSize: fontSize,
      textColor: color, textAnimation: animation,
    ));
  }

  void updateLayerMask(String id, LayerMask mask) {
    final layer = _findLayer(id);
    if (layer == null) return;
    updateLayer(layer.copyWith(mask: mask));
  }

  void updateBlendMode(String id, String blendMode) {
    final layer = _findLayer(id);
    if (layer == null) return;
    updateLayer(layer.copyWith(blendMode: blendMode));
  }

  void applyFilter(String id, String filterId) {
    final layer = _findLayer(id);
    if (layer == null) return;
    updateLayer(layer.copyWith(filterId: filterId));
  }

  /// Update the color grading settings for a layer.
  void updateColorGrading(String layerId, ColorGrading grading) {
    final layer = _findLayer(layerId);
    if (layer == null) return;
    updateLayer(layer.copyWith(colorGrading: grading));
  }

  /// Update the chroma key settings for a layer.
  void updateChromaKey(String layerId, ChromaKey chromaKey) {
    final layer = _findLayer(layerId);
    if (layer == null) return;
    updateLayer(layer.copyWith(chromaKey: chromaKey));
  }

  /// Apply a voice effect preset to an audio layer.
  void applyVoiceEffect(String layerId, String effectId) {
    final layer = _findLayer(layerId);
    if (layer == null) return;
    updateLayer(layer.copyWith(voiceEffectId: effectId));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BEAT SYNC & AUDIO DUCKING
  // ─────────────────────────────────────────────────────────────────────────

  /// Detect audio beats from all audio layers and store them as beat markers.
  Future<void> detectBeats() async {
    final project = state.currentProject;
    if (project == null) return;

    final audioLayers = project.layers.where((l) => l.type == 'audio' && l.content.isNotEmpty).toList();
    if (audioLayers.isEmpty) return;

    // Use the first audio layer to detect beats
    final firstAudio = audioLayers.first;
    final audioPath = firstAudio.content;

    if (!audioPath.startsWith('/')) return;

    final beats = await BeatDetector.detectBeats(audioPath);
    state = state.copyWith(beatMarkers: beats, beatSyncEnabled: true);
  }

  /// Toggle beat sync snapping on/off.
  void toggleBeatSync() {
    state = state.copyWith(beatSyncEnabled: !state.beatSyncEnabled);
  }

  /// Snap a time value to the nearest beat marker.
  double snapToBeat(double time) {
    if (!state.beatSyncEnabled || state.beatMarkers.isEmpty) return time;
    return BeatDetector.snapToBeat(time, state.beatMarkers);
  }

  /// Toggle audio ducking on/off.
  void toggleDucking() {
    final project = state.currentProject;
    if (project == null) return;
    _mutate((p) => p.copyWith(duckingEnabled: !p.duckingEnabled));
  }

  /// Update the noise gate threshold for an audio layer.
  void updateNoiseGate(String layerId, double threshold) {
    final layer = _findLayer(layerId);
    if (layer == null) return;
    updateLayer(layer.copyWith(noiseGateThreshold: threshold.clamp(0.0, 1.0)));
  }

  /// Toggle beat sync on a specific audio layer.
  void toggleLayerBeatSync(String layerId) {
    final layer = _findLayer(layerId);
    if (layer == null) return;
    updateLayer(layer.copyWith(beatSync: !layer.beatSync));
  }

  void updateAspectRatio(String ratio) {
    if (state.currentProject == null) return;
    _mutate((p) => p.copyWith(aspectRatio: ratio));
  }

  /// Set the reframe mode for auto-crop when changing aspect ratios.
  void setReframeMode(String mode) {
    if (state.currentProject == null) return;
    _mutate((p) => p.copyWith(reframeMode: mode));
  }

  /// Stabilize a shaky video layer using FFmpeg's vidstabdetect + vidstabtransform.
  ///
  /// Returns true on success, false on failure.
  /// The caller is responsible for showing a loading dialog before calling this.
  Future<bool> stabilizeVideo(String layerId, {
    void Function(double progress, String message)? onProgress,
  }) async {
    final layer = _findLayer(layerId);
    if (layer == null || layer.type != 'video') return false;

    final inputPath = layer.content;
    if (!inputPath.startsWith('/') || !File(inputPath).existsSync()) return false;

    // Generate output path in temp directory
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = '${tempDir.path}/stabilized_$timestamp.mp4';

    final result = await VideoStabilizer.stabilize(
      inputPath,
      outputPath,
      shakiness: 5,
      accuracy: 15,
      smoothing: 10,
      onProgress: onProgress,
    );

    if (result != null) {
      // Copy to persistent storage and replace the layer's content
      final persistentPath = await PersistentMediaStore.persistFile(result);
      final updated = layer.copyWith(
        content: persistentPath,
        stabilized: true,
      );
      updateLayer(updated);
      return true;
    }

    return false;
  }

  void reorderLayers(List<String> orderedIds) {
    final project = state.currentProject;
    if (project == null) return;
    final layerMap = {for (var l in project.layers) l.id: l};
    final reordered = orderedIds.map((id) => layerMap[id]).whereType<Layer>().toList();
    _mutate((p) => p.copyWith(layers: reordered));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UNDO / REDO
  // ─────────────────────────────────────────────────────────────────────────

  void undo() {
    if (!state.canUndo) return;
    final prev = state.undoStack.last;
    state = state.copyWith(
      currentProject: prev,
      undoStack: state.undoStack.sublist(0, state.undoStack.length - 1),
      redoStack: [if (state.currentProject != null) state.currentProject!, ...state.redoStack],
    );
    _scheduleSave();
  }

  void redo() {
    if (!state.canRedo) return;
    final next = state.redoStack.first;
    state = state.copyWith(
      currentProject: next,
      redoStack: state.redoStack.sublist(1),
      undoStack: [...state.undoStack, if (state.currentProject != null) state.currentProject!],
    );
    _scheduleSave();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PLAYBACK
  // ─────────────────────────────────────────────────────────────────────────

  void setCurrentTime(double time) {
    state = state.copyWith(currentTime: time.clamp(0, state.currentProject?.totalDuration ?? 0));
  }

  void togglePlay() {
    state = state.copyWith(isPlaying: !state.isPlaying);
  }

  void pause() => state = state.copyWith(isPlaying: false);

  // ─────────────────────────────────────────────────────────────────────────
  // SELECTION & ZOOM
  // ─────────────────────────────────────────────────────────────────────────

  void setSelectedLayer(String? id) {
    state = state.copyWith(selectedLayerId: id, clearSelected: id == null);
    if (id != null) {
      setActiveToolbarCategory(null);
    }
  }

  void setActiveToolbarCategory(String? category) {
    if (state.activeToolbarCategory == category) {
      state = state.copyWith(activeToolbarCategory: null);
    } else {
      state = state.copyWith(activeToolbarCategory: category);
    }
  }

  void setZoomLevel(double zoom) {
    state = state.copyWith(zoomLevel: zoom.clamp(10.0, 300.0));
  }

  void setDraggingTimeline(bool dragging) {
    state = state.copyWith(isDraggingTimeline: dragging);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TRACK CONTROLS (lock, hide, mute)
  // ─────────────────────────────────────────────────────────────────────────

  /// Toggle lock state for a track type. Locked tracks prevent clips from being moved or trimmed.
  void toggleTrackLock(String trackType) {
    final updated = Set<String>.from(state.lockedTracks);
    if (updated.contains(trackType)) {
      updated.remove(trackType);
    } else {
      updated.add(trackType);
    }
    state = state.copyWith(lockedTracks: updated);
  }

  /// Toggle hide state for a track type. Hidden tracks are not rendered in the preview.
  void toggleTrackHide(String trackType) {
    final updated = Set<String>.from(state.hiddenTracks);
    if (updated.contains(trackType)) {
      updated.remove(trackType);
    } else {
      updated.add(trackType);
    }
    state = state.copyWith(hiddenTracks: updated);
  }

  /// Toggle mute state for a track type. Muted tracks have their audio silenced.
  void toggleTrackMute(String trackType) {
    final updated = Set<String>.from(state.mutedTracks);
    if (updated.contains(trackType)) {
      updated.remove(trackType);
    } else {
      updated.add(trackType);
    }
    state = state.copyWith(mutedTracks: updated);
  }

  // ── Text Layer Methods ───────────────────────────────────────────────────

  /// Add a new text layer at the current playhead position.
  void addTextLayer({String content = 'Nouveau texte', TextLayerStyle? style}) {
    final project = state.currentProject;
    if (project == null) return;
    final id = 'text_${DateTime.now().millisecondsSinceEpoch}';
    final newLayer = Layer(
      id: id,
      type: 'text',
      content: content,
      startTime: state.currentTime,
      duration: 5.0,
      style: {},
      textStyle: style ?? const TextLayerStyle(),
    );
    _mutate((p) => p.copyWith(layers: [...p.layers, newLayer]));
    // Select the new layer automatically
    state = state.copyWith(selectedLayerId: id);
  }

  /// Add a media layer (image or video) at the current playhead position.
  void addMediaLayer({
    required String type,
    required String content,
    double? startTime,
    double? duration,
  }) {
    final project = state.currentProject;
    if (project == null) return;
    final id = '${type}_${DateTime.now().millisecondsSinceEpoch}';
    final newLayer = Layer(
      id: id,
      type: type, // 'image' or 'video'
      content: content,
      startTime: startTime ?? state.currentTime,
      duration: duration ?? 10.0,
      style: {},
    );
    _mutate((p) => p.copyWith(layers: [...p.layers, newLayer]));
    state = state.copyWith(selectedLayerId: id);
  }

  /// Add a sticker layer at the current playhead position.
  void addStickerLayer({
    required String stickerId,
    required String emoji,
    double size = 48.0,
  }) {
    final project = state.currentProject;
    if (project == null) return;
    final id = 'sticker_${DateTime.now().millisecondsSinceEpoch}';
    final newLayer = Layer(
      id: id,
      type: 'sticker',
      content: emoji,
      startTime: state.currentTime,
      duration: 5.0,
      style: {'size': size},
      transform: const ClipTransform(x: 0.5, y: 0.5, scaleX: 1.0, scaleY: 1.0),
    );
    _mutate((p) => p.copyWith(layers: [...p.layers, newLayer]));
    state = state.copyWith(selectedLayerId: id);
  }

  /// Set the canvas background preset for the project.
  void setCanvasBackground(String bgId) {
    if (state.currentProject == null) return;
    _mutate((p) => p.copyWith(canvasBackgroundId: bgId));
  }

  /// Update the TextLayerStyle of an existing layer.
  void updateLayerTextStyle(String layerId, TextLayerStyle newStyle) {
    final layer = _findLayer(layerId);
    if (layer == null) return;
    updateLayer(layer.copyWith(textStyle: newStyle));
  }

  /// Update the text content of a layer.
  void updateLayerContent(String layerId, String content) {
    final layer = _findLayer(layerId);
    if (layer == null) return;
    updateLayer(layer.copyWith(content: content));
  }

  /// Apply a full TextStylePreset to the selected text layer.
  void applyTextPreset(String layerId, TextLayerStyle presetStyle) {
    updateLayerTextStyle(layerId, presetStyle);
  }

  Future<void> resetEditorOnExit() async {
    // Cancel all timers to prevent saving after exit
    _saveTimer?.cancel();
    _autoSaveTimer?.cancel();
    // Force save immediately before exiting
    await _save();

    state = state.copyWith(
      isPlaying: false,
      isFullScreen: false,
      isTimelineExpanded: false,
      activeToolbarCategory: null,
      selectedLayerId: null,
      clearSelected: true,
    );
  }

  void toggleTimelineExpansion() {
    state = state.copyWith(isTimelineExpanded: !state.isTimelineExpanded);
  }

  void toggleFullScreen() {
    state = state.copyWith(isFullScreen: !state.isFullScreen);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS (old compat)
  // ─────────────────────────────────────────────────────────────────────────

  void setSurah(int surahId) {
    if (state.currentProject != null) {
      _mutate((p) => p.copyWith(surahId: surahId));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MULTI-CAM
  // ─────────────────────────────────────────────────────────────────────────

  /// Create a multi-cam group from a list of video layer IDs.
  void createMultiCamGroup(List<String> layerIds, String name) {
    final project = state.currentProject;
    if (project == null || layerIds.length < 2) return;

    // Validate that all layer IDs exist and are video layers
    for (final id in layerIds) {
      final layer = project.layers.where((l) => l.id == id).firstOrNull;
      if (layer == null || layer.type != 'video') return;
    }

    final angles = layerIds.asMap().entries.map((entry) {
      return MultiCamAngle(
        layerId: entry.value,
        label: 'Cam ${entry.key + 1}',
        syncOffset: 0.0,
      );
    }).toList();

    final group = MultiCamGroup(
      id: 'mcg_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      angles: angles,
    );

    _mutate((p) => p.copyWith(
      multiCamGroups: [...p.multiCamGroups, group],
    ));
  }

  /// Switch the active angle in a multi-cam group.
  void switchMultiCamAngle(String groupId, int angleIndex) {
    final project = state.currentProject;
    if (project == null) return;

    final groupIndex = project.multiCamGroups.indexWhere((g) => g.id == groupId);
    if (groupIndex < 0) return;

    final group = project.multiCamGroups[groupIndex];
    if (angleIndex < 0 || angleIndex >= group.angles.length) return;

    final updatedGroup = group.copyWith(activeAngleIndex: angleIndex);
    final updatedGroups = List<MultiCamGroup>.from(project.multiCamGroups);
    updatedGroups[groupIndex] = updatedGroup;

    _mutate((p) => p.copyWith(multiCamGroups: updatedGroups));
  }

  /// Remove a multi-cam group but keep the layers intact.
  void removeMultiCamGroup(String groupId) {
    final project = state.currentProject;
    if (project == null) return;

    _mutate((p) => p.copyWith(
      multiCamGroups: p.multiCamGroups.where((g) => g.id != groupId).toList(),
    ));
  }

  /// Update the sync offset for a specific angle in a group.
  void updateMultiCamSyncOffset(String groupId, int angleIndex, double offset) {
    final project = state.currentProject;
    if (project == null) return;

    final groupIndex = project.multiCamGroups.indexWhere((g) => g.id == groupId);
    if (groupIndex < 0) return;

    final group = project.multiCamGroups[groupIndex];
    if (angleIndex < 0 || angleIndex >= group.angles.length) return;

    final updatedAngle = group.angles[angleIndex].copyWith(syncOffset: offset);
    final updatedAngles = List<MultiCamAngle>.from(group.angles);
    updatedAngles[angleIndex] = updatedAngle;

    final updatedGroup = group.copyWith(angles: updatedAngles);
    final updatedGroups = List<MultiCamGroup>.from(project.multiCamGroups);
    updatedGroups[groupIndex] = updatedGroup;

    _mutate((p) => p.copyWith(multiCamGroups: updatedGroups));
  }

  /// Check if a layer belongs to any multi-cam group.
  /// Returns the group if found, null otherwise.
  MultiCamGroup? getMultiCamGroupForLayer(String layerId) {
    final project = state.currentProject;
    if (project == null) return null;

    for (final group in project.multiCamGroups) {
      if (group.angles.any((a) => a.layerId == layerId)) {
        return group;
      }
    }
    return null;
  }

  /// Get the sync offset for a layer that belongs to a multi-cam group.
  double getLayerSyncOffset(String layerId) {
    final group = getMultiCamGroupForLayer(layerId);
    if (group == null) return 0.0;

    final angleIndex = group.angles.indexWhere((a) => a.layerId == layerId);
    if (angleIndex < 0) return 0.0;

    return group.angles[angleIndex].syncOffset;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // INTERNAL
  // ─────────────────────────────────────────────────────────────────────────

  void _mutate(Project Function(Project) updater) {
    final current = state.currentProject;
    if (current == null) return;

    final updated = updater(current);
    const maxUndo = 30;
    final newUndo = [...state.undoStack, current];

    state = state.copyWith(
      currentProject: updated,
      undoStack: newUndo.length > maxUndo ? newUndo.sublist(1) : newUndo,
      redoStack: [],
    );
    _scheduleSave();
  }

  Layer? _findLayer(String id) {
    final project = state.currentProject;
    if (project == null) return null;
    try {
      return project.layers.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    // Auto-save after 1 second of inactivity
    _saveTimer = Timer(const Duration(seconds: 1), _save);
  }

  Future<void> _save() async {
    final project = state.currentProject;
    if (project == null) return;
    state = state.copyWith(isSaving: true);
    try {
      final data = project.toMap();
      // Remove fields that don't exist in the Supabase schema
      data.remove('multi_cam_groups');
      data.remove('canvas_background_id');
      data.remove('ducking_enabled');
      data.remove('reframe_mode');
      await _supabase
          .from('projects')
          .update(data)
          .eq('id', project.id);
    } catch (e) {
      // Log error but don't crash — auto-save should be resilient
      debugPrint('[AutoSave] Failed to save project: $e');
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  Future<void> updateProject(Project project) async {
    _mutate((_) => project);
  }
}

final editorProvider = NotifierProvider<EditorNotifier, EditorState>(() {
  return EditorNotifier();
});
