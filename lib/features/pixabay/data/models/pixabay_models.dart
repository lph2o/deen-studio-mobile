class PixabayImage {
  final int id;
  final String previewURL;
  final String webformatURL;
  final String largeImageURL;
  final String tags;
  final String user;
  final int views;
  final int likes;
  final int downloads;
  final int imageWidth;
  final int imageHeight;

  PixabayImage({
    required this.id,
    required this.previewURL,
    required this.webformatURL,
    required this.largeImageURL,
    required this.tags,
    required this.user,
    required this.views,
    required this.likes,
    required this.downloads,
    required this.imageWidth,
    required this.imageHeight,
  });

  factory PixabayImage.fromJson(Map<String, dynamic> json) {
    return PixabayImage(
      id: json['id'] ?? 0,
      previewURL: json['previewURL'] ?? '',
      webformatURL: json['webformatURL'] ?? '',
      largeImageURL: json['largeImageURL'] ?? '',
      tags: json['tags'] ?? '',
      user: json['user'] ?? '',
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      downloads: json['downloads'] ?? 0,
      imageWidth: json['imageWidth'] ?? 0,
      imageHeight: json['imageHeight'] ?? 0,
    );
  }

  bool get isPortrait => imageHeight > imageWidth;
  String get extension => 'jpg';
}

class PixabayVideo {
  final int id;
  final String tags;
  final String user;
  final String thumbnailUrl;
  final String mediumUrl;
  final String smallUrl;
  final int views;
  final int likes;
  final int downloads;

  PixabayVideo({
    required this.id,
    required this.tags,
    required this.user,
    required this.thumbnailUrl,
    required this.mediumUrl,
    required this.smallUrl,
    required this.views,
    required this.likes,
    required this.downloads,
  });

  factory PixabayVideo.fromJson(Map<String, dynamic> json) {
    final vids = json['videos'] ?? {};
    final medium = vids['medium'] ?? {};
    final small = vids['small'] ?? {};
    final tiny = vids['tiny'] ?? {};
    
    final thumbnailUrl = medium['thumbnail'] ?? small['thumbnail'] ?? tiny['thumbnail'] ?? '';
    final mediumUrl = medium['url'] ?? small['url'] ?? tiny['url'] ?? '';
    final smallUrl = small['url'] ?? tiny['url'] ?? '';

    return PixabayVideo(
      id: json['id'] ?? 0,
      tags: json['tags'] ?? '',
      user: json['user'] ?? '',
      thumbnailUrl: thumbnailUrl,
      mediumUrl: mediumUrl,
      smallUrl: smallUrl,
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      downloads: json['downloads'] ?? 0,
    );
  }

  String get extension => 'mp4';
  String get downloadUrl => mediumUrl.isNotEmpty ? mediumUrl : smallUrl;
}

enum PixabayMediaType { images, videos }
