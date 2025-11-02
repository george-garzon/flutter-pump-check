import 'package:flutter/material.dart';
import '../models/friend.dart';
import '../models/group.dart';

Future<Group?> showCreateGroupDialog(
  BuildContext context,
  List<Friend> friends,
) async {
  final nameController = TextEditingController();
  final selected = <String>{};

  return showDialog<Group>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Create Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Group name'),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 250,
              child: ListView(
                shrinkWrap: true,
                children: friends.map((f) {
                  final checked = selected.contains(f.name);
                  return CheckboxListTile(
                    value: checked,
                    title: Text(f.name),
                    onChanged: (v) {
                      if (v == true) {
                        selected.add(f.name);
                      } else {
                        selected.remove(f.name);
                      }
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(
                ctx,
                Group(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  memberIds: selected.toList(),
                ),
              );
            },
            child: const Text('Create'),
          ),
        ],
      );
    },
  );
}
