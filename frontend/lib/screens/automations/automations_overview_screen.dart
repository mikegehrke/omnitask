import 'package:flutter/material.dart';

class AutomationsOverviewScreen extends StatefulWidget {
  const AutomationsOverviewScreen({super.key});

  @override
  State<AutomationsOverviewScreen> createState() => _AutomationsOverviewScreenState();
}

class _AutomationsOverviewScreenState extends State<AutomationsOverviewScreen> {
  final List<Map<String, dynamic>> _automations = [
    {
      'id': 1,
      'name': 'Daily Market Analysis',
      'description': 'Analyze market trends every morning',
      'trigger': 'schedule',
      'schedule': '09:00 daily',
      'enabled': true,
      'lastRun': DateTime.now().subtract(const Duration(hours: 3)),
      'nextRun': DateTime.now().add(const Duration(hours: 21)),
      'runs': 45,
    },
    {
      'id': 2,
      'name': 'Weekly Report Generator',
      'description': 'Generate comprehensive weekly reports',
      'trigger': 'schedule',
      'schedule': 'Monday 08:00',
      'enabled': true,
      'lastRun': DateTime.now().subtract(const Duration(days: 6)),
      'nextRun': DateTime.now().add(const Duration(days: 1)),
      'runs': 12,
    },
    {
      'id': 3,
      'name': 'Email Summarizer',
      'description': 'Summarize important emails',
      'trigger': 'event',
      'schedule': 'On new email',
      'enabled': false,
      'lastRun': DateTime.now().subtract(const Duration(days: 2)),
      'nextRun': null,
      'runs': 234,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Automations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Active',
                  value: _automations.where((a) => a['enabled']).length.toString(),
                  icon: Icons.play_circle,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Total Runs',
                  value: _automations.fold<int>(0, (sum, a) => sum + (a['runs'] as int)).toString(),
                  icon: Icons.repeat,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Automations List
          ..._automations.map((automation) => _AutomationCard(
                automation: automation,
                onToggle: () {
                  setState(() {
                    automation['enabled'] = !automation['enabled'];
                  });
                },
                onEdit: () {
                  // Navigate to edit
                },
                onDelete: () {
                  setState(() {
                    _automations.remove(automation);
                  });
                },
              )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to create automation
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Automation'),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AutomationCard extends StatelessWidget {
  final Map<String, dynamic> automation;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AutomationCard({
    required this.automation,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'Never';
    final now = DateTime.now();
    final diff = date.difference(now);
    
    if (diff.isNegative) {
      final absDiff = diff.abs();
      if (absDiff.inDays > 0) return '${absDiff.inDays}d ago';
      if (absDiff.inHours > 0) return '${absDiff.inHours}h ago';
      return '${absDiff.inMinutes}m ago';
    } else {
      if (diff.inDays > 0) return 'in ${diff.inDays}d';
      if (diff.inHours > 0) return 'in ${diff.inHours}h';
      return 'in ${diff.inMinutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            automation['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (automation['enabled'] ? Colors.green : Colors.grey)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              automation['enabled'] ? 'ACTIVE' : 'PAUSED',
                              style: TextStyle(
                                color: automation['enabled'] ? Colors.green : Colors.grey,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        automation['description'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: automation['enabled'],
                  onChanged: (_) => onToggle(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Details
            Row(
              children: [
                Expanded(
                  child: _InfoRow(
                    icon: Icons.schedule,
                    label: automation['schedule'],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${automation['runs']} runs',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InfoRow(
                  icon: Icons.history,
                  label: 'Last: ${_formatDateTime(automation['lastRun'])}',
                ),
                if (automation['nextRun'] != null)
                  _InfoRow(
                    icon: Icons.access_time,
                    label: 'Next: ${_formatDateTime(automation['nextRun'])}',
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('Logs'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
