import 'package:flutter/material.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';
import '../models/group.dart';
import 'package:flutter_pump_check/theme/text_sizes.dart';

Future<Group?> showCreateGroupModal(BuildContext context) async {
  final theme = Theme.of(context);
  final nameController = TextEditingController();

  return showDialog<Group>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Dialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.dimensions.values.s24),
        ),
        child: Padding(
          padding: EdgeInsets.all(context.dimensions.values.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),

              SizedBox(height: context.dimensions.values.s8),

              Text(
                "Create Group",
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: context.textSizes.s20,
                ),
              ),

              SizedBox(height: context.dimensions.values.s24),

              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: "Group Name",
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: context.dimensions.values.s16,
                    vertical: context.dimensions.values.s12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      context.dimensions.values.s24,
                    ),
                  ),
                ),
              ),

              SizedBox(height: context.dimensions.values.s24),

              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;

                  final group = Group(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                    memberIds: [],
                  );

                  Navigator.pop(ctx, group);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: context.dimensions.values.s14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      context.dimensions.values.s16,
                    ),
                  ),
                ),
                child: Text("Create"),
              ),

              SizedBox(height: context.dimensions.values.s16),
            ],
          ),
        ),
      );
    },
  );
}
