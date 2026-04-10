import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/models/pixabay_models.dart';
import '../state/pixabay_notifier.dart';

class PixabayGalleryWidget extends ConsumerStatefulWidget {
  final void Function(String filePath, bool isVideo) onMediaImported;

  const PixabayGalleryWidget({super.key, required this.onMediaImported});

  @override
  ConsumerState<PixabayGalleryWidget> createState() => _PixabayGalleryWidgetState();
}

class _PixabayGalleryWidgetState extends ConsumerState<PixabayGalleryWidget> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400) {
      ref.read(pixabayProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pixabayProvider);
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(LucideIcons.image, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Visual Library',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, fontFamily: 'Manrope'),
                ),
                const Spacer(),
                Text(
                  'Powered by Pixabay',
                  style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: ref.read(pixabayProvider.notifier).onSearchChanged,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search for visuals (e.g. "mosque", "nature")',
                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 13),
                prefixIcon: Icon(LucideIcons.search, size: 18, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(pixabayProvider.notifier).search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Media Type Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _TypeButton(
                  label: 'Photos',
                  icon: LucideIcons.image,
                  isActive: state.mediaType == PixabayMediaType.images,
                  onTap: () => ref.read(pixabayProvider.notifier).switchMediaType(PixabayMediaType.images),
                ),
                const SizedBox(width: 10),
                _TypeButton(
                  label: 'Videos',
                  icon: LucideIcons.video,
                  isActive: state.mediaType == PixabayMediaType.videos,
                  onTap: () => ref.read(pixabayProvider.notifier).switchMediaType(PixabayMediaType.videos),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Error
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(state.error!, style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
            ),

          // Grid
          Expanded(
            child: _buildGrid(state, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(PixabayState state, ThemeData theme) {
    if (state.query.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.search, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('Search for images or videos above', style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4), fontSize: 13)),
          ],
        ),
      );
    }

    if (state.isLoading && state.items.isEmpty) {
      return _buildShimmerGrid(theme);
    }

    if (state.items.isEmpty) {
      return Center(
        child: Text('No results for "${state.query}"', style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5))),
      );
    }

    return MasonryGridView.count(
      controller: _scrollController,
      crossAxisCount: 2,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final item = state.items[index];
        final isImporting = state.importingId == '${item.id}';

        return _MediaCard(
          item: item,
          isImporting: isImporting,
          mediaType: state.mediaType,
          onTap: () async {
            HapticFeedback.lightImpact();
            final filePath = await ref.read(pixabayProvider.notifier).downloadAndImport(item);
            if (filePath != null && mounted) {
              widget.onMediaImported(filePath, state.mediaType == PixabayMediaType.videos);
            }
          },
        );
      },
    );
  }

  Widget _buildShimmerGrid(ThemeData theme) {
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 8,
      itemBuilder: (context, index) {
        final heights = [120.0, 180.0, 140.0, 200.0, 130.0, 160.0, 190.0, 150.0];
        return Container(
          height: heights[index % 8],
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _TypeButton({required this.label, required this.icon, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? theme.colorScheme.primary.withValues(alpha: 0.4) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final dynamic item;
  final bool isImporting;
  final PixabayMediaType mediaType;
  final VoidCallback onTap;

  const _MediaCard({
    required this.item,
    required this.isImporting,
    required this.mediaType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbnailUrl = mediaType == PixabayMediaType.images
        ? (item as PixabayImage).webformatURL
        : (item as PixabayVideo).thumbnailUrl;

    return GestureDetector(
      onTap: isImporting ? null : onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            // Thumbnail
            CachedNetworkImage(
              imageUrl: thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 140,
                color: theme.colorScheme.surfaceContainerLow,
              ),
              errorWidget: (context, url, error) => Container(
                height: 140,
                color: theme.colorScheme.surfaceContainerLow,
                child: const Icon(Icons.broken_image, color: Colors.white24),
              ),
            ),

            // Video play icon badge
            if (mediaType == PixabayMediaType.videos)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, size: 14, color: Colors.white),
                ),
              ),

            // Importing overlay
            if (isImporting)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Downloading…',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),

            // Tap ripple area
            if (!isImporting)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    splashColor: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
