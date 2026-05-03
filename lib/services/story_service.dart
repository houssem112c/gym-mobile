import '../models/story.dart';
import 'api_service.dart';

class StoryService {
  final ApiService _apiService = ApiService();

  Future<List<StoryGroup>> getStoriesGroupedByCategory() async {
    try {
      final response = await _apiService.get('/stories/grouped');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => StoryGroup.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load stories');
      }
    } catch (e) {
      print('Error fetching stories: $e');
      rethrow;
    }
  }

  Future<List<Story>> getAllStories() async {
    try {
      final response = await _apiService.get('/stories');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Story.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load stories');
      }
    } catch (e) {
      print('Error fetching stories: $e');
      rethrow;
    }
  }
}
