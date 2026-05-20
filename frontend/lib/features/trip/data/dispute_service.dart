import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/dispute.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/error_handler.dart';

final disputeServiceProvider = Provider<DisputeService>((ref) {
  return DisputeService(ref.read(dioProvider));
});

/// Customer dispute endpoints (`/customer/disputes`).
class DisputeService {
  final Dio _dio;
  DisputeService(this._dio);

  Future<Paginated<Dispute>> list({int page = 1}) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.disputes,
        queryParameters: {'page': page},
      );
      return Paginated<Dispute>.from(
        ApiResponse.data(res.data),
        Dispute.fromJson,
      );
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<Dispute> create(
    String bookingId, {
    required String type,
    required String description,
    List<String>? evidenceUrls,
  }) async {
    try {
      final res = await _dio.post(ApiEndpoints.bookingDispute(bookingId), data: {
        'type': type,
        'description': description,
        if (evidenceUrls != null) 'evidence_urls': evidenceUrls,
      });
      return Dispute.fromJson(ApiResponse.data(res.data));
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<Dispute> get(String id) async {
    try {
      final res = await _dio.get(ApiEndpoints.disputeDetail(id));
      return Dispute.fromJson(ApiResponse.data(res.data));
    } catch (e) {
      throw mapError(e);
    }
  }
}
