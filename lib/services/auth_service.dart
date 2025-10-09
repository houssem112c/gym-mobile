import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';

class AuthService extends ChangeNotifier {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user';

  final Dio _dio = Dio();
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  String? _accessToken;
  String? _refreshToken;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  String? get accessToken => _accessToken;

  AuthService() {
    _setupInterceptors();
    _loadFromStorage();
  }

  void _setupInterceptors() {
    // Request interceptor to add auth header
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 && _refreshToken != null) {
            // Try to refresh token
            try {
              await _refreshAccessToken();
              
              // Retry the original request
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $_accessToken';
              
              final response = await _dio.fetch(opts);
              handler.resolve(response);
              return;
            } catch (e) {
              // Refresh failed, logout user
              await logout();
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _accessToken = prefs.getString(_accessTokenKey);
      _refreshToken = prefs.getString(_refreshTokenKey);
      
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        _user = json.decode(userJson);
      }

      _isAuthenticated = _accessToken != null && _user != null;
      notifyListeners();
    } catch (e) {
      print('Error loading auth data from storage: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_accessToken != null) {
        await prefs.setString(_accessTokenKey, _accessToken!);
      } else {
        await prefs.remove(_accessTokenKey);
      }

      if (_refreshToken != null) {
        await prefs.setString(_refreshTokenKey, _refreshToken!);
      } else {
        await prefs.remove(_refreshTokenKey);
      }

      if (_user != null) {
        await prefs.setString(_userKey, json.encode(_user!));
      } else {
        await prefs.remove(_userKey);
      }
    } catch (e) {
      print('Error saving auth data to storage: $e');
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/auth/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
        },
      );

      final data = response.data;
      
      _accessToken = data['accessToken'];
      _refreshToken = data['refreshToken'];
      _user = data['user'];
      _isAuthenticated = true;

      await _saveToStorage();
      notifyListeners();

      return data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data;
      
      _accessToken = data['accessToken'];
      _refreshToken = data['refreshToken'];
      _user = data['user'];
      _isAuthenticated = true;

      await _saveToStorage();
      notifyListeners();

      return data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      if (_accessToken != null) {
        await _dio.post('${ApiConfig.baseUrl}/auth/logout');
      }
    } catch (e) {
      print('Error during logout: $e');
    } finally {
      _accessToken = null;
      _refreshToken = null;
      _user = null;
      _isAuthenticated = false;

      await _saveToStorage();
      notifyListeners();
    }
  }

  Future<void> _refreshAccessToken() async {
    if (_refreshToken == null) {
      throw Exception('No refresh token available');
    }

    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/auth/refresh',
        data: {
          'refreshToken': _refreshToken,
        },
      );

      final data = response.data;
      
      _accessToken = data['accessToken'];
      _refreshToken = data['refreshToken'];
      _user = data['user'];

      await _saveToStorage();
      notifyListeners();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
      return 'Server error: ${error.response!.statusCode}';
    } else if (error.type == DioExceptionType.connectionTimeout ||
               error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (error.type == DioExceptionType.connectionError) {
      return 'Unable to connect to server. Please check your internet connection.';
    } else {
      return 'An unexpected error occurred.';
    }
  }
}