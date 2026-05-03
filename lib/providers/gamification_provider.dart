import '../services/gamification_service.dart';
import '../services/auth_service.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:easy_localization/easy_localization.dart';
import '../models/gamification.dart' as model;

class GamificationProvider with ChangeNotifier {
  final AuthService _authService;
  final GamificationService _gamificationService = GamificationService();

  model.UserGamification? _userGamification;
  List<model.Badge> _allBadges = [];
  List<model.Badge> _myBadges = [];
  List<model.XpTransaction> _xpHistory = [];
  List<Map<String, dynamic>> _leaderboard = [];

  bool _isLoading = false;
  String? _error;

  // For notifications
  BuildContext? _notificationContext;
  void setContext(BuildContext context) => _notificationContext = context;

  GamificationProvider(this._authService) {
    if (_authService.isAuthenticated) {
      loadData();
    }
  }

  model.UserGamification? get userGamification => _userGamification;
  List<model.Badge> get allBadges => _allBadges;
  List<model.Badge> get myBadges => _myBadges;
  List<model.XpTransaction> get xpHistory => _xpHistory;

  List<Map<String, dynamic>> get leaderboard => _leaderboard;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadData() async {
    if (!_authService.isAuthenticated) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = _authService.token!;
      
      // Load everything in parallel
      final results = await Future.wait([
        _gamificationService.getMyGamification(token),
        _gamificationService.getAllBadges(token),
        _gamificationService.getMyBadges(token),
        _gamificationService.getXpHistory(token),
        _gamificationService.getLeaderboard(token),
      ]);

      final newGamification = results[0] as model.UserGamification;
      
      // Check for XP gain or level up for notification
      if (_userGamification != null && _notificationContext != null) {
        if (newGamification.totalXp > _userGamification!.totalXp) {
          final xpGained = newGamification.totalXp - _userGamification!.totalXp;
          _showXpSnackBar(xpGained);
        }
        if (newGamification.level > _userGamification!.level) {
          _showLevelUpDialog(newGamification.level);
        }
      }

      final newBadges = List<model.Badge>.from(results[2] as List);
      if (_myBadges.isNotEmpty && newBadges.length > _myBadges.length && _notificationContext != null) {
        // Find new badge
        final oldIds = _myBadges.map((b) => b.id).toSet();
        for (var badge in newBadges) {
          if (!oldIds.contains(badge.id)) {
            _showBadgeSnackBar(badge.name);
          }
        }
      }

      _userGamification = newGamification;
      _allBadges = List<model.Badge>.from(results[1] as List);
      _myBadges = newBadges;
      _xpHistory = List<model.XpTransaction>.from(results[3] as List);
      _leaderboard = List<Map<String, dynamic>>.from(results[4] as List);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      print('Error loading gamification data: $e');
    }
  }

  Future<void> refreshGamification() async {
    if (!_authService.isAuthenticated) return;
    
    try {
      final token = _authService.token!;
      _userGamification = await _gamificationService.getMyGamification(token) as model.UserGamification;
      notifyListeners();
    } catch (e) {
      print('Error refreshing gamification: $e');
    }
  }

  Future<void> completeCourse(String courseId) async {
    if (!_authService.isAuthenticated) return;
    
    try {
      final token = _authService.token!;
      await _gamificationService.completeCourse(token, courseId);
      // Refresh data after completion
      await loadData();
    } catch (e) {
      print('Error completing course: $e');
      rethrow;
    }
  }

  void _showXpSnackBar(int amount) {
    if (_notificationContext == null) return;
    ScaffoldMessenger.of(_notificationContext!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 8),
            Text('xp_earned_notification'.tr(args: [amount.toString()])),
          ],
        ),
        backgroundColor: Colors.blueGrey[900],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showBadgeSnackBar(String badgeName) {
    if (_notificationContext == null) return;
    ScaffoldMessenger.of(_notificationContext!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(child: Text('badge_earned_notification'.tr(args: [badgeName]))),
          ],
        ),
        backgroundColor: Colors.deepPurple[900],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showLevelUpDialog(int level) {
    if (_notificationContext == null) return;
    showDialog(
      context: _notificationContext!,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.blueGrey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Icon(Icons.trending_up, color: Colors.amber, size: 60),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'level_up_notification'.tr(args: [level.toString()]),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Keep up the great work!',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('AWESOME!'),
          ),
        ],
      ),
    );
  }
}
