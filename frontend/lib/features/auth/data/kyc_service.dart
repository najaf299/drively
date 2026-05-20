import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/error_handler.dart';
import '../../../core/utils/json_utils.dart';

final kycServiceProvider = Provider<KycService>((ref) {
  return KycService(ref.read(dioProvider));
});

/// Current KYC state: overall [status] plus the submitted [documents].
class KycStatus {
  final String status; // none | pending | in_review | approved | rejected
  final List<Map<String, dynamic>> documents;

  const KycStatus({required this.status, this.documents = const []});

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending' || status == 'in_review';

  factory KycStatus.fromJson(Map<String, dynamic> json) => KycStatus(
        status: asString(json['kyc_status'], fallback: 'none'),
        documents: (json['documents'] is List)
            ? (json['documents'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : const [],
      );
}

/// KYC document submission (`/kyc/*`).
class KycService {
  final Dio _dio;
  KycService(this._dio);

  Future<KycStatus> status() async {
    try {
      final res = await _dio.get(ApiEndpoints.kycStatus);
      return KycStatus.fromJson(asMap(ApiResponse.data(res.data)) ?? {});
    } catch (e) {
      throw mapError(e);
    }
  }

  /// Submits a document. Image upload happens out-of-band (R2); the resulting
  /// URLs are passed here.
  Future<void> submit({
    required String documentType,
    required String frontUrl,
    String? backUrl,
    String? selfieUrl,
  }) async {
    try {
      await _dio.post(ApiEndpoints.kycSubmit, data: {
        'document_type': documentType,
        'front_url': frontUrl,
        if (backUrl != null) 'back_url': backUrl,
        if (selfieUrl != null) 'selfie_url': selfieUrl,
      });
    } catch (e) {
      throw mapError(e);
    }
  }
}
