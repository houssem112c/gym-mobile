
import 'package:flutter/foundation.dart';
import 'user.dart';

enum PrivateSessionStatus {
  PENDING,
  ACCEPTED,
  DECLINED,
  CANCELLED,
  COMPLETED
}

class PrivateSession {
  final String id;
  final String userId;
  final User? user;
  final String coachId;
  final User? coach;
  final DateTime date;
  final String startTime;
  final String endTime;
  final PrivateSessionStatus status;
  final String? note;
  final DateTime createdAt;

  PrivateSession({
    required this.id,
    required this.userId,
    this.user,
    required this.coachId,
    this.coach,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.note,
    required this.createdAt,
  });

  factory PrivateSession.fromJson(Map<String, dynamic> json) {
    return PrivateSession(
      id: json['id'],
      userId: json['userId'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      coachId: json['coachId'],
      coach: json['coach'] != null ? User.fromJson(json['coach']) : null,
      date: DateTime.parse(json['date']),
      startTime: json['startTime'],
      endTime: json['endTime'],
      status: PrivateSessionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => PrivateSessionStatus.PENDING,
      ),
      note: json['note'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'coachId': coachId,
      'date': date.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'status': status.toString().split('.').last,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class SessionAvailability {
  final String time;
  final bool isAvailable;

  SessionAvailability({required this.time, required this.isAvailable});

  factory SessionAvailability.fromJson(Map<String, dynamic> json) {
    return SessionAvailability(
      time: json['time'],
      isAvailable: json['isAvailable'],
    );
  }
}
