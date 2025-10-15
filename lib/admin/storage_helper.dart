import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageHelper {
  static const String bucket = 'product-images';

  // Pick image from gallery (returns File path) or null if cancelled
  static Future<File?> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;
    return File(picked.path);
  }

  // Upload bytes or File to storage; returns path (bucket path) on success
  static Future<String> uploadFile(File file) async {
    final client = Supabase.instance.client;
    final ext = file.path.split('.').last;
    final bytes = await file.readAsBytes();

    // Generate filename and try upload. If a 409 Duplicate occurs (very rare
    // because we use UUIDs), retry a few times with a fresh UUID.
    const maxAttempts = 4;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final filename = '${const Uuid().v4()}.$ext';
      final path = 'images/$filename';
      try {
        // Prefer newer uploadBinary API if available
        await client.storage.from(bucket).uploadBinary(path, bytes);
        return path;
      } catch (e) {
        // If it's a StorageException with 409 (Duplicate), retry with a new UUID
        final msg = e.toString();
        if (msg.contains('409') || msg.toLowerCase().contains('duplicate')) {
          // try next attempt
          if (attempt == maxAttempts - 1) rethrow;
          continue;
        }

        // Fallback to older upload API once if uploadBinary fails for other reasons
        try {
          await client.storage.from(bucket).upload(path, file);
          return path;
        } catch (e2) {
          // If this was a duplicate and we have attempts left, retry
          final msg2 = e2.toString();
          if ((msg2.contains('409') ||
                  msg2.toLowerCase().contains('duplicate')) &&
              attempt < maxAttempts - 1) {
            continue;
          }
          rethrow;
        }
      }
    }
    // Shouldn't reach here
    throw Exception('Upload failed after $maxAttempts attempts');
  }

  // For public bucket return public URL (client-side)
  static String publicUrlForPath(String path) {
    // If caller already passed a full URL, just return it.
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final client = Supabase.instance.client;
    final dynamic obj = client.storage.from(bucket).getPublicUrl(path);
    // SDKs differ: sometimes getPublicUrl returns a String, sometimes an
    // object with a publicUrl property or map with 'publicUrl' key.
    if (obj is String) return obj;
    if (obj is Map<String, dynamic>) {
      return obj['publicUrl'] ?? obj['public_url'] ?? obj['publicurl'] ?? '';
    }
    // Fallback: try dynamic access, but protect against NoSuchMethodError
    try {
      return obj.publicUrl ?? obj['publicUrl'] ?? '';
    } catch (_) {
      return '';
    }
  }
}
