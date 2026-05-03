import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/workout.dart';

class WorkoutService {
  final Dio _dio = Dio();

  Future<List<Exercise>> getExercises() async {
    try {
      final response = await _dio.get('${ApiConfig.baseUrl}/exercises');
      if (response.data is List) {
        return (response.data as List)
            .map((json) => Exercise.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching exercises: $e');
      return [];
    }
  }

  Future<List<WorkoutPlan>> getWorkoutPlans() async {
    try {
      final response = await _dio.get('${ApiConfig.baseUrl}/workout-plans');
      if (response.data is List) {
        return (response.data as List)
            .map((json) => WorkoutPlan.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching workout plans: $e');
      return [];
    }
  }

  Future<List<WorkoutPlan>> getRecommendedPlans(String token) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/workout-plans/recommended',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.data is List) {
        return (response.data as List)
            .map((json) => WorkoutPlan.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching recommended plans: $e');
      return [];
    }
  }

  // Session Management
  Future<WorkoutSession> startSession(String token, String? planId) async {
    final response = await _dio.post(
      '${ApiConfig.baseUrl}/workout-sessions/start',
      data: {'workoutPlanId': planId},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return WorkoutSession.fromJson(response.data);
  }

  Future<WorkoutSession?> getActiveSession(String token) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/workout-sessions/active',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.data == null || response.data == '') return null;
      return WorkoutSession.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<void> logSet(String token, String sessionId, Map<String, dynamic> data) async {
    await _dio.post(
      '${ApiConfig.baseUrl}/workout-sessions/$sessionId/log-set',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<void> completeSession(String token, String sessionId, String notes) async {
    await _dio.post(
      '${ApiConfig.baseUrl}/workout-sessions/$sessionId/complete',
      data: {'notes': notes},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<List<WorkoutSession>> getSessionHistory(String token) async {
    final response = await _dio.get(
      '${ApiConfig.baseUrl}/workout-sessions/history',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (response.data as List).map((e) => WorkoutSession.fromJson(e)).toList();
  }
}
