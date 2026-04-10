import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:deen_studio_01/models/project.dart';
import 'package:deen_studio_01/features/editor/presentation/editor_state.dart';
import 'package:deen_studio_01/core/utils/toast_service.dart';

/// Text-to-Speech sheet using flutter_tts (native) + optional ElevenLabs API.
///
/// ## Architecture
/// - **Native TTS**: Uses device's built-in speech engine (free, works offline)
/// - **ElevenLabs (optional)**: If ELEVENLABS_API_KEY is set in .env, uses premium voices
/// - Generated audio is saved locally and added as an audio layer to the project
class TextToSpeechSheet extends ConsumerStatefulWidget {
  final Layer targetLayer;
  const TextToSpeechSheet({super.key, required this.targetLayer});

  @override
  ConsumerState<TextToSpeechSheet> createState() => _TextToSpeechSheetState();
}

class _TextToSpeechSheetState extends ConsumerState<TextToSpeechSheet> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isGenerating = false;
  bool _isPreviewing = false;
  String _selectedVoiceLang = 'ar-SA';
  double _speed = 1.0;
  double _pitch = 1.0;
  bool _useElevenLabs = false;
  String _elevenLabsVoiceId = '21m00Tcm4TlvDq8ikWAM'; // Default: Rachel

  // Available languages/voices for native TTS
  final _languages = [
    {'code': 'ar-SA', 'name': 'Arabe (SA)', 'flag': '🇸🇦'},
    {'code': 'fr-FR', 'name': 'Français (FR)', 'flag': '🇫🇷'},
    {'code': 'en-US', 'name': 'Anglais (US)', 'flag': '🇺🇸'},
    {'code': 'en-GB', 'name': 'Anglais (UK)', 'flag': '🇬🇧'},
    {'code': 'es-ES', 'name': 'Espagnol', 'flag': '🇪🇸'},
    {'code': 'de-DE', 'name': 'Allemand', 'flag': '🇩🇪'},
  ];

  // ElevenLabs voice options
  final _elevenLabsVoices = [
    {'id': '21m00Tcm4TlvDq8ikWAM', 'name': 'Rachel (F)', 'gender': 'F'},
    {'id': 'AZnzlk1XvdvUeBnXmlld', 'name': 'Domi (F)', 'gender': 'F'},
    {'id': 'EXAVITQu4vr4xnSDxMaL', 'name': 'Bella (F)', 'gender': 'F'},
    {'id': 'MF3mGyEYCl7XYWbV9V6O', 'name': 'Elli (M)', 'gender': 'M'},
    {'id': 'TxGEqnHWrfWFTfGW9XjX', 'name': 'Josh (M)', 'gender': 'M'},
    {'id': 'VR6AewLTigWG4xSOukaG', 'name': 'Arnold (M)', 'gender': 'M'},
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    _checkElevenLabs();
  }

  void _initTts() {
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isPreviewing = false);
    });
    _flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() => _isPreviewing = false);
        ToastService.showError(context, 'Erreur TTS: $msg');
      }
    });
  }

  void _checkElevenLabs() {
    final apiKey = dotenv.env['ELEVENLABS_API_KEY'] ?? '';
    if (apiKey.isNotEmpty) {
      setState(() => _useElevenLabs = true);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  /// Preview the text with native TTS.
  Future<void> _previewSpeech() async {
    final text = widget.targetLayer.content.isEmpty ? 'Texte exemple' : widget.targetLayer.content;
    if (text.isEmpty) return;

    await _flutterTts.setSpeechRate(_speed - 0.5); // Map 0.5-2.0 to 0.0-1.5
    await _flutterTts.setPitch(_pitch);
    await _flutterTts.setLanguage(_selectedVoiceLang);

    setState(() => _isPreviewing = true);
    await _flutterTts.speak(text);
  }

  /// Stop preview.
  Future<void> _stopPreview() async {
    await _flutterTts.stop();
    if (mounted) setState(() => _isPreviewing = false);
  }

  /// Generate speech and add as audio layer.
  Future<void> _generateSpeech() async {
    final text = widget.targetLayer.content;
    if (text.isEmpty) {
      ToastService.showError(context, 'Le calque ne contient aucun texte.');
      return;
    }

    setState(() => _isGenerating = true);

    try {
      String? audioPath;

      if (_useElevenLabs) {
        audioPath = await _generateElevenLabsSpeech(text);
      } else {
        // Native TTS doesn't support saving to file directly.
        // We'll use a workaround: speak the text and record it.
        // For now, we inform the user that native TTS can only preview.
        ToastService.showInfo(
          context,
          'Le TTS natif permet uniquement la prévisualisation. Configurez ELEVENLABS_API_KEY dans .env pour l\'export audio.',
        );
        setState(() => _isGenerating = false);
        return;
      }

      if (audioPath != null && mounted) {
        // Add audio layer to the project
        final notifier = ref.read(editorProvider.notifier);
        final audioLayer = Layer(
          id: 'audio_tts_${DateTime.now().millisecondsSinceEpoch}',
          type: 'audio',
          content: audioPath,
          startTime: widget.targetLayer.startTime,
          duration: 5.0,
          style: {},
        );
        notifier.addLayer(audioLayer);

        ToastService.showSuccess(context, 'Audio TTS ajouté au projet');
        Navigator.of(context).pop();
      } else if (mounted) {
        ToastService.showError(context, 'Erreur lors de la génération audio.');
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Erreur: $e');
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  /// Generate speech using ElevenLabs API.
  Future<String?> _generateElevenLabsSpeech(String text) async {
    final apiKey = dotenv.env['ELEVENLABS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('ElevenLabs API key not configured');
    }

    final uri = Uri.parse(
      'https://api.elevenlabs.io/v1/text-to-speech/$_elevenLabsVoiceId',
    );

    final response = await http.post(
      uri,
      headers: {
        'xi-api-key': apiKey,
        'Content-Type': 'application/json',
        'Accept': 'audio/mpeg',
      },
      body: {
        'text': text,
        'model_id': 'eleven_multilingual_v2',
        'voice_settings': {
          'stability': 0.5,
          'similarity_boost': 0.75,
          'speed': _speed,
        },
      },
    );

    if (response.statusCode != 200) {
      throw Exception('ElevenLabs API error: ${response.statusCode}');
    }

    // Save audio file
    final dir = await getApplicationDocumentsDirectory();
    final audioFile = File('${dir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3');
    await audioFile.writeAsBytes(response.bodyBytes);

    return audioFile.path;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = widget.targetLayer.content;

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
      child: SingleChildScrollView(
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
                Icon(LucideIcons.mic2, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'Texte en voix',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Text preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                text.isEmpty ? '(Aucun texte dans le calque)' : '"${text.length > 60 ? '${text.substring(0, 60)}...' : text}"',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 20),

            // TTS Engine selection
            _buildSectionTitle('Moteur TTS'),
            Row(
              children: [
                _buildEngineToggle(
                  label: 'Natif',
                  selected: !_useElevenLabs,
                  onTap: () => setState(() => _useElevenLabs = false),
                ),
                const SizedBox(width: 8),
                _buildEngineToggle(
                  label: 'ElevenLabs',
                  selected: _useElevenLabs,
                  onTap: () {
                    final apiKey = dotenv.env['ELEVENLABS_API_KEY'] ?? '';
                    if (apiKey.isEmpty) {
                      ToastService.showInfo(
                        context,
                        'Configurez ELEVENLABS_API_KEY dans .env pour utiliser ElevenLabs.',
                      );
                    } else {
                      setState(() => _useElevenLabs = true);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Language/Voice selector
            if (!_useElevenLabs) ...[
              _buildSectionTitle('Langue'),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _languages.map((lang) {
                  final isSelected = _selectedVoiceLang == lang['code'];
                  return ChoiceChip(
                    label: Text('${lang['flag']} ${lang['name']}'),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedVoiceLang = lang['code'] as String),
                  );
                }).toList(),
              ),
            ] else ...[
              _buildSectionTitle('Voix ElevenLabs'),
              ..._elevenLabsVoices.map((voice) {
                final isSelected = _elevenLabsVoiceId == voice['id'];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: voice['gender'] == 'M'
                        ? Colors.blue.withValues(alpha: 0.2)
                        : Colors.pink.withValues(alpha: 0.2),
                    child: Icon(
                      voice['gender'] == 'M' ? LucideIcons.user : LucideIcons.user,
                      color: voice['gender'] == 'M' ? Colors.blue[200] : Colors.pink[200],
                      size: 18,
                    ),
                  ),
                  title: Text(voice['name']!, style: const TextStyle(fontSize: 14)),
                  trailing: isSelected
                      ? Icon(LucideIcons.checkCircle2, color: theme.colorScheme.primary, size: 20)
                      : null,
                  onTap: () => setState(() => _elevenLabsVoiceId = voice['id'] as String),
                );
              }),
            ],
            const SizedBox(height: 16),

            // Speed & Pitch
            _buildSectionTitle('Paramètres vocaux'),
            _buildSliderRow(
              label: 'Vitesse',
              value: _speed,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              onChanged: (v) => setState(() => _speed = v),
              format: (v) => '${v.toStringAsFixed(1)}x',
            ),
            _buildSliderRow(
              label: 'Tonalité',
              value: _pitch,
              min: 0.5,
              max: 1.5,
              divisions: 10,
              onChanged: (v) => setState(() => _pitch = v),
              format: (v) => '${(v * 100).toInt()}%',
            ),
            const SizedBox(height: 20),

            // Preview + Generate buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: text.isEmpty ? null : (_isPreviewing ? _stopPreview : _previewSpeech),
                    icon: Icon(_isPreviewing ? LucideIcons.square : LucideIcons.play),
                    label: Text(_isPreviewing ? 'Stop' : 'Aperçu'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: text.isEmpty || _isGenerating ? null : _generateSpeech,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(LucideIcons.download),
                    label: Text(_useElevenLabs ? 'Générer & Ajouter' : 'Aperçu uniquement'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
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
                      _useElevenLabs
                          ? 'ElevenLabs: audio réaliste, exportable au projet. Nécessite une clé API.'
                          : 'TTS natif: prévisualisation uniquement. Configurez ELEVENLABS_API_KEY pour l\'export audio.',
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
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  Widget _buildEngineToggle({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String Function(double) format,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(format(value), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
