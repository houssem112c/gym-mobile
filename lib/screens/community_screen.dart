import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/colors.dart';
import '../config/supabase_config.dart';
import '../widgets/gradient_background.dart';
import '../widgets/premium_card.dart';
import '../services/feed_service.dart';
import '../services/social_service.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import 'search_users_screen.dart';
import 'user_profile_screen.dart';
import 'friend_requests_screen.dart';
import 'notifications_screen.dart';
import '../services/notification_service.dart';
import 'dart:async';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final FeedService _feedService = FeedService();
  final SocialService _socialService = SocialService();
  final SupabaseService _supabaseService = SupabaseService();
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true;
  List<FeedPost> _posts = [];
  int _unreadNotificationsCount = 0;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _loadUnreadCount();
    // Refresh unread count every 30 seconds
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadUnreadCount();
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final auth = context.read<AuthService>();
      if (auth.accessToken == null) return;
      
      final notifications = await _notificationService.getNotifications(auth.accessToken!);
      final unreadCount = notifications.where((n) => !n.isRead).length;
      
      if (mounted) {
        setState(() {
          _unreadNotificationsCount = unreadCount;
        });
      }
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  Future<void> _loadFeed() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthService>();
      final posts = await _feedService.getFeed(auth.user!['id'], auth.accessToken!);
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showCreatePostDialog() async {
    final controller = TextEditingController();
    final ImagePicker picker = ImagePicker();
    List<XFile> selectedImages = [];
    bool isPosting = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          scrollable: true,
          backgroundColor: AppColors.gray800,
          title: Text('community_create_post'.tr(), style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'community_write_caption'.tr(),
                  hintStyle: TextStyle(color: AppColors.gray400),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 12),
              if (selectedImages.isNotEmpty)
                SizedBox(
                  height: 100,
                  width: 300, // Give it a defined width for horizontal scroll
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: selectedImages.asMap().entries.map((entry) {
                        final index = entry.key;
                        final file = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              if (kIsWeb)
                                Image.network(
                                  file.path,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                              else
                                Image.file(
                                  File(file.path),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () => setModalState(() => selectedImages.removeAt(index)),
                                  child: Container(
                                    color: Colors.black54,
                                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () async {
                  final List<XFile> images = await picker.pickMultiImage();
                  if (images.isNotEmpty) {
                    setModalState(() {
                      selectedImages.addAll(images);
                    });
                  }
                },
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text('community_add_photos'.tr()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('common_cancel'.tr()),
            ),
            isPosting 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : ElevatedButton(
                  onPressed: () async {
                    if (controller.text.trim().isNotEmpty || selectedImages.isNotEmpty) {
                      setModalState(() => isPosting = true);
                      List<String> mediaUrls = [];
                      if (selectedImages.isNotEmpty) {
                        final auth = context.read<AuthService>();
                        mediaUrls = await _supabaseService.uploadMultipleImages(
                          selectedImages, 
                          SupabaseConfig.feedBucket,
                          auth.user!['id'],
                        );
                      }
                      final auth = context.read<AuthService>();
                      await _feedService.createPost(auth.accessToken!, controller.text.trim(), mediaUrls: mediaUrls);
                      if (mounted) {
                        Navigator.pop(context);
                        _loadFeed();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary500),
                  child: Text('community_share'.tr()),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSharePostDialog(FeedPost originalPost) async {
    final controller = TextEditingController();
    bool isSharing = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.gray800,
          title: Text('community_share_post'.tr(), style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'community_say_something'.tr(),
                  hintStyle: TextStyle(color: AppColors.gray400),
                  border: InputBorder.none,
                ),
              ),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              Row(
                children: [
                   const Icon(Icons.reply, color: AppColors.primary500, size: 16),
                   const SizedBox(width: 8),
                   Expanded(
                     child: Text(
                       'Sharing ${originalPost.userName}\'s post',
                       style: TextStyle(color: AppColors.gray400, fontSize: 12),
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                     ),
                   ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('common_cancel'.tr()),
            ),
            isSharing 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : ElevatedButton(
                  onPressed: () async {
                    setModalState(() => isSharing = true);
                    final auth = context.read<AuthService>();
                    await _feedService.sharePost(
                      auth.accessToken!, 
                      originalPost.id, 
                      content: controller.text.trim().isNotEmpty ? controller.text.trim() : null
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      _loadFeed();
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary500),
                  child: Text('community_share'.tr()),
                ),
          ],
        ),
      ),
    );
  }

  void _showShareOptions(FeedPost post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply, color: AppColors.primary500),
                title: Text('community_share'.tr(), style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showSharePostDialog(post);
                },
              ),
              ListTile(
                leading: const Icon(Icons.send_outlined, color: Colors.white),
                title: Text('community_send_to_friend'.tr(), style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showShareToFriendSheet(post);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showShareToFriendSheet(FeedPost post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'community_select_friend'.tr(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: FutureBuilder<List<FriendUser>>(
                      future: _socialService.getFriends(context.read<AuthService>().accessToken!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: AppColors.primary500));
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              '${'common_error'.tr()}: ${snapshot.error}',
                              style: const TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        final friends = snapshot.data ?? [];
                        if (friends.isEmpty) {
                          return Center(
                            child: Text(
                              'community_no_friends'.tr(),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: friends.length,
                          separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
                          itemBuilder: (context, index) {
                            final friend = friends[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary500,
                                backgroundImage: friend.avatar != null ? NetworkImage(friend.avatar!) : null,
                                child: friend.avatar == null
                                    ? Text(friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white))
                                    : null,
                              ),
                              title: Text(friend.name, style: const TextStyle(color: Colors.white)),
                              trailing: const Icon(Icons.send, color: AppColors.primary500),
                              onTap: () async {
                                final auth = context.read<AuthService>();
                                try {
                                  await _feedService.sharePostToFriend(auth.accessToken!, post.id, friend.id);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('community_sent_to_friend'.tr(args: [friend.name]))),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${'common_error'.tr()}: $e')),
                                    );
                                  }
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        backgroundColor: AppColors.primary500,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'community_title'.tr(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Stack(
                            children: [
                              const Icon(Icons.notifications_none_rounded, color: Colors.white),
                              if (_unreadNotificationsCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: AppColors.red500,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 12,
                                      minHeight: 12,
                                    ),
                                    child: Text(
                                      _unreadNotificationsCount > 9 ? '9+' : '$_unreadNotificationsCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                            );
                            _loadUnreadCount(); // Refresh count when coming back
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.people_outline, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const FriendRequestsScreen()),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SearchUsersScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadFeed,
                        color: AppColors.primary500,
                        child: _posts.isEmpty
                            ? Center(child: Text('community_no_posts'.tr(), style: const TextStyle(color: Colors.white60)))
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                                itemCount: _posts.length,
                                itemBuilder: (context, index) {
                                  return _buildInstagramPost(_posts[index]);
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstagramPost(FeedPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.gray900.withOpacity(0.5),
        border: Border(
           top: BorderSide(color: Colors.white.withOpacity(0.05)),
           bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfileScreen(
                      userId: post.userId,
                      userName: post.userName,
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary500,
                    backgroundImage: post.userAvatar != null ? NetworkImage(post.userAvatar!) : null,
                    child: post.userAvatar == null ? Text(post.userName[0].toUpperCase(), style: const TextStyle(color: Colors.white)) : null,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(DateFormat.MMMd().format(post.createdAt), style: TextStyle(color: AppColors.gray500, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (post.sharedPost != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.primary500,
                          backgroundImage: post.sharedPost!.userAvatar != null ? NetworkImage(post.sharedPost!.userAvatar!) : null,
                          child: post.sharedPost!.userAvatar == null ? Text(post.sharedPost!.userName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10)) : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          post.sharedPost!.userName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'community_original_post'.tr(),
                          style: TextStyle(color: AppColors.gray500, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (post.sharedPost!.content != null)
                      Text(
                        post.sharedPost!.content!,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    if (post.sharedPost!.mediaUrls.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: post.sharedPost!.mediaUrls[0],
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Media (Carousel)
          if (post.mediaUrls.isNotEmpty)
            _buildMediaCarousel(post.mediaUrls),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _buildActionIcon(
                  post.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                  post.isLikedByMe ? AppColors.red500 : Colors.white,
                  () async {
                    final auth = context.read<AuthService>();
                    if (post.isLikedByMe) {
                      await _feedService.unlikePost(auth.accessToken!, post.id);
                    } else {
                      await _feedService.likePost(auth.accessToken!, post.id);
                    }
                    _loadFeed();
                  },
                ),
                const SizedBox(width: 16),
                _buildActionIcon(Icons.chat_bubble_outline, Colors.white, () => _showCommentsModal(post.id)),
                const SizedBox(width: 16),
                if (post.sharedPost == null && post.userId != context.read<AuthService>().user!['id']) ...[
                  _buildActionIcon(Icons.send_outlined, Colors.white, () => _showShareOptions(post)),
                ],
                const Spacer(),
                if (post.mediaUrls.length > 1)
                  _buildCarouselIndicator(post.mediaUrls.length),
              ],
            ),
          ),

          // Likes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              '${post.likesCount} ${'community_likes'.tr()}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),

          // Caption
          if (post.content != null && post.content!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: post.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const TextSpan(text: ' '),
                    TextSpan(text: post.content!, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
            
          // View all comments
          if (post.commentsCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: GestureDetector(
                onTap: () => _showCommentsModal(post.id),
                child: Text(
                  '${'community_view_comments'.tr()} ${post.commentsCount} ${'community_comments'.tr()}',
                  style: TextStyle(color: AppColors.gray500, fontSize: 13),
                ),
              ),
            ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMediaCarousel(List<String> urls) {
    if (urls.length == 1) {
      return CachedNetworkImage(
        imageUrl: urls[0],
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(height: 300, color: AppColors.gray800),
      );
    }

    return SizedBox(
      height: 400,
      child: PageView.builder(
        itemCount: urls.length,
        itemBuilder: (context, index) => CachedNetworkImage(
          imageUrl: urls[index],
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: AppColors.gray800),
        ),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: 26),
    );
  }

  Widget _buildCarouselIndicator(int count) {
    return Row(
      children: List.generate(
        count,
        (index) => Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  void _showCommentsModal(String postId) {
    final commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.gray900,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            children: [
              Container(
                height: 4, width: 40, margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('community_comments'.tr(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: FutureBuilder<List<FeedComment>>(
                  future: _feedService.getComments(context.read<AuthService>().accessToken!, postId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text('community_no_comments'.tr(), style: const TextStyle(color: Colors.white60)));
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final comment = snapshot.data![index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary500,
                            backgroundImage: comment.userAvatar != null ? NetworkImage(comment.userAvatar!) : null,
                            child: comment.userAvatar == null ? Text(comment.userName[0].toUpperCase()) : null,
                          ),
                          title: Text(comment.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(comment.content, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          trailing: Text(DateFormat.MMMd().format(comment.createdAt), style: TextStyle(color: AppColors.gray500, fontSize: 10)),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'community_add_comment'.tr(),
                          hintStyle: TextStyle(color: AppColors.gray400),
                          fillColor: AppColors.gray800,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send, color: AppColors.primary500),
                      onPressed: () async {
                        if (commentController.text.trim().isNotEmpty) {
                          final auth = context.read<AuthService>();
                          await _feedService.addComment(auth.accessToken!, postId, commentController.text.trim());
                          commentController.clear();
                          setModalState(() {});
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
