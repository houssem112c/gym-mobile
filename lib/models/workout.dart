enum Difficulty { BEGINNER, INTERMEDIATE, ADVANCED }

class Exercise {
  final String id;
  final String name;
  final String? description;
  final String? muscleGroup;
  final String? equipment;
  final String? videoUrl;
  final String? imageUrl;
  final Difficulty difficulty;
  final bool isActive;

  Exercise({
    required this.id,
    required this.name,
    this.description,
    this.muscleGroup,
    this.equipment,
    this.videoUrl,
    this.imageUrl,
    required this.difficulty,
    this.isActive = true,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      muscleGroup: json['muscleGroup'],
      equipment: json['equipment'],
      videoUrl: json['videoUrl'],
      imageUrl: json['imageUrl'],
      difficulty: Difficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => Difficulty.BEGINNER,
      ),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'muscleGroup': muscleGroup,
      'equipment': equipment,
      'videoUrl': videoUrl,
      'imageUrl': imageUrl,
      'difficulty': difficulty.name,
      'isActive': isActive,
    };
  }
}

class WorkoutPlan {
  final String id;
  final String title;
  final String? description;
  final String? goal;
  final int? durationWeeks;
  final Difficulty difficulty;
  final String? imageUrl;
  final bool isActive;
  final List<WorkoutPlanExercise> exercises;

  WorkoutPlan({
    required this.id,
    required this.title,
    this.description,
    this.goal,
    this.durationWeeks,
    required this.difficulty,
    this.imageUrl,
    this.isActive = true,
    required this.exercises,
  });

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      goal: json['goal'],
      durationWeeks: json['durationWeeks'],
      difficulty: Difficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => Difficulty.BEGINNER,
      ),
      imageUrl: json['imageUrl'],
      isActive: json['isActive'] ?? true,
      exercises: (json['exercises'] as List? ?? [])
          .map((e) => WorkoutPlanExercise.fromJson(e))
          .toList(),
    );
  }
}

class WorkoutPlanExercise {
  final String id;
  final String exerciseId;
  final Exercise exercise;
  final int order;
  final int? sets;
  final String? reps;
  final String? notes;

  WorkoutPlanExercise({
    required this.id,
    required this.exerciseId,
    required this.exercise,
    required this.order,
    this.sets,
    this.reps,
    this.notes,
  });

  factory WorkoutPlanExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutPlanExercise(
      id: json['id'],
      exerciseId: json['exerciseId'],
      exercise: Exercise.fromJson(json['exercise']),
      order: json['order'] ?? 0,
      sets: json['sets'],
      reps: json['reps'],
      notes: json['notes'],
    );
  }
}

enum SessionStatus { IN_PROGRESS, COMPLETED, CANCELLED }

class WorkoutSession {
  final String id;
  final String userId;
  final String? workoutPlanId;
  final String? workoutPlanTitle;
  final DateTime startTime;
  final DateTime? endTime;
  final SessionStatus status;
  final double? totalVolume;
  final String? notes;
  final List<SetLog> setLogs;

  WorkoutSession({
    required this.id,
    required this.userId,
    this.workoutPlanId,
    this.workoutPlanTitle,
    required this.startTime,
    this.endTime,
    required this.status,
    this.totalVolume,
    this.notes,
    required this.setLogs,
  });

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'],
      userId: json['userId'],
      workoutPlanId: json['workoutPlanId'],
      workoutPlanTitle: json['workoutPlan']?['title'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      status: SessionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SessionStatus.IN_PROGRESS,
      ),
      totalVolume: json['totalVolume']?.toDouble(),
      notes: json['notes'],
      setLogs: (json['setLogs'] as List? ?? [])
          .map((e) => SetLog.fromJson(e))
          .toList(),
    );
  }
}

class SetLog {
  final String id;
  final String exerciseId;
  final String? exerciseName;
  final int setNumber;
  final double weight;
  final int reps;
  final bool isPersonalRecord;
  final DateTime createdAt;

  SetLog({
    required this.id,
    required this.exerciseId,
    this.exerciseName,
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.isPersonalRecord = false,
    required this.createdAt,
  });

  factory SetLog.fromJson(Map<String, dynamic> json) {
    return SetLog(
      id: json['id'],
      exerciseId: json['exerciseId'],
      exerciseName: json['exercise']?['name'],
      setNumber: json['setNumber'],
      weight: json['weight'].toDouble(),
      reps: json['reps'],
      isPersonalRecord: json['isPersonalRecord'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
