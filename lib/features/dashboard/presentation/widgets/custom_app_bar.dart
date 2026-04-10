import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../auth/presentation/auth_state.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return AppBar(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        onPressed: () {},
        icon: Icon(LucideIcons.menu, color: theme.colorScheme.primary),
      ),
      title: Text(
        'DEEN STUDIO',
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: PopupMenuButton<String>(
            color: theme.colorScheme.surfaceContainerHigh,
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) async {
              if (value == 'logout') {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) context.go('/');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(LucideIcons.logOut, size: 16, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Text('Log out', style: TextStyle(color: theme.colorScheme.error)),
                  ],
                ),
              ),
            ],
            child: CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              backgroundImage: const NetworkImage(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCQ2udw5qAqqMGguBPEl3Pk_1Cw5U30XYxsrngxyyRhQYJOkbasTk8Xh1iuVcSksL4O8K94kI2Bn1Yqkd3I1Ur57CnD5Xz-C2P0PisPrkgfEA0wqJ5CLBSUp9OTrEGCiHbFiVRfdFxjrCCZcge74vamBLtjI3lwd2_tqc7_VvJg3GqkI_Hi3CMlQPfp5B6z91Mz8FRXRr6Rq0D6B7nhDrLPxFzoLZyVn5rlTCY71EHeuFofMy1Qne8Nxvix_PW3QARqXVypJV44mclT'
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
