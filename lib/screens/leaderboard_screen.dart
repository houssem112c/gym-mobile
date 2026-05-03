import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/gamification_provider.dart';
import '../config/colors.dart';
import '../widgets/premium_card.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface950,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('leaderboard_title'.tr()),
      ),
      body: Consumer<GamificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.leaderboard.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final players = provider.leaderboard;

          if (players.isEmpty) {
            return Center(child: Text('no_data'.tr()));
          }

          return Column(
            children: [
              const SizedBox(height: 20),
              _buildTopThree(context, players),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface900.withOpacity(0.5),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    itemCount: players.length > 3 ? players.length - 3 : 0,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final player = players[index + 3];
                      final user = player['user'];
                      final isMe = user['id'] == Provider.of<GamificationProvider>(context, listen: false).userGamification?.userId;

                      return _buildLeaderboardTile(context, index + 4, player, isMe);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopThree(BuildContext context, List<Map<String, dynamic>> players) {
    if (players.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd Place
        if (players.length > 1)
          _buildTopPlayer(context, players[1], 2, 100),
        const SizedBox(width: 12),
        // 1st Place
        if (players.length > 0)
          _buildTopPlayer(context, players[0], 1, 140),
        const SizedBox(width: 12),
        // 3rd Place
        if (players.length > 2)
          _buildTopPlayer(context, players[2], 3, 90),
      ],
    );
  }

  Widget _buildTopPlayer(BuildContext context, Map<String, dynamic> player, int rank, double height) {
    final user = player['user'];
    Color ribbonColor;
    switch (rank) {
      case 1: ribbonColor = Colors.amber; break;
      case 2: ribbonColor = Colors.grey[300]!; break;
      case 3: ribbonColor = Colors.brown[300]!; break;
      default: ribbonColor = Colors.grey;
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: height * 0.6,
              height: height * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ribbonColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: ribbonColor.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: AppColors.gray800,
                backgroundImage: user['avatar'] != null ? NetworkImage(user['avatar']) : null,
                child: user['avatar'] == null ? const Icon(Icons.person, color: Colors.white70) : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: ribbonColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          user['name'] ?? 'Anonymous',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          '${player['totalXp']} XP',
          style: TextStyle(
            color: AppColors.primary400,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTile(BuildContext context, int rank, Map<String, dynamic> player, bool isMe) {
    final user = player['user'];

    return PremiumCard(
      color: isMe ? AppColors.primary500.withOpacity(0.1) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '$rank',
                style: TextStyle(
                  color: AppColors.gray400,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.gray800,
              backgroundImage: user['avatar'] != null ? NetworkImage(user['avatar']) : null,
              child: user['avatar'] == null ? const Icon(Icons.person, color: Colors.white70, size: 18) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'] ?? 'Anonymous',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Level ${player['level']}',
                    style: TextStyle(
                      color: AppColors.gray400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${player['totalXp']} XP',
              style: TextStyle(
                color: AppColors.primary400,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
