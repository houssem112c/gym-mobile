class Course {
  final String id;
  final String title;
  final String? description;
  final int duration;
  final int capacity;
  final String instructor;
  final String? videoUrl;
  final String? thumbnail;
  final String? categoryId;
  final List<CourseSchedule>? schedules;
  final DateTime createdAt;
  final DateTime updatedAt;

  Course({
    required this.id,
    required this.title,
    this.description,
    required this.duration,
    required this.capacity,
    required this.instructor,
    this.videoUrl,
    this.thumbnail,
    this.categoryId,
    this.schedules,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      duration: json['duration'],
      capacity: json['capacity'],
      instructor: json['instructor'],
      videoUrl: json['videoUrl'],
      thumbnail: json['thumbnail'],
      categoryId: json['categoryId'],
      schedules: json['schedules'] != null
          ? (json['schedules'] as List)
              .map((s) => CourseSchedule.fromJson(s))
              .toList()
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class CourseSchedule {
  final String id;
  final String courseId;
  final String? title;
  final String? coachName;
  final String? specificDate;
  final int? dayOfWeek;
  final String startTime;
  final String endTime;
  final String? startDate;
  final String? endDate;
  final bool isRecurring;
  final bool isActive;
  final bool isBooked;
  final Course? course;

  CourseSchedule({
    required this.id,
    required this.courseId,
    this.title,
    this.coachName,
    this.specificDate,
    this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.startDate,
    this.endDate,
    required this.isRecurring,
    required this.isActive,
    this.isBooked = false,
    this.course,
  });

  factory CourseSchedule.fromJson(Map<String, dynamic> json) {
    return CourseSchedule(
      id: json['id'],
      courseId: json['courseId'],
      title: json['title'],
      coachName: json['coachName'],
      specificDate: json['specificDate'],
      dayOfWeek: json['dayOfWeek'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      isRecurring: json['isRecurring'],
      isActive: json['isActive'],
      isBooked: json['isBooked'] ?? false,
      course: json['course'] != null ? Course.fromJson(json['course']) : null,
    );
  }
}
