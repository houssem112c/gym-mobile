import '../services/api_service.dart';
import '../services/feed_service.dart';
import '../config/api_config.dart';

class UserSearchResult {
  final String id;
  final String name;
  final String? avatar;
  final String email;

  UserSearchResult({
    required this.id,
    required this.name,
    this.avatar,
    required this.email,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'],
      email: json['email'],
    );
  }
}

class UserProfile {
  final String id;
  final String name;
  final String? avatar;
  final String? bio;
  final String role;
  final int postCount;
  final int friendsCount;

  UserProfile({
    required this.id,
    required this.name,
    this.avatar,
    this.bio,
    required this.role,
    required this.postCount,
    required this.friendsCount,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'],
      bio: json['bio'],
      role: json['role'],
      postCount: json['_count']['feedPosts'] ?? 0,
      friendsCount: (json['_count']['sentRequests'] ?? 0) + (json['_count']['receivedRequests'] ?? 0),
    );
  }
}

class FriendRequest {
  final String id;
  final String requesterId;
  final String requesterName;
  final String? requesterAvatar;
  final String requesterEmail;

  FriendRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    this.requesterAvatar,
    required this.requesterEmail,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    final requester = json['requester'];
    return FriendRequest(
      id: json['id'],
      requesterId: json['requesterId'],
      requesterName: requester['name'],
      requesterAvatar: requester['avatar'],
      requesterEmail: requester['email'],
    );
  }
}

class FriendUser {
  final String id;
  final String name;
  final String? avatar;

  FriendUser({
    required this.id,
    required this.name,
    this.avatar,
  });

  factory FriendUser.fromJson(Map<String, dynamic> json) {
    return FriendUser(
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'],
    );
  }
}

class SocialService {
  final ApiService _apiService = ApiService();

  Future<List<UserSearchResult>> searchUsers(String token, String query) async {
    final response = await _apiService.get(
      'users/search',
      queryParameters: {'q': query},
      headers: {'Authorization': 'Bearer $token'},
    );
    final List<dynamic> data = response.data;
    return data.map((json) => UserSearchResult.fromJson(json)).toList();
  }

  Future<List<FriendRequest>> getPendingRequests(String token) async {
    final response = await _apiService.get(
      'friendships/pending',
      headers: {'Authorization': 'Bearer $token'},
    );
    final List<dynamic> data = response.data;
    return data.map((json) => FriendRequest.fromJson(json)).toList();
  }

  Future<List<FriendUser>> getFriends(String token) async {
    final response = await _apiService.get(
      'friendships/friends',
      headers: {'Authorization': 'Bearer $token'},
    );
    final List<dynamic> data = response.data;
    return data.map((json) => FriendUser.fromJson(json)).toList();
  }

  Future<UserProfile> getUserProfile(String token, String userId) async {
    final response = await _apiService.get(
      'users/profile/$userId',
      headers: {'Authorization': 'Bearer $token'},
    );
    return UserProfile.fromJson(response.data);
  }

  Future<List<FeedPost>> getUserPosts(String token, String userId) async {
    final response = await _apiService.get(
      'feed/user/$userId',
      headers: {'Authorization': 'Bearer $token'},
    );
    final List<dynamic> data = response.data;
    return data.map((json) => FeedPost.fromJson(json, "")).toList(); // userId not needed for parsing list
  }

  Future<void> sendFriendRequest(String token, String userId) async {
    await _apiService.post(
      'friendships/request/$userId',
      data: {},
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<void> acceptFriendRequest(String token, String requestId) async {
    await _apiService.post(
      'friendships/accept/$requestId',
      data: {},
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<void> declineFriendRequest(String token, String requestId) async {
    await _apiService.post(
      'friendships/decline/$requestId',
      data: {},
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<Map<String, dynamic>?> getFriendshipStatus(String token, String userId) async {
    final response = await _apiService.get(
      'friendships/status/$userId',
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.data;
  }
}
