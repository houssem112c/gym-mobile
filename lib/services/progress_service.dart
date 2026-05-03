import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/api_config.dart';
import '../config/supabase_config.dart';
import '../models/progress.dart';

class ProgressService {
  final Dio _dio = Dio();

  SupabaseClient get _supabase => Supabase.instance.client;

  // Take XFile instead of File for cross-platform support
  Future<String> uploadProgressPhoto(XFile imageFile, String userId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalFileName = 'progress_${userId}_$timestamp.${imageFile.name.split('.').last}';
      
      final Uint8List bytes = await imageFile.readAsBytes();
      
      // Use uploadBinary for both as it works everywhere with bytes
      await _supabase.storage.from(SupabaseConfig.profilesBucket).uploadBinary(
        finalFileName, 
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      return _supabase.storage.from(SupabaseConfig.profilesBucket).getPublicUrl(finalFileName);
    } catch (e) {
      throw Exception('Failed to upload progress photo: $e');
    }
  }

  // API Calls
  Future<UserProgressPhoto> addPhoto(String token, Map<String, dynamic> data) async {
    final response = await _dio.post(
      '${ApiConfig.baseUrl}/user-progress/photos',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return UserProgressPhoto.fromJson(response.data);
  }

  Future<List<UserProgressPhoto>> getPhotos(String token) async {
    final response = await _dio.get(
      '${ApiConfig.baseUrl}/user-progress/photos',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (response.data as List).map((e) => UserProgressPhoto.fromJson(e)).toList();
  }

  Future<UserMeasurement> addMeasurement(String token, Map<String, dynamic> data) async {
    final response = await _dio.post(
      '${ApiConfig.baseUrl}/user-progress/measurements',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return UserMeasurement.fromJson(response.data);
  }

  Future<List<UserMeasurement>> getMeasurements(String token) async {
    final response = await _dio.get(
      '${ApiConfig.baseUrl}/user-progress/measurements',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (response.data as List).map((e) => UserMeasurement.fromJson(e)).toList();
  }

  Future<UserPR> addPR(String token, Map<String, dynamic> data) async {
    final response = await _dio.post(
      '${ApiConfig.baseUrl}/user-progress/prs',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return UserPR.fromJson(response.data);
  }

  Future<List<UserPR>> getPRs(String token) async {
    final response = await _dio.get(
      '${ApiConfig.baseUrl}/user-progress/prs',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (response.data as List).map((e) => UserPR.fromJson(e)).toList();
  }
}
