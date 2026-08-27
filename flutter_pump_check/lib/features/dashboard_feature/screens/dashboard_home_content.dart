// flutter_pump_check/lib/features/dashboard_feature/screens/dashboard_home_content.dart
import 'package:flutter/material.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../screens/create_group_modal.dart';
import '../widgets/group_card.dart';
import '../widgets/profile_card.dart';
import '../widgets/section_header.dart';
import '../../../models/friend.dart';
import '../../../models/group.dart';
import '../../../utils/messages.dart';
import '../../../widgets/friend_tile.dart';
import '../../../screens/message_dialog.dart';
import '../../../screens/add_friend_modal.dart';
import '../../../../../../theme/theme.dart';
import 'package:flutter_pump_check/theme/text_sizes.dart';

class DashboardHomeContent extends StatefulWidget {
  const DashboardHomeContent({super.key});

  @override
  State<DashboardHomeContent> createState() => _DashboardHomeContentState();
}

class _DashboardHomeContentState extends State<DashboardHomeContent> {
  Group? currentGroup;

  // Firestore Streams
  Stream<List<Friend>> getFriendsStream(String userId) {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    return userRef.snapshots().asyncMap((snapshot) async {
      final data = snapshot.data();
      if (data == null || data['friends'] == null) return [];

      final friendIds = List<String>.from(data['friends']);
      if (friendIds.isEmpty) return [];

      final friendsSnap = await FirebaseFirestore.instance
          .collection('users') // pull friends from users collection
          .where(FieldPath.documentId, whereIn: friendIds)
          .get();

      return friendsSnap.docs.map((doc) {
        final f = doc.data();
        return Friend(
          name: f['name'] ?? '',
          username: f['username'] ?? '',
          score: "${f['score'] ?? 0} 🏅",
          completion: 0.0, // 👈 you can compute progress later if needed
        );
      }).toList();
    });
  }

  Stream<List<Group>> getGroupsStream(String userId) {
    return FirebaseFirestore.instance
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final g = doc.data();
            return Group(
              id: doc.id,
              name: g['name'] ?? '',
              memberIds: List<String>.from(g['memberIds'] ?? []),
              ownerId: g['ownerId'], // ✅ include this safely
            );
          }).toList();
        });
  }

  // UI BUILD
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colors = context.theme.appColors;

    if (user == null) {
      return Center(child: Text('Not logged in'));
    }

    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    return StreamBuilder<DocumentSnapshot>(
      stream: userDoc.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: Color(0xFF9BBF9E)),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text("No user data found"));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'Buddy';
        final goal = data['goalMinutes'] ?? 45;
        final score = data['score'] ?? 0;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(context.dimensions.values.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile card (with Pump button)
                  ProfileCard(
                    name: name,
                    goal: goal,
                    score: score,
                    onWorkoutAdded: () => setState(() {}),
                  ),
                  SizedBox(height: context.dimensions.values.s20),

                  SectionHeader(
                    title: "Groups",
                    onAdd: () async {
                      final newGroup = await showCreateGroupModal(context);

                      if (newGroup != null) {
                        final user = FirebaseAuth.instance.currentUser;

                        await FirebaseFirestore.instance
                            .collection('groups')
                            .add({
                              'name': newGroup.name,
                              'ownerId': user!.uid,
                              'memberIds': [user.uid],
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                      }
                    },
                    actionLabel: "Create",
                  ),

                  StreamBuilder<List<Group>>(
                    stream: getGroupsStream(user.uid),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final groups = snapshot.data!;

                      if (groups.isEmpty) {
                        return _placeholderCard(context, "No groups yet");
                      }

                      return Column(
                        children: groups.map((g) {
                          return GroupCard(
                            group: g,
                            refresh: () => setState(() {}),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  SizedBox(height: context.dimensions.values.s20),
                  SectionHeader(
                    title: "Friends",
                    onAdd: () async {
                      await showAddFriendModal(context);
                      setState(() {});
                    },
                    onAction: () {},
                    actionLabel: "Remind All",
                  ),
                  Expanded(
                    child: StreamBuilder<List<Friend>>(
                      stream: getFriendsStream(user.uid),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }
                        final friends = snapshot.data!;
                        if (friends.isEmpty) {
                          return _placeholderCard(context, "No friends yet");
                        }
                        return ListView(
                          children: friends
                              .map(
                                (f) => FriendTile(
                                  friend: f,
                                  onSend: () async {
                                    final chosen = await showMessageDialog(
                                      context,
                                      (messages.toList()..shuffle()).first,
                                    );
                                    if (chosen != null && chosen.isNotEmpty) {
                                      await FirebaseFirestore.instance
                                          .collection('messages')
                                          .add({
                                            'from': FirebaseAuth
                                                .instance
                                                .currentUser
                                                ?.uid,
                                            'to': f.username,
                                            'text': chosen,
                                            'timestamp':
                                                FieldValue.serverTimestamp(),
                                          });

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Sent to ${f.name}: $chosen",
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Section header (Groups/Friends)
  Widget _sectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onAdd,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: context.textSizes.s16,
          ),
        ),
        Row(
          children: [
            if (onAdd != null)
              IconButton(onPressed: onAdd, icon: Icon(Icons.add)),
            if (onAction != null && actionLabel != null)
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionLabel,
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // Placeholder Card
  Widget _placeholderCard(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.dimensions.values.s16),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.dimensions.values.s24),
        child: Center(
          child: Text(text, style: TextStyle(color: Colors.black)),
        ),
      ),
    );
  }
}
