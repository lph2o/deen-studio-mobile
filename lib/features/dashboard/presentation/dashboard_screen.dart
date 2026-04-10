import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import newly created widgets
import 'widgets/custom_app_bar.dart';
import 'widgets/dashboard_bottom_nav.dart';
import 'widgets/hero_create_card.dart';
import 'widgets/recent_projects_section.dart';
import 'widgets/popular_templates.dart';
import 'widgets/inspiration_studio.dart';

import 'views/projects_view.dart';
import 'views/templates_view.dart';
import 'views/profile_view.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121414), // Using the theme default
      extendBody: true, // Crucial for the bottom nav glassmorphism!
      appBar: _currentIndex == 0 ? const CustomAppBar() : null, // AppBar logic depends on view, ideally moved into views if complex, or kept uniform
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeView(),
          TemplatesView(),
          ProjectsView(),
          ProfileView(),
        ],
      ),
      bottomNavigationBar: DashboardBottomNav(
        currentIndex: _currentIndex,
        onTabChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeroCreateCard(
              onCreatePressed: () => context.push('/select-surah'),
            ),
            const SizedBox(height: 40),
            
            // Middle grid/layout section
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(flex: 2, child: RecentProjectsSection()),
                      const SizedBox(width: 24),
                      const Expanded(child: PopularTemplates()),
                    ],
                  );
                }
                
                // Mobile Layout
                return Column(
                  children: [
                    const RecentProjectsSection(),
                    const SizedBox(height: 40),
                    const PopularTemplates(),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 40),
            const InspirationStudio(),
            
            // Extra padding at the bottom so content isn't hidden by the floating nav
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

