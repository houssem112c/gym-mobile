import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/gamification.dart';

class GamificationService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<UserGamification> getMyGamification(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/gamification/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return UserGamification.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load gamification data');
    }
  }

  Future<List<Badge>> getAllBadges(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/gamification/badges'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Badge.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load badges');
    }
  }

  Future<List<Badge>> getMyBadges(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/gamification/badges/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Badge.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load my badges');
    }
  }

  Future<List<XpTransaction>> getXpHistory(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/gamification/history'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => XpTransaction.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load XP history');
    }
  }

  Future<List<Map<String, dynamic>>> getLeaderboard(String token, {int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/gamification/leaderboard?limit=$limit'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to load leaderboard');
    }
  }

  Future<void> completeCourse(String token, String courseId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/courses/$courseId/complete'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to complete course');
    }
  }
}
