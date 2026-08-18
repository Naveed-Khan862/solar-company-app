class ChatMessage {
  final String id;
  final String channel;
  final String senderEmail;
  final String senderName;
  final String text;
  final DateTime sentAt;

  /// Denormalized access fields — rules read in ke ANDAR se channel access
  /// check karti hain (get()/exists() bina). Ye Firestore queries par kaam
  /// karne ke liye zaroori hain.
  ///
  /// 'request:{id}' channel ke liye:
  final String? userEmail; // request ka owner
  final String? assignedTo; // request ka assigned subAdmin

  /// SEC-01 fix v2: rules ko channel parse karne ki zaroorat nahi — doc path
  /// in fields se banta hai (substring runtime par fail hota tha).
  final String? requestId; // request ka doc ID (request channels)

  /// 'team:{owner}' channel ke liye:
  final String? ownerEmail; // team ka owner (subAdmin)
  final List<String>? memberEmails; // team ke members

  const ChatMessage({
    required this.id,
    required this.channel,
    required this.senderEmail,
    required this.senderName,
    required this.text,
    required this.sentAt,
    this.userEmail,
    this.assignedTo,
    this.requestId,
    this.ownerEmail,
    this.memberEmails,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'channel': channel,
        'senderEmail': senderEmail,
        'senderName': senderName,
        'text': text,
        'sentAt': sentAt.toIso8601String(),
        if (userEmail != null) 'userEmail': userEmail,
        if (assignedTo != null) 'assignedTo': assignedTo,
        if (requestId != null) 'requestId': requestId,
        if (ownerEmail != null) 'ownerEmail': ownerEmail,
        if (memberEmails != null) 'memberEmails': memberEmails,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final channel = json['channel'] ??
        (json['requestId'] != null ? 'request:${json['requestId']}' : 'support');
    return ChatMessage(
      id: json['id'],
      channel: channel,
      senderEmail: json['senderEmail'],
      senderName: json['senderName'],
      text: json['text'],
      sentAt: DateTime.parse(json['sentAt']),
      userEmail: json['userEmail'] as String?,
      assignedTo: json['assignedTo'] as String?,
      requestId: json['requestId'] as String?,
      ownerEmail: json['ownerEmail'] as String?,
      memberEmails: (json['memberEmails'] as List?)?.cast<String>(),
    );
  }
}
