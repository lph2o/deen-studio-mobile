import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../models/project.dart';
import '../editor_state.dart';

/// Opens the color grading panel as a modal bottom sheet.
void showColorGradingPanel(BuildContext context, String layerId, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.5, 0.75, 0.95],
      builder: (context, scrollController) {
        return _ColorGradingSheet(layerId: layerId, ref: ref);
      },
    ),
  );
}

class _ColorGradingSheet extends StatefulWidget {
  final String layerId;
  final WidgetRef ref;

  const _ColorGradingSheet({required this.layerId, required this.ref});

  @override
  State<_ColorGradingSheet> createState() => _ColorGradingSheetState();
}

class _ColorGradingSheetState extends State<_ColorGradingSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layer = widget.ref.read(editorProvider).currentProject?.layers
        .where((l) => l.id == widget.layerId)
        .firstOrNull;
    if (layer == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 32, offset: const Offset(0, -8))],
      ),
      child: Column(
        children: [
          // Handle + header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.4)),
                      ),
                      child: const Text(
                        'COLOR',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF7C3AED), letterSpacing: 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Color Grading',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                    // Reset button
                    IconButton(
                      onPressed: () {
                        widget.ref.read(editorProvider.notifier).updateColorGrading(
                          widget.layerId, const ColorGrading(),
                        );
                        setState(() {});
                      },
                      icon: const Icon(LucideIcons.rotateCcw, size: 18, color: Colors.white38),
                      tooltip: 'Reset',
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(LucideIcons.x, size: 18, color: Colors.white38),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Courbes'),
              Tab(text: 'HSL'),
              Tab(text: 'Roues'),
            ],
            indicatorColor: const Color(0xFF7C3AED),
            labelColor: const Color(0xFF7C3AED),
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CurvesTab(layerId: widget.layerId, ref: widget.ref),
                _HSLTab(layerId: widget.layerId, ref: widget.ref),
                _WheelsTab(layerId: widget.layerId, ref: widget.ref),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CURVES TAB
// ─────────────────────────────────────────────────────────────────────────────

class _CurvesTab extends StatefulWidget {
  final String layerId;
  final WidgetRef ref;

  const _CurvesTab({required this.layerId, required this.ref});

  @override
  State<_CurvesTab> createState() => _CurvesTabState();
}

class _CurvesTabState extends State<_CurvesTab> {
  String _selectedChannel = 'master'; // master, red, green, blue
  final Map<String, List<Point2D>> _editingCurves = {};

  @override
  void initState() {
    super.initState();
    _loadCurves();
  }

  void _loadCurves() {
    final layer = widget.ref.read(editorProvider).currentProject?.layers
        .where((l) => l.id == widget.layerId)
        .firstOrNull;
    if (layer == null) return;
    final g = layer.colorGrading;
    _editingCurves['master'] = List<Point2D>.from(g.masterCurve);
    _editingCurves['red'] = List<Point2D>.from(g.redCurve);
    _editingCurves['green'] = List<Point2D>.from(g.greenCurve);
    _editingCurves['blue'] = List<Point2D>.from(g.blueCurve);
  }

  void _saveCurves() {
    final layer = widget.ref.read(editorProvider).currentProject?.layers
        .where((l) => l.id == widget.layerId)
        .firstOrNull;
    if (layer == null) return;
    final g = layer.colorGrading.copyWith(
      masterCurve: List<Point2D>.from(_editingCurves['master'] ?? const [Point2D(0, 0), Point2D(0.5, 0.5), Point2D(1, 1)]),
      redCurve: List<Point2D>.from(_editingCurves['red'] ?? const [Point2D(0, 0), Point2D(0.5, 0.5), Point2D(1, 1)]),
      greenCurve: List<Point2D>.from(_editingCurves['green'] ?? const [Point2D(0, 0), Point2D(0.5, 0.5), Point2D(1, 1)]),
      blueCurve: List<Point2D>.from(_editingCurves['blue'] ?? const [Point2D(0, 0), Point2D(0.5, 0.5), Point2D(1, 1)]),
    );
    widget.ref.read(editorProvider.notifier).updateColorGrading(widget.layerId, g);
  }

  List<Point2D> get _currentCurve => _editingCurves[_selectedChannel] ??
      [const Point2D(0, 0), const Point2D(0.5, 0.5), const Point2D(1, 1)];

  Color get _curveColor {
    switch (_selectedChannel) {
      case 'red': return Colors.red;
      case 'green': return Colors.green;
      case 'blue': return Colors.blue;
      default: return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Channel selector
          Row(
            children: [
              _channelButton('Master', 'master', Colors.white),
              const SizedBox(width: 8),
              _channelButton('R', 'red', Colors.red),
              const SizedBox(width: 8),
              _channelButton('G', 'green', Colors.green),
              const SizedBox(width: 8),
              _channelButton('B', 'blue', Colors.blue),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _editingCurves['master'] = [const Point2D(0, 0), const Point2D(0.5, 0.5), const Point2D(1, 1)];
                    _editingCurves['red'] = [const Point2D(0, 0), const Point2D(0.5, 0.5), const Point2D(1, 1)];
                    _editingCurves['green'] = [const Point2D(0, 0), const Point2D(0.5, 0.5), const Point2D(1, 1)];
                    _editingCurves['blue'] = [const Point2D(0, 0), const Point2D(0.5, 0.5), const Point2D(1, 1)];
                    _selectedChannel = 'master';
                  });
                  _saveCurves();
                },
                icon: const Icon(LucideIcons.rotateCcw, size: 14),
                label: const Text('Reset', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white54,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Curve editor canvas
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: CustomPaint(
                painter: _CurvePainter(
                  curve: _currentCurve,
                  channelColor: _curveColor,
                  gridSize: 8,
                ),
                child: _CurveGestureDetector(
                  curve: _currentCurve,
                  onPointMove: _onMovePoint,
                  onPointDelete: _onDeletePoint,
                  onPointAdd: _onAddPoint,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to add point. Drag to move. Double-tap point to delete.',
            style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );
  }

  Widget _channelButton(String label, String channel, Color color) {
    final isSelected = _selectedChannel == channel;
    return GestureDetector(
      onTap: () => setState(() => _selectedChannel = channel),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? color : Colors.white54,
          ),
        ),
      ),
    );
  }

  void _onAddPoint(double x, double y) {
    setState(() {
      final points = List<Point2D>.from(_currentCurve);
      points.add(Point2D(x, y));
      points.sort((a, b) => a.x.compareTo(b.x));
      _editingCurves[_selectedChannel] = points;
    });
    _saveCurves();
  }

  int _onMovePoint(int index, double x, double y) {
    int newIndex = index;
    setState(() {
      final points = List<Point2D>.from(_currentCurve);
      points[index] = Point2D(x, y);
      points.sort((a, b) => a.x.compareTo(b.x));
      // Re-find the index after sort
      final newIdx = points.indexWhere((p) => p.x == x && p.y == y);
      if (newIdx >= 0) {
        // Ensure first and last points stay at 0 and 1
        if (points.first.x != 0) points[0] = Point2D(0, points.first.y);
        if (points.last.x != 1) points[points.length - 1] = Point2D(1, points.last.y);
        
        newIndex = points.indexWhere((p) => p.x == x && p.y == y);
      }
      _editingCurves[_selectedChannel] = points;
    });
    _saveCurves();
    return newIndex >= 0 ? newIndex : index;
  }

  void _onDeletePoint(int index) {
    final points = List<Point2D>.from(_currentCurve);
    if (points.length <= 2) return; // Keep at least 2 points
    // Don't delete endpoints
    if (index == 0 || index == points.length - 1) return;
    setState(() {
      points.removeAt(index);
      _editingCurves[_selectedChannel] = points;
    });
    _saveCurves();
  }
}

