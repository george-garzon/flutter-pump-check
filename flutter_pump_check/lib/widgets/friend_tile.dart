import 'package:flutter/material.dart';
import 'package:flutter_pump_check/theme/theme.dart';
import '../models/friend.dart';
import 'progress_ring.dart'; // 👈 ADD THIS

class FriendTile extends StatelessWidget {
  final Friend friend;
  final VoidCallback onSend;

  const FriendTile({super.key, required this.friend, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.theme.appColors;

    return Card(
      color: colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Stack(
          alignment: Alignment.center,
          children: [
            ProgressRing(
              progress: friend.completion, // new property on Friend model
              size: 50,
            ),
            const CircleAvatar(radius: 20),
          ],
        ),

        title: Text(friend.name, style: theme.textTheme.bodyMedium),
        subtitle: Text(friend.username, style: theme.textTheme.bodySmall),
        trailing: IconButton(
          icon: const Icon(Icons.send),
          color: theme.colorScheme.primary,
          onPressed: onSend,
        ),
      ),
    );
  }
}
