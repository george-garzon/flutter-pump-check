class Group {
  final String id;
  final String name;
  final List<String> memberIds;
  final String? ownerId;

  Group({
    required this.id,
    required this.name,
    required this.memberIds,
    this.ownerId,
  });
}
