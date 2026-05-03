class Story {
  final String id;
  final String categoryId;
  final String mediaUrl;
  final String mediaType;
  final String? caption;
  final int duration;
  final DateTime? expiresAt;
  final bool isActive;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  Story({
    required this.id,
    required this.categoryId,
    required this.mediaUrl,
    required this.mediaType,
    this.caption,
    required this.duration,
    this.expiresAt,
    required this.isActive,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'],
      categoryId: json['categoryId'],
      mediaUrl: json['mediaUrl'],
      mediaType: json['mediaType'],
      caption: json['caption'],
      duration: json['duration'],
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      isActive: json['isActive'],
      order: json['order'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'caption': caption,
      'duration': duration,
      'expiresAt': expiresAt?.toIso8601String(),
      'isActive': isActive,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class StoryGroup {
  final Category category;
  final List<Story> stories;

  StoryGroup({
    required this.category,
    required this.stories,
  });

  factory StoryGroup.fromJson(Map<String, dynamic> json) {
    return StoryGroup(
      category: Category.fromJson(json['category']),
      stories: (json['stories'] as List)
          .map((story) => Story.fromJson(story))
          .toList(),
    );
  }
}

class Category {
  final String id;
  final String name;
  final String? description;
  final String? color;
  final String? icon;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.color,
    this.icon,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      color: json['color'],
      icon: json['icon'],
    );
  }
}
