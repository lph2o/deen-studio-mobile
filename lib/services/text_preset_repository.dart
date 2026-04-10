import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/text_style_preset.dart';
import '../models/text_layer_style.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Text Preset Repository (SharedPreferences-backed)
// ─────────────────────────────────────────────────────────────────────────────

class TextPresetRepository {
  static const _kKey = 'deen_text_presets';
  static const _kFavoritesKey = 'deen_text_preset_favorites';

  // ── Favorites ──────────────────────────────────────────────────────────────

  Future<Set<String>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kFavoritesKey)?.toSet() ?? {};
  }

  Future<void> toggleFavorite(String presetId) async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList(_kFavoritesKey)?.toSet() ?? {};
    if (favs.contains(presetId)) {
      favs.remove(presetId);
    } else {
      favs.add(presetId);
    }
    await prefs.setStringList(_kFavoritesKey, favs.toList());
  }

  // ── Custom Presets ─────────────────────────────────────────────────────────

  Future<List<TextStylePreset>> loadCustom() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((m) => TextStylePreset.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePreset(TextStylePreset preset) async {
    final prefs = await SharedPreferences.getInstance();
    final custom = await loadCustom();
    final existing = custom.indexWhere((p) => p.id == preset.id);
    if (existing >= 0) {
      custom[existing] = preset;
    } else {
      custom.add(preset);
    }
    await prefs.setString(_kKey, jsonEncode(custom.map((p) => p.toMap()).toList()));
  }

  Future<void> deletePreset(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final custom = await loadCustom();
    custom.removeWhere((p) => p.id == id);
    await prefs.setString(_kKey, jsonEncode(custom.map((p) => p.toMap()).toList()));
  }

  /// Export selected preset IDs to a JSON string.
  Future<String> exportToJson(List<String> presetIds) async {
    final custom = await loadCustom();
    final all = [...kBuiltInPresets, ...custom];
    final selected = all.where((p) => presetIds.contains(p.id)).toList();
    return jsonEncode(selected.map((p) => p.toMap()).toList());
  }

  /// Import presets from a JSON string.
  Future<int> importFromJson(String json) async {
    try {
      final list = jsonDecode(json) as List;
      final presets = list.map((m) => TextStylePreset.fromMap(m)).toList();
      for (final p in presets) {
        await savePreset(p);
      }
      return presets.length;
    } catch (_) {
      return 0;
    }
  }

  /// Get all presets: built-in + custom, filtered by category.
  Future<List<TextStylePreset>> getAll({String? category}) async {
    final custom = await loadCustom();
    final all = [...kBuiltInPresets, ...custom];
    if (category == null || category == 'all') return all;
    return all.where((p) => p.category == category).toList();
  }

  /// Create a custom preset from the current style with a given name.
  Future<TextStylePreset> saveCurrentStyle(TextLayerStyle style, String name) async {
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final preset = TextStylePreset(
      id: id,
      name: name,
      category: 'custom',
      style: style,
    );
    await savePreset(preset);
    return preset;
  }
}
