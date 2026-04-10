import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:deen_studio_01/core/models/template.dart';
import 'package:deen_studio_01/core/models/template_presets.dart';
import 'package:deen_studio_01/features/auth/presentation/auth_state.dart';

/// Template visual data — gradient + icon instead of unreliable network thumbnails.
class _TemplateVisual {
  final List<Color> gradient;
  final String arabicExample;
  final IconData icon;
  const _TemplateVisual({required this.gradient, required this.arabicExample, required this.icon});
}

const _templateVisuals = <String, _TemplateVisual>{
  'quran_golden': _TemplateVisual(
    gradient: [Color(0xFF4A3000), Color(0xFF8B6914)],
    arabicExample: 'ٱللَّهُ لَآ إِلَـٰهَ إِلَّا هُوَ',
    icon: LucideIcons.sparkles,
  ),
  'verset_du_jour': _TemplateVisual(
    gradient: [Color(0xFF1a0533), Color(0xFF4a1a8a)],
    arabicExample: 'بِسْمِ ٱللَّهِ',
    icon: LucideIcons.sun,
  ),
  'nature_paix': _TemplateVisual(
    gradient: [Color(0xFF0D2818), Color(0xFF1B5E20)],
    arabicExample: 'ٱلسَّلَامُ عَلَيْكُمْ',
    icon: LucideIcons.leaf,
  ),
  'cinematique': _TemplateVisual(
    gradient: [Color(0xFF0D0D0D), Color(0xFF1a1a2e)],
    arabicExample: 'ٱلْحَمْدُ لِلَّهِ',
    icon: LucideIcons.clapperboard,
  ),
};

class HeroCreateCard extends ConsumerStatefulWidget {
  const HeroCreateCard({super.key});

  @override
  ConsumerState<HeroCreateCard> createState() => _HeroCreateCardState();
}

class _HeroCreateCardState extends ConsumerState<HeroCreateCard> {
  Future<void> _useTemplate(Template template) async {
    final authState = ref.read(authProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vous connecter pour créer une vidéo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final projectId = 'proj_${DateTime.now().millisecondsSinceEpoch}';
      final project = template.toProject(userId: userId, projectId: projectId);

      await Supabase.instance.client
          .from('projects')
          .insert(project.toInsertMap())
          .select()
          .single();

      if (!mounted) return;
      Navigator.of(context).pop();
      context.push('/editor/$projectId');
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showcaseTemplates = [
      getTemplateById('quran_golden'),
      getTemplateById('verset_du_jour'),
      getTemplateById('nature_paix'),
      getTemplateById('cinematique'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header label ──────────────────────────────────────────────────
        Row(
          children: [
            Icon(LucideIcons.zap, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'DÉMARRAGE RAPIDE',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Commencez avec un style.',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 28,
            height: 1.15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choisissez un template ci-dessous ou personnalisez vos propres versets.',
          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 24),

        // ── Template carousel ─────────────────────────────────────────────
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: showcaseTemplates.length,
            clipBehavior: Clip.none,
            itemBuilder: (context, index) {
              final template = showcaseTemplates[index];
              final visual = _templateVisuals[template.id];
              return Padding(
                padding: const EdgeInsets.only(right: 14.0),
                child: _HeroTemplateCard(
                  template: template,
                  visual: visual,
                  theme: theme,
                  onTap: () => _useTemplate(template),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // ── Custom project CTA ────────────────────────────────────────────
        InkWell(
          onTap: () => context.push('/select-surah'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.primary.withValues(alpha: 0.06),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.bookOpen, color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choisir mes propres versets',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sélectionnez une sourate, une plage d\'ayahs et un réciteur',
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.arrowRight, color: theme.colorScheme.primary, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroTemplateCard extends StatelessWidget {
  final Template template;
  final _TemplateVisual? visual;
  final ThemeData theme;
  final VoidCallback onTap;

  const _HeroTemplateCard({
    required this.template,
    required this.visual,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = visual?.gradient ?? [const Color(0xFF1a1a2e), const Color(0xFF4a1a8a)];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background shimmer dots
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      visual?.icon ?? LucideIcons.sparkles,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const Spacer(),
                  // Arabic preview text
                  if (visual?.arabicExample != null)
                    Text(
                      visual!.arabicExample,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 16,
                        color: Colors.white,
                        height: 1.6,
                      ),
                      textDirection: TextDirection.rtl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    template.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      template.category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tap overlay
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.plus, size: 12, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
