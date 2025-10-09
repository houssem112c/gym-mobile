import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/bmi.dart';
import 'auth_service.dart';

class BmiService {
  final Dio _dio;
  final AuthService _authService;

  BmiService(this._authService) : _dio = Dio() {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout = ApiConfig.connectTimeout;
    _dio.options.receiveTimeout = ApiConfig.receiveTimeout;
    
    // Add auth token to requests
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _authService.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Content-Type'] = 'application/json';
          handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 errors by refreshing token
          if (error.response?.statusCode == 401) {
            try {
              // The auth service handles token refresh automatically
              // Just retry the request
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            } catch (e) {
              // If refresh fails, let the error propagate
            }
          }
          handler.next(error);
        },
      ),
    );

    // Add logging interceptor for debugging
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

  /// Calculate BMI without saving to database
  Future<BmiCalculationResult> calculateBmi(CreateBmiRequest request) async {
    try {
      final response = await _dio.post(
        '/bmi/calculate',
        data: request.toJson(),
      );

      if (response.data['success'] == true) {
        return BmiCalculationResult.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to calculate BMI');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create and save BMI record
  Future<BmiRecord> createBmiRecord(CreateBmiRequest request) async {
    try {
      final response = await _dio.post(
        '/bmi',
        data: request.toJson(),
      );

      if (response.data['success'] == true) {
        return BmiRecord.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to create BMI record');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get user's BMI records
  Future<List<BmiRecord>> getUserBmiRecords() async {
    try {
      final response = await _dio.get('/bmi');

      if (response.data['success'] == true) {
        final List<dynamic> recordsJson = response.data['data'];
        return recordsJson.map((json) => BmiRecord.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch BMI records');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get latest BMI record
  Future<BmiRecord?> getLatestBmiRecord() async {
    try {
      final response = await _dio.get('/bmi/latest');

      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null) {
          return BmiRecord.fromJson(data);
        }
        return null;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch latest BMI record');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get specific BMI record by ID
  Future<BmiRecord> getBmiRecord(String id) async {
    try {
      final response = await _dio.get('/bmi/$id');

      if (response.data['success'] == true) {
        return BmiRecord.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch BMI record');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete BMI record
  Future<void> deleteBmiRecord(String id) async {
    try {
      final response = await _dio.delete('/bmi/$id');

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to delete BMI record');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Helper method to calculate BMI locally (for instant feedback)
  static double calculateBmiValue(double weight, double height) {
    return weight / (height * height);
  }

  /// Get BMI category and status locally (for instant feedback)
  static Map<String, dynamic> getBmiCategory(double bmiValue, int age, Gender gender) {
    String category;
    BmiStatus status;
    String recommendations;

    if (age >= 2 && age <= 17) {
      // Children & Teenagers - simplified ranges
      final result = _getChildBmiCategory(bmiValue, age, gender);
      category = result['category'];
      status = result['status'];
      recommendations = result['recommendations'];
    } else if (age >= 18 && age <= 64) {
      // Adults
      final result = _getAdultBmiCategory(bmiValue);
      category = result['category'];
      status = result['status'];
      recommendations = result['recommendations'];
    } else if (age >= 65) {
      // Elderly
      final result = _getElderlyBmiCategory(bmiValue);
      category = result['category'];
      status = result['status'];
      recommendations = result['recommendations'];
    } else {
      category = 'Invalid Age';
      status = BmiStatus.notOk;
      recommendations = 'Age must be 2 years or older for BMI calculation.';
    }

    return {
      'category': category,
      'status': status,
      'recommendations': recommendations,
    };
  }

  static Map<String, dynamic> _getAdultBmiCategory(double bmiValue) {
    if (bmiValue < 18.5) {
      return {
        'category': 'Underweight',
        'status': BmiStatus.notOk,
        'recommendations': 'Consider consulting a healthcare provider. Focus on healthy weight gain through balanced nutrition and strength training.',
      };
    } else if (bmiValue >= 18.5 && bmiValue <= 24.9) {
      return {
        'category': 'Normal',
        'status': BmiStatus.ok,
        'recommendations': 'Great job! Maintain your current lifestyle with regular exercise and balanced nutrition.',
      };
    } else if (bmiValue >= 25 && bmiValue <= 29.9) {
      return {
        'category': 'Overweight',
        'status': BmiStatus.caution,
        'recommendations': 'Consider increasing physical activity and reviewing your diet. Small changes can make a big difference.',
      };
    } else if (bmiValue >= 30 && bmiValue <= 34.9) {
      return {
        'category': 'Obesity Class I',
        'status': BmiStatus.notOk,
        'recommendations': 'Consult with a healthcare provider for a personalized weight management plan.',
      };
    } else if (bmiValue >= 35 && bmiValue <= 39.9) {
      return {
        'category': 'Obesity Class II',
        'status': BmiStatus.notOk,
        'recommendations': 'Medical supervision recommended. Consider comprehensive weight management program.',
      };
    } else {
      return {
        'category': 'Obesity Class III',
        'status': BmiStatus.notOk,
        'recommendations': 'Immediate medical attention recommended. Consult with healthcare professionals.',
      };
    }
  }

  static Map<String, dynamic> _getElderlyBmiCategory(double bmiValue) {
    if (bmiValue < 18.5) {
      return {
        'category': 'Underweight',
        'status': BmiStatus.notOk,
        'recommendations': 'Consult with a healthcare provider. Adequate nutrition is especially important for seniors.',
      };
    } else if (bmiValue >= 18.5 && bmiValue <= 22.9) {
      return {
        'category': 'Slightly Low',
        'status': BmiStatus.caution,
        'recommendations': 'Monitor weight regularly. Consider increasing protein intake and gentle strength exercises.',
      };
    } else if (bmiValue >= 23 && bmiValue <= 29.9) {
      return {
        'category': 'Normal/Slightly High',
        'status': BmiStatus.ok,
        'recommendations': 'Excellent! Continue with regular gentle exercise and balanced nutrition.',
      };
    } else {
      return {
        'category': 'Obese',
        'status': BmiStatus.notOk,
        'recommendations': 'Consult with healthcare provider. Focus on gentle, age-appropriate exercise.',
      };
    }
  }

  static Map<String, dynamic> _getChildBmiCategory(double bmiValue, int age, Gender gender) {
    double underweightThreshold;
    double overweightThreshold;
    double obeseThreshold;

    if (age >= 2 && age <= 5) {
      underweightThreshold = 14.0;
      overweightThreshold = 17.5;
      obeseThreshold = 19.0;
    } else if (age >= 6 && age <= 11) {
      underweightThreshold = 15.0;
      overweightThreshold = gender == Gender.male ? 20.0 : 19.5;
      obeseThreshold = gender == Gender.male ? 23.0 : 22.5;
    } else {
      underweightThreshold = gender == Gender.male ? 17.0 : 16.5;
      overweightThreshold = gender == Gender.male ? 24.0 : 23.5;
      obeseThreshold = gender == Gender.male ? 28.0 : 27.0;
    }

    if (bmiValue < underweightThreshold) {
      return {
        'category': 'Underweight',
        'status': BmiStatus.notOk,
        'recommendations': 'Consult with a pediatrician. Ensure adequate nutrition for healthy growth.',
      };
    } else if (bmiValue >= underweightThreshold && bmiValue < overweightThreshold) {
      return {
        'category': 'Healthy Weight',
        'status': BmiStatus.ok,
        'recommendations': 'Great! Maintain healthy eating habits and stay active.',
      };
    } else if (bmiValue >= overweightThreshold && bmiValue < obeseThreshold) {
      return {
        'category': 'Overweight',
        'status': BmiStatus.caution,
        'recommendations': 'Consult with a pediatrician. Focus on healthy family meals and increased physical activity.',
      };
    } else {
      return {
        'category': 'Obese',
        'status': BmiStatus.notOk,
        'recommendations': 'Medical evaluation recommended. Work with healthcare providers on lifestyle changes.',
      };
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      } else if (data is Map && data.containsKey('error')) {
        return data['error'];
      }
      return 'Server error: ${error.response!.statusCode}';
    } else if (error.type == DioExceptionType.connectionTimeout ||
               error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (error.type == DioExceptionType.connectionError) {
      return 'Unable to connect to server. Please check your internet connection.';
    } else {
      return 'An unexpected error occurred: ${error.message}';
    }
  }
}
