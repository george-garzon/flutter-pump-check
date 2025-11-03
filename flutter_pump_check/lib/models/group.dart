class Group {
  final String id;
  final String name;
  final List<String> memberIds;
  final String? ownerId; // ✅ add this

  Group({
    required this.id,
    required this.name,
    required this.memberIds,
    this.ownerId, // ✅ add this
  });
}
