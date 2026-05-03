import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../config/colors.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/local_notification_service.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_card.dart';

class TrainingSettingsScreen extends StatefulWidget {
  const TrainingSettingsScreen({super.key});

  @override
  State<TrainingSettingsScreen> createState() => _TrainingSettingsScreenState();
}

class _TrainingSettingsScreenState extends State<TrainingSettingsScreen> {
  int _frequency = 3;
  List<int> _trainingDays = [1, 3, 5]; // Mon, Wed, Fri
  bool _isLoading = false;

  final List<String> _weekDays = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      _frequency = user.trainingFrequency ?? 3;
      _trainingDays = user.trainingDays ?? [1, 3, 5];
    }
  }

  void _toggleDay(int dayIndex) {
    setState(() {
      if (_trainingDays.contains(dayIndex)) {
        _trainingDays.remove(dayIndex);
      } else {
        if (_trainingDays.length < 7) {
          _trainingDays.add(dayIndex);
          _trainingDays.sort();
        }
      }
      _frequency = _trainingDays.length;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      final profileService = ProfileService();
      final user = authService.currentUser;

      if (user != null) {
        final updatedUser = await profileService.updateProfile(
          token: authService.token!,
          trainingFrequency: _frequency,
          trainingDays: _trainingDays,
        );

        print('✅ Profile updated in backend');

        // Update local state in AuthService
        print('🔄 Updating local AuthService...');
        authService.updateUser(updatedUser);
        print('✅ Local AuthService updated');

        // Schedule notifications
        if (kIsWeb) {
          print('🌐 Web platform detected, skipping local notification scheduling');
        } else {
          print('⏰ Scheduling daily reminders...');
          try {
            await LocalNotificationService.scheduleDailyReminders(_trainingDays);
            print('✅ Daily reminders scheduled');
          } catch (notificationError) {
            print('⚠️ Notification scheduling failed: $notificationError');
            // We don't want to crash or show error if ONLY notifications fail on some platforms
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Training settings saved!'),
              backgroundColor: AppColors.primary500,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: AppColors.red500,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface950,
      appBar: AppBar(
        title: const Text('Training Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configure Your Week',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set how many days you train and which days to receive reminders.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Weekly Frequency',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary500.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_frequency days',
                          style: const TextStyle(
                            color: AppColors.primary400,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(7, (index) {
                      bool isSelected = _trainingDays.contains(index);
                      return GestureDetector(
                        onTap: () => _toggleDay(index),
                        child: Container(
                          width: (MediaQuery.of(context).size.width - 80) / 4,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary500
                                : AppColors.gray800,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary400
                                  : AppColors.gray700,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _weekDays[index].substring(0, 3),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.gray400,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : PremiumButton(
                    text: 'Save Configuration',
                    onPressed: _saveSettings,
                  ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'A notification will be sent at 8:00 AM daily.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
