import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Unsigned-upload config for the KSVL Cloudinary account. Set once at app
/// startup (see main.dart in admin_app) before any upload is attempted.
class CloudinaryConfig {
  const CloudinaryConfig({required this.cloudName, required this.uploadPreset});

  final String cloudName;
  final String uploadPreset;

  static CloudinaryConfig? _current;

  static void configure(CloudinaryConfig config) => _current = config;

  static CloudinaryConfig get current {
    final c = _current;
    if (c == null) {
      throw StateError(
        'CloudinaryConfig.configure() must be called before uploading images.',
      );
    }
    return c;
  }

  static bool get isConfigured => _current != null;
}

/// Uploads product/banner photos to Cloudinary via an unsigned upload
/// preset (no backend server available to sign requests).
class CloudinaryService {
  CloudinaryService._();

  static final CloudinaryService instance = CloudinaryService._();

  Future<String> uploadImage(Uint8List bytes, {required String folder}) async {
    final config = CloudinaryConfig.current;
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${config.cloudName}/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = config.uploadPreset
      ..fields['folder'] = folder
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: 'upload.jpg'),
      );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) {
      throw Exception('Cloudinary upload failed: ${response.body}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['secure_url'] as String;
  }
}
