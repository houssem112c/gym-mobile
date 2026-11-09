class ApiConfig {
  // Replace with your computer's IP address when testing on physical device
  // For emulator: use 10.0.2.2 (Android) or localhost (iOS)
  static const String baseUrl = 'https://gym-backend-1-qchc.onrender.com/api';
  
  // Endpoints
  static const String courses = '/courses';
  static const String calendar = '/courses/calendar';
  static const String locations = '/locations';
  static const String locationsActive = '/locations/active';
  static const String contacts = '/contacts';
  static const String feed = '/feed';

  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
