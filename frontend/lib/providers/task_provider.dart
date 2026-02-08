import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/task.dart';

class TaskProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Task> _tasks = [];
  Task? _selectedTask;
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;

  List<Task> get tasks => _tasks;
  Task? get selectedTask => _selectedTask;
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final data = await _apiService.getTasks();
      _tasks = data.map((json) => Task.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchTask(int taskId) async {
    try {
      final data = await _apiService.getTask(taskId);
      _selectedTask = Task.fromJson(data);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<Task?> createTask({
    required String description,
    String urgency = 'flexible',
    String? provider,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final data = await _apiService.createTask(
        description: description,
        urgency: urgency,
        provider: provider,
      );
      
      final task = Task.fromJson(data);
      _tasks.insert(0, task);
      _isLoading = false;
      notifyListeners();
      return task;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteTask(int taskId) async {
    try {
      await _apiService.deleteTask(taskId);
      _tasks.removeWhere((task) => task.id == taskId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> cancelTask(int taskId) async {
    try {
      final data = await _apiService.cancelTask(taskId);
      final updatedTask = Task.fromJson(data);
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Chat
  Future<void> fetchMessages(int taskId) async {
    try {
      final data = await _apiService.getMessages(taskId);
      _messages = data.map((json) => Message.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> sendMessage(
    int taskId, 
    {String? content, 
    String? fileUrl, 
    String? fileName, 
    String? fileType}
  ) async {
    try {
      final data = await _apiService.sendMessage(
        taskId: taskId, 
        content: content,
        fileUrl: fileUrl,
        fileName: fileName,
        fileType: fileType,
      );
      _messages.add(Message.fromJson(data));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<Map<String, dynamic>?> uploadFile({
    String? filePath,
    List<int>? bytes,
    required String filename,
  }) async {
    try {
      return await _apiService.uploadFile(
        filePath: filePath,
        bytes: bytes,
        filename: filename,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
  
  Future<void> uploadAndSendFile(
    int taskId,
    {
      String? filePath,
      List<int>? bytes,
      required String filename,
      String? message,
    }
  ) async {
    try {
      // Upload file first
      final uploadResult = await uploadFile(
        filePath: filePath,
        bytes: bytes,
        filename: filename,
      );
      
      if (uploadResult != null) {
        // Send message with file attachment
        await sendMessage(
          taskId,
          content: message,
          fileUrl: uploadResult['url'],
          fileName: uploadResult['filename'],
          fileType: uploadResult['file_type'],
        );
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Payment
  Future<String?> getCheckoutUrl(int taskId) async {
    try {
      final data = await _apiService.createCheckoutSession(taskId);
      return data['url'];
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
  
  Future<bool> confirmPayment(int taskId) async {
    try {
      await _apiService.confirmTaskPayment(taskId);
      // Refresh task to get updated status
      await fetchTask(taskId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}

