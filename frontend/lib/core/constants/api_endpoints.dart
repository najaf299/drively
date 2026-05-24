class ApiEndpoints {
  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String googleAuth = '/auth/google';
  static const String appleAuth = '/auth/apple';
  static const String sendOtp = '/auth/otp/send';
  static const String verifyOtp = '/auth/otp/verify';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Profile
  static const String profile = '/profile';

  // KYC
  static const String kycStatus = '/kyc/status';
  static const String kycSubmit = '/kyc/submit';

  // Cars (Public)
  static const String cars = '/cars';
  static String carDetail(String id) => '/cars/$id';
  static String carReviews(String id) => '/cars/$id/reviews';

  // Customer Bookings
  static const String customerBookings = '/customer/bookings';
  static const String bookingPricing = '/customer/bookings/pricing';
  static String bookingDetail(String id) => '/customer/bookings/$id';
  static String cancelBooking(String id) => '/customer/bookings/$id/cancel';
  static String payBooking(String id) => '/customer/bookings/$id/pay';
  static String confirmPayment(String id) =>
      '/customer/bookings/$id/payment/confirm';
  static String bookingReview(String id) => '/customer/bookings/$id/review';

  // Customer Trips
  static String tripDetail(String id) => '/customer/trips/$id';
  static String startTrip(String bookingId) =>
      '/customer/bookings/$bookingId/trip/start';
  static String endTrip(String tripId) => '/customer/trips/$tripId/end';
  static String updateTripLocation(String tripId) =>
      '/customer/trips/$tripId/location';
  static String extendTrip(String tripId) => '/customer/trips/$tripId/extend';

  // Customer Reviews
  static const String myReviews = '/customer/reviews';

  // Customer Favorites
  static const String favorites = '/customer/favorites';
  static const String toggleFavorite = '/customer/favorites/toggle';

  // Customer Wallet
  static const String wallet = '/customer/wallet';
  static const String walletTransactions = '/customer/wallet/transactions';
  static const String walletTopUp = '/customer/wallet/top-up';

  // Customer Disputes
  static const String disputes = '/customer/disputes';
  static String bookingDispute(String bookingId) =>
      '/customer/bookings/$bookingId/dispute';
  static String disputeDetail(String disputeId) =>
      '/customer/disputes/$disputeId';

  // Host Verification
  static const String hostVerificationStatus = '/host/verification/status';
  static const String hostVerificationInitiate = '/host/verification/initiate';
  static const String hostVerificationStep = '/host/verification/step';
  static const String hostStats = '/host/stats';

  // Host Cars
  static const String hostCars = '/host/cars';
  static String hostCarDetail(String id) => '/host/cars/$id';
  static String hostCarPhotos(String id) => '/host/cars/$id/photos';
  static String deleteHostCarPhoto(String carId, String photoId) =>
      '/host/cars/$carId/photos/$photoId';

  // Host Bookings
  static const String hostBookings = '/host/bookings';
  static String approveBooking(String id) => '/host/bookings/$id/approve';
  static String declineBooking(String id) => '/host/bookings/$id/decline';

  // Host Earnings
  static const String hostEarnings = '/host/earnings';
  static const String hostEarningsHistory = '/host/earnings/history';

  // Chat
  static const String chatThreads = '/chat/threads';
  static String threadMessages(String id) => '/chat/threads/$id/messages';
  static const String sendMessage = '/chat/messages';
  static String markThreadAsRead(String id) => '/chat/threads/$id/read';

  // Notifications
  static const String notifications = '/notifications';
  static String markNotificationRead(String id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static const String registerDevice = '/notifications/devices';
  static const String unregisterDevice = '/notifications/devices';

  // Admin (for future use)
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static String adminUserDetail(String id) => '/admin/users/$id';
  static String suspendUser(String id) => '/admin/users/$id/suspend';
  static String unsuspendUser(String id) => '/admin/users/$id/unsuspend';
  static const String adminCars = '/admin/cars';
  static String adminCarApprove(String id) => '/admin/cars/$id/approve';
  static String adminCarReject(String id) => '/admin/cars/$id/reject';
  static String adminCarSuspend(String id) => '/admin/cars/$id/suspend';
  static const String adminKycPending = '/admin/kyc/pending';
  static String adminKycReview(String docId) => '/admin/kyc/$docId/review';
  static const String adminDisputes = '/admin/disputes';
  static String adminDisputeResolve(String disputeId) =>
      '/admin/disputes/$disputeId/resolve';
  static String adminDisputeEscalate(String disputeId) =>
      '/admin/disputes/$disputeId/escalate';
  static const String adminPromoCodes = '/admin/promo-codes';
  static String adminPromoCodeDetail(String code) => '/admin/promo-codes/$code';

  // Webhooks
  static const String stripeWebhook = '/webhooks/stripe';
}
