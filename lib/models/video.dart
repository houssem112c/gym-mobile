class VideoCategory {
  final String id;
  final String name;
  final String? description;
  final String slug;
  final int order;
  final List<Video>? videos;

  VideoCategory({
    required this.id,
    required this.name,
    this.description,
    required this.slug,
    required this.order,
    this.videos,
  });

  factory VideoCategory.fromJson(Map<String, dynamic> json) {
    return VideoCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      slug: json['slug'],
      order: json['order'],
      videos: json['videos'] != null
          ? (json['videos'] as List).map((v) => Video.fromJson(v)).toList()
          : null,
    );
  }
}

class Video {
  final String id;
  final String title;
  final String? description;
  final String url;
  final String? thumbnail;
  final int? duration;
  final String categoryId;
  final VideoCategory? category;
  final int order;
  final bool isPublished;

  Video({
    required this.id,
    required this.title,
    this.description,
    required this.url,
    this.thumbnail,
    this.duration,
    required this.categoryId,
    this.category,
    required this.order,
    required this.isPublished,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Video',
      description: json['description']?.toString(),
      url: json['url']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString(),
      duration: json['duration'] is int ? json['duration'] : 
                json['duration'] is String ? int.tryParse(json['duration']) : null,
      categoryId: json['categoryId']?.toString() ?? '',
      category: json['category'] != null
          ? VideoCategory.fromJson(json['category'])
          : null,
      order: json['order'] is int ? json['order'] : 
             json['order'] is String ? int.tryParse(json['order']) ?? 0 : 0,
      isPublished: json['isPublished'] == true || json['isPublished'] == 'true',
    );
  }

  String get formattedDuration {
    if (duration == null) return '';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}
