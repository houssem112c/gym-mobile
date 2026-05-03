
import 'package:dio/dio.dart';
import '../models/private_session.dart';
import '../models/user.dart';
import 'api_service.dart';

class PrivateSessionService {
  final ApiService _apiService = ApiService();

  Future<List<SessionAvailability>> getAvailability(String coachId, DateTime date) async {
    try {
      final response = await _apiService.get(
        '/private-sessions/availability',
        queryParameters: {
          'coachId': coachId,
          'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD
        },
      );
      
      return (response.data as List)
          .map((e) => SessionAvailability.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to get availability: $e');
    }
  }

  Future<PrivateSession> requestSession({
    required String coachId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? note,
  }) async {
    try {
      final response = await _apiService.post(
        '/private-sessions',
        data: {
          'coachId': coachId,
          'date': date.toIso8601String().split('T')[0],
          'startTime': startTime,
          'endTime': endTime,
          'note': note,
        },
      );
      
      return PrivateSession.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to request session: $e');
    }
  }

  Future<List<User>> getCoaches() async {
    try {
      final response = await _apiService.get('/coach/list');
      return (response.data as List).map((e) => User.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to get coaches: $e');
    }
  }

  Future<List<PrivateSession>> getMySessions() async {
    try {
      final response = await _apiService.get('/private-sessions/my-sessions');
      return (response.data as List)
          .map((e) => PrivateSession.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to get my sessions: $e');
    }
  }
}
