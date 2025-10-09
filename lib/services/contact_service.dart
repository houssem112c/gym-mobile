import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/contact.dart';

class ContactService {
  late final Dio _dio;

  ContactService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add interceptors for logging
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  // Get user's messages (requires authentication)
  Future<List<ContactMessage>> getUserMessages(String token) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.contacts}/user/messages',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data is List) {
        return (response.data as List)
            .map((json) => ContactMessage.fromJson(json))
            .toList();
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Send message as authenticated user
  Future<ContactMessage> sendUserMessage({
    required String token,
    required String subject,
    required String message,
    required String priority,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.contacts}/user',
        data: {
          'subject': subject,
          'message': message,
          'priority': priority,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      return ContactMessage.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Send message as guest user (no authentication)
  Future<ContactMessage> sendGuestMessage({
    required String name,
    required String email,
    required String phone,
    required String subject,
    required String message,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.contacts,
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'subject': subject,
          'message': message,
        },
      );

      return ContactMessage.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error handling
  String _handleError(DioException error) {
    String errorMessage = '';
    
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Connection timeout. Please try again.';
        break;
      case DioExceptionType.badResponse:
        if (error.response?.data is Map<String, dynamic>) {
          errorMessage = error.response?.data['message'] ?? 'Server error occurred';
        } else {
          errorMessage = 'Server error occurred';
        }
        break;
      case DioExceptionType.cancel:
        errorMessage = 'Request cancelled';
        break;
      default:
        errorMessage = 'Network error. Please check your connection.';
    }
    
    return errorMessage;
  }
}