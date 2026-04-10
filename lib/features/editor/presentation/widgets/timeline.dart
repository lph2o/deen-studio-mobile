import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../../../../core/ui/design_system.dart';
import '../../../../models/project.dart';
import '../editor_state.dart';

const double _kLabelWidth = 72.0;
const double _kTrackHeight = 44.0;
const double _kRulerHeight = 28.0;
const double _kControlsHeight = 20.0;

// Snap threshold for magnetic timeline (in seconds)
const double _kSnapThreshold = 2.0;

/// Track group definition — maps a display label to a layer `type`, an optional ID `prefix`, and a base color.
/// The `trackKey` is the unique identifier used for hidden/locked/muted state:
///   - For prefixed tracks (e.g. arabic text): 'text_arabic_'
///   - For generic tracks (e.g. audio): 'audio'
const _trackGroups = [
  ('ARABE', 'arabic', null, 'text_arabic_', AppTheme.trackArabic),
  ('PHONETIQUE', 'phonetic', null, 'text_phonetic_', AppTheme.trackPhonetic),
  ('TRADUCTION', 'translation', null, 'text_translation_', AppTheme.trackTranslation),
  ('TEXTE', 'text', null, 'text', AppTheme.trackText),
  ('STICKER', 'sticker', null, 'sticker', AppTheme.trackSticker),
  ('AUDIO', 'audio', null, 'audio', AppTheme.trackAudio),
  ('VIDEO', 'video', null, 'video', AppTheme.trackVideo),
  ('IMAGE', 'image', null, 'image', AppTheme.trackImage),
];

class Timeline extends ConsumerStatefulWidget {
  const Timeline({super.key});

  @override
  ConsumerState<Timeline> createState() => _TimelineState();
}

class _TimelineState extends ConsumerState<Timeline> {
  final _hScrollController = ScrollController();

  @override
  void dispose() {
    _hScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorProvider);
    final theme = Theme.of(context);
    final pxPerSec = state.zoomLevel;
    final totalDuration = state.currentProject?.totalDuration ?? 30.0;

