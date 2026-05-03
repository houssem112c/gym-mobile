import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<String?> uploadImage(XFile imageFile, String bucket, String userId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.name.split('.').last;
      final finalFileName = 'feed_${userId}_$timestamp.$extension';
      
      final Uint8List bytes = await imageFile.readAsBytes();
      
      await _supabase.storage.from(bucket).uploadBinary(
        finalFileName, 
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      return _supabase.storage.from(bucket).getPublicUrl(finalFileName);
    } catch (e) {
      print('❌ Supabase Upload Error: $e');
      return null;
    }
  }

  Future<List<String>> uploadMultipleImages(List<XFile> files, String bucket, String userId) async {
    List<String> urls = [];
    for (var file in files) {
      final url = await uploadImage(file, bucket, userId);
      if (url != null) {
        urls.add(url);
      }
    }
    return urls;
  }
}
