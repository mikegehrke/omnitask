import 'package:flutter/material.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} months ago';
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    return '${diff.inMinutes} minutes ago';
  }
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, active, banned
  
  final List<Map<String, dynamic>> _users = [
    {
      'id': 1,
      'email': 'test@test.com',
      'name': 'Test User',
      'status': 'active',
      'tasks': 12,
      'credits': 150.0,
      'joinedAt': DateTime.now().subtract(const Duration(days: 30)),
      'lastActive': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'id': 2,
      'email': 'john@example.com',
      'name': 'John Doe',
      'status': 'active',
      'tasks': 45,
      'credits': 320.5,
      'joinedAt': DateTime.now().subtract(const Duration(days: 60)),
      'lastActive': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'id': 3,
      'email': 'spam@example.com',
      'name': 'Spam Account',
      'status': 'banned',
      'tasks': 2,
      'credits': 0.0,
      'joinedAt': DateTime.now().subtract(const Duration(days: 5)),
      'lastActive': DateTime.now().subtract(const Duration(days: 5)),
    },
  ];

  List<Map<String, dynamic>> get _filteredUsers {
    return _users.where((user) {
      final matchesSearch = user['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesFilter = _filterStatus == 'all' || user['status'] == _filterStatus;
      
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'all', label: Text('All')),
                          ButtonSegment(value: 'active', label: Text('Active')),
                          ButtonSegment(value: 'banned', label: Text('Banned')),
                        ],
                        selected: {_filterStatus},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() => _filterStatus = newSelection.first);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _StatChip(
                  label: 'Total',
                  value: _users.length.toString(),
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Active',
                  value: _users.where((u) => u['status'] == 'active').length.toString(),
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Banned',
                  value: _users.where((u) => u['status'] == 'banned').length.toString(),
                  color: Colors.red,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Users List
          Expanded(
            child: _filteredUsers.isEmpty
                ? const Center(child: Text('No users found'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return _UserCard(
                        user: user,
                        onBanToggle: () {
                          setState(() {
                            user['status'] = user['status'] == 'active' ? 'banned' : 'active';
                          });
                        },
                        onViewDetails: () {
                          _showUserDetails(context, user);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(BuildContext context, Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'User Details',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _DetailRow(label: 'ID', value: user['id'].toString()),
              _DetailRow(label: 'Email', value: user['email']),
              _DetailRow(label: 'Name', value: user['name']),
              _DetailRow(
                label: 'Status',
                value: user['status'].toString().toUpperCase(),
                valueColor: user['status'] == 'active' ? Colors.green : Colors.red,
              ),
              _DetailRow(label: 'Tasks Completed', value: user['tasks'].toString()),
              _DetailRow(label: 'Credits Balance', value: '\$${user['credits']}'),
              _DetailRow(
                label: 'Joined',
                value: _formatTimeAgo(user['joinedAt']),
              ),
              _DetailRow(
                label: 'Last Active',
                value: _formatTimeAgo(user['lastActive']),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit User'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {},
                      icon: Icon(
                        user['status'] == 'active' ? Icons.block : Icons.check_circle,
                      ),
                      label: Text(user['status'] == 'active' ? 'Ban User' : 'Unban User'),
                      style: FilledButton.styleFrom(
                        backgroundColor: user['status'] == 'active' ? Colors.red : Colors.green,
                      ),
                    ),
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

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onBanToggle;
  final VoidCallback onViewDetails;

  const _UserCard({
    required this.user,
    required this.onBanToggle,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                child: Text(
                  user['name'].toString().substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (user['status'] == 'active' ? Colors.green : Colors.red)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user['status'].toString().toUpperCase(),
                            style: TextStyle(
                              color: user['status'] == 'active' ? Colors.green : Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['email'],
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.task_alt, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${user['tasks']} tasks',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.account_balance_wallet, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '\$${user['credits']}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  user['status'] == 'active' ? Icons.block : Icons.check_circle,
                  color: user['status'] == 'active' ? Colors.red : Colors.green,
                ),
                onPressed: onBanToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
