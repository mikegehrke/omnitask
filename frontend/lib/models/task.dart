class Task {
  final int? id;
  final String description;
  final String status;
  final String urgency;
  final double? costEstimate;
  final double? finalPrice;
  final String currency;
  final bool isPaid;
  final List<dynamic>? plan;

  Task({
    this.id,
    required this.description,
    required this.status,
    required this.urgency,
    this.costEstimate,
    this.finalPrice,
    required this.currency,
    required this.isPaid,
    this.plan,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      description: json['description'],
      status: json['status'] ?? 'pending',
      urgency: json['urgency'] ?? 'flexible',
      costEstimate: json['cost_estimate']?.toDouble(),
      finalPrice: json['final_price']?.toDouble(),
      currency: json['currency'] ?? 'USD',
      isPaid: json['is_paid'] ?? false,
      plan: json['plan'] ?? [],
    );
  }
}

class Message {
  final int? id;
  final String sender; // user, system, agent
  final String content;
  final List<String> attachments;
  final String? timestamp;

  Message({this.id, required this.sender, required this.content, this.attachments = const [], this.timestamp});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      sender: json['sender'],
      content: json['content'],
      attachments: List<String>.from(json['attachments'] ?? []),
      timestamp: json['timestamp'],
    );
  }
}
