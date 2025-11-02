import 'package:flutter/material.dart';
import '../models/friend.dart';
import '../models/group.dart';

Future<Group?> showCreateGroupModal(
  BuildContext context,
  List<Friend> friends,
) async {
  final theme = Theme.of(context);
  final nameController = TextEditingController();
  final searchController = TextEditingController();
  final selected = <Friend>[];

  return showDialog<Group>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Dialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: StatefulBuilder(
          builder: (ctx, setState) {
            final filtered = friends
                .where(
                  (f) => f.name.toLowerCase().contains(
                    searchController.text.toLowerCase(),
                  ),
                )
                .toList();

            return Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Create Group",
                      style: theme.textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: "Group Name",
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Selected Members as Chips
                    if (selected.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: selected
                            .map(
                              (f) => Chip(
                                label: Text(f.name),
                                onDeleted: () {
                                  setState(() => selected.remove(f));
                                },
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: "Search Friends",
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...filtered.map((f) {
                      final isAdded = selected.contains(f);
                      return ListTile(
                        leading: const CircleAvatar(radius: 20),
                        title: Text(f.name),
                        subtitle: Text(f.username),
                        trailing: ElevatedButton(
                          onPressed: isAdded
                              ? null
                              : () {
                                  setState(() => selected.add(f));
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAdded
                                ? Colors.grey
                                : theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(isAdded ? "Added" : "Add To Group"),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isEmpty) return;
                        final group = Group(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: nameController.text.trim(),
                          memberIds: selected.map((f) => f.name).toList(),
                        );
                        Navigator.pop(ctx, group);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text("Create"),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}
