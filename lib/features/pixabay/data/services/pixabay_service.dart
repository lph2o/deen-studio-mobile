import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/pixabay_models.dart';

class PixabayService {
  final Dio _dio;
  static const String _imageBase = 'https://pixabay.com/api/';
  static const String _videoBase = 'https://pixabay.com/api/videos/';

  PixabayService() : _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10)));

  String get _apiKey => dotenv.env['PIXABAY_API_KEY'] ?? '';

  Future<List<PixabayImage>> searchImages({
    required String query,
    int page = 1,
    int perPage = 30,
    String orientation = 'all',
  }) async {
    final response = await _dio.get(_imageBase, queryParameters: {
      'key': _apiKey,
      'q': query,
      'image_type': 'photo',
      'per_page': perPage,
      'page': page,
      if (orientation != 'all') 'orientation': orientation,
      'safesearch': 'true',
    });
    
    final hits = response.data['hits'] as List<dynamic>? ?? [];
    return hits.map((h) => PixabayImage.fromJson(h as Map<String, dynamic>)).toList();
  }

  Future<List<PixabayVideo>> searchVideos({
    required String query,
    int page = 1,
    int perPage = 30,
    String orientation = 'all',
  }) async {
    final response = await _dio.get(_videoBase, queryParameters: {
      'key': _apiKey,
      'q': query,
      'per_page': perPage,
      'page': page,
      if (orientation != 'all') 'orientation': orientation,
      'safesearch': 'true',
    });
    
    final hits = response.data['hits'] as List<dynamic>? ?? [];
    return hits.map((h) => PixabayVideo.fromJson(h as Map<String, dynamic>)).toList();
  }
}
