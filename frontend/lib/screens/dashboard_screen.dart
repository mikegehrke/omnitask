import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import 'chat_screen.dart';
import 'create_task_sheet.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      Provider.of<TaskProvider>(context, listen: false).fetchTasks()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("OmniTask")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => CreateTaskSheet(),
        ),
        label: const Text("New Task"),
        icon: const Icon(Icons.add),
      ),
      body: Consumer<TaskProvider>(
        builder: (ctx, provider, _) {
          if (provider.isLoading && provider.tasks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assistant, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text("No active tasks.", style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: provider.fetchTasks,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: provider.tasks.length,
              itemBuilder: (ctx, i) => TaskCard(task: provider.tasks[i]),
            ),
          );
        },
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  const TaskCard({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color statusColor = Colors.grey;
    if (task.status == 'completed') statusColor = Colors.green;
    if (task.status == 'waiting_for_payment') statusColor = Colors.orange;
    if (task.status == 'executing') statusColor = Colors.blue;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ChatScreen(task: task)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.description,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.status.toUpperCase().replaceAll("_", " "),
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(task.urgency, style: const TextStyle(color: Colors.grey)),
                  const Spacer(),
                  if (task.finalPrice != null) ...[
                    Text(
                      "${task.finalPrice} ${task.currency}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                  ]
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
