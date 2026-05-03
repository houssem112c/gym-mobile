import '../config/api_config.dart';
import 'api_service.dart';

enum NotificationType {
  POST_CREATED,
  POST_SHARED,
  STORY_CREATED,
  FRIEND_REQUEST,
  FRIEND_ACCEPTED,
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String actorId;
  final String? referenceId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.actorId,
    this.referenceId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['userId'],
      type: _parseType(json['type']),
      actorId: json['actorId'],
      referenceId: json['referenceId'],
      title: json['title'],
      message: json['message'],
      isRead: json['isRead'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  static NotificationType _parseType(String type) {
    switch (type) {
      case 'POST_CREATED':
        return NotificationType.POST_CREATED;
      case 'POST_SHARED':
        return NotificationType.POST_SHARED;
      case 'STORY_CREATED':
        return NotificationType.STORY_CREATED;
      case 'FRIEND_REQUEST':
        return NotificationType.FRIEND_REQUEST;
      case 'FRIEND_ACCEPTED':
        return NotificationType.FRIEND_ACCEPTED;
      default:
        return NotificationType.POST_CREATED;
    }
  }
}

class NotificationService {
  final ApiService _apiService = ApiService();

  Future<List<NotificationModel>> getNotifications(String token) async {
    final response = await _apiService.get(
      '/notifications',
      headers: {'Authorization': 'Bearer $token'},
    );
    final List<dynamic> data = response.data;
    return data.map((json) => NotificationModel.fromJson(json)).toList();
  }

  Future<void> markAsRead(String token, String notificationId) async {
    await _apiService.patch(
      '/notifications/$notificationId/read',
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<void> markAllAsRead(String token) async {
    await _apiService.patch(
      '/notifications/read-all',
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<void> deleteNotification(String token, String notificationId) async {
    await _apiService.delete(
      '/notifications/$notificationId',
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}
