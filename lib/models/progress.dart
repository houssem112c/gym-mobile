import 'workout.dart';

enum PhotoType { FRONT, SIDE, BACK }

class UserProgressPhoto {
  final String id;
  final String userId;
  final String imageUrl;
  final PhotoType type;
  final String? notes;
  final DateTime createdAt;

  UserProgressPhoto({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.type,
    this.notes,
    required this.createdAt,
  });

  factory UserProgressPhoto.fromJson(Map<String, dynamic> json) {
    return UserProgressPhoto(
      id: json['id'],
      userId: json['userId'],
      imageUrl: json['imageUrl'],
      type: PhotoType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PhotoType.FRONT,
      ),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class UserMeasurement {
  final String id;
  final String userId;
  final double? weight;
  final double? bodyFat;
  final double? waist;
  final double? chest;
  final double? arms;
  final double? legs;
  final DateTime createdAt;

  UserMeasurement({
    required this.id,
    required this.userId,
    this.weight,
    this.bodyFat,
    this.waist,
    this.chest,
    this.arms,
    this.legs,
    required this.createdAt,
  });

  factory UserMeasurement.fromJson(Map<String, dynamic> json) {
    return UserMeasurement(
      id: json['id'],
      userId: json['userId'],
      weight: json['weight']?.toDouble(),
      bodyFat: json['bodyFat']?.toDouble(),
      waist: json['waist']?.toDouble(),
      chest: json['chest']?.toDouble(),
      arms: json['arms']?.toDouble(),
      legs: json['legs']?.toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class UserPR {
  final String id;
  final String userId;
  final String exerciseId;
  final Exercise? exercise;
  final double weight;
  final int reps;
  final String? notes;
  final DateTime createdAt;

  UserPR({
    required this.id,
    required this.userId,
    required this.exerciseId,
    this.exercise,
    required this.weight,
    required this.reps,
    this.notes,
    required this.createdAt,
  });

  factory UserPR.fromJson(Map<String, dynamic> json) {
    return UserPR(
      id: json['id'],
      userId: json['userId'],
      exerciseId: json['exerciseId'],
      exercise: json['exercise'] != null ? Exercise.fromJson(json['exercise']) : null,
      weight: json['weight']?.toDouble() ?? 0.0,
      reps: json['reps'] ?? 0,
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
