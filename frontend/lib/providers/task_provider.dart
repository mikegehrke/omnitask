import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;
  
  // Change localhost to 10.0.2.2 for Android Emulator, or localhost for iOS/Web
  // For production this would be an ENV var or real domain
  static const String baseUrl = 'http://localhost:8000/api/v1'; 

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  Future<void> fetchTasks() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('$baseUrl/tasks/'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _tasks = data.map((json) => Task.fromJson(json)).toList();
      }
    } catch (e) {
      print("Error fetching tasks: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Task?> createTask(String description, String urgency) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tasks/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'description': description,
          'urgency': urgency, // 1h, today, tomorrow, flexible
        }),
      );
      if (response.statusCode == 200) {
        await fetchTasks();
        return Task.fromJson(json.decode(response.body));
      }
    } catch (e) {
      print("Error creating task: $e");
    }
    return null;
  }
  
  // Chat logic
  List<Message> _messages = [];
  List<Message> get messages => _messages;

  Future<void> fetchMessages(int taskId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/chat/$taskId/messages'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _messages = data.map((json) => Message.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
       print("Error chat: $e");
    }
  }

  Future<void> sendMessage(int taskId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/$taskId/messages'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'content': content}),
      );
      if (response.statusCode == 200) {
        _messages.add(Message.fromJson(json.decode(response.body)));
        notifyListeners();
      }
    } catch (e) {
       print("Send error: $e");
    }
  }
  
  // Payment
  Future<String?> getCheckoutUrl(int taskId) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/payments/create-checkout-session/$taskId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['url'];
      }
    } catch(e) {
      print("Payment error: $e");
    }
    return null;
  }
}