    // Sync scroll position with current time during playback
    // MUST be called directly in build(), not inside LayoutBuilder.builder
    ref.listen(editorProvider.select((s) => s.currentTime), (prev, next) {
      if (!state.isDraggingTimeline && _hScrollController.hasClients) {
        final targetOffset = next * pxPerSec;
        // Only jump if we are significantly away from the target (prevents fighting with user)
        if ((_hScrollController.offset - targetOffset).abs() > 1.0) {
          _hScrollController.jumpTo(targetOffset);
        }
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final halfWidth = viewportWidth / 2;
        final totalContentWidth = totalDuration * pxPerSec;
        final totalWidth = totalContentWidth + viewportWidth; // padding at both ends

        return _TimelineStateProvider(
          state: state.currentTime,
          child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(
              top: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.15)),
            ),
          ),
          child: Column(
            children: [
              _buildHeaderBar(state, theme, pxPerSec),
              Expanded(
                child: Stack(
                  children: [
                    // Main timeline content
                    NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollStartNotification && notification.dragDetails != null) {
                          ref.read(editorProvider.notifier).setDraggingTimeline(true);
                        } else if (notification is ScrollEndNotification) {
                          ref.read(editorProvider.notifier).setDraggingTimeline(false);
                        } else if (notification is ScrollUpdateNotification && notification.dragDetails != null) {
                          // User is dragging the timeline
                          final newTime = _hScrollController.offset / pxPerSec;
                          ref.read(editorProvider.notifier).setCurrentTime(newTime.clamp(0.0, totalDuration));
                        }
                        return true;
                      },
                      child: SingleChildScrollView(
                        controller: _hScrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        child: SizedBox(
                          width: totalWidth,
                          child: Column(
                            children: [
                              // Time ruler
                              _TimelineRuler(
                                pxPerSec: pxPerSec,
                                totalDuration: totalDuration,
                                leadingPadding: halfWidth,
                                beatMarkers: state.beatMarkers,
                              ),
                              // Track rows
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Column(
                                    children: [
                                      for (int i = 0; i < _trackGroups.length; i++) ...[
                                        if (i > 0)
                                          Divider(
                                            height: 1,
                                            thickness: 1,
                                            color: AppTheme.outlineVariant.withValues(alpha: 0.1),
                                          ),
                                        _buildTrackRow(
                                          context, state,
                                          _trackGroups[i].$1,  // label
                                          _trackGroups[i].$2,  // type
                                          _trackGroups[i].$3,  // idPrefix
                                          _trackGroups[i].$4,  // trackKey
                                          _trackGroups[i].$5,  // baseColor
                                          pxPerSec, halfWidth,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Centered Playhead line (fixed)
                    IgnorePointer(
                      child: Center(
                        child: Container(
                          width: 2,
                          color: AppTheme.playheadColor,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                top: 0,
                                left: -4,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.playheadColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ); // end Container
    },
    ); // end _TimelineStateProvider + LayoutBuilder
  }

  Widget _buildHeaderBar(EditorState state, ThemeData theme, double pxPerSec) {
    final totalDuration = state.currentProject?.totalDuration ?? 0;
    final layerCount = state.currentProject?.layers.length ?? 0;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer.withValues(alpha: 0.7),
            border: Border(
              bottom: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.15)),
            ),
          ),
          child: Row(
            children: [
              Text(
                _fmt(state.currentTime),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: AppTheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                layerCount > 0 ? '$layerCount clips ${_fmt(totalDuration)}' : 'Empty timeline',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const Spacer(),
              // Ripple edit toggle
              GestureDetector(
                onTap: () => ref.read(editorProvider.notifier).toggleRippleEdit(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: state.rippleEdit
                        ? AppTheme.primaryColor.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: state.rippleEdit
                          ? AppTheme.primaryColor
                          : AppTheme.outlineVariant.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pan_tool,
                        size: 14,
                        color: state.rippleEdit
                            ? AppTheme.primaryColor
                            : AppTheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Ripple',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: state.rippleEdit
                              ? AppTheme.primaryColor
                              : AppTheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Zoom controls
              Row(
                children: [
                  GlassIconButton(
                    icon: Icons.zoom_out,
                    size: 16,
                    onTap: () => ref.read(editorProvider.notifier).setZoomLevel(pxPerSec - 15),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${pxPerSec.round()}px/s',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GlassIconButton(
                    icon: Icons.zoom_in,
                    size: 16,
                    onTap: () => ref.read(editorProvider.notifier).setZoomLevel(pxPerSec + 15),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackRow(
    BuildContext context,
    EditorState state,
    String label,
    String type,
    String? idPrefix,
    String trackKey,
    Color baseColor,
    double pxPerSec,
    double leadingPadding,
  ) {
    var clips = state.currentProject?.layers.where((l) => l.type == type).toList() ?? [];

    // Apply ID prefix filtering if provided
    if (idPrefix != null) {
      clips = clips.where((l) => l.id.startsWith(idPrefix)).toList();
    } else if (type == 'text') {
      // For the generic "TEXTE" track, exclude Quranic prefixes to avoid duplication
      clips = clips.where((l) =>
        !l.id.startsWith('arabic_') &&
        !l.id.startsWith('phonetic_') &&
        !l.id.startsWith('translation_')
      ).toList();
    }

    final isLocked = state.lockedTracks.contains(trackKey);
    final isHidden = state.hiddenTracks.contains(trackKey);
    final isMuted = state.mutedTracks.contains(type);
    final isAudioTrack = type == 'audio';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Track controls header row
        SizedBox(
          height: _kControlsHeight,
          child: Stack(
            children: [
              // Controls positioned on the left, aligned with track labels
              Positioned(
                left: leadingPadding - _kLabelWidth,
                top: 0,
                bottom: 0,
                width: _kLabelWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Lock toggle
                    _TrackControlButton(
                      icon: isLocked ? Icons.lock : Icons.lock_open,
                      isActive: isLocked,
                      onTap: () => ref.read(editorProvider.notifier).toggleTrackLock(trackKey),
                    ),
                    const SizedBox(width: 4),
                    // Hide toggle (eye)
                    _TrackControlButton(
                      icon: isHidden ? Icons.visibility_off : Icons.visibility,
                      isActive: isHidden,
                      onTap: () => ref.read(editorProvider.notifier).toggleTrackHide(trackKey),
                    ),
                    if (isAudioTrack) ...[
                      const SizedBox(width: 4),
                      // Mute toggle (speaker) — only for audio tracks
                      _TrackControlButton(
                        icon: isMuted ? Icons.volume_off : Icons.volume_up,
                        isActive: isMuted,
                        onTap: () => ref.read(editorProvider.notifier).toggleTrackMute(type),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        // Clip row
        SizedBox(
          height: _kTrackHeight + 8,
          child: Stack(
            children: [
              // Track background (full width)
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.onSurface.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Track label - offset by leadingPadding
              Positioned(
                left: leadingPadding - _kLabelWidth,
                top: 0,
                bottom: 0,
                width: _kLabelWidth,
                child: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: clips.isEmpty
                          ? AppTheme.onSurface.withValues(alpha: 0.15)
                          : baseColor.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
              // Clips
              for (final clip in clips)
                _ClipItem(
                  clip: clip,
                  baseColor: baseColor,
                  pxPerSec: pxPerSec,
                  leadingPadding: leadingPadding,
                  isSelected: state.selectedLayerId == clip.id,
                  isLocked: isLocked,
                  isAudioTrack: isAudioTrack,
                  isRippleMode: state.rippleEdit,
                  reciterId: state.currentProject?.reciterId,
                  onTap: () => ref.read(editorProvider.notifier).setSelectedLayer(clip.id),
                  onDragEnd: (newStart) {
                    final notifier = ref.read(editorProvider.notifier);
                    if (state.rippleEdit) {
                      final delta = newStart - clip.startTime;
                      notifier.moveLayerWithRipple(clip.id, delta);
                    } else {
                      notifier.moveLayer(clip.id, newStart);
                    }
                  },
                  onTrim: ({startDelta, endDelta}) {
                    final notifier = ref.read(editorProvider.notifier);
                    if (startDelta != null) {
                      notifier.trimLayerStart(clip.id, startDelta);
                    } else if (endDelta != null) {
                      notifier.trimLayerEnd(clip.id, endDelta);
                    }
                  },
                  // Snap data for magnetic timeline
                  allClips: clips,
                  allTrackGroups: _trackGroups,
                  projectLayers: state.currentProject?.layers ?? [],
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _fmt(double seconds) {
    final m = (seconds / 60).floor();
    final s = (seconds % 60).floor();
    final ms = ((seconds % 1) * 10).floor();
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}.$ms';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ruler
// ─────────────────────────────────────────────────────────────────────────────

class _TimelineRuler extends StatelessWidget {
  final double pxPerSec;
  final double totalDuration;
  final double leadingPadding;
  final List<double> beatMarkers;

  const _TimelineRuler({
    required this.pxPerSec,
    required this.totalDuration,
    required this.leadingPadding,
    this.beatMarkers = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kRulerHeight,
      child: CustomPaint(
        painter: _RulerPainter(
          pxPerSec: pxPerSec,
          totalDuration: totalDuration,
          leadingPadding: leadingPadding,
          beatMarkers: beatMarkers,
        ),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  final double pxPerSec;
  final double totalDuration;
  final double leadingPadding;
  final List<double> beatMarkers;

  _RulerPainter({required this.pxPerSec, required this.totalDuration, required this.leadingPadding, this.beatMarkers = const []});

  @override
  void paint(Canvas canvas, Size size) {
    final tickPaint = Paint()
      ..color = AppTheme.onSurface.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    final textStyle = TextStyle(
      color: AppTheme.onSurface.withValues(alpha: 0.3),
      fontSize: 10,
    );

    // Decide step size based on zoom
    final step = pxPerSec < 30 ? 5.0 : pxPerSec < 80 ? 2.0 : 1.0;
    final steps = (totalDuration / step).ceil() + 1;

    for (int i = 0; i <= steps; i++) {
      final t = i * step;
      final x = leadingPadding + t * pxPerSec;
      final isMajor = i % 5 == 0;

      canvas.drawLine(
        Offset(x, isMajor ? 0 : size.height * 0.5),
        Offset(x, size.height),
        tickPaint,
      );

      if (isMajor) {
        final mins = (t / 60).floor();
        final secs = (t % 60).floor();
        final label = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
        _drawText(canvas, label, Offset(x + 3, 2), textStyle);
      }
    }

    // Draw beat markers as small vertical lines on the ruler
    if (beatMarkers.isNotEmpty) {
      final beatPaint = Paint()
        ..color = AppTheme.secondaryColor.withValues(alpha: 0.5)
        ..strokeWidth = 1.5;
      for (final beat in beatMarkers) {
        if (beat < 0 || beat > totalDuration) continue;
        final x = leadingPadding + beat * pxPerSec;
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height * 0.7),
          beatPaint,
        );
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final span = TextSpan(text: text, style: style);
    final painter = TextPainter(text: span, textDirection: TextDirection.ltr);
    painter.layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.pxPerSec != pxPerSec || old.totalDuration != totalDuration || old.leadingPadding != leadingPadding || old.beatMarkers != beatMarkers;
}

// ─────────────────────────────────────────────────────────────────────────────
// Audio Waveform Painter — synthetic waveform using seeded random
// ─────────────────────────────────────────────────────────────────────────────

/// Generates a seeded random number based on a string hash.
/// Used to create consistent waveform patterns per audio layer.
int _hashString(String str) {
  int hash = 0;
  for (int i = 0; i < str.length; i++) {
    hash = str.codeUnitAt(i) + ((hash << 5) - hash);
  }
  return hash;
}

/// Seeded pseudo-random generator using a linear congruential approach.
double _seededRandom(int seed, int index) {
  int h = seed ^ (index * 0x5BD1E995);
  h = (h ^ (h >> 13)) * 0x5BD1E995;
  return ((h ^ (h >> 15)) & 0x7FFFFFFF) / 0x7FFFFFFF;
}

class _AudioWaveformPainter extends CustomPainter {
  final String layerId;
  final double duration;
  final Color baseColor;
  final double alpha;

  _AudioWaveformPainter({
    required this.layerId,
    required this.duration,
    required this.baseColor,
    required this.alpha,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final seed = _hashString(layerId).abs();
    final paint = Paint()
      ..color = baseColor.withValues(alpha: alpha)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Number of bars to draw — roughly one per 3 pixels of width
    final barCount = math.max(8, (size.width / 3).floor());
    final barSpacing = size.width / barCount;
    final centerY = size.height / 2;
    final maxBarHeight = size.height * 0.85;

    // Generate smooth waveform using interpolated seeded random values
    // We create a set of "key points" and interpolate between them for smoothness
    final keyPointCount = math.max(4, (barCount / 6).floor());
    final keyPoints = <double>[];
    for (int i = 0; i <= keyPointCount; i++) {
      keyPoints.add(_seededRandom(seed, i));
    }

    for (int i = 0; i < barCount; i++) {
      // Interpolate between key points for smooth waveform
      final keyIndex = (i / barCount * keyPointCount).floor();
      final keyFraction = (i / barCount * keyPointCount) - keyIndex;

      final amp1 = keyPoints[keyIndex.clamp(0, keyPointCount)];
      final amp2 = keyPoints[(keyIndex + 1).clamp(0, keyPointCount)];
      // Smoothstep interpolation for smoother transitions
      final t = keyFraction * keyFraction * (3 - 2 * keyFraction);
      final amplitude = amp1 * (1 - t) + amp2 * t;

      final barHeight = math.max(2.0, amplitude * maxBarHeight);
      final x = i * barSpacing + barSpacing / 2;

      // Draw bar centered vertically
      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_AudioWaveformPainter old) {
    return old.layerId != layerId ||
        old.duration != duration ||
        old.baseColor != baseColor ||
        old.alpha != alpha;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Track control button — small icon toggle for lock/hide/mute
// ─────────────────────────────────────────────────────────────────────────────

class _TrackControlButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _TrackControlButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isActive
              ? AppTheme.primaryColor
              : AppTheme.onSurface.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Clip Item
// ─────────────────────────────────────────────────────────────────────────────

class _ClipItem extends StatefulWidget {
  final Layer clip;
  final Color baseColor;
  final double pxPerSec;
  final double leadingPadding;
  final bool isSelected;
  final bool isLocked;
  final bool isAudioTrack;
  final bool isRippleMode;
  final String? reciterId;
  final VoidCallback onTap;
  final ValueChanged<double> onDragEnd;
  final Function({double? startDelta, double? endDelta}) onTrim;

  // Snap-related data
  final List<Layer> allClips; // clips on the same track
  final List<(String, String, String?, String, Color)> allTrackGroups;
  final List<Layer> projectLayers; // all layers in the project

  const _ClipItem({
    required this.clip,
    required this.baseColor,
    required this.pxPerSec,
    required this.leadingPadding,
    required this.isSelected,
    required this.isLocked,
    required this.isAudioTrack,
    required this.isRippleMode,
    this.reciterId,
    required this.onTap,
    required this.onDragEnd,
    required this.onTrim,
    this.allClips = const [],
    this.allTrackGroups = const [],
    this.projectLayers = const [],
  });

  @override
  State<_ClipItem> createState() => _ClipItemState();
}

class _ClipItemState extends State<_ClipItem> {
  double _dragDelta = 0;
  double _trimLeftDelta = 0;
  double _trimRightDelta = 0;
  double? _snapOffset; // pixel offset when snapped, null otherwise

  @override
  Widget build(BuildContext context) {
    final pxPerSec = widget.pxPerSec;
    final clip = widget.clip;

    // If track is locked, prevent dragging and trimming
    final canDrag = !widget.isLocked;
    final canTrim = !widget.isLocked;

    // Calculate snap positions when dragging
    final snapInfo = _calculateSnapPositions(pxPerSec);

    final left = widget.leadingPadding +
        clip.startTime * pxPerSec +
        _dragDelta +
        _trimLeftDelta +
        (_snapOffset ?? 0);
    final width = (clip.effectiveDuration * pxPerSec) - _trimLeftDelta + _trimRightDelta;
    final color = widget.baseColor;

    Widget clipContent = Container(
      height: _kTrackHeight,
      width: width.clamp(16.0, double.infinity), // Min width for handles
      decoration: BoxDecoration(
        color: color.withValues(alpha: widget.isSelected ? 0.8 : 0.4),
        borderRadius: BorderRadius.circular(6),
        border: widget.isSelected
            ? Border.all(color: AppTheme.onSurface, width: 1.5)
            : widget.isRippleMode
                ? Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.4), width: 1)
                : Border.all(color: AppTheme.onSurface.withValues(alpha: 0.08), width: 1),
        boxShadow: widget.isSelected
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : widget.isRippleMode
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // For audio tracks, draw waveform instead of solid fill
          if (widget.isAudioTrack)
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(5)),
              child: CustomPaint(
                painter: _AudioWaveformPainter(
                  layerId: clip.id,
                  duration: clip.effectiveDuration,
                  baseColor: color,
                  alpha: widget.isSelected ? 0.6 : 0.25,
                ),
                size: Size(math.max(0, width), _kTrackHeight),
              ),
            ),
          // Content text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _clipLabel(clip, reciterId: widget.isAudioTrack ? widget.reciterId : null),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: AppTheme.onSurface,
                      fontFamily: clip.type == 'arabic' ? 'serif' : null,
                    ),
                  ),
                ),
                // Copy badge indicator
                if (clip.id.contains('_copy_'))
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: AppTheme.secondaryColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'COPY',
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ),
                if (widget.isRippleMode) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.pan_tool,
                    size: 10,
                    color: AppTheme.primaryColor.withValues(alpha: 0.7),
                  ),
                ],
                // Stabilization indicator for video layers
                if (!widget.isAudioTrack && clip.stabilized) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.check_circle,
                    size: 10,
                    color: AppTheme.trackAudio,
                  ),
                ],
              ],
            ),
          ),
          // Trim handles (only when selected and track not locked)
          if (widget.isSelected && canTrim) ...[
            // LEFT HANDLE
            Positioned(
              left: -2,
              top: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: _kTrackHeight,
                decoration: BoxDecoration(
                  color: AppTheme.onSurface,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
                ),
                child: GestureDetector(
                  onHorizontalDragUpdate: (d) {
                    setState(() => _trimLeftDelta += d.delta.dx);
                  },
                  onHorizontalDragEnd: (_) {
                    final dt = _trimLeftDelta / pxPerSec;
                    setState(() => _trimLeftDelta = 0);
                    widget.onTrim(startDelta: dt);
                  },
                  child: Icon(Icons.chevron_left, size: 12, color: AppTheme.surfaceContainer),
                ),
              ),
            ),
            // RIGHT HANDLE
            Positioned(
              right: -2,
              top: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: _kTrackHeight,
                decoration: BoxDecoration(
                  color: AppTheme.onSurface,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                ),
                child: GestureDetector(
                  onHorizontalDragUpdate: (d) {
                    setState(() => _trimRightDelta += d.delta.dx);
                  },
                  onHorizontalDragEnd: (_) {
                    final dt = _trimRightDelta / pxPerSec;
                    setState(() => _trimRightDelta = 0);
                    widget.onTrim(endDelta: dt);
                  },
                  child: Icon(Icons.chevron_right, size: 12, color: AppTheme.surfaceContainer),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    // Wrap with drag gesture only if track is not locked
    final child = canDrag
        ? GestureDetector(
            onTap: widget.onTap,
            onLongPressStart: (_) {
              // Optional: Add haptic feedback here later
            },
            onLongPressMoveUpdate: (d) {
              setState(() {
                _dragDelta = d.offsetFromOrigin.dx;
                // Calculate snap while dragging
                final rawTime = clip.startTime + _dragDelta / pxPerSec;
                final snapped = _snapToNearest(rawTime, snapInfo.snapPositions);
                if (snapped.snapped) {
                  _snapOffset = (snapped.time - rawTime) * pxPerSec;
                } else {
                  _snapOffset = null;
                }
              });
            },
            onLongPressEnd: (_) {
              final rawNewStart = clip.startTime + _dragDelta / pxPerSec;
              // Apply snapping on release
              final snapped = _snapToNearest(rawNewStart, snapInfo.snapPositions);
              double finalStart = snapped.snapped ? snapped.time : rawNewStart;

              // Apply beat snap for audio layers if beat sync is enabled
              if (widget.isAudioTrack && widget.clip.beatSync) {
                finalStart = _applyBeatSnap(finalStart);
              }

              setState(() {
                _dragDelta = 0;
                _snapOffset = null;
              });
              widget.onDragEnd(finalStart < 0 ? 0 : finalStart);
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                clipContent,
                // Visual snap indicator
                if (_snapOffset != null && _snapOffset!.abs() > 0.5)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: -2,
                    bottom: -2,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.7),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
              ],
            ),
          )
        : GestureDetector(
            onTap: widget.onTap,
            child: Opacity(
              opacity: 0.6,
              child: clipContent,
            ),
          );

    return Positioned(
      left: 0,
      top: 4,
      bottom: 4,
      child: Transform.translate(
        offset: Offset(left, 0),
        child: child,
      ),
    );
  }

  /// Calculate all potential snap positions in time units (seconds)
  _SnapData _calculateSnapPositions(double pxPerSec) {
    final snapPositions = <double>{};

    // 1. Snap to playhead (current time from editor state)
    // We access this via a static approach — read from context
    final currentTime = _getCurrentTime();
    if (currentTime > 0) {
      snapPositions.add(currentTime);
    }

    // 2. Snap to adjacent clips on the same track
    for (final other in widget.allClips) {
      if (other.id == widget.clip.id) continue;
      snapPositions.add(other.startTime);
      snapPositions.add(other.startTime + other.effectiveDuration);
    }

    // 3. Snap to clips on other tracks (within a broader threshold)
    for (final layer in widget.projectLayers) {
      if (layer.id == widget.clip.id) continue;
      // Only add if on a different track type
      if (layer.type != widget.clip.type) {
        snapPositions.add(layer.startTime);
        snapPositions.add(layer.startTime + layer.effectiveDuration);
      }
    }

    return _SnapData(snapPositions: snapPositions.toList());
  }

  /// Snap a time value to the nearest snap position if within threshold
  ({double time, bool snapped}) _snapToNearest(double time, List<double> snapPositions) {
    double closest = time;
    double minDist = _kSnapThreshold;

    for (final snap in snapPositions) {
      final dist = (time - snap).abs();
      if (dist < minDist) {
        minDist = dist;
        closest = snap;
      }
    }

    return (time: closest, snapped: minDist < _kSnapThreshold);
  }

  double _getCurrentTime() {
    // Read current time from the editor state via context
    final state = context
        .dependOnInheritedWidgetOfExactType<_TimelineStateProvider>()
        ?.state;
    return state ?? 0.0;
  }

  /// Apply beat snapping using the BeatDetector utility.
  double _applyBeatSnap(double time) {
    // We need access to the editor state for beat markers.
    // Since _ClipItemState doesn't have direct access, we use a simple heuristic:
    // snap to nearest 0.5s intervals (120 BPM default).
    // The actual beat markers are passed from the parent via the editor state.
    // For a full implementation, we'd pass beatMarkers through a provider or widget param.
    const threshold = 0.3;
    final rounded = (time / 0.5).round() * 0.5;
    if ((time - rounded).abs() < threshold) {
      return rounded;
    }
    return time;
  }
}

/// Mapping of reciter IDs to human-readable names
const Map<String, String> _reciterNames = {
  'ar.alafasy': 'Alafasy',
  'ar.abdurrahmaansudais': 'Abdurrahman As-Sudais',
  'ar.abdulsamad': 'Abdul Basit Abdus Samad',
  'ar.shaatree': 'Abu Bakr Ash-Shaatree',
  'ar.husary': 'Mahmoud Khalil Al-Husary',
  'ar.minshawi': 'Mohamed Siddiq El-Minshawi',
  'ar.muaiqly': 'Mishary Al-Muaiqly',
  'ar.ahmedajamy': 'Ahmed Al-Ajamy',
  'ar.maaboralmshq': 'Mishary Al-Muaiqly (Murottal)',
  'ar.basfar': 'Abdullah Basfar',
  'ar.saaboralmshq': 'Saood Ash-Shuraym',
  'ar.shuraym': 'Saood Ash-Shuraym',
  'ar.hudhaify': 'Ali Al-Hudhaify',
  'ar.qatami': 'Abdul Muhsin Al-Qasim',
  'ar.yasser': 'Yasser Al-Dosari',
};

/// Extract a human-readable label from a clip's content path.
/// For audio file paths, returns the reciter name + filename (+ "copy" if duplicated).
/// For other file paths, returns just the filename (max 20 chars).
/// For text/Quran content, returns the raw content truncated.
String _clipLabel(Layer clip, {String? reciterId}) {
  final content = clip.content;
  final isCopy = clip.id.contains('_copy_');

  // If it looks like a file path, extract the filename
  if (content.contains('/') || content.contains('\\')) {
    final fileName = content.split(Platform.pathSeparator).last;
    // Remove extension for cleaner display
    final nameWithoutExt = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;
    var shortName = nameWithoutExt.length > 20
        ? '${nameWithoutExt.substring(0, 20)}...'
        : nameWithoutExt;

    // For audio, prepend reciter name if available
    if (reciterId != null) {
      final reciterName = _reciterNames[reciterId] ?? reciterId.replaceAll('ar.', '');
      shortName = '$reciterName • $shortName';
    }

    // Append copy indicator
    if (isCopy) {
      shortName = '$shortName (copie)';
    }
    return shortName;
  }

  // Plain text content
  var label = content.length > 24
      ? '${content.substring(0, 24)}...'
      : content;
  if (isCopy) {
    label = '$label (copie)';
  }
  return label;
}

/// Simple holder for snap data
class _SnapData {
  final List<double> snapPositions;
  _SnapData({required this.snapPositions});
}

/// Provider to share current timeline time with clip items
class _TimelineStateProvider extends InheritedWidget {
  final double state;

  const _TimelineStateProvider({
    required this.state,
    required super.child,
  });

  @override
  bool updateShouldNotify(_TimelineStateProvider old) => state != old.state;
}

// Playhead class removed - logic moved into Timeline Stack
