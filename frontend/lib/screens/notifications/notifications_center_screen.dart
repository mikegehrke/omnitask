import 'package:flutter/material.dart';

class NotificationsCenterScreen extends StatefulWidget {
  const NotificationsCenterScreen({super.key});

  @override
  State<NotificationsCenterScreen> createState() => _NotificationsCenterScreenState();
}

class _NotificationsCenterScreenState extends State<NotificationsCenterScreen> {
  String _filter = 'all'; // all, unread, task, system

  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 1,
      'type': 'task_completed',
      'title': 'Task Completed',
      'message': 'Your task "Analyze market trends" has been completed successfully',
      'read': false,
      'createdAt': DateTime.now().subtract(const Duration(minutes: 5)),
      'icon': Icons.check_circle,
      'color': Colors.green,
    },
    {
      'id': 2,
      'type': 'task_failed',
      'title': 'Task Failed',
      'message': 'Your task "Generate report" failed. Please check the details',
      'read': false,
      'createdAt': DateTime.now().subtract(const Duration(hours: 1)),
      'icon': Icons.error,
      'color': Colors.red,
    },
    {
      'id': 3,
      'type': 'payment',
      'title': 'Payment Successful',
      'message': 'Your payment of \$12.50 was processed successfully',
      'read': true,
      'createdAt': DateTime.now().subtract(const Duration(hours: 3)),
      'icon': Icons.payment,
      'color': Colors.blue,
    },
    {
      'id': 4,
      'type': 'system',
      'title': 'System Maintenance',
      'message': 'Scheduled maintenance on Sunday 2 AM - 4 AM',
      'read': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      'icon': Icons.info,
      'color': Colors.orange,
    },
    {
      'id': 5,
      'type': 'task_started',
      'title': 'Task Started',
      'message': 'Your task "Create Python script" is now being processed',
      'read': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 2)),
      'icon': Icons.play_circle,
      'color': Colors.purple,
    },
  ];

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_filter == 'all') return _notifications;
    if (_filter == 'unread') return _notifications.where((n) => !n['read']).toList();
    return _notifications.where((n) => n['type'].toString().startsWith(_filter)).toList();
  }

  int get _unreadCount => _notifications.where((n) => !n['read']).length;

  void _markAsRead(Map<String, dynamic> notification) {
    setState(() {
      notification['read'] = true;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['read'] = true;
      }
    });
  }

  void _deleteNotification(Map<String, dynamic> notification) {
    setState(() {
      _notifications.remove(notification);
    });
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications'),
            if (_unreadCount > 0)
              Text(
                '$_unreadCount unread',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read'),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _FilterChip(
                  label: 'All',
                  count: _notifications.length,
                  isSelected: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                ),
                _FilterChip(
                  label: 'Unread',
                  count: _unreadCount,
                  isSelected: _filter == 'unread',
                  color: Colors.blue,
                  onTap: () => setState(() => _filter = 'unread'),
                ),
                _FilterChip(
                  label: 'Tasks',
                  count: _notifications.where((n) => n['type'].toString().startsWith('task')).length,
                  isSelected: _filter == 'task',
                  color: Colors.green,
                  onTap: () => setState(() => _filter = 'task'),
                ),
                _FilterChip(
                  label: 'System',
                  count: _notifications.where((n) => n['type'] == 'system').length,
                  isSelected: _filter == 'system',
                  color: Colors.orange,
                  onTap: () => setState(() => _filter = 'system'),
                ),
              ],
            ),
          ),

          // Notifications List
          Expanded(
            child: _filteredNotifications.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No notifications',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = _filteredNotifications[index];
                      return Dismissible(
                        key: ValueKey(notification['id']),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteNotification(notification),
                        child: _NotificationCard(
                          notification: notification,
                          onTap: () => _markAsRead(notification),
                          formatTime: _formatTime,
                        ),
                      );
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

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  final String Function(DateTime) formatTime;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification['read'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isUnread ? Colors.blue.withOpacity(0.05) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: notification['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  notification['icon'],
                  color: notification['color'],
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          notification['title'],
                          style: TextStyle(
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['message'],
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatTime(notification['createdAt']),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
