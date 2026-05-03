class UserGamification {
  final String id;
  final String userId;
  final int totalXp;
  final int totalPoints;
  final int level;
  final int postsCount;
  final int ordersCount;
  final int coursesCount;
  final int commentsCount;
  final int likesCount;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastLoginDate;
  final int xpToNextLevel;
  final int currentLevelXp;
  final double progress;

  UserGamification({
    required this.id,
    required this.userId,
    required this.totalXp,
    required this.totalPoints,
    required this.level,
    required this.postsCount,
    required this.ordersCount,
    required this.coursesCount,
    required this.commentsCount,
    required this.likesCount,
    required this.currentStreak,
    required this.longestStreak,
    this.lastLoginDate,
    required this.xpToNextLevel,
    required this.currentLevelXp,
    required this.progress,
  });

  factory UserGamification.fromJson(Map<String, dynamic> json) {
    return UserGamification(
      id: json['id'],
      userId: json['userId'],
      totalXp: json['totalXp'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
      level: json['level'] ?? 1,
      postsCount: json['postsCount'] ?? 0,
      ordersCount: json['ordersCount'] ?? 0,
      coursesCount: json['coursesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      likesCount: json['likesCount'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      lastLoginDate: json['lastLoginDate'] != null ? DateTime.parse(json['lastLoginDate']) : null,
      xpToNextLevel: json['xpToNextLevel'] ?? 100,
      currentLevelXp: json['currentLevelXp'] ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Badge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category;
  final int requirement;
  final int xpReward;
  final DateTime? earnedAt;
  final bool isEarned;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.requirement,
    required this.xpReward,
    this.earnedAt,
    this.isEarned = false,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    // If it comes from user badges, it has a 'badge' field
    final badgeData = json['badge'] ?? json;
    return Badge(
      id: badgeData['id'],
      name: badgeData['name'],
      description: badgeData['description'],
      icon: badgeData['icon'],
      category: badgeData['category'],
      requirement: badgeData['requirement'],
      xpReward: badgeData['xpReward'],
      earnedAt: json['earnedAt'] != null ? DateTime.parse(json['earnedAt']) : null,
      isEarned: json['earnedAt'] != null,
    );
  }
}

class XpTransaction {
  final String id;
  final int amount;
  final String action;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  XpTransaction({
    required this.id,
    required this.amount,
    required this.action,
    this.description,
    this.metadata,
    required this.createdAt,
  });

  factory XpTransaction.fromJson(Map<String, dynamic> json) {
    return XpTransaction(
      id: json['id'],
      amount: json['amount'],
      action: json['action'],
      description: json['description'],
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
