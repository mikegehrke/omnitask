import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';

class ChatScreen extends StatefulWidget {
  final Task task;
  const ChatScreen({Key? key, required this.task}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Provider.of<TaskProvider>(context, listen: false).fetchMessages(widget.task.id!);
  }

  void _send() {
    if (_inputCtrl.text.isEmpty) return;
    Provider.of<TaskProvider>(context, listen: false).sendMessage(widget.task.id!, _inputCtrl.text);
    _inputCtrl.clear();
  }
  
  void _pay() async {
    final url = await Provider.of<TaskProvider>(context, listen: false).getCheckoutUrl(widget.task.id!);
    if (url != null) {
      // Launch URL (mocking via print/dialog for now as url_launcher needs config)
      showDialog(context: context, builder: (_) => AlertDialog(
        title: Text("Payment Link"),
        content: Text("Open this link to pay: $url"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Close")),
          // Mock Pay Button for dev flow
          ElevatedButton(
            onPressed: () async {
                 // Trigger mock pay
                 // This would be a separate API call "mock-pay"
                 Navigator.pop(context);
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payment simulated!")));
            },
            child: Text("Simulate Payment Success")
          )
        ],
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.task.description)),
      body: Column(
        children: [
          // Plan / Price Header
          if (widget.task.finalPrice != null && !widget.task.isPaid)
            Container(
              color: Colors.orange[50],
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(child: Text("Total Price: ${widget.task.finalPrice} ${widget.task.currency}")),
                  ElevatedButton(
                    onPressed: _pay,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: Text("Pay Now"),
                  )
                ],
              ),
            ),
          
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (ctx, provider, _) { 
                return ListView.builder(
                  reverse: false, // For now normal order
                  padding: EdgeInsets.all(16),
                  itemCount: provider.messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = provider.messages[i];
                    bool isMe = msg.sender == 'user';
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.teal[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(msg.content),
                      ),
                    );
                  },
                );
              }
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      suffixIcon: IconButton(icon: Icon(Icons.attach_file), onPressed: (){}),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _send,
                  mini: true,
                  child: Icon(Icons.send),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
