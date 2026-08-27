import 'package:flutter/material.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';
import '../utils/messages.dart';

Future<String?> showMessageDialog(BuildContext context, String initial) async {
  final controller = TextEditingController(text: initial);
  String selected = initial;

  return showDialog<String>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(context);
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.dimensions.values.s20),
        ),
        title: const Text(
          'Send Encouragement 💬',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<String>(
              value: selected,
              isExpanded: true,
              items: messages
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  selected = val;
                  controller.text = val;
                }
              },
            ),
            SizedBox(height: context.dimensions.values.s10),
            TextField(
              controller: controller,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Custom message (optional)',
                border: OutlineInputBorder(),
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
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white, // ✅ Fix: make “Send” visible
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  context.dimensions.values.s12,
                ),
              ),
            ),
            child: const Text(
              'Send',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    },
  );
}
