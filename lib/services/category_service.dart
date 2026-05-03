import 'package:http/http.dart' as http;
import '../models/category.dart' as cat;
import 'api_service.dart';

class CategoryService {
  final ApiService _apiService = ApiService();

  Future<List<cat.Category>> getCategories() async {
    try {
      final response = await _apiService.get('/categories');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => cat.Category.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<cat.Category> getCategoryById(String id) async {
    try {
      final response = await _apiService.get('/categories/$id');
      
      if (response.statusCode == 200) {
        return cat.Category.fromJson(response.data);
      } else {
        throw Exception('Failed to load category: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching category: $e');
      throw Exception('Failed to load category: $e');
    }
  }
}
