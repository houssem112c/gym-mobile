import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/colors.dart';
import '../widgets/premium_card.dart';
import '../widgets/gradient_background.dart';
import '../services/social_service.dart';
import '../services/auth_service.dart';
import '../services/feed_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const UserProfileScreen({super.key, required this.userId, required this.userName});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final SocialService _socialService = SocialService();
  final FeedService _feedService = FeedService();
  UserProfile? _profile;
  List<FeedPost> _userPosts = [];
  Map<String, dynamic>? _friendshipStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthService>();
      final profile = await _socialService.getUserProfile(auth.accessToken!, widget.userId);
      final posts = await _socialService.getUserPosts(auth.accessToken!, widget.userId);
      final status = await _socialService.getFriendshipStatus(auth.accessToken!, widget.userId);

      setState(() {
        _profile = profile;
        _userPosts = posts;
        _friendshipStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFriendAction() async {
    final auth = context.read<AuthService>();
    if (_friendshipStatus == null) {
      await _socialService.sendFriendRequest(auth.accessToken!, widget.userId);
    } else if (_friendshipStatus!['status'] == 'PENDING' && _friendshipStatus!['addresseeId'] == auth.user!['id']) {
      await _socialService.acceptFriendRequest(auth.accessToken!, _friendshipStatus!['id']);
    }
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.userName, style: const TextStyle(color: Colors.white)),
      ),
      body: GradientBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildFriendshipButton(),
                      const SizedBox(height: 32),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Posts', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      _userPosts.isEmpty
                          ? const Center(child: Text('No posts yet', style: TextStyle(color: Colors.white60)))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _userPosts.length,
                              itemBuilder: (context, index) => _buildMiniPost(_userPosts[index]),
                            ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: AppColors.primary500,
          backgroundImage: _profile?.avatar != null ? NetworkImage(_profile!.avatar!) : null,
          child: _profile?.avatar == null ? Text(widget.userName[0].toUpperCase(), style: const TextStyle(fontSize: 32, color: Colors.white)) : null,
        ),
        const SizedBox(height: 16),
        Text(_profile?.name ?? widget.userName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        if (_profile?.bio != null) ...[
          const SizedBox(height: 8),
          Text(_profile!.bio!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatItem('Posts', _profile?.postCount ?? 0),
            const SizedBox(width: 40),
            _buildStatItem('Friends', _profile?.friendsCount ?? 0),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    );
  }

  Widget _buildFriendshipButton() {
    final auth = context.read<AuthService>();
    String text = 'Add Friend';
    Color color = AppColors.primary500;
    bool enabled = true;

    if (_friendshipStatus != null) {
      final status = _friendshipStatus!['status'];
      if (status == 'ACCEPTED') {
        text = 'Friends';
        color = AppColors.gray700;
        enabled = false;
      } else if (status == 'PENDING') {
        if (_friendshipStatus!['requesterId'] == auth.user!['id']) {
          text = 'Request Sent';
          color = AppColors.gray700;
          enabled = false;
        } else {
          text = 'Accept Request';
          color = AppColors.primary500;
        }
      }
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? _handleFriendAction : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMiniPost(FeedPost post) {
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.mediaUrls.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: post.mediaUrls[0],
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.content != null)
                  Text(post.content!, style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.favorite_border, color: Colors.white54, size: 16),
                    const SizedBox(width: 4),
                    Text(post.likesCount.toString(), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(width: 16),
                    const Icon(Icons.chat_bubble_outline, color: Colors.white54, size: 16),
                    const SizedBox(width: 4),
                    Text(post.commentsCount.toString(), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    const Spacer(),
                    Text(DateFormat.yMMMd().format(post.createdAt), style: const TextStyle(color: Colors.white24, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
