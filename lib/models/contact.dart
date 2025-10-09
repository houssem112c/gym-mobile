class ContactMessage {
  final String id;
  final String subject;
  final String message;
  final String email;
  final String? phone;
  final String status;
  final String priority;
  final String? adminResponse;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? userId;

  ContactMessage({
    required this.id,
    required this.subject,
    required this.message,
    required this.email,
    this.phone,
    required this.status,
    required this.priority,
    this.adminResponse,
    required this.createdAt,
    this.respondedAt,
    this.userId,
  });

  factory ContactMessage.fromJson(Map<String, dynamic> json) {
    return ContactMessage(
      id: json['id'],
      subject: json['subject'],
      message: json['message'],
      email: json['email'],
      phone: json['phone'],
      status: json['status'],
      priority: json['priority'],
      adminResponse: json['adminResponse'],
      createdAt: DateTime.parse(json['createdAt']),
      respondedAt: json['respondedAt'] != null 
          ? DateTime.parse(json['respondedAt']) 
          : null,
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'message': message,
      'email': email,
      'phone': phone,
      'status': status,
      'priority': priority,
      'adminResponse': adminResponse,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'userId': userId,
    };
  }

  bool get hasResponse => adminResponse != null && adminResponse!.isNotEmpty;
  bool get isOpen => status.toLowerCase() == 'open';
  bool get isInProgress => status.toLowerCase() == 'in_progress';
  bool get isResponded => status.toLowerCase() == 'responded';
  bool get isClosed => status.toLowerCase() == 'closed';
}