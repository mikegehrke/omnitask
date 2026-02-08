import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/task_provider.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  String _filter = 'all'; // all, active, completed

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    
    var filteredTasks = taskProvider.tasks;
    if (_filter == 'active') {
      filteredTasks = filteredTasks.where((t) => 
        t.status != 'completed' && t.status != 'failed'
      ).toList();
    } else if (_filter == 'completed') {
      filteredTasks = filteredTasks.where((t) => t.status == 'completed').toList();
    }

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Aufträge', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[850],
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => taskProvider.fetchTasks(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Alle',
                  isSelected: _filter == 'all',
                  onSelected: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Aktiv',
                  isSelected: _filter == 'active',
                  onSelected: () => setState(() => _filter = 'active'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Erledigt',
                  isSelected: _filter == 'completed',
                  onSelected: () => setState(() => _filter = 'completed'),
                ),
              ],
            ),
          ),

          // Task List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => taskProvider.fetchTasks(),
              child: taskProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredTasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.task_alt, size: 64, color: Colors.grey[600]),
                              const SizedBox(height: 16),
                              Text(
                                'Keine Aufträge gefunden',
                                style: TextStyle(fontSize: 18, color: Colors.grey[400]),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () => context.push('/tasks/create'),
                                icon: const Icon(Icons.add),
                                label: const Text('Ersten Auftrag erstellen'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            return Card(
                              color: Colors.grey[850],
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: _buildStatusIcon(task.status),
                                title: Text(
                                  task.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    _buildStatusChip(task.status),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Preis: ${(task.costEstimate ?? 1.50).toStringAsFixed(2)} €',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                                    ),
                                  ],
                                ),
                                trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                                onTap: () => context.push('/tasks/${task.id}'),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;

    switch (status) {
      case 'completed':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'failed':
        icon = Icons.error;
        color = Colors.red;
        break;
      case 'analyzing':
      case 'planning':
      case 'executing':
        icon = Icons.pending;
        color = Colors.orange;
        break;
      default:
        icon = Icons.circle_outlined;
        color = Colors.blue;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: _getStatusColor(status),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'analyzing':
      case 'planning':
      case 'executing':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
    );
  }
}
