import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/gamification_provider.dart';
import '../config/colors.dart';
import '../widgets/premium_card.dart';
import '../models/gamification.dart' as model;

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface950,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('badges_title'.tr()),
      ),
      body: Consumer<GamificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.allBadges.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final allBadges = provider.allBadges;
          final myBadgeIds = provider.myBadges.map((b) => b.id).toSet();

          // Group badges by category
          final Map<String, List<model.Badge>> groupedBadges = {};
          for (var badge in allBadges) {
            if (!groupedBadges.containsKey(badge.category)) {
              groupedBadges[badge.category] = [];
            }
            groupedBadges[badge.category]!.add(badge);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedBadges.keys.length,
            itemBuilder: (context, index) {
              final category = groupedBadges.keys.elementAt(index);
              final badges = groupedBadges[category]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      category.split('_').join(' '),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: badges.length,
                    itemBuilder: (context, bIndex) {
                      final badge = badges[bIndex];
                      final isEarned = myBadgeIds.contains(badge.id);

                      return _buildBadgeCard(context, badge, isEarned);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBadgeCard(BuildContext context, model.Badge badge, bool isEarned) {
    return GestureDetector(
      onTap: () => _showBadgeDetails(context, badge, isEarned),
      child: PremiumCard(
        child: Opacity(
          opacity: isEarned ? 1.0 : 0.4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isEarned ? AppColors.primary500.withOpacity(0.1) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isEarned ? Border.all(color: AppColors.primary500, width: 2) : null,
                ),
                child: Center(
                  child: Text(
                    badge.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                badge.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBadgeDetails(BuildContext context, model.Badge badge, bool isEarned) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface900,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isEarned ? AppColors.primary500.withOpacity(0.2) : AppColors.gray800,
                shape: BoxShape.circle,
                border: isEarned ? Border.all(color: AppColors.primary500, width: 3) : null,
              ),
              child: Center(
                child: Text(
                  badge.icon,
                  style: const TextStyle(fontSize: 50),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              badge.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isEarned ? AppColors.green500.withOpacity(0.2) : AppColors.gray700,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isEarned ? 'earned'.tr() : 'not_earned'.tr(),
                style: TextStyle(
                  color: isEarned ? AppColors.green400 : AppColors.gray400,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.gray300,
              ),
            ),
            const SizedBox(height: 24),
            if (!isEarned)
              Text(
                'requirement_label'.tr(args: [badge.requirement.toString()]),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary400,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'reward_label'.tr(args: [badge.xpReward.toString()]),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray400,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
