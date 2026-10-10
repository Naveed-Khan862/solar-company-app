class ChatMessage {
  final String id;
  final String channel;
  final String senderEmail;
  final String senderName;
  final String text;
  final DateTime sentAt;

  /// Denormalized access fields — the rules check channel access from inside
  /// these fields (without get()/exists()). They are also required so that
  /// Firestore queries work.
  ///
  /// For the 'request:{id}' channel:
  final String? userEmail; // owner of the request
  final String? assignedTo; // sub-admin the request is assigned to

  /// SEC-01 fix v2: rules no longer parse the channel — the doc path is
  /// built from these fields (substring parsing failed at runtime).
  final String? requestId; // doc ID of the request (request channels)

  /// For the 'team:{owner}' channel:
  final String? ownerEmail; // owner of the team (sub-admin)
  final List<String>? memberEmails; // members of the team

  /// Readers — lowercase emails. Rules read gate: `email() in participants`
  /// (query-provable). Built by [[utils/chat_access.dart]].
  final List<String> participants;

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
    this.participants = const [],
  });

  ChatMessage copyWith({List<String>? participants}) {
    return ChatMessage(
      id: id,
      channel: channel,
      senderEmail: senderEmail,
      senderName: senderName,
      text: text,
      sentAt: sentAt,
      userEmail: userEmail,
      assignedTo: assignedTo,
      requestId: requestId,
      ownerEmail: ownerEmail,
      memberEmails: memberEmails,
      participants: participants ?? this.participants,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'channel': channel,
        'senderEmail': senderEmail,
        'senderName': senderName,
        'text': text,
        'sentAt': sentAt.toIso8601String(),
        'participants': participants,
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
      participants:
          (json['participants'] as List?)?.cast<String>() ?? const [],
    );
  }
}
