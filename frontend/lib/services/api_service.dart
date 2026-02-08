import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/constants.dart';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    // Add interceptor for auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.keyToken);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired, clear storage
          await _storage.delete(key: AppConstants.keyToken);
          await _storage.delete(key: AppConstants.keyUserId);
        }
        return handler.next(error);
      },
    ));
  }
  
  // Auth
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      AppConstants.authRegister,
      data: {'email': email, 'password': password},
    );
    return response.data;
  }
  
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      AppConstants.authLogin,
      data: {'email': email, 'password': password},
    );
    
    // Save token
    if (response.data['access_token'] != null) {
      await _storage.write(
        key: AppConstants.keyToken,
        value: response.data['access_token'],
      );
    }
    
    return response.data;
  }
  
  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get(AppConstants.authMe);
    return response.data;
  }
  
  Future<void> logout() async {
    await _dio.post(AppConstants.authLogout);
    await _storage.delete(key: AppConstants.keyToken);
    await _storage.delete(key: AppConstants.keyUserId);
  }
  
  // Tasks
  Future<Map<String, dynamic>> estimatePrice({
    required String description,
    String urgency = 'flexible',
    String? provider,
  }) async {
    final response = await _dio.post(
      AppConstants.tasksEstimatePrice,
      data: {
        'description': description,
        'urgency': urgency,
        if (provider != null) 'provider': provider,
      },
    );
    return response.data;
  }
  
  Future<Map<String, dynamic>> createTask({
    required String description,
    String urgency = 'flexible',
    String? provider,
    String? deadline,
  }) async {
    final response = await _dio.post(
      AppConstants.tasks,
      data: {
        'description': description,
        'urgency': urgency,
        if (provider != null) 'provider': provider,
        if (deadline != null) 'deadline': deadline,
      },
    );
    return response.data;
  }
  
  Future<List<dynamic>> getTasks() async {
    final response = await _dio.get(AppConstants.tasks);
    return response.data as List;
  }
  
  Future<Map<String, dynamic>> getTask(int taskId) async {
    final response = await _dio.get('${AppConstants.tasks}/$taskId');
    return response.data;
  }
  
  Future<void> deleteTask(int taskId) async {
    await _dio.delete('${AppConstants.tasks}/$taskId');
  }
  
  Future<Map<String, dynamic>> cancelTask(int taskId) async {
    final response = await _dio.post('${AppConstants.tasks}/$taskId/cancel');
    return response.data;
  }
  
  // Chat
  Future<List<dynamic>> getMessages(int taskId) async {
    final response = await _dio.get(
      '/tasks/$taskId/chat',
    );
    return response.data as List;
  }
  
  Future<Map<String, dynamic>> sendMessage({
    required int taskId,
    String? content,
    String? fileUrl,
    String? fileName,
    String? fileType,
  }) async {
    final response = await _dio.post(
      '/tasks/$taskId/chat',
      data: {
        if (content != null) 'content': content,
        if (fileUrl != null) 'file_url': fileUrl,
        if (fileName != null) 'file_name': fileName,
        if (fileType != null) 'file_type': fileType,
      },
    );
    return response.data;
  }
  
  // Payments
  Future<Map<String, dynamic>> createCheckoutSession(int taskId) async {
    final response = await _dio.post(
      '${AppConstants.paymentsCheckout}/$taskId',
    );
    return response.data;
  }
  
  Future<Map<String, dynamic>> mockPay(int taskId) async {
    final response = await _dio.post(
      '${AppConstants.paymentsMockPay}/$taskId',
    );
    return response.data;
  }
  
  Future<Map<String, dynamic>> confirmTaskPayment(int taskId) async {
    final response = await _dio.post(
      '/tasks/$taskId/confirm',
    );
    return response.data;
  }
  
  // File Upload
  Future<Map<String, dynamic>> uploadFile({
    String? filePath,
    List<int>? bytes,
    required String filename,
  }) async {
    MultipartFile multipartFile;
    
    if (bytes != null) {
      // Web: use bytes
      multipartFile = MultipartFile.fromBytes(bytes, filename: filename);
    } else if (filePath != null) {
      // Mobile: use file path
      multipartFile = await MultipartFile.fromFile(filePath, filename: filename);
    } else {
      throw Exception('Either filePath or bytes must be provided');
    }
    
    final formData = FormData.fromMap({
      'file': multipartFile,
    });
    
    final response = await _dio.post(
      AppConstants.upload,
      data: formData,
    );
    return response.data;
  }
}
