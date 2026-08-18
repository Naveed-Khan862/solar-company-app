import 'dart:math';

/// Client-generated doc IDs — Fix #6.
///
/// Pehle IDs sirf timestamp the (`DateTime.now().microsecondsSinceEpoch`),
/// jo predictable the — koi doosra user ID guess kar ke kisi aur ki doc ko
/// overwrite (`.set()`) kar sakta tha. Ab random suffix ke sath unique.
String generateId() {
  final ts = DateTime.now().microsecondsSinceEpoch;
  final rand = Random.secure().nextInt(0x7fffffff).toRadixString(16);
  return '$ts-$rand';
}
