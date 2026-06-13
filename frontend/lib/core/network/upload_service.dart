import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/api_endpoints.dart';
import '../utils/json_utils.dart';
import 'api_response.dart';
import 'dio_client.dart';
import 'error_handler.dart';

final uploadServiceProvider = Provider<UploadService>((ref) {
  return UploadService(ref.read(dioProvider));
});

/// Single funnel for turning a picked image into a stored URL.
///
/// The backend stores every image as a URL (car photos, KYC docs, chat images,
/// trip inspection shots), so each of those features does: pick → [uploadImage]
/// → send the returned URL to its own endpoint. Posts multipart to `/uploads`.
class UploadService {
  final Dio _dio;
  UploadService(this._dio);

  /// Uploads a single picked image and returns its public URL.
  /// [folder] is one of: car_photos, kyc, chat, trips, misc.
  Future<String> uploadImage(XFile file, {String folder = 'misc'}) async {
    try {
      final form = FormData.fromMap({
        'folder': folder,
        'file': await MultipartFile.fromFile(file.path, filename: file.name),
      });
      final res = await _dio.post(
        ApiEndpoints.uploads,
        data: form,
        // Override the client's default application/json so Dio emits the
        // multipart boundary header.
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = ApiResponse.data(res.data);
      return asString((data as Map)['url']);
    } catch (e) {
      throw mapError(e);
    }
  }

  /// Uploads several images in order and returns their URLs. Stops and rethrows
  /// on the first failure so the caller can surface a single error.
  Future<List<String>> uploadImages(
    List<XFile> files, {
    String folder = 'misc',
  }) async {
    final urls = <String>[];
    for (final file in files) {
      urls.add(await uploadImage(file, folder: folder));
    }
    return urls;
  }
}
