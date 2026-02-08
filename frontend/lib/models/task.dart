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
      costEstimate: (json['estimated_cost'] ?? json['cost_estimate'])?.toDouble(),
      finalPrice: (json['final_cost'] ?? json['final_price'])?.toDouble(),
      currency: json['currency'] ?? 'EUR',
      isPaid: json['is_paid'] ?? false,
      plan: json['plan'] ?? [],
    );
  }
}

class Message {
  final int? id;
  final String role; // user, assistant, system
  final String? content;
  final String? fileUrl;
  final String? fileName;
  final String? fileType; // image/pdf/document/text
  final int? tokensUsed;
  final double? cost;
  final String? createdAt;

  Message({
    this.id, 
    required this.role, 
    this.content, 
    this.fileUrl,
    this.fileName,
    this.fileType,
    this.tokensUsed,
    this.cost,
    this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      role: json['role'],
      content: json['content'],
      fileUrl: json['file_url'],
      fileName: json['file_name'],
      fileType: json['file_type'],
      tokensUsed: json['tokens_used'],
      cost: json['cost']?.toDouble(),
      createdAt: json['created_at'],
    );
  }

  bool get hasFile => fileUrl != null;
  bool get isImage => fileType == 'image';
  bool get isPdf => fileType == 'pdf';
  bool get isDocument => fileType == 'document';
  bool get isText => fileType == 'text' || fileName?.endsWith('.txt') == true || fileName?.endsWith('.md') == true;
}
