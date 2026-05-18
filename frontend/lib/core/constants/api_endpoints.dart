class ApiEndpoints {
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String googleAuth = '/auth/google';
  static const String appleAuth = '/auth/apple';
  static const String sendOtp = '/auth/otp/send';
  static const String verifyOtp = '/auth/otp/verify';

  static const String profile = '/profile';
  static const String kycStatus = '/kyc/status';
  static const String kycSubmit = '/kyc/submit';

  static const String cars = '/cars';
  static String carDetail(String id) => '/cars/\$id';

  static const String customerBookings = '/customer/bookings';
  static String bookingDetail(String id) => '/customer/bookings/\$id';
  static String cancelBooking(String id) => '/customer/bookings/\$id/cancel';
  static const String favorites = '/customer/favorites';
  static const String toggleFavorite = '/customer/favorites/toggle';

  static const String hostCars = '/host/cars';
  static const String hostBookings = '/host/bookings';
  static String approveBooking(String id) => '/host/bookings/\$id/approve';
  static String declineBooking(String id) => '/host/bookings/\$id/decline';
  static const String hostEarnings = '/host/earnings';

  static const String chatThreads = '/chat/threads';
  static String threadMessages(String id) => '/chat/threads/\$id/messages';
  static const String sendMessage = '/chat/messages';
}
