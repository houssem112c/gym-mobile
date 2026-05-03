import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/feed_service.dart';
import '../config/colors.dart';
import '../widgets/premium_card.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final FeedService _feedService = FeedService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  void _showSharedPostPreview(String token, String currentUserId, String postId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: FutureBuilder<FeedPost>(
                future: _feedService.getPostById(token, postId, currentUserId: currentUserId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading post: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final post = snapshot.data;
                  if (post == null) {
                    return const Center(child: Text('Post not found', style: TextStyle(color: Colors.white70)));
                  }

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary,
                              backgroundImage: post.userAvatar != null ? NetworkImage(post.userAvatar!) : null,
                              child: post.userAvatar == null
                                  ? Text(post.userName.isNotEmpty ? post.userName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white))
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(post.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  Text(DateFormat('MMM dd, HH:mm').format(post.createdAt), style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close, color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (post.content != null && post.content!.isNotEmpty)
                          Text(post.content!, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        if (post.mediaUrls.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: post.mediaUrls[0],
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(height: 220, color: Colors.black12),
                              errorWidget: (context, url, error) => Container(height: 220, color: Colors.black12),
                            ),
                          ),
                        ],
                        if (post.sharedPost != null) ...[
                          const SizedBox(height: 16),
                          Text('Shared original post:', style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post.sharedPost!.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                if (post.sharedPost!.content != null && post.sharedPost!.content!.isNotEmpty)
                                  Text(post.sharedPost!.content!, style: const TextStyle(color: Colors.white70)),
                                if (post.sharedPost!.mediaUrls.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: CachedNetworkImage(
                                      imageUrl: post.sharedPost!.mediaUrls[0],
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(height: 180, color: Colors.black12),
                                      errorWidget: (context, url, error) => Container(height: 180, color: Colors.black12),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.accessToken == null) return;

    try {
      final notifications = await _notificationService.getNotifications(authService.accessToken!);
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notifications: $e')),
        );
      }
    }
  }

  Future<void> _markAsRead(String id) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await _notificationService.markAsRead(authService.accessToken!, id);
      _loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking as read: $e')),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await _notificationService.markAllAsRead(authService.accessToken!);
      _loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteNotification(String id) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await _notificationService.deleteNotification(authService.accessToken!, id);
      _loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting notification: $e')),
        );
      }
    }
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.POST_CREATED:
        return Icons.post_add_rounded;
      case NotificationType.POST_SHARED:
        return Icons.send_rounded;
      case NotificationType.STORY_CREATED:
        return Icons.auto_stories_rounded;
      case NotificationType.FRIEND_REQUEST:
        return Icons.person_add_rounded;
      case NotificationType.FRIEND_ACCEPTED:
        return Icons.how_to_reg_rounded;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.POST_CREATED:
        return Colors.blueAccent;
      case NotificationType.POST_SHARED:
        return AppColors.primary;
      case NotificationType.STORY_CREATED:
        return Colors.purpleAccent;
      case NotificationType.FRIEND_REQUEST:
        return Colors.orangeAccent;
      case NotificationType.FRIEND_ACCEPTED:
        return Colors.greenAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all as read', style: TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              Colors.black,
              Colors.black,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none_rounded, size: 80, color: Colors.white.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        const Text(
                          'No notifications yet',
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 120, 16, 16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return PremiumCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: notification.isRead ? Colors.transparent : AppColors.primary.withOpacity(0.05),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _getIconColor(notification.type).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_getIcon(notification.type), color: _getIconColor(notification.type)),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (!notification.isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  notification.message,
                                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  DateFormat('MMM dd, HH:mm').format(notification.createdAt),
                                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                                ),
                              ],
                            ),
                            onTap: () {
                              final auth = Provider.of<AuthService>(context, listen: false);

                              if (!notification.isRead) {
                                _markAsRead(notification.id);
                              }

                              if (notification.type == NotificationType.POST_SHARED &&
                                  notification.referenceId != null &&
                                  auth.accessToken != null &&
                                  auth.user != null) {
                                _showSharedPostPreview(
                                  auth.accessToken!,
                                  auth.user!['id'],
                                  notification.referenceId!,
                                );
                              }
                            },
                            onLongPress: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.grey[900],
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                builder: (context) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.delete_outline, color: Colors.red),
                                      title: const Text('Delete Notification', style: TextStyle(color: Colors.white)),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _deleteNotification(notification.id);
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
