import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/task_provider.dart';
import '../../config/constants.dart';

class TaskCreateScreen extends StatefulWidget {
  const TaskCreateScreen({super.key});

  @override
  State<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends State<TaskCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _urgency = 'flexible';
  String? _provider;

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Task'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Description
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        hintText: 'Describe what you need done...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      validator: (v) => v!.isEmpty ? 'Please enter a description' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Urgency
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Urgency',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...AppConstants.urgencyLevels.map((level) => RadioListTile<String>(
                      title: Text(_getUrgencyLabel(level)),
                      subtitle: Text(_getUrgencyDescription(level)),
                      value: level,
                      groupValue: _urgency,
                      onChanged: (value) => setState(() => _urgency = value!),
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // AI Provider
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Provider (Optional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Leave empty for automatic selection',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _provider,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Auto (recommended)',
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Auto')),
                        ...AppConstants.aiProviders.map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.toUpperCase()),
                        )),
                      ],
                      onChanged: (value) => setState(() => _provider = value),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Create Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: taskProvider.isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          final task = await taskProvider.createTask(
                            description: _descriptionController.text,
                            urgency: _urgency,
                            provider: _provider,
                          );

                          if (task != null && mounted) {
                            context.pop();
                            context.push('/tasks/${task.id}');
                          }
                        }
                      },
                child: taskProvider.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Create Task'),
              ),
            ),

            if (taskProvider.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      taskProvider.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getUrgencyLabel(String level) {
    switch (level) {
      case 'urgent':
        return 'Urgent (1 hour)';
      case 'normal':
        return 'Normal (Today)';
      case 'flexible':
        return 'Flexible (When possible)';
      default:
        return level;
    }
  }

  String _getUrgencyDescription(String level) {
    switch (level) {
      case 'urgent':
        return 'Higher priority, may cost more';
      case 'normal':
        return 'Standard processing time';
      case 'flexible':
        return 'Lower cost, processed when resources available';
      default:
        return '';
    }
  }
}
