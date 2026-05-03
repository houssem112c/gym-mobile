import '../services/api_service.dart';
import '../models/course.dart';

class CourseService {
  final ApiService _apiService = ApiService();

  Future<List<Course>> getCourses() async {
    try {
      final response = await _apiService.get('/courses');
      
      print('🎯 Course API Response: ${response.data}');
      
      if (response.data is List) {
        final courses = (response.data as List)
            .map((json) => Course.fromJson(json))
            .toList();
            
        print('🎯 Parsed courses count: ${courses.length}');
        if (courses.isNotEmpty) {
          print('🎯 Sample course: ${courses.first.title}');
          print('🎯 Sample videoUrl: ${courses.first.videoUrl}');
          print('🎯 Sample thumbnail: ${courses.first.thumbnail}');
        }
        
        return courses;
      }
      
      return [];
    } catch (e) {
      print('Error fetching courses: $e');
      return [];
    }
  }

  Future<Course?> getCourseById(String id) async {
    try {
      final response = await _apiService.get('/courses/$id');
      return Course.fromJson(response.data);
    } catch (e) {
      print('Error fetching course: $e');
      return null;
    }
  }

  Future<bool> bookSession(String scheduleId) async {
    try {
      final response = await _apiService.post('/courses/schedules/$scheduleId/book', data: {});
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error booking session: $e');
      return false;
    }
  }

  Future<List<dynamic>> getMyBookings() async {
    try {
      final response = await _apiService.get('/courses/my/bookings');
      return response.data as List;
    } catch (e) {
      print('Error fetching bookings: $e');
      return [];
    }
  }
}
