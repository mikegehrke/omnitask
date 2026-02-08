import 'package:flutter/material.dart';

class TaskQueueStatusScreen extends StatefulWidget {
  final int taskId;

  const TaskQueueStatusScreen({
    super.key,
    required this.taskId,
  });

  @override
  State<TaskQueueStatusScreen> createState() => _TaskQueueStatusScreenState();
}

class _TaskQueueStatusScreenState extends State<TaskQueueStatusScreen> {
  // Mock queue data
  final Map<String, dynamic> _queueInfo = {
    'position': 3,
    'totalInQueue': 8,
    'estimatedWait': '5-8 minutes',
    'status': 'queued',
    'priority': 'normal',
    'submittedAt': DateTime.now().subtract(const Duration(minutes: 2)),
  };

  final List<Map<String, dynamic>> _queueHistory = [
    {
      'timestamp': DateTime.now().subtract(const Duration(minutes: 2)),
      'status': 'submitted',
      'message': 'Task submitted to queue',
    },
    {
      'timestamp': DateTime.now().subtract(const Duration(minutes: 1, seconds: 30)),
      'status': 'validated',
      'message': 'Task validated successfully',
    },
    {
      'timestamp': DateTime.now().subtract(const Duration(seconds: 45)),
      'status': 'queued',
      'message': 'Waiting in queue (position #3)',
    },
  ];

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return '${diff.inSeconds}s ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Queue Position Card
          Card(
            color: Colors.blue.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.queue, size: 64, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text(
                    'Your Position in Queue',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '#${_queueInfo['position']}',
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        ' / ${_queueInfo['totalInQueue']}',
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Est. wait: ${_queueInfo['estimatedWait']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Progress Indicator
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Processing Progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ProgressStep(
                    title: 'Submitted',
                    isCompleted: true,
                    isActive: false,
                    icon: Icons.check_circle,
                  ),
                  _ProgressStep(
                    title: 'Validated',
                    isCompleted: true,
                    isActive: false,
                    icon: Icons.verified,
                  ),
                  _ProgressStep(
                    title: 'In Queue',
                    isCompleted: false,
                    isActive: true,
                    icon: Icons.hourglass_empty,
                  ),
                  _ProgressStep(
                    title: 'Processing',
                    isCompleted: false,
                    isActive: false,
                    icon: Icons.refresh,
                    isLast: false,
                  ),
                  _ProgressStep(
                    title: 'Completed',
                    isCompleted: false,
                    isActive: false,
                    icon: Icons.done_all,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Task Details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Task Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    label: 'Task ID',
                    value: '#${widget.taskId}',
                  ),
                  _DetailRow(
                    label: 'Priority',
                    value: (_queueInfo['priority'] as String).toUpperCase(),
                    valueColor: _queueInfo['priority'] == 'urgent' ? Colors.red : null,
                  ),
                  _DetailRow(
                    label: 'Submitted',
                    value: _formatTime(_queueInfo['submittedAt']),
                  ),
                  _DetailRow(
                    label: 'Queue Position',
                    value: '#${_queueInfo['position']} of ${_queueInfo['totalInQueue']}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Activity Log
          const Text(
            'Activity Log',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_queueHistory.length, (index) {
            final event = _queueHistory[_queueHistory.length - 1 - index];
            return _ActivityLogItem(event: event, formatTime: _formatTime);
          }),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cancel Task'),
              content: const Text('Are you sure you want to cancel this task?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('No'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Yes, Cancel'),
                ),
              ],
            ),
          );
        },
        backgroundColor: Colors.red,
        icon: const Icon(Icons.cancel),
        label: const Text('Cancel Task'),
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  final String title;
  final bool isCompleted;
  final bool isActive;
  final IconData icon;
  final bool isLast;

  const _ProgressStep({
    required this.title,
    required this.isCompleted,
    required this.isActive,
    required this.icon,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted
        ? Colors.green
        : isActive
            ? Colors.blue
            : Colors.grey;

    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: color,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: color.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 30),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityLogItem extends StatelessWidget {
  final Map<String, dynamic> event;
  final String Function(DateTime) formatTime;

  const _ActivityLogItem({
    required this.event,
    required this.formatTime,
  });

  IconData _getIcon(String status) {
    switch (status) {
      case 'submitted':
        return Icons.upload;
      case 'validated':
        return Icons.check;
      case 'queued':
        return Icons.queue;
      case 'processing':
        return Icons.refresh;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.info;
    }
  }

  Color _getColor(String status) {
    switch (status) {
      case 'submitted':
        return Colors.blue;
      case 'validated':
        return Colors.green;
      case 'queued':
        return Colors.orange;
      case 'processing':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(event['status']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIcon(event['status']),
            color: color,
            size: 20,
          ),
        ),
        title: Text(event['message']),
        subtitle: Text(formatTime(event['timestamp'])),
      ),
    );
  }
}
