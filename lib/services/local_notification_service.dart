import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    
    try {
      String timeZoneName;
      if (kIsWeb) {
        // Fallback for web as flutter_timezone may not be implemented
        timeZoneName = 'UTC';
      } else {
        final dynamic tzResult = await FlutterTimezone.getLocalTimezone();
        if (tzResult is String) {
          timeZoneName = tzResult;
        } else {
          // Handle newer versions returning an object. Try common property names.
          try {
            final dynamic d = tzResult as dynamic;
            timeZoneName = d.name ?? d.timezone ?? d.zoneId ?? d.value ?? d.timeZone ?? d.toString();
          } catch (_) {
            timeZoneName = tzResult.toString();
          }
        }
      }
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      print('Could not set local timezone: $e');
      // Fallback to UTC if timezone detection fails
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> scheduleDailyReminders(List<int> trainingDays) async {
    // Cancel all existing scheduled notifications
    await _notificationsPlugin.cancelAll();

    // Schedule for each day of the week (0-6)
    // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
    for (int day = 0; day < 7; day++) {
      bool isTrainingDay = trainingDays.contains(day);
      String title = isTrainingDay ? "Training Day! 🏋️" : "Day Off 🏠";
      String body = isTrainingDay
          ? "Today is a training day. Get ready to crush it!"
          : "Today is a rest day. Enjoy your recovery!";

      await _scheduleWeeklyNotification(
        id: day,
        title: title,
        body: body,
        day: day,
      );
    }
  }

  static Future<void> scheduleSessionNotifications(List<dynamic> sessions) async {
    // We'll use a specific ID range for session reminders (e.g., 100+)
    // to avoid conflict with daily training reminders (0-6)
    
    // 1. Filter sessions for TODAY
    final now = DateTime.now();
    final todaySessions = sessions.where((s) {
      if (s['isBooked'] != true) return false;
      
      final bool isRecurring = s['isRecurring'] ?? false;
      if (isRecurring) {
        // Backend uses 0=Sun, 1=Mon... Dart uses 1=Mon, 7=Sun
        int dartWeekday = s['dayOfWeek'] == 0 ? 7 : s['dayOfWeek'];
        return now.weekday == dartWeekday;
      } else if (s['date'] != null) {
        final sessionDate = DateTime.parse(s['date']);
        return sessionDate.year == now.year && 
               sessionDate.month == now.month && 
               sessionDate.day == now.day;
      }
      return false;
    }).toList();

    if (todaySessions.isEmpty) return;

    for (int i = 0; i < todaySessions.length; i++) {
      final session = todaySessions[i];
      final String startTime = session['startTime'] ?? "00:00";
      final List<String> parts = startTime.split(':');
      final int hour = parts.length > 0 ? int.tryParse(parts[0]) ?? 8 : 8;
      final int minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

      // Schedule notification for 30 minutes before the session
      final scheduledTime = now.copyWith(hour: hour, minute: minute).subtract(const Duration(minutes: 30));
      
      // If the notification time has already passed for today, don't schedule
      if (scheduledTime.isBefore(now)) continue;

      await _notificationsPlugin.zonedSchedule(
        100 + i, // Unique ID
        "Upcoming Session! 🕒",
        "Your course '${session['courseName']}' starts at $startTime. Get ready!",
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'session_reminders',
            'Session Reminders',
            channelDescription: 'Reminders for booked course sessions',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> _scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int day,
  }) async {
    // Schedule for 8:00 AM
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfDay(day, 8, 0),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'training_reminders',
          'Training Reminders',
          channelDescription: 'Daily reminders for training days',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  static tz.TZDateTime _nextInstanceOfDay(int day, int hour, int minute) {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    // If day is target day but time has passed, move to next week
    // Day in TZ is 1=Mon, 7=Sun. Our day is 0=Sun, 1=Mon...
    int targetDay = day == 0 ? 7 : day;
    
    while (scheduledDate.weekday != targetDay || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
