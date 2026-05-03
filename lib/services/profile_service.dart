import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../config/api_config.dart';
import '../config/supabase_config.dart';
import '../models/user.dart';

class ProfileService {
  final Dio _dio = Dio();
  
  SupabaseClient get _supabase {
    if (!SupabaseConfig.isConfigured) {
      throw Exception('Supabase is not configured. Please check SupabaseConfig.');
    }
    
    // Check if Supabase instance is initialized
    try {
      final client = Supabase.instance.client;
      return client;
    } catch (e) {
      throw Exception('Supabase not initialized. Please restart the app. Error: $e');
    }
  }

  // Upload profile image to Supabase
  Future<String> uploadProfileImage(File? imageFile, String userId, {Uint8List? imageBytes, String? fileName}) async {
    try {
      print('🖼️  Starting profile image upload...');
      print('📁  Supabase configured: ${SupabaseConfig.isConfigured}');
      
      if (!SupabaseConfig.isConfigured) {
        print('⚠️  Supabase not configured. Please check SUPABASE_SETUP.md');
        throw Exception('Supabase not configured. Please set up Supabase credentials in SupabaseConfig.');
      }

      // Create a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String finalFileName;
      
      if (fileName != null) {
        final extension = fileName.split('.').last;
        finalFileName = 'profile_${userId}_$timestamp.$extension';
      } else if (imageFile != null) {
        final extension = imageFile.path.split('.').last;
        finalFileName = 'profile_${userId}_$timestamp.$extension';
      } else {
        finalFileName = 'profile_${userId}_$timestamp.jpg';
      }
      
      print('📁  Uploading to bucket: ${SupabaseConfig.profilesBucket}');
      print('📂  File name: $finalFileName');
      
      if (kIsWeb) {
        // For web, use provided bytes or read from file
        final bytes = imageBytes ?? (imageFile != null ? await imageFile.readAsBytes() : null);
        if (bytes == null) {
          throw Exception('No image data provided for web upload');
        }
        
        print('🌐  Web upload: ${bytes.length} bytes');
        
        // Upload to Supabase Storage using bytes
        await _supabase.storage
            .from(SupabaseConfig.profilesBucket)
            .uploadBinary(finalFileName, bytes);
            
        print('✅  Web upload completed');
      } else {
        // For mobile platforms, upload the file directly
        if (imageFile == null) {
          throw Exception('No image file provided for mobile upload');
        }
        
        print('📱  Mobile upload: ${imageFile.path}');
        
        await _supabase.storage
            .from(SupabaseConfig.profilesBucket)
            .upload(finalFileName, imageFile);
            
        print('✅  Mobile upload completed');
      }

      // Get the public URL
      final publicUrl = _supabase.storage
          .from(SupabaseConfig.profilesBucket)
          .getPublicUrl(finalFileName);

      print('🌍  Public URL generated: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌  Upload failed: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // Update user profile
  Future<User> updateProfile({
    required String token,
    String? name,
    String? bio,
    String? phone,
    DateTime? dateOfBirth,
    String? address,
    String? city,
    String? country,
    String? avatarUrl,
    int? trainingFrequency,
    List<int>? trainingDays,
  }) async {
    try {
      final data = <String, dynamic>{};
      
      if (name != null) data['name'] = name;
      if (bio != null) data['bio'] = bio;
      if (phone != null) data['phone'] = phone;
      if (dateOfBirth != null) data['dateOfBirth'] = dateOfBirth.toIso8601String();
      if (address != null) data['address'] = address;
      if (city != null) data['city'] = city;
      if (country != null) data['country'] = country;
      if (avatarUrl != null) data['avatar'] = avatarUrl;
      if (trainingFrequency != null) data['trainingFrequency'] = trainingFrequency;
      if (trainingDays != null) data['trainingDays'] = trainingDays;

      final response = await _dio.patch(
        '${ApiConfig.baseUrl}/auth/profile',
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get user profile
  Future<User> getProfile(String token) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/auth/profile',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update profile with image
  Future<User> updateProfileWithImage({
    required String token,
    required String userId,
    String? name,
    String? bio,
    String? phone,
    DateTime? dateOfBirth,
    String? address,
    String? city,
    String? country,
    File? imageFile,
    Uint8List? imageBytes,
    String? imageFileName,
    int? trainingFrequency,
    List<int>? trainingDays,
  }) async {
    try {
      String? avatarUrl;
      
      print('👤  Updating profile for user: $userId');
      
      // Upload image first if provided and Supabase is configured
      if (imageFile != null || imageBytes != null) {
        if (SupabaseConfig.isConfigured) {
          print('🖼️  Image provided, uploading to Supabase...');
          avatarUrl = await uploadProfileImage(
            imageFile, 
            userId, 
            imageBytes: imageBytes,
            fileName: imageFileName,
          );
          print('✅  Avatar URL: $avatarUrl');
        } else {
          // If Supabase is not configured, we'll skip image upload
          print('⚠️  Supabase not configured, skipping image upload');
          print('📖  Please check SUPABASE_SETUP.md for setup instructions');
        }
      }

      print('🔄  Updating profile on backend...');
      
      // Update profile
      final updatedUser = await updateProfile(
        token: token,
        name: name,
        bio: bio,
        phone: phone,
        dateOfBirth: dateOfBirth,
        address: address,
        city: city,
        country: country,
        avatarUrl: avatarUrl,
        trainingFrequency: trainingFrequency,
        trainingDays: trainingDays,
      );
      
      print('✅  Profile updated successfully');
      print('🖼️  Final avatar URL: ${updatedUser.avatar}');
      
      return updatedUser;
    } catch (e) {
      print('❌  Profile update failed: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<Map<String, dynamic>> save2dAvatar({
    required String token,
    required Map<String, dynamic> config,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/avatars/me/config',
        data: config,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getMy2dAvatar({
    required String token,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/avatars/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteMy2dAvatar({
    required String token,
  }) async {
    try {
      await _dio.delete(
        '${ApiConfig.baseUrl}/avatars/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
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