/// Detects gestures on the curve canvas for point manipulation.
class _CurveGestureDetector extends StatefulWidget {
  final List<Point2D> curve;
  final int Function(int index, double x, double y) onPointMove;
  final Function(int index) onPointDelete;
  final Function(double x, double y) onPointAdd;

  const _CurveGestureDetector({
    required this.curve,
    required this.onPointMove,
    required this.onPointDelete,
    required this.onPointAdd,
  });

  @override
  State<_CurveGestureDetector> createState() => _CurveGestureDetectorState();
}

class _CurveGestureDetectorState extends State<_CurveGestureDetector> {
  int? _dragIndex;

  static const double _padding = 24.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) => _findNearestPoint(d.localPosition, size),
          onPanUpdate: (d) => _dragPoint(d.localPosition, size),
          onPanEnd: (_) => _dragIndex = null,
          onTapUp: (d) => _handleTap(d.localPosition, size),
          child: Stack(
            children: widget.curve.asMap().entries.map((entry) {
              final idx = entry.key;
              final pt = entry.value;
              final x = _padding + pt.x * (size.width - _padding * 2);
              final y = _padding + (1 - pt.y) * (size.height - _padding * 2);

              return Positioned(
                left: x - 8,
                top: y - 8,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onDoubleTap: () => widget.onPointDelete(idx),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black.withValues(alpha: 0.3), width: 1.5),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _findNearestPoint(Offset pos, Size size) {
    double minDist = 40.0; // max snap distance
    int? closest;
    for (int i = 0; i < widget.curve.length; i++) {
      final px = _padding + widget.curve[i].x * (size.width - _padding * 2);
      final py = _padding + (1 - widget.curve[i].y) * (size.height - _padding * 2);
      final dist = (Offset(px, py) - pos).distance;
      if (dist < minDist) {
        minDist = dist;
        closest = i;
      }
    }
    _dragIndex = closest;
  }

  void _dragPoint(Offset pos, Size size) {
    if (_dragIndex == null) return;
    final x = ((pos.dx - _padding) / (size.width - _padding * 2)).clamp(0.0, 1.0);
    final y = (1 - (pos.dy - _padding) / (size.height - _padding * 2)).clamp(0.0, 1.0);
    _dragIndex = widget.onPointMove(_dragIndex!, x, y);
  }

  void _handleTap(Offset pos, Size size) {
    // Only add point if not tapping near an existing point
    double minDist = 40.0;
    for (final pt in widget.curve) {
      final px = _padding + pt.x * (size.width - _padding * 2);
      final py = _padding + (1 - pt.y) * (size.height - _padding * 2);
      final dist = (Offset(px, py) - pos).distance;
      if (dist < minDist) return;
    }
    
    // Not near any point, add a new one
    final x = ((pos.dx - _padding) / (size.width - _padding * 2)).clamp(0.0, 1.0);
    final y = (1 - (pos.dy - _padding) / (size.height - _padding * 2)).clamp(0.0, 1.0);
    widget.onPointAdd(x, y);
  }
}

/// Paints the curve with a grid background.
class _CurvePainter extends CustomPainter {
  final List<Point2D> curve;
  final Color channelColor;
  final int gridSize;

  _CurvePainter({required this.curve, required this.channelColor, this.gridSize = 8});

  static const double _padding = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grid background
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= gridSize; i++) {
      final x = _padding + i / gridSize * (w - _padding * 2);
      final y = _padding + i / gridSize * (h - _padding * 2);
      canvas.drawLine(Offset(x, _padding), Offset(x, h - _padding), gridPaint);
      canvas.drawLine(Offset(_padding, y), Offset(w - _padding, y), gridPaint);
    }

    // Diagonal reference line
    final diagPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(_padding, h - _padding),
      Offset(w - _padding, _padding),
      diagPaint,
    );

    // Draw curve
    if (curve.length < 2) return;

    final sorted = List<Point2D>.from(curve)..sort((a, b) => a.x.compareTo(b.x));

    // Fill under curve
    final fillPaint = Paint()
      ..color = channelColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    final fillPath = Path();
    fillPath.moveTo(_padding + sorted.first.x * (w - _padding * 2), h - _padding);
    for (final pt in sorted) {
      fillPath.lineTo(
        _padding + pt.x * (w - _padding * 2),
        _padding + (1 - pt.y) * (h - _padding * 2),
      );
    }
    fillPath.lineTo(_padding + sorted.last.x * (w - _padding * 2), h - _padding);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Curve line
    final linePaint = Paint()
      ..color = channelColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(
      _padding + sorted.first.x * (w - _padding * 2),
      _padding + (1 - sorted.first.y) * (h - _padding * 2),
    );

    if (sorted.length == 2) {
      path.lineTo(
        _padding + sorted.last.x * (w - _padding * 2),
        _padding + (1 - sorted.last.y) * (h - _padding * 2),
      );
    } else {
      // Use catmull-rom spline for smooth curves
      for (int i = 0; i < sorted.length - 1; i++) {
        final p0 = sorted[math.max(0, i - 1)];
        final p1 = sorted[i];
        final p2 = sorted[i + 1];
        final p3 = sorted[math.min(sorted.length - 1, i + 2)];

        final x1 = _padding + p1.x * (w - _padding * 2);
        final y1 = _padding + (1 - p1.y) * (h - _padding * 2);
        final x2 = _padding + p2.x * (w - _padding * 2);
        final y2 = _padding + (1 - p2.y) * (h - _padding * 2);
        final cp1x = x1 + (x2 - _padding + p0.x * (w - _padding * 2)) / 6;
        final cp1y = y1 + (y2 - (_padding + (1 - p0.y) * (h - _padding * 2))) / 6;
        final cp2x = x2 - (_padding + p3.x * (w - _padding * 2) - x1) / 6;
        final cp2y = y2 - (_padding + (1 - p3.y) * (h - _padding * 2) - y1) / 6;

        if (i == 0) {
          path.moveTo(x1, y1);
        }
        path.cubicTo(cp1x, cp1y, cp2x, cp2y, x2, y2);
      }
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _CurvePainter oldDelegate) =>
      oldDelegate.curve != curve || oldDelegate.channelColor != channelColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// HSL TAB
// ─────────────────────────────────────────────────────────────────────────────

class _HSLTab extends StatelessWidget {
  final String layerId;
  final WidgetRef ref;

  const _HSLTab({required this.layerId, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final layer = ref.watch(editorProvider).currentProject?.layers
            .where((l) => l.id == layerId)
            .firstOrNull;
        if (layer == null) return const SizedBox.shrink();

        final grading = layer.colorGrading;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Live preview bar
              Container(
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: _buildHSLPreviewGradient(grading),
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
              const SizedBox(height: 20),

              // Hue slider
              _HSLSlider(
                label: 'Teinte (Hue)',
                value: grading.hue,
                min: -180,
                max: 180,
                unit: '',
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF0000), Color(0xFFFFFF00), Color(0xFF00FF00),
                    Color(0xFF00FFFF), Color(0xFF0000FF), Color(0xFFFF00FF),
                    Color(0xFFFF0000),
                  ],
                ),
                onChanged: (v) => ref.read(editorProvider.notifier).updateColorGrading(
                  layerId, grading.copyWith(hue: v),
                ),
              ),
              const SizedBox(height: 12),

              // Saturation slider
              _HSLSlider(
                label: 'Saturation',
                value: grading.saturation,
                min: -100,
                max: 100,
                unit: '%',
                gradient: LinearGradient(
                  colors: [Colors.grey, _getHueColor(grading.hue)],
                ),
                onChanged: (v) => ref.read(editorProvider.notifier).updateColorGrading(
                  layerId, grading.copyWith(saturation: v),
                ),
              ),
              const SizedBox(height: 12),

              // Lightness slider
              _HSLSlider(
                label: 'Lumiere (Lightness)',
                value: grading.lightness,
                min: -100,
                max: 100,
                unit: '%',
                gradient: LinearGradient(
                  colors: [Colors.black, _getHueColor(grading.hue), Colors.white],
                ),
                onChanged: (v) => ref.read(editorProvider.notifier).updateColorGrading(
                  layerId, grading.copyWith(lightness: v),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Color> _buildHSLPreviewGradient(ColorGrading grading) {
    final baseHue = grading.hue;
    final satBoost = grading.saturation / 100;
    return List.generate(
      20,
      (i) {
        final h = (baseHue + i * 18) % 360;
        final s = (0.5 + satBoost * 0.5).clamp(0.0, 1.0);
        final l = (0.5 + grading.lightness / 200).clamp(0.0, 1.0);
        return HSLColor.fromAHSL(1, h, s, l).toColor();
      },
    );
  }

  Color _getHueColor(double hue) {
    final h = (hue + 360) % 360;
    return HSLColor.fromAHSL(1, h, 0.8, 0.5).toColor();
  }
}

class _HSLSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final Gradient gradient;
  final ValueChanged<double> onChanged;

  const _HSLSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.gradient,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value.toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
            Text('$displayValue$unit', style: const TextStyle(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            trackShape: _TransparentTrackShape(),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            activeColor: Colors.white.withValues(alpha: 0.8),
            inactiveColor: Colors.transparent,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _TransparentTrackShape extends RoundedRectSliderTrackShape {
  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    bool isDiscrete = false,
    required TextDirection textDirection,
    Offset? secondaryOffset,
    bool isEnabled = true,
    double additionalActiveTrackHeight = 0,
  }) {
    // Don't paint the track background - we use a Container behind it
    // Just paint the active portion
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final trackRadius = Radius.circular(trackRect.height / 2);

    final activeWidth = thumbCenter.dx - offset.dx;

    context.canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(
          offset.dx,
          trackRect.top - additionalActiveTrackHeight / 2,
          textDirection == TextDirection.ltr ? activeWidth : parentBox.size.width - activeWidth,
          trackRect.height + additionalActiveTrackHeight,
        ),
        topLeft: trackRadius,
        bottomLeft: trackRadius,
        topRight: textDirection == TextDirection.ltr && activeWidth >= trackRect.width ? trackRadius : Radius.zero,
        bottomRight: textDirection == TextDirection.ltr && activeWidth >= trackRect.width ? trackRadius : Radius.zero,
      ),
      Paint()..color = sliderTheme.activeTrackColor ?? Colors.white,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WHEELS TAB (Color Wheels for Shadows, Midtones, Highlights)
// ─────────────────────────────────────────────────────────────────────────────

class _WheelsTab extends StatelessWidget {
  final String layerId;
  final WidgetRef ref;

  const _WheelsTab({required this.layerId, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final layer = ref.watch(editorProvider).currentProject?.layers
            .where((l) => l.id == layerId)
            .firstOrNull;
        if (layer == null) return const SizedBox.shrink();

        final grading = layer.colorGrading;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _ColorWheelRow(
                label: 'Shadows (Ombres)',
                tintHex: grading.shadowsTint,
                amount: grading.shadowsAmount,
                onTintChanged: (hex, amt) => ref.read(editorProvider.notifier).updateColorGrading(
                  layerId, grading.copyWith(shadowsTint: hex, shadowsAmount: amt),
                ),
                onAmountChanged: (amt) => ref.read(editorProvider.notifier).updateColorGrading(
                  layerId, grading.copyWith(shadowsAmount: amt),
                ),
              ),
              const SizedBox(height: 20),
              _ColorWheelRow(
                label: 'Midtones (Tons moyens)',
                tintHex: grading.midtonesTint,
                amount: grading.midtonesAmount,
                onTintChanged: (hex, amt) => ref.read(editorProvider.notifier).updateColorGrading(
                  layerId, grading.copyWith(midtonesTint: hex, midtonesAmount: amt),
                ),
                onAmountChanged: (amt) => ref.read(editorProvider.notifier).updateColorGrading(
                  layerId, grading.copyWith(midtonesAmount: amt),
                ),
              ),
              const SizedBox(height: 20),
              _ColorWheelRow(
                label: 'Highlights (Lumieres)',
                tintHex: grading.highlightsTint,
                amount: grading.highlightsAmount,
                onTintChanged: (hex, amt) => ref.read(editorProvider.notifier).updateColorGrading(
                  layerId, grading.copyWith(highlightsTint: hex, highlightsAmount: amt),
                ),
                onAmountChanged: (amt) => ref.read(editorProvider.notifier).updateColorGrading(
                  layerId, grading.copyWith(highlightsAmount: amt),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ColorWheelRow extends StatefulWidget {
  final String label;
  final String tintHex;
  final double amount;
  final Function(String hex, double amount) onTintChanged;
  final ValueChanged<double> onAmountChanged;

  const _ColorWheelRow({
    required this.label,
    required this.tintHex,
    required this.amount,
    required this.onTintChanged,
    required this.onAmountChanged,
  });

  @override
  State<_ColorWheelRow> createState() => _ColorWheelRowState();
}

class _ColorWheelRowState extends State<_ColorWheelRow> {
  @override
  Widget build(BuildContext context) {
    final wheelSize = 110.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            // Color wheel
            SizedBox(
              width: wheelSize,
              height: wheelSize,
              child: _ColorWheel(
                currentColor: widget.tintHex,
                onColorChanged: (hex) => widget.onTintChanged(hex, widget.amount),
              ),
            ),
            const SizedBox(width: 16),
            // Amount slider + color preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Color preview swatch
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _parseColor(widget.tintHex),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.tintHex,
                        style: const TextStyle(fontSize: 11, color: Colors.white38, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Amount: ${widget.amount.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 10, color: Colors.white38),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    ),
                    child: Slider(
                      value: widget.amount,
                      min: 0,
                      max: 100,
                      activeColor: const Color(0xFF7C3AED),
                      onChanged: widget.onAmountChanged,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF808080);
    }
  }
}

/// Interactive color wheel widget.
class _ColorWheel extends StatefulWidget {
  final String currentColor;
  final ValueChanged<String> onColorChanged;

  const _ColorWheel({required this.currentColor, required this.onColorChanged});

  @override
  State<_ColorWheel> createState() => _ColorWheelState();
}

class _ColorWheelState extends State<_ColorWheel> {
  double _hue = 0;
  double _saturation = 0;

  @override
  void initState() {
    super.initState();
    _updateFromColor(widget.currentColor);
  }

  @override
  void didUpdateWidget(_ColorWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentColor != widget.currentColor) {
      _updateFromColor(widget.currentColor);
    }
  }

  void _updateFromColor(String hex) {
    try {
      final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
      final hsl = HSLColor.fromColor(color);
      setState(() {
        _hue = hsl.hue;
        _saturation = hsl.saturation;
      });
    } catch (_) {}
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final localPos = details.localPosition - center;
    final dist = localPos.distance;

    if (dist > radius) return; // outside wheel

    // Calculate hue from angle
    var angle = math.atan2(localPos.dy, localPos.dx);
    var hue = (angle * 180 / math.pi + 360) % 360;

    // Saturation from distance from center
    var saturation = (dist / radius).clamp(0.0, 1.0);

    // Snap saturation to 0 if very close to center
    if (saturation < 0.05) saturation = 0;

    setState(() {
      _hue = hue;
      _saturation = saturation;
    });

    // Convert to hex
    final hsl = HSLColor.fromAHSL(1, hue, saturation, 0.5);
    final color = hsl.toColor();
    final hex = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    widget.onColorChanged(hex);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) {},
      onPanUpdate: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          _onPanUpdate(details, box.size);
        }
      },
      child: CustomPaint(
        painter: _ColorWheelPainter(hue: _hue, saturation: _saturation),
      ),
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  final double hue;
  final double saturation;

  _ColorWheelPainter({required this.hue, required this.saturation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Draw color wheel using conic gradient approximation
    const segments = 72;
    for (int i = 0; i < segments; i++) {
      final startAngle = (i * 360 / segments - 90) * math.pi / 180;
      final sweepAngle = (360 / segments) * math.pi / 180;

      // Vary saturation from center to edge
      final paint = Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: [
            HSLColor.fromAHSL(1, (startAngle * 180 / math.pi + 90 + 360) % 360, 1.0, 0.5).toColor(),
            HSLColor.fromAHSL(1, ((startAngle + sweepAngle) * 180 / math.pi + 90 + 360) % 360, 1.0, 0.5).toColor(),
          ],
          stops: const [0, 1],
          transform: GradientRotation(startAngle),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(center.dx, center.dy);
      path.arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
      );
      path.close();
      canvas.drawPath(path, paint);
    }

    // White center (desaturation)
    final centerGradient = RadialGradient(
      colors: [Colors.white.withValues(alpha: 0.9), Colors.white.withValues(alpha: 0)],
      stops: const [0.0, 0.3],
    );
    canvas.drawCircle(
      center,
      radius * 0.3,
      Paint()..shader = centerGradient.createShader(Rect.fromCircle(center: center, radius: radius * 0.3)),
    );

    // Current color indicator
    final indicatorRadius = radius * saturation;
    final indicatorX = center.dx + math.cos((hue - 90) * math.pi / 180) * indicatorRadius;
    final indicatorY = center.dy + math.sin((hue - 90) * math.pi / 180) * indicatorRadius;

    final hsl = HSLColor.fromAHSL(1, hue, saturation, 0.5);
    final indicatorColor = hsl.toColor();

    // Outer ring
    canvas.drawCircle(
      Offset(indicatorX, indicatorY),
      8,
      Paint()
        ..color = indicatorColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(indicatorX, indicatorY),
      8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _ColorWheelPainter oldDelegate) =>
      oldDelegate.hue != hue || oldDelegate.saturation != saturation;
}
