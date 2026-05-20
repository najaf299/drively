import '../utils/json_utils.dart';

/// Host onboarding verification state (matches `HostVerificationResource` and
/// the `GET /host/verification/status` response, which returns
/// `{ "status": "not_started" }` before onboarding begins).
class HostVerification {
  final bool notStarted;
  final String identityStatus; // pending | submitted | approved | rejected
  final String bankStatus;
  final String vehicleStatus;
  final String agreementStatus;
  final bool isComplete;
  final DateTime? completedAt;

  const HostVerification({
    this.notStarted = false,
    this.identityStatus = 'pending',
    this.bankStatus = 'pending',
    this.vehicleStatus = 'pending',
    this.agreementStatus = 'pending',
    this.isComplete = false,
    this.completedAt,
  });

  /// Ordered (key, label, status) tuples for the 4-step wizard UI.
  List<HostVerificationStep> get steps => [
        HostVerificationStep('identity', 'Identity', identityStatus),
        HostVerificationStep('bank', 'Bank account', bankStatus),
        HostVerificationStep('vehicle', 'Vehicle documents', vehicleStatus),
        HostVerificationStep('agreement', 'Host agreement', agreementStatus),
      ];

  int get completedSteps => steps
      .where((s) => s.status == 'approved' || s.status == 'submitted')
      .length;

  factory HostVerification.fromJson(Map<String, dynamic> json) {
    if (asString(json['status']) == 'not_started') {
      return const HostVerification(notStarted: true);
    }
    return HostVerification(
      identityStatus: asString(json['identity_status'], fallback: 'pending'),
      bankStatus: asString(json['bank_status'], fallback: 'pending'),
      vehicleStatus: asString(json['vehicle_status'], fallback: 'pending'),
      agreementStatus: asString(json['agreement_status'], fallback: 'pending'),
      isComplete: asBool(json['is_complete']),
      completedAt: asDateTime(json['completed_at']),
    );
  }
}

/// A single step in the host verification wizard.
class HostVerificationStep {
  final String key; // identity | bank | vehicle | agreement
  final String label;
  final String status;

  const HostVerificationStep(this.key, this.label, this.status);

  bool get isApproved => status == 'approved';
  bool get isSubmitted => status == 'submitted' || status == 'in_review';
  bool get isRejected => status == 'rejected';
}
