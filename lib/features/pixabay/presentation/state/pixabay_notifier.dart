import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:deen_studio_01/core/services/persistent_media_store.dart';
import '../../data/models/pixabay_models.dart';
import '../../data/services/pixabay_service.dart';

class PixabayState {
  final String query;
  final PixabayMediaType mediaType;
  final List<dynamic> items;
  final bool isLoading;
  final String? importingId;
  final int page;
  final bool hasMore;
  final String? error;

  const PixabayState({
    this.query = '',
    this.mediaType = PixabayMediaType.images,
    this.items = const [],
    this.isLoading = false,
    this.importingId,
    this.page = 1,
    this.hasMore = true,
    this.error,
  });

  PixabayState copyWith({
    String? query,
    PixabayMediaType? mediaType,
    List<dynamic>? items,
    bool? isLoading,
    String? importingId,
    int? page,
    bool? hasMore,
    String? error,
    bool clearImporting = false,
    bool clearError = false,
  }) {
    return PixabayState(
      query: query ?? this.query,
      mediaType: mediaType ?? this.mediaType,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      importingId: clearImporting ? null : (importingId ?? this.importingId),
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PixabayNotifier extends Notifier<PixabayState> {
  final _service = PixabayService();
  final _dio = Dio();
  Timer? _debounceTimer;

  @override
  PixabayState build() {
    Future.microtask(() => search('islamic', reset: true));
    return const PixabayState(query: 'islamic');
  }

  void onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      search(query);
    });
  }

  Future<void> search(String query, {bool reset = true}) async {
    final q = query.trim();
    if (q.isEmpty) {
      state = const PixabayState();
      return;
    }
    if (reset) {
      state = state.copyWith(query: q, isLoading: true, items: [], page: 1, hasMore: true, clearError: true);
    }

    try {
      final results = await _fetchPage(q, state.mediaType, reset ? 1 : state.page);
      state = state.copyWith(
        items: reset ? results : [...state.items, ...results],
        isLoading: false,
        page: (reset ? 1 : state.page) + 1,
        hasMore: results.length == 30,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || state.query.isEmpty) return;
    state = state.copyWith(isLoading: true);
    await search(state.query, reset: false);
  }

  void switchMediaType(PixabayMediaType type) {
    if (type == state.mediaType) return;
    state = state.copyWith(mediaType: type, items: [], page: 1, hasMore: true);
    if (state.query.isNotEmpty) search(state.query);
  }

  Future<String?> downloadAndImport(dynamic item) async {
    final id = '${item.id}';
    state = state.copyWith(importingId: id);

    try {
      // Download to temp first, then copy to persistent storage
      final tmpDir = await getTemporaryDirectory();
      final ext = item.extension as String;
      final tempPath = '${tmpDir.path}/pixabay_$id.$ext';

      final String url;
      if (item is PixabayImage) {
        url = item.largeImageURL.isNotEmpty ? item.largeImageURL : item.webformatURL;
      } else {
        url = (item as PixabayVideo).downloadUrl;
      }

      await _dio.download(url, tempPath);

      // Copy to persistent storage
      final persistentPath = await PersistentMediaStore.persistFile(tempPath);

      // Clean up temp file
      final tempFile = File(tempPath);
      if (await tempFile.exists()) await tempFile.delete();

      state = state.copyWith(clearImporting: true);
      return persistentPath;
    } catch (e) {
      state = state.copyWith(clearImporting: true, error: 'Download failed: $e');
      return null;
    }
  }

  Future<List<dynamic>> _fetchPage(String q, PixabayMediaType type, int page) async {
    if (type == PixabayMediaType.images) {
      return _service.searchImages(query: q, page: page);
    } else {
      return _service.searchVideos(query: q, page: page);
    }
  }

  void cancel() {
    _debounceTimer?.cancel();
  }
}

final pixabayProvider = NotifierProvider<PixabayNotifier, PixabayState>(() => PixabayNotifier());
