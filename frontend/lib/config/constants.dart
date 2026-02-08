class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://localhost:8000';
  static const String apiVersion = '/api/v1';
  static const String apiBaseUrl = '$baseUrl$apiVersion';
  
  // Endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authMe = '/auth/me';
  static const String authLogout = '/auth/logout';
  
  static const String tasks = '/tasks';
  static const String tasksEstimatePrice = '/tasks/estimate-price';
  
  static const String chat = '/chat';
  static const String upload = '/upload';
  
  static const String paymentsCheckout = '/payments/create-checkout-session';
  static const String paymentsMockPay = '/payments/mock-pay';
  
  // Storage Keys
  static const String keyToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyLanguage = 'app_language';
  static const String keyTheme = 'app_theme';
  static const String keyProvider = 'default_provider';
  
  // Defaults
  static const List<String> supportedLanguages = ['en', 'de'];
  static const List<String> aiProviders = ['openai', 'claude', 'gemini', 'ollama'];
  static const List<String> urgencyLevels = ['urgent', 'normal', 'flexible'];
}
