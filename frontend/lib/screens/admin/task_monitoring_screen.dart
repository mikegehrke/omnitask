import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class TaskMonitoringScreen extends StatefulWidget {
  const TaskMonitoringScreen({super.key});

  @override
  State<TaskMonitoringScreen> createState() => _TaskMonitoringScreenState();
}

class _TaskMonitoringScreenState extends State<TaskMonitoringScreen> {
  String _filterStatus = 'all'; // all, pending, processing, completed, failed
  String _searchQuery = '';

  final List<Map<String, dynamic>> _allTasks = [
    {
      'id': 1,
      'userId': 1,
      'userEmail': 'test@test.com',
      'description': 'Analyze market trends for Q4 2024',
      'status': 'completed',
      'provider': 'openai',
      'urgency': 'normal',
      'cost': 0.45,
      'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
      'completedAt': DateTime.now().subtract(const Duration(hours: 1)),
    },
    {
      'id': 2,
      'userId': 2,
      'userEmail': 'john@example.com',
      'description': 'Create Python script for data processing',
      'status': 'processing',
      'provider': 'claude',
      'urgency': 'urgent',
      'cost': 0.89,
      'createdAt': DateTime.now().subtract(const Duration(minutes: 30)),
      'completedAt': null,
    },
    {
      'id': 3,
      'userId': 1,
      'userEmail': 'test@test.com',
      'description': 'Summarize research paper',
      'status': 'pending',
      'provider': 'gemini',
      'urgency': 'flexible',
      'cost': 0.12,
      'createdAt': DateTime.now().subtract(const Duration(minutes: 5)),
      'completedAt': null,
    },
    {
      'id': 4,
      'userId': 3,
      'userEmail': 'spam@example.com',
      'description': 'Generate spam content',
      'status': 'failed',
      'provider': 'ollama',
      'urgency': 'normal',
      'cost': 0.0,
      'createdAt': DateTime.now().subtract(const Duration(hours: 5)),
      'completedAt': DateTime.now().subtract(const Duration(hours: 5)),
    },
  ];

  List<Map<String, dynamic>> get _filteredTasks {
    return _allTasks.where((task) {
      final matchesStatus = _filterStatus == 'all' || task['status'] == _filterStatus;
      final matchesSearch = task['description'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          task['userEmail'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Monitoring'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Status Filter
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All',
                  count: _allTasks.length,
                  isSelected: _filterStatus == 'all',
                  onTap: () => setState(() => _filterStatus = 'all'),
                ),
                _FilterChip(
                  label: 'Pending',
                  count: _allTasks.where((t) => t['status'] == 'pending').length,
                  isSelected: _filterStatus == 'pending',
                  color: Colors.orange,
                  onTap: () => setState(() => _filterStatus = 'pending'),
                ),
                _FilterChip(
                  label: 'Processing',
                  count: _allTasks.where((t) => t['status'] == 'processing').length,
                  isSelected: _filterStatus == 'processing',
                  color: Colors.blue,
                  onTap: () => setState(() => _filterStatus = 'processing'),
                ),
                _FilterChip(
                  label: 'Completed',
                  count: _allTasks.where((t) => t['status'] == 'completed').length,
                  isSelected: _filterStatus == 'completed',
                  color: Colors.green,
                  onTap: () => setState(() => _filterStatus = 'completed'),
                ),
                _FilterChip(
                  label: 'Failed',
                  count: _allTasks.where((t) => t['status'] == 'failed').length,
                  isSelected: _filterStatus == 'failed',
                  color: Colors.red,
                  onTap: () => setState(() => _filterStatus = 'failed'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tasks List
          Expanded(
            child: _filteredTasks.isEmpty
                ? const Center(child: Text('No tasks found'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = _filteredTasks[index];
                      return _TaskMonitorCard(task: task);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).primaryColor;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: chipColor.withOpacity(0.1),
        selectedColor: chipColor.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? chipColor : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _TaskMonitorCard extends StatelessWidget {
  final Map<String, dynamic> task;

  const _TaskMonitorCard({required this.task});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'processing':
        return Icons.autorenew;
      case 'completed':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(task['status']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate to task details
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getStatusIcon(task['status']),
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task #${task['id']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          task['userEmail'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      task['status'].toString().toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                task['description'],
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Details
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.smart_toy,
                    label: task['provider'].toString().toUpperCase(),
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.priority_high,
                    label: task['urgency'].toString().toUpperCase(),
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.attach_money,
                    label: '\$${task['cost']}',
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Timing
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Created ${timeago.format(task['createdAt'])}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (task['completedAt'] != null)
                    Row(
                      children: [
                        Icon(Icons.check, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Done ${timeago.format(task['completedAt'])}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
