/// Readers of a chat message — every message stores them in `participants`;
/// the rules gate reads with `allow read: email() in participants` (this is
/// query-provable, while get()/exists() rules fail on queries).
///
/// Channel → participants:
/// - support        → sender + staff (CEO + subAdmins)
/// - admin          → staff + sender (the rules check for the admin/superAdmin role)
/// - subadmins      → subs + sender
/// - team:{owner}   → owner + members + sender + staff (CEO/subAdmins oversight)
/// - request:{id}   → sender + request (userEmail, assignedTo) + CEO
///   (the CEO can always read request chats)
List<String> participantsFor({
  required String channel,
  required String senderEmail,
  String? userEmail,
  String? assignedTo,
  Iterable<String> ceoEmails = const [],
  Iterable<String> subAdminEmails = const [],
  String? ownerEmail,
  Iterable<String> memberEmails = const [],
}) {
  final sender = senderEmail.toLowerCase();
  final ceo = ceoEmails.map((e) => e.toLowerCase()).toSet();
  final subs = subAdminEmails.map((e) => e.toLowerCase()).toSet();
  final staff = ceo.union(subs);

  final Set<String> p;
  if (channel == 'support') {
    // Support: sender + all staff (CEO + subAdmins)
    p = {...staff, sender};
  } else if (channel == 'admin') {
    // Admin: staff + sender. Staff includes CEO + subAdmins.
    // Only admins/superAdmins whose role matches can read it.
    p = {...staff, sender};
  } else if (channel == 'subadmins') {
    // Subadmins: only subs + sender
    p = {...subs, sender};
  } else if (channel.startsWith('team:')) {
    // Team: owner + members + sender + staff (CEO/subAdmins overhead)
    // Lowercase the owner's email
    final owner = (ownerEmail ?? channel.substring('team:'.length)).toLowerCase();
    p = {
      owner,
      sender,
      ...memberEmails.map((e) => e.toLowerCase()),
      ...staff,
    };
  } else if (channel.startsWith('request:')) {
    // Request: sender + userEmail (request owner) + assignedTo + CEO
    // These are the 3 base participants; CEO emails come from config.
    // The rules validate that participants = [sender, userEmail, assignedTo, ...ceos]
    // and that there are at most 4 participants.
    final Set<String> base = {
      sender,
    };
    if (userEmail != null && userEmail.isNotEmpty) {
      base.add(userEmail.toLowerCase());
    }
    if (assignedTo != null && assignedTo.isNotEmpty) {
      base.add(assignedTo.toLowerCase());
    }
    // Add the CEO emails separately
    final Set<String> withCeo = base.union(ceo);
    p = withCeo;
  } else {
    // Unknown channel: sender only
    p = {sender};
  }
  return p.toList()..sort();
}