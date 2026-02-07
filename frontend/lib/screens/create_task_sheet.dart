import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import 'chat_screen.dart';

class CreateTaskSheet extends StatefulWidget {
  @override
  _CreateTaskSheetState createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<CreateTaskSheet> {
  final _controller = TextEditingController();
  String _urgency = 'flexible';
  bool _submitting = false;

  void _submit() async {
    if (_controller.text.isEmpty) return;
    setState(() => _submitting = true);
    
    final newTask = await Provider.of<TaskProvider>(context, listen: false).createTask(
      _controller.text,
      _urgency,
    );
    
    if (mounted) {
      Navigator.pop(context); // Close the bottom sheet
      
      // Navigate to chat screen for the newly created task
      if (newTask != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(task: newTask),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("New Task", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Describe what you need done...",
              labelText: "Task Description"
            ),
          ),
          const SizedBox(height: 16),
          const Text("Urgency", style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: [
              _urgencyChip("flexible", "Flexible"),
              _urgencyChip("tomorrow", "Tomorrow"),
              _urgencyChip("today", "Today"),
              _urgencyChip("1h", "ASAP (1h)"),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: _submitting 
              ? const CircularProgressIndicator(color: Colors.white) 
              : const Text("Start Task"),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _urgencyChip(String value, String label) {
    bool selected = _urgency == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) => setState(() => _urgency = value),
    );
  }
}
