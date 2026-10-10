import 'dart:math';

/// Client-generated doc IDs — Fix #6.
///
/// IDs used to be only a timestamp (`DateTime.now().microsecondsSinceEpoch`),
/// which was predictable — another user could guess an ID and overwrite
/// someone else's doc (`.set()`). Now they are unique with a random suffix.
String generateId() {
  final ts = DateTime.now().microsecondsSinceEpoch;
  final rand = Random.secure().nextInt(0x7fffffff).toRadixString(16);
  return '$ts-$rand';
}
