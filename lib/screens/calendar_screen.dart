import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:easy_localization/easy_localization.dart';
import '../config/colors.dart';
import '../widgets/gradient_background.dart';
import '../services/api_service.dart';
import '../services/course_service.dart';
import '../services/local_notification_service.dart';
import '../config/api_config.dart';
import 'booking/book_private_session_screen.dart';
import 'booking/my_private_sessions_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ApiService _apiService = ApiService();
  final CourseService _courseService = CourseService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _sessions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Calculate date range (current month + previous and next month for better UX)
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - 1, 1);
      final endDate = DateTime(now.year, now.month + 2, 0); // Last day of next month
      
      // Format dates as ISO strings
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];
      
      final response = await _apiService.get(
        '${ApiConfig.calendar}?startDate=$startDateStr&endDate=$endDateStr'
      );
      final List<dynamic> data = response.data;
      
      // Group sessions by date
      Map<DateTime, List<dynamic>> sessions = {};
      for (var session in data) {
        try {
          final bool isRecurring = session['isRecurring'] ?? false;
          
          if (isRecurring && session['dayOfWeek'] != null) {
            // For recurring sessions: show ALL occurrences within the date range
            final int dayOfWeek = session['dayOfWeek'] as int;
            final List<DateTime> occurrences = _getAllRecurringOccurrences(
              dayOfWeek, 
              startDate, 
              endDate
            );
            
            // Add session to each occurrence date
            for (DateTime occurrence in occurrences) {
              final normalizedDate = DateTime(occurrence.year, occurrence.month, occurrence.day);
              
              if (sessions[normalizedDate] == null) {
                sessions[normalizedDate] = [];
              }
              
              final formattedSession = {
                'id': session['id'],
                'date': normalizedDate.toIso8601String(),
                'courseName': session['course']?['title'] ?? session['title'] ?? 'Unknown Course',
                'startTime': session['startTime'] ?? '',
                'endTime': session['endTime'] ?? '',
                'instructor': session['course']?['instructor'] ?? session['coachName'] ?? 'TBA',
                'isRecurring': session['isRecurring'] ?? false,
                'capacity': session['course']?['capacity'],
                'isBooked': session['isBooked'] ?? false,
              };
              
              sessions[normalizedDate]!.add(formattedSession);
            }
          }
        } catch (e) {
          print('Error parsing session: $e');
          print('Session data: $session');
          continue; // Skip this session and continue with others
        }
      }
      
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });

      // Schedule session notifications for today's booked sessions
      final flattenedSessions = sessions.values.expand((x) => x).toList();
      LocalNotificationService.scheduleSessionNotifications(flattenedSessions);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load sessions: $e')),
        );
      }
    }
  }

  List<dynamic> _getSessionsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _sessions[normalizedDay] ?? [];
  }

  List<DateTime> _getAllRecurringOccurrences(int dayOfWeek, DateTime startDate, DateTime endDate) {
    // Backend uses: 0 = Sunday, 1 = Monday, ..., 6 = Saturday
    // Dart uses: 1 = Monday, 2 = Tuesday, ..., 7 = Sunday
    
    List<DateTime> occurrences = [];
    
    // Convert backend dayOfWeek to Dart weekday
    int dartWeekday = dayOfWeek == 0 ? 7 : dayOfWeek; // 0 (Sunday) -> 7, others stay same
    
    // Find first occurrence on or after startDate
    DateTime current = startDate;
    int daysToAdd = dartWeekday - current.weekday;
    if (daysToAdd < 0) {
      daysToAdd += 7; // Move to next week if day already passed
    }
    current = current.add(Duration(days: daysToAdd));
    
    // Add all occurrences within the date range
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      occurrences.add(current);
      current = current.add(const Duration(days: 7)); // Next week
    }
    
    return occurrences;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;
    
    // Responsive padding and font sizes
    final horizontalPadding = isDesktop ? 40.0 : isTablet ? 30.0 : 20.0;
    final titleFontSize = isDesktop ? 40.0 : isTablet ? 36.0 : 32.0;
    final subtitleFontSize = isDesktop ? 18.0 : 16.0;
    
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.all(horizontalPadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'calendar_title'.tr(),
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'calendar_subtitle'.tr(),
                                style: TextStyle(
                                  fontSize: subtitleFontSize,
                                  color: AppColors.gray400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary500.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary500.withOpacity(0.3)),
                          ),
                          child: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MyPrivateSessionsScreen(),
                                ),
                              ).then((_) => _loadSessions());
                            },
                            icon: const Icon(Icons.person),
                            color: AppColors.primary500,
                            tooltip: 'Private Sessions',
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Calendar
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    padding: EdgeInsets.all(isTablet ? 20 : 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.gray800,
                          AppColors.gray900,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.gray700),
                    ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: _getSessionsForDay,
                  calendarStyle: CalendarStyle(
                    // Today
                    todayDecoration: BoxDecoration(
                      color: AppColors.primary500.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    // Selected
                    selectedDecoration: BoxDecoration(
                      color: AppColors.primary500,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    // Default
                    defaultTextStyle: const TextStyle(color: Colors.white),
                    // Weekend
                    weekendTextStyle: TextStyle(color: AppColors.primary300),
                    // Outside month
                    outsideTextStyle: TextStyle(color: AppColors.gray600),
                    // Event marker
                    markerDecoration: BoxDecoration(
                      color: AppColors.primary400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isEmpty) return const SizedBox();
                      
                      final hasBooked = events.any((e) => (e as Map)['isBooked'] == true);
                      
                      return Positioned(
                        right: 1,
                        bottom: 1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: hasBooked ? AppColors.accent500 : AppColors.primary400,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    titleTextStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: AppColors.primary400,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: AppColors.primary400,
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: AppColors.gray400),
                    weekendStyle: TextStyle(color: AppColors.primary300),
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    _showDateActions(selectedDay);
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                ),
              ),
                  
                  const SizedBox(height: 20),
                  
                  // Sessions for selected day
                  Container(
                    constraints: BoxConstraints(
                      minHeight: 200,
                      maxHeight: screenHeight * 0.5, // Max 50% of screen height
                    ),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildSessionsList(horizontalPadding),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionsList(double horizontalPadding) {
    final sessions = _getSessionsForDay(_selectedDay ?? _focusedDay);
    
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: AppColors.gray600,
            ),
            const SizedBox(height: 16),
            Text(
              'calendar_no_classes'.tr(),
              style: TextStyle(
                fontSize: 16,
                color: AppColors.gray400,
              ),
            ),
          ],
        ),
      );
    }

    // Sort sessions by start time
    sessions.sort((a, b) {
      final timeA = a['startTime'] as String? ?? '';
      final timeB = b['startTime'] as String? ?? '';
      return timeA.compareTo(timeB);
    });

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _buildSessionCard(session);
      },
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final courseName = session['courseName'] as String? ?? 'Unknown Course';
    final startTime = session['startTime'] as String? ?? '';
    final endTime = session['endTime'] as String? ?? '';
    final instructor = session['instructor'] as String?;
    final isRecurring = session['isRecurring'] as bool? ?? false;
    final capacity = session['capacity'] as int?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gray800,
            AppColors.gray900,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray700),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _showSessionDetails(session);
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Time indicator
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: session['isBooked'] == true ? AppColors.accent500 : AppColors.primary400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Session details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              courseName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (isRecurring)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.blue500.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.blue500.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.repeat,
                                    size: 12,
                                    color: AppColors.blue400,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'course_recurring'.tr(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.blue400,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Time info - always on first line
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: AppColors.gray400,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '$startTime - $endTime',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.gray300,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      // Instructor info - separate line to avoid overflow
                      if (instructor != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color: AppColors.gray400,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                instructor,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.gray300,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (capacity != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 16,
                              color: AppColors.gray400,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$capacity spots available',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.gray300,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                Icon(
                  Icons.arrow_forward_ios,
                  color: session['isBooked'] == true ? AppColors.accent500 : AppColors.primary400,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSessionDetails(Map<String, dynamic> session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.gray800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.gray700),
        ),
        title: Text(
          session['courseName'] ?? 'calendar_session_details'.tr(),
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              Icons.access_time,
              'calendar_time'.tr(),
              '${session['startTime']} - ${session['endTime']}',
            ),
            if (session['instructor'] != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.person,
                'course_instructor'.tr(),
                session['instructor'],
              ),
            ],
            if (session['capacity'] != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.people,
                'course_capacity'.tr(),
                '${session['capacity']} spots',
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'common_close'.tr(),
              style: TextStyle(color: AppColors.gray400),
            ),
          ),
          ElevatedButton(
            onPressed: session['isBooked'] == true
                ? null
                : () async {
                    Navigator.pop(context);
                    final success = await _courseService.bookSession(session['id']);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Successfully booked!').tr(),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadSessions(); // Reload to update UI
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Booking failed.').tr(),
                          backgroundColor: AppColors.accent500,
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: session['isBooked'] == true ? AppColors.gray600 : AppColors.primary500,
            ),
            child: Text(session['isBooked'] == true ? 'Booked' : 'calendar_book_now'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary400),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.gray400,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDateActions(DateTime date) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.gray900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('d MMMM y').format(date),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookPrivateSessionScreen(initialDate: date),
                  ),
                ).then((_) => _loadSessions()); // Refresh after booking
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Book Private Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
