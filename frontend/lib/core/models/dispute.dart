import 'package:json_annotation/json_annotation.dart';

part 'dispute.g.dart';

@JsonSerializable()
class Dispute {
  final String id;
  final String bookingId;
  final String raisedBy;
  final String disputeType; // 'damage', 'late_return', 'cleaning', 'odometer', 'other'
  final String description;
  final List<String>? evidencePhotos;
  final double? claimedAmount;
  final String status; // 'pending', 'under_review', 'resolved', 'escalated', 'rejected'
  final String? resolution;
  final double? awardedAmount;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Nested relationships
  final Map<String, dynamic>? bookingInfo;

  Dispute({
    required this.id,
    required this.bookingId,
    required this.raisedBy,
    required this.disputeType,
    required this.description,
    this.evidencePhotos,
    this.claimedAmount,
    required this.status,
    this.resolution,
    this.awardedAmount,
    this.resolvedAt,
    this.resolvedBy,
    required this.createdAt,
    required this.updatedAt,
    this.bookingInfo,
  });

  factory Dispute.fromJson(Map<String, dynamic> json) => _$DisputeFromJson(json);
  Map<String, dynamic> toJson() => _$DisputeToJson(this);

  bool get isPending => status == 'pending';
  bool get isUnderReview => status == 'under_review';
  bool get isResolved => status == 'resolved';
  bool get isEscalated => status == 'escalated';
  bool get isRejected => status == 'rejected';
}

@JsonSerializable()
class DisputeSubmission {
  final String bookingId;
  final String disputeType;
  final String description;
  final List<String>? evidencePhotos;
  final double? claimedAmount;

  DisputeSubmission({
    required this.bookingId,
    required this.disputeType,
    required this.description,
    this.evidencePhotos,
    this.claimedAmount,
  });

  factory DisputeSubmission.fromJson(Map<String, dynamic> json) => _$DisputeSubmissionFromJson(json);
  Map<String, dynamic> toJson() => _$DisputeSubmissionToJson(this);
}
