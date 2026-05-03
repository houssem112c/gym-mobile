import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/gamification_provider.dart';
import '../config/colors.dart';
import '../widgets/premium_card.dart';
import '../models/gamification.dart' as model;
import 'badges_screen.dart';
import 'leaderboard_screen.dart';

class GamificationScreen extends StatelessWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface950,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'gamification_title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<GamificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.userGamification == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final gamification = provider.userGamification;
          if (gamification == null) {
            return Center(child: Text('no_data'.tr()));
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadData(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLevelCard(context, gamification),
                  const SizedBox(height: 24),
                  _buildStatsGrid(context, gamification),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    context,
                    'badges_title'.tr(),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BadgesScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRecentBadges(context, provider.myBadges),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    context,
                    'leaderboard_title'.tr(),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLeaderboardPreview(context, provider.leaderboard),
                  const SizedBox(height: 100), // Buffer for bottom nav
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLevelCard(BuildContext context, gamification) {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primary500, AppColors.accent500],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary500.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${gamification.level}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'level_label'.tr(args: [gamification.level.toString()]),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'xp_label'.tr(args: [gamification.totalXp.toString()]),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.gray400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.stars, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${gamification.totalPoints} points',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Icon(Icons.local_fire_department, color: AppColors.orange500, size: 32),
                  Text(
                    '${gamification.currentStreak}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'days'.tr(),
                    style: TextStyle(fontSize: 12, color: AppColors.gray400),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'progress_label'.tr(),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                'xp_to_next'.tr(args: [gamification.xpToNextLevel.toString()]),
                style: TextStyle(color: AppColors.primary400, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: gamification.progress,
              minHeight: 12,
              backgroundColor: AppColors.gray800,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, gamification) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildStatItem(Icons.movie_filter, gamification.postsCount.toString(), 'stats_posts'.tr(), AppColors.blue500),
        _buildStatItem(Icons.shopping_bag, gamification.ordersCount.toString(), 'stats_orders'.tr(), AppColors.purple500),
        _buildStatItem(Icons.fitness_center, gamification.coursesCount.toString(), 'stats_courses'.tr(), AppColors.green500),
        _buildStatItem(Icons.comment, gamification.commentsCount.toString(), 'stats_comments'.tr(), AppColors.orange500),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return PremiumCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.gray400),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text('view_all'.tr()),
        ),
      ],
    );
  }

  Widget _buildRecentBadges(BuildContext context, List<model.Badge> badges) {
    if (badges.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.gray800.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'no_badges_yet'.tr(),
            style: TextStyle(color: AppColors.gray400),
          ),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: badges.length,
        itemBuilder: (context, index) {
          final badge = badges[index];
          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary500.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary500.withOpacity(0.5), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      badge.icon,
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  badge.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardPreview(BuildContext context, List<Map<String, dynamic>> players) {
    if (players.isEmpty) {
      return const SizedBox.shrink();
    }

    return PremiumCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: players.take(3).length,
        separatorBuilder: (context, index) => Divider(color: AppColors.gray800, height: 1),
        itemBuilder: (context, index) {
          final player = players[index];
          final user = player['user'];
          
          return ListTile(
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.gray700,
              backgroundImage: user['avatar'] != null ? NetworkImage(user['avatar']) : null,
              child: user['avatar'] == null ? const Icon(Icons.person, color: Colors.white70, size: 20) : null,
            ),
            title: Text(
              user['name'] ?? 'Anonymous',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lvl ${player['level']}',
                  style: TextStyle(color: AppColors.primary400, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  '${player['totalXp']} XP',
                  style: TextStyle(color: AppColors.gray400, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
