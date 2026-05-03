import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/colors.dart';
import '../../models/private_session.dart';
import '../../services/private_session_service.dart';
import '../../widgets/gradient_background.dart';

class MyPrivateSessionsScreen extends StatefulWidget {
  const MyPrivateSessionsScreen({super.key});

  @override
  State<MyPrivateSessionsScreen> createState() => _MyPrivateSessionsScreenState();
}

class _MyPrivateSessionsScreenState extends State<MyPrivateSessionsScreen> {
  final PrivateSessionService _sessionService = PrivateSessionService();
  List<PrivateSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final sessions = await _sessionService.getMySessions();
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load sessions: $e')),
        );
      }
    }
  }

  Color _getStatusColor(PrivateSessionStatus status) {
    switch (status) {
      case PrivateSessionStatus.ACCEPTED:
      case PrivateSessionStatus.COMPLETED:
        return AppColors.primary500;
      case PrivateSessionStatus.DECLINED:
      case PrivateSessionStatus.CANCELLED:
        return AppColors.accent500;
      case PrivateSessionStatus.PENDING:
        return Colors.orange;
      default:
        return AppColors.gray400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.gray900,
        title: const Text(
          'My Private Sessions',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GradientBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _sessions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 64, color: AppColors.gray600),
                        const SizedBox(height: 16),
                        Text(
                          'No private sessions yet.',
                          style: TextStyle(color: AppColors.gray400, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final session = _sessions[index];
                      final dateStr = DateFormat('EEE, MMM d, yyyy').format(session.date);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.gray800,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.gray700),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(session.status).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _getStatusColor(session.status).withOpacity(0.5)),
                                  ),
                                  child: Text(
                                    session.status.toString().split('.').last,
                                    style: TextStyle(
                                      color: _getStatusColor(session.status),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 16, color: AppColors.primary400),
                                const SizedBox(width: 8),
                                Text(
                                  '${session.startTime} - ${session.endTime}',
                                  style: TextStyle(color: AppColors.gray300, fontSize: 14),
                                ),
                              ],
                            ),
                            if (session.coach != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.person, size: 16, color: AppColors.primary400),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Coach: ${session.coach!.name}',
                                    style: TextStyle(color: AppColors.gray300, fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                            if (session.note != null && session.note!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.gray900,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '"${session.note}"',
                                  style: TextStyle(color: AppColors.gray400, fontStyle: FontStyle.italic, fontSize: 12),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
