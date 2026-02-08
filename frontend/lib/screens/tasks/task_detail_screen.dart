import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import 'task_detail_chat_new.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _headerExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().fetchTask(widget.taskId);
      context.read<TaskProvider>().fetchMessages(widget.taskId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final task = taskProvider.selectedTask;

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Task Details', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[850],
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              taskProvider.fetchTask(widget.taskId);
              taskProvider.fetchMessages(widget.taskId);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Zusammenklappbarer Task Header
          Container(
            color: Colors.grey[850],
            child: Column(
              children: [
                // Immer sichtbare Zeile mit Toggle
                InkWell(
                  onTap: () => setState(() => _headerExpanded = !_headerExpanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        _buildStatusChip(task.status),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '#${task.id} • ${(task.costEstimate ?? 1.50).toStringAsFixed(2)} €',
                            style: TextStyle(color: Colors.grey[400], fontSize: 13),
                          ),
                        ),
                        if (task.status == 'awaiting_payment' && !_headerExpanded)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ElevatedButton(
                              onPressed: () => _showPaymentDialog(task),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                              child: const Text('Bezahlen', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                        Icon(
                          _headerExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Erweiterbarer Bereich
                if (_headerExpanded)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(color: Colors.grey, height: 1),
                        const SizedBox(height: 12),
                        Text(
                          task.description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            _buildInfoChip(Icons.priority_high, task.urgency.toUpperCase()),
                            if (task.isPaid)
                              _buildInfoChip(Icons.check_circle, 'Bezahlt', color: Colors.green),
                          ],
                        ),
                        if (task.status == 'awaiting_payment')
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showPaymentDialog(task),
                                icon: const Icon(Icons.payment, size: 18),
                                label: const Text('Jetzt bezahlen'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Chat - Full Height ChatGPT Style
          Expanded(
            child: TaskDetailChat(task: task),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor(status)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: _getStatusColor(status),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? Colors.grey[400]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color ?? Colors.grey[300],
            fontSize: 13,
          ),
        ),
      ],
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
      case 'awaiting_payment':
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }

  void _showPaymentDialog(dynamic task) {
    bool agbAccepted = false;
    bool datenschutzAccepted = false;
    final price = task.costEstimate ?? 1.50;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Zahlung bestätigen',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.euro, color: Colors.teal),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Zu zahlen:', style: TextStyle(color: Colors.grey)),
                          Text(
                            '${price.toStringAsFixed(2)} €',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                CheckboxListTile(
                  value: agbAccepted,
                  onChanged: (val) => setState(() => agbAccepted = val ?? false),
                  title: const Text('AGB akzeptieren', style: TextStyle(color: Colors.white)),
                  activeColor: Colors.teal,
                ),
                CheckboxListTile(
                  value: datenschutzAccepted,
                  onChanged: (val) => setState(() => datenschutzAccepted = val ?? false),
                  title: const Text('Datenschutzerklärung akzeptieren', style: TextStyle(color: Colors.white)),
                  activeColor: Colors.teal,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: (agbAccepted && datenschutzAccepted)
                  ? () async {
                      Navigator.pop(context);
                      final success = await context.read<TaskProvider>().confirmPayment(widget.taskId);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Zahlung erfolgreich'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // Refresh task
                        context.read<TaskProvider>().fetchTask(widget.taskId);
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Jetzt bezahlen'),
            ),
          ],
        ),
      ),
    );
  }
}
