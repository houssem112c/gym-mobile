import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/colors.dart';
import '../widgets/gradient_background.dart';
import '../widgets/premium_card.dart';
import '../services/social_service.dart';
import '../services/auth_service.dart';
import 'user_profile_screen.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final SocialService _socialService = SocialService();
  final TextEditingController _searchController = TextEditingController();
  List<UserSearchResult> _searchResults = [];
  bool _isLoading = false;

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthService>();
      final results = await _socialService.searchUsers(auth.accessToken!, query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.gray900.withOpacity(0.8),
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search users...',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
          onChanged: _performSearch,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
            ),
        ],
      ),
      body: GradientBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _searchResults.isEmpty
                ? const Center(child: Text('Search for users to add friends', style: TextStyle(color: Colors.white60)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return PremiumCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserProfileScreen(userId: user.id, userName: user.name),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary500,
                            backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
                            child: user.avatar == null ? Text(user.name[0].toUpperCase()) : null,
                          ),
                          title: Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text(user.email, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
