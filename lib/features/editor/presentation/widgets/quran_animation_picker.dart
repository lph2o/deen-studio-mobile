import 'package:flutter/material.dart';
import 'package:deen_studio_01/core/models/quran_text_animations.dart';
import 'package:deen_studio_01/core/ui/arabic_text_animation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Quran Animation Picker — Bottom Sheet with Live Previews
// ─────────────────────────────────────────────────────────────────────────────

void showQuranAnimationPicker({
  required BuildContext context,
  required ValueChanged<QuranTextAnimation> onSelected,
  String? currentAnimationId,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QuranAnimationPickerSheet(
      onSelected: onSelected,
      currentAnimationId: currentAnimationId,
    ),
  );
}

/// Sample Arabic text for previews
const _previewTexts = {
  'بسم الله الرحمن الرحيم': 'بسم',
  'الحمد لله رب العالمين': 'الحمد',
  'قل هو الله أحد': 'قل',
  'الله الصمد': 'الله',
  'لم يلد ولم يولد': 'لم',
  'ولم يكن له كفوا أحد': 'ولم',
};

class _QuranAnimationPickerSheet extends StatefulWidget {
  final ValueChanged<QuranTextAnimation> onSelected;
  final String? currentAnimationId;

  const _QuranAnimationPickerSheet({
    required this.onSelected,
    this.currentAnimationId,
  });

  @override
  State<_QuranAnimationPickerSheet> createState() =>
      _QuranAnimationPickerSheetState();
}

class _QuranAnimationPickerSheetState extends State<_QuranAnimationPickerSheet>
    with SingleTickerProviderStateMixin {
  QuranAnimationCategory? _selectedCategory;
  late AnimationController _previewController;

  // Category colors for indicators
  static const Map<QuranAnimationCategory, Color> _categoryColors = {
    QuranAnimationCategory.revelation: Color(0xFFFFD700),
    QuranAnimationCategory.nature: Color(0xFF4CAF50),
    QuranAnimationCategory.calligraphy: Color(0xFF8B0000),
    QuranAnimationCategory.geometry: Color(0xFF4A90D9),
    QuranAnimationCategory.spiritual: Color(0xFF9C27B0),
    QuranAnimationCategory.cosmic: Color(0xFF3F51B5),
  };

  @override
  void initState() {
    super.initState();
    _previewController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _previewController.dispose();
    super.dispose();
  }

  List<QuranTextAnimation> get _filteredAnimations {
    if (_selectedCategory == null) return kQuranTextAnimations;
    return getQuranAnimationsByCategory(_selectedCategory!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final panelBg = const Color(0xFF0D1117);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Animations Coraniques',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Category filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                // "All" chip
                _buildCategoryChip(null, 'Tout', '\u{2728}', theme),
                const SizedBox(width: 6),
                // Individual categories
                ...kCategoryInfo.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _buildCategoryChip(
                      entry.key,
                      entry.value.label,
                      entry.value.icon,
                      theme,
                    ),
                  );
                }),
              ],
            ),
          ),

          // Animation grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.9,
              ),
              itemCount: _filteredAnimations.length,
              itemBuilder: (context, index) {
                final anim = _filteredAnimations[index];
                return _buildAnimationCard(anim, theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    QuranAnimationCategory? category,
    String label,
    String icon,
    ThemeData theme,
  ) {
    final isSelected = _selectedCategory == category;
    final color = category != null
        ? (_categoryColors[category] ?? theme.colorScheme.primary)
        : theme.colorScheme.primary;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: color.withValues(alpha: 0.6), width: 1.5)
              : Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimationCard(QuranTextAnimation anim, ThemeData theme) {
    final isSelected = widget.currentAnimationId == anim.id;
    final categoryColor = _categoryColors[anim.category] ?? theme.colorScheme.primary;

    // Convert QuranTextAnimation to ArabicTextAnimation for preview
    final arabicAnim = arabicAnimationFromId(anim.id);

    return GestureDetector(
      onTap: () => widget.onSelected(anim),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: const Color(0xFFFFD700), width: 2.0)
              : Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: categoryColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar with category indicator
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: categoryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),

            // Live preview area
            SizedBox(
              height: 50,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: Container(
                  color: const Color(0xFF0A0E14),
                  child: AnimatedBuilder(
                    animation: _previewController,
                    builder: (context, _) {
                      final previewProgress = (_previewController.value * 1.5).clamp(0.0, 1.0);
                      return CustomPaint(
                        size: const Size(double.infinity, 50),
                        painter: ArabicTextPainter(
                          config: ArabicTextAnimationConfig(
                            animation: arabicAnim,
                            text: _previewTexts.entries.elementAt(
                              anim.id.hashCode.abs() % _previewTexts.length,
                            ).key,
                            baseStyle: TextStyle(
                              fontFamily: 'UthmanicRegular',
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            highlightColor: const Color(0xFFFFD700),
                            progress: previewProgress,
                            elapsed: _previewController.value * 3,
                            isRTL: true,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Name and description
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emoji + Name
                    Row(
                      children: [
                        Text(anim.icon, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            anim.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Description
                    Text(
                      anim.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 9,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // Selected indicator
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(bottom: 6, right: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD700),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
