import '../services/api_service.dart';
import '../config/api_config.dart';

class FeedPost {
  final String id;
  final String userId;
  final String? content;
  final List<String> mediaUrls;
  final String userName;
  final String? userAvatar;
  final int likesCount;
  final int commentsCount;
   final bool isLikedByMe;
   final DateTime createdAt;
   final FeedPost? sharedPost;
 
   FeedPost({
     required this.id,
     required this.userId,
     this.content,
     required this.mediaUrls,
     required this.userName,
     this.userAvatar,
     required this.likesCount,
     required this.commentsCount,
     required this.isLikedByMe,
     required this.createdAt,
     this.sharedPost,
   });

  factory FeedPost.fromJson(Map<String, dynamic> json, String currentUserId) {
    final user = json['user'];
    final likes = json['likes'] as List<dynamic>? ?? [];
    final media = json['media'] as List<dynamic>? ?? [];
    
    return FeedPost(
      id: json['id'],
      userId: json['userId'] ?? user['id'],
      content: json['content'],
      mediaUrls: media.map((m) => m['url'] as String).toList(),
      userName: user['name'],
      userAvatar: user['avatar'],
      likesCount: json['_count']?['likes'] ?? 0,
      commentsCount: json['_count']?['comments'] ?? 0,
      isLikedByMe: likes.any((like) => like['userId'] == currentUserId),
      createdAt: DateTime.parse(json['createdAt']),
      sharedPost: json['sharedPost'] != null 
          ? FeedPost.fromJson(json['sharedPost'], currentUserId) 
          : null,
    );
  }
}

class FeedComment {
  final String id;
  final String content;
  final String userName;
  final String? userAvatar;
  final DateTime createdAt;

  FeedComment({
    required this.id,
    required this.content,
    required this.userName,
    this.userAvatar,
    required this.createdAt,
  });

  factory FeedComment.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return FeedComment(
      id: json['id'],
      content: json['content'],
      userName: user['name'],
      userAvatar: user['avatar'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class FeedService {
  final ApiService _apiService = ApiService();

  Future<List<FeedPost>> getFeed(String currentUserId, String token) async {
    final response = await _apiService.get(
      ApiConfig.feed,
      headers: {'Authorization': 'Bearer $token'},
    );
    final List<dynamic> data = response.data;
    return data.map((json) => FeedPost.fromJson(json, currentUserId)).toList();
  }

  Future<FeedPost> getPostById(String token, String postId, {required String currentUserId}) async {
    final response = await _apiService.get(
      '${ApiConfig.feed}/$postId',
      headers: {'Authorization': 'Bearer $token'},
    );
    return FeedPost.fromJson(response.data, currentUserId);
  }

  Future<FeedPost> createPost(String token, String content, {List<String>? mediaUrls}) async {
    final response = await _apiService.post(
      ApiConfig.feed,
      data: {
        'content': content,
        'mediaUrls': mediaUrls ?? [],
      },
      headers: {'Authorization': 'Bearer $token'},
    );
    return FeedPost.fromJson(response.data, response.data['userId'] ?? ""); 
  }

  Future<void> likePost(String token, String postId) async {
    await _apiService.post(
      '${ApiConfig.feed}/$postId/like', 
      data: {},
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<void> unlikePost(String token, String postId) async {
    await _apiService.delete(
      '${ApiConfig.feed}/$postId/like',
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<List<FeedComment>> getComments(String token, String postId) async {
    final response = await _apiService.get(
      '${ApiConfig.feed}/$postId/comments',
      headers: {'Authorization': 'Bearer $token'},
    );
    final List<dynamic> data = response.data;
    return data.map((json) => FeedComment.fromJson(json)).toList();
  }

  Future<void> addComment(String token, String postId, String content) async {
    await _apiService.post(
      '${ApiConfig.feed}/$postId/comments',
      data: {'content': content},
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<FeedPost> sharePost(String token, String originalPostId, {String? content}) async {
    final response = await _apiService.post(
      '${ApiConfig.feed}/$originalPostId/share',
      data: {
        'content': content,
      },
      headers: {'Authorization': 'Bearer $token'},
    );
    return FeedPost.fromJson(response.data, ""); // userId will be filled in fromJson
  }

  Future<void> sharePostToFriend(String token, String postId, String friendId) async {
    await _apiService.post(
      '${ApiConfig.feed}/$postId/share-to-friend/$friendId',
      data: {},
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}
