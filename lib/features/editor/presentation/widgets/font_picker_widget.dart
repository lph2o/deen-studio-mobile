import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/text_layer_style.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Font Picker Widget
// ─────────────────────────────────────────────────────────────────────────────

class FontPickerWidget extends ConsumerStatefulWidget {
  final String selectedFont;
  final ValueChanged<String> onFontSelected;

  const FontPickerWidget({
    super.key,
    required this.selectedFont,
    required this.onFontSelected,
  });

  @override
  ConsumerState<FontPickerWidget> createState() => _FontPickerWidgetState();
}

class _FontPickerWidgetState extends ConsumerState<FontPickerWidget> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, List<String>> get _filteredGroups {
    if (_searchQuery.isEmpty) return FontCatalogue.groups;
    final q = _searchQuery.toLowerCase();
    final result = <String, List<String>>{};
    FontCatalogue.groups.forEach((group, fonts) {
      final matched = fonts.where((f) => f.toLowerCase().contains(q)).toList();
      if (matched.isNotEmpty) result[group] = matched;
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = _filteredGroups;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Rechercher une police...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.07),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),

        // Font list grouped
        Expanded(
          child: groups.isEmpty
              ? Center(
                  child: Text(
                    'Aucune police trouvée',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                )
              : ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, groupIndex) {
                    final group = groups.keys.elementAt(groupIndex);
                    final fonts = groups[group]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Group header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                          child: Text(
                            group.toUpperCase(),
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        // Font items
                        ...fonts.map((fontName) {
                          final isSelected = fontName == widget.selectedFont;
                          final isArabic = FontCatalogue.isArabic(fontName);
                          final isLocal = FontCatalogue.isLocal(fontName);

                          Widget nameWidget;
                          try {
                            nameWidget = isLocal
                                ? Text(
                                    fontName,
                                    style: TextStyle(
                                      fontFamily: fontName,
                                      fontSize: 18,
                                      color: isSelected ? theme.colorScheme.primary : Colors.white,
                                    ),
                                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                                  )
                                : Text(
                                    fontName,
                                    style: GoogleFonts.getFont(fontName, textStyle: TextStyle(
                                      fontSize: 18,
                                      color: isSelected ? theme.colorScheme.primary : Colors.white,
                                    )),
                                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                                  );
                          } catch (_) {
                            nameWidget = Text(
                              fontName,
                              style: TextStyle(
                                fontSize: 18,
                                color: isSelected ? theme.colorScheme.primary : Colors.white,
                              ),
                            );
                          }

                          return InkWell(
                            onTap: () => widget.onFontSelected(fontName),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                                    : Colors.transparent,
                                border: Border(
                                  left: isSelected
                                      ? BorderSide(color: theme.colorScheme.primary, width: 3)
                                      : BorderSide.none,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(child: nameWidget),
                                  if (isArabic)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF166534).withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('RTL', style: TextStyle(color: Color(0xFF86efac), fontSize: 9, fontWeight: FontWeight.w700)),
                                    ),
                                  if (isSelected)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Icon(Icons.check_rounded, color: theme.colorScheme.primary, size: 18),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}
