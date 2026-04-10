import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import '../editor_state.dart';
import '../../../../models/text_layer_style.dart';
import '../../../../models/project.dart';
import '../../../../core/utils/toast_service.dart';

/// Auto-subtitle generation sheet using device speech recognition.
///
/// ## Architecture
/// - Uses `speech_to_text` package (native iOS/Android speech recognition)
/// - Listens to microphone audio and converts to text in real-time
/// - Creates text layers with timestamps based on speech pauses
/// - Free, works offline, no external API needed
///
/// ## Limitations
/// - Requires microphone permission
/// - Quality varies by device/OS
/// - Best for short recordings (under 5 minutes)
class AutoSubtitleSheet extends ConsumerStatefulWidget {
  const AutoSubtitleSheet({super.key});

  @override
  ConsumerState<AutoSubtitleSheet> createState() => _AutoSubtitleSheetState();
}

class _AutoSubtitleSheetState extends ConsumerState<AutoSubtitleSheet> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;
  bool _hasError = false;
  String _lastWords = '';
  double _confidence = 0.0;
  String _currentLocale = 'fr_FR';
  final List<_SubtitleSegment> _segments = [];
  String _currentSegment = '';
  DateTime? _segmentStartTime;

  final Map<String, String> _locales = {
    'Français': 'fr_FR',
    'English': 'en_US',
    'العربية': 'ar_SA',
    'Español': 'es_ES',
    'Deutsch': 'de_DE',
  };

  String _selectedLanguage = 'Français';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          setState(() => _hasError = true);
          ToastService.showError(
            context,
            'Permission microphone requise pour la reconnaissance vocale.',
          );
        }
        return;
      }

      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() => _isListening = false);
              _saveCurrentSegment();
            }
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _hasError = true;
              _isListening = false;
            });
            ToastService.showError(context, 'Erreur: ${error.errorMsg}');
          }
        },
      );

      if (mounted) {
        setState(() => _isInitialized = available);
        if (!available) {
          ToastService.showError(
            context,
            'La reconnaissance vocale n\'est pas disponible sur cet appareil.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
        ToastService.showError(context, 'Erreur d\'initialisation: $e');
      }
    }
  }

  void _startListening() async {
    if (!_isInitialized) return;

    _localeFromLanguage();
    _segments.clear();
    _currentSegment = '';
    _segmentStartTime = DateTime.now();

    await _speech.listen(
      localeId: _currentLocale,
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(partialResults: true),
      onResult: (result) {
        if (mounted) {
          setState(() {
            _lastWords = result.recognizedWords;
            _confidence = result.confidence;
            if (result.hasConfidenceRating && result.confidence > 0.0) {
              _currentSegment = result.recognizedWords;
            }
          });
        }
      },
    );

    if (mounted) {
      setState(() => _isListening = true);
    }
  }

  void _stopListening() async {
    await _speech.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
      });
      _saveCurrentSegment();
      _addSubtitleLayers();
    }
  }

  void _localeFromLanguage() {
    _currentLocale = _locales[_selectedLanguage] ?? 'fr_FR';
  }

  void _saveCurrentSegment() {
    if (_currentSegment.trim().isNotEmpty && _segmentStartTime != null) {
      _segments.add(_SubtitleSegment(
        text: _currentSegment.trim(),
        startTime: _segmentStartTime!,
        confidence: _confidence,
      ));
    }
  }

  void _addSubtitleLayers() {
    final state = ref.read(editorProvider);
    final notifier = ref.read(editorProvider.notifier);
    final baseTime = state.currentTime;

    for (int i = 0; i < _segments.length; i++) {
      final segment = _segments[i];
      final duration = i < _segments.length - 1
          ? _segments[i + 1].startTime.difference(segment.startTime).inMilliseconds / 1000.0
          : 3.0;

      if (segment.text.isNotEmpty) {
        notifier.addLayer(Layer(
          id: 'subtitle_auto_${i}_${DateTime.now().millisecondsSinceEpoch}',
          type: 'text',
          content: segment.text,
          startTime: baseTime + (i * 3.0),
          duration: duration.clamp(1.0, 5.0),
          style: {},
          textStyle: const TextLayerStyle(
            fontSize: 28,
            color: '#FFFFFF',
            shadowBlur: 6,
            shadowColor: '#000000',
            textAlign: TextAlign.center,
          ),
        ));
      }
    }

    if (_segments.isNotEmpty) {
      ToastService.showSuccess(
        context,
        '${_segments.length} sous-titres ajoutés à la timeline.',
      );
    } else {
      ToastService.showInfo(
        context,
        'Aucune parole détectée. Réessayez en parlant clairement.',
      );
    }

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    if (_isListening) _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 8,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Row(
            children: [
              Icon(LucideIcons.mic, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Sous-titres automatiques',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Parlez clairement. L\'IA transcrira vos paroles en sous-titres synchronisés.',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),

          // Language selection
          const Text('Langue parlée', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _locales.keys.map((lang) {
              final isSelected = _selectedLanguage == lang;
              return ChoiceChip(
                label: Text(lang),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedLanguage = lang);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Listening status / transcription
          if (_isListening || _lastWords.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isListening
                    ? Colors.green.withValues(alpha: 0.1)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isListening
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_isListening) ...[
                        SizedBox(
                          width: 8,
                          height: 8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Écoute en cours...', style: TextStyle(fontWeight: FontWeight.w600)),
                      ] else ...[
                        const Icon(LucideIcons.check, size: 18, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text('Écoute terminée', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                  if (_lastWords.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _lastWords,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    if (_confidence > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Confiance: ${(_confidence * 100).toInt()}%',
                        style: const TextStyle(fontSize: 11, color: Colors.white54),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Error state
          if (_hasError && !_isInitialized) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Erreur: La reconnaissance vocale n\'est pas disponible. Vérifiez les permissions et les paramètres de l\'appareil.',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Action buttons
          if (!_isListening)
            ElevatedButton.icon(
              onPressed: _isInitialized && !_hasError ? _startListening : null,
              icon: const Icon(LucideIcons.mic),
              label: const Text('Commencer l\'écoute', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _stopListening,
              icon: const Icon(LucideIcons.square),
              label: const Text('Arrêter et générer les sous-titres', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          const SizedBox(height: 12),

          // Info box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.info, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Utilise la reconnaissance vocale native de l\'appareil. Qualité variable selon l\'appareil et la langue.',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtitleSegment {
  final String text;
  final DateTime startTime;
  final double confidence;

  _SubtitleSegment({required this.text, required this.startTime, required this.confidence});
}
