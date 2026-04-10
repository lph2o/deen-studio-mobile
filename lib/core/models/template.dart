import 'package:flutter/material.dart';
import 'package:deen_studio_01/models/project.dart';
import 'package:deen_studio_01/models/text_layer_style.dart';

/// A layer template that can be converted to an actual Layer.
class LayerTemplate {
  final String type;
  final String content;
  final double startTime;
  final double duration;
  final Map<String, dynamic> style;
  final Map<String, dynamic> textStyle;
  final String? fontFamily;
  final double? fontSize;
  final String? textColor;
  final String? textAnimation;

  const LayerTemplate({
    required this.type,
    required this.content,
    required this.startTime,
    required this.duration,
    this.style = const {},
    this.textStyle = const {},
    this.fontFamily,
    this.fontSize,
    this.textColor,
    this.textAnimation,
  });

  /// Convert this template to an actual Layer with a unique ID.
  Layer toLayer() {
    TextLayerStyle? parsedTextStyle;
    if (textStyle.isNotEmpty) {
      parsedTextStyle = TextLayerStyle(
        fontFamily: fontFamily ?? textStyle['fontFamily'] ?? 'Inter',
        fontSize: fontSize ?? (textStyle['fontSize'] as num?)?.toDouble() ?? 40.0,
        color: textColor ?? textStyle['color'] ?? '#FFFFFF',
        backgroundColor: textStyle['backgroundColor'] as String?,
        fontWeight: _parseFontWeight(textStyle['fontWeight']),
        shadowColor: textStyle['shadowColor'] as String? ?? '#000000',
        shadowBlur: (textStyle['shadowBlur'] as num?)?.toDouble() ?? 0.0,
        strokeColor: textStyle['strokeColor'] as String? ?? '#000000',
        strokeWidth: (textStyle['strokeWidth'] as num?)?.toDouble() ?? 0.0,
        letterSpacing: (textStyle['letterSpacing'] as num?)?.toDouble() ?? 0.0,
        lineHeight: (textStyle['lineHeight'] as num?)?.toDouble() ?? 1.2,
      );
    }

    return Layer(
      id: 'template_${DateTime.now().millisecondsSinceEpoch}_$type',
      type: type,
      content: content,
      startTime: startTime,
      duration: duration,
      style: style,
      textStyle: parsedTextStyle,
      fontFamily: fontFamily,
      fontSize: fontSize,
      textColor: textColor,
      textAnimation: textAnimation,
    );
  }

  static FontWeight _parseFontWeight(dynamic v) {
    if (v == null) return FontWeight.normal;
    if (v is int) return FontWeight.values[v.clamp(0, FontWeight.values.length - 1)];
    if (v is String) {
      switch (v) {
        case 'bold':
          return FontWeight.bold;
        case 'w300':
          return FontWeight.w300;
        case 'w500':
          return FontWeight.w500;
        case 'w700':
          return FontWeight.w700;
        default:
          return FontWeight.normal;
      }
    }
    return FontWeight.normal;
  }
}

/// A project template that can be converted into a full Project.
class Template {
  final String id;
  final String name;
  final String description;
  final String category; // 'quran', 'reminder', 'nature', 'cinematic'
  final String thumbnailUrl;
  final String aspectRatio;
  final List<LayerTemplate> layers;

  const Template({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.thumbnailUrl,
    this.aspectRatio = '9:16',
    this.layers = const [],
  });

  /// Convert this template to a new Project.
  Project toProject({required String userId, required String projectId}) {
    // Generate unique IDs for each layer
    final baseTime = DateTime.now().millisecondsSinceEpoch;
    final layers = this.layers.asMap().entries.map((entry) {
      final lt = entry.value;
      return Layer(
        id: 'tpl_${baseTime}_${entry.key}_${lt.type}',
        type: lt.type,
        content: lt.content,
        startTime: lt.startTime,
        duration: lt.duration,
        style: lt.style,
        textStyle: _parseTextStyle(lt),
        fontFamily: lt.fontFamily,
        fontSize: lt.fontSize,
        textColor: lt.textColor,
        textAnimation: lt.textAnimation,
      );
    }).toList();

    return Project(
      id: projectId,
      userId: userId,
      title: name,
      surahId: 0,
      ayahRange: AyahRange(start: 1, end: 1),
      reciterId: '',
      layers: layers,
      aspectRatio: aspectRatio,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  TextLayerStyle? _parseTextStyle(LayerTemplate lt) {
    if (lt.textStyle.isEmpty) return null;
    final ts = lt.textStyle;
    return TextLayerStyle(
      fontFamily: lt.fontFamily ?? ts['fontFamily'] ?? 'Inter',
      fontSize: lt.fontSize ?? (ts['fontSize'] as num?)?.toDouble() ?? 40.0,
      color: lt.textColor ?? ts['color'] ?? '#FFFFFF',
      backgroundColor: ts['backgroundColor'] as String?,
      fontWeight: LayerTemplate._parseFontWeight(ts['fontWeight']),
      shadowColor: ts['shadowColor'] as String? ?? '#000000',
      shadowBlur: (ts['shadowBlur'] as num?)?.toDouble() ?? 0.0,
      strokeColor: ts['strokeColor'] as String? ?? '#000000',
      strokeWidth: (ts['strokeWidth'] as num?)?.toDouble() ?? 0.0,
      letterSpacing: (ts['letterSpacing'] as num?)?.toDouble() ?? 0.0,
      lineHeight: (ts['lineHeight'] as num?)?.toDouble() ?? 1.2,
    );
  }
}
