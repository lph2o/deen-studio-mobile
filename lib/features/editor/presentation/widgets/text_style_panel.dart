import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../models/project.dart';
import '../editor_state.dart';
import '../../../../core/theme.dart';

class TextStylePanel extends ConsumerStatefulWidget {
  final Layer layer;
  const TextStylePanel({super.key, required this.layer});

  @override
  ConsumerState<TextStylePanel> createState() => _TextStylePanelState();
}

class _TextStylePanelState extends ConsumerState<TextStylePanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _textController;

  final List<Map<String, dynamic>> _fonts = [
    {'name': 'Amiri', 'font': GoogleFonts.amiri},
    {'name': 'Inter', 'font': GoogleFonts.inter},
    {'name': 'Manrope', 'font': GoogleFonts.manrope},
    {'name': 'Outfit', 'font': GoogleFonts.outfit},
    {'name': 'Playfair', 'font': GoogleFonts.playfairDisplay},
    {'name': 'Mono', 'font': GoogleFonts.robotoMono},
  ];

  final List<Color> _colors = [
    Colors.white,
    AppTheme.primaryColor,
    AppTheme.secondaryColor,
    const Color(0xFFD4AF37), // Gold
    const Color(0xFF38BDF8), // Sky Blue
    const Color(0xFFFB7185), // Rose
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF10B981), // Emerald
    const Color(0xFF6366F1), // Indigo
    Colors.black,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _textController = TextEditingController(text: widget.layer.content);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = ref.read(editorProvider.notifier);

    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Tab Header
          TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            indicatorColor: AppTheme.secondaryColor,
            labelColor: AppTheme.secondaryColor,
            unselectedLabelColor: Colors.white38,
            tabs: const [
              Tab(text: 'TEXTE'),
              Tab(text: 'STYLE'),
              Tab(text: 'ANIMATION'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. TEXT TAB
                _buildTextTab(notifier),

                // 2. STYLE TAB
                _buildStyleTab(notifier),

                // 3. ANIMATION TAB
                _buildAnimationTab(notifier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextTab(EditorNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TextField(
        controller: _textController,
        maxLines: 5,
        autofocus: true,
        style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Entrez votre texte...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
        ),
        onChanged: (val) => notifier.updateTextContent(widget.layer.id, val),
      ),
    );
  }

  Widget _buildStyleTab(EditorNotifier notifier) {
    final currentFont = widget.layer.fontFamily ?? 'Inter';
    final currentColorStr = widget.layer.textColor ?? '0xFFFFFFFF';
    final currentColor = Color(int.parse(currentColorStr.replaceAll('#', '0xFF')));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('POLICE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _fonts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final font = _fonts[index];
              final isSelected = font['name'] == currentFont;
              return ChoiceChip(
                label: Text(font['name']),
                selected: isSelected,
                onSelected: (val) {
                   notifier.updateTextStyle(widget.layer.id, fontFamily: font['name']);
                },
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontFamily: (font['font'] as TextStyle Function())().fontFamily,
                ),
                selectedColor: AppTheme.secondaryColor,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        const Text('COULEUR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _colors.map((color) {
            final isSelected = color.toARGB32() == currentColor.toARGB32();
            return GestureDetector(
              onTap: () {
                final colorHex = '0x${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
                notifier.updateTextStyle(widget.layer.id, color: colorHex);
              },
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.white24,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected ? const Icon(LucideIcons.check, size: 18, color: Colors.black) : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text('TAILLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1.5)),
        Slider(
          value: widget.layer.fontSize ?? 20,
          min: 10, max: 100,
          onChanged: (val) => notifier.updateTextStyle(widget.layer.id, fontSize: val),
          activeColor: AppTheme.secondaryColor,
        ),
      ],
    );
  }

  Widget _buildAnimationTab(EditorNotifier notifier) {
    final currentAnim = widget.layer.textAnimation ?? 'none';
    final animations = [
      {'id': 'none', 'name': 'Aucune', 'icon': LucideIcons.circleSlash},
      {'id': 'fade', 'name': 'Fondu', 'icon': LucideIcons.cloud},
      {'id': 'typewriter', 'name': 'Tapuscrit', 'icon': LucideIcons.keyboard},
      {'id': 'karaoke', 'name': 'Karaoké', 'icon': LucideIcons.music},
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: animations.length,
      itemBuilder: (context, index) {
        final anim = animations[index];
        final isSelected = anim['id'] == currentAnim;
        return GestureDetector(
          onTap: () => notifier.updateTextStyle(widget.layer.id, animation: anim['id'] == 'none' ? null : anim['id'] as String),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.secondaryColor.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppTheme.secondaryColor : Colors.white10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(anim['icon'] as IconData, color: isSelected ? AppTheme.secondaryColor : Colors.white54),
                const SizedBox(height: 8),
                Text(anim['name'] as String, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.white38)),
              ],
            ),
          ),
        );
      },
    );
  }
}

void showTextStylePanel(BuildContext context, Layer layer) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: TextStylePanel(layer: layer),
    ),
  );
}
