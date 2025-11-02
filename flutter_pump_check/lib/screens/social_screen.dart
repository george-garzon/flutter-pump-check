import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final db = FirebaseFirestore.instance;

  // 🔹 Stream for pending group invites
  Stream<QuerySnapshot> getGroupInvites() {
    return db
        .collection('group_invites')
        .where('toUserId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // 🔹 Stream for friend requests (optional)
  Stream<QuerySnapshot> getFriendRequests() {
    return db
        .collection('friend_requests')
        .where('toUserId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> acceptInvite(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final groupId = data['groupId'];
    final userId = user.uid;

    final groupRef = db.collection('groups').doc(groupId);
    await db.runTransaction((t) async {
      final snap = await t.get(groupRef);
      final members = List<String>.from(snap['memberIds'] ?? []);
      if (!members.contains(userId)) members.add(userId);
      t.update(groupRef, {'memberIds': members});
      t.update(doc.reference, {'status': 'accepted'});
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Joined ${data['groupName']}!')));
  }

  Future<void> declineInvite(DocumentSnapshot doc) async {
    await doc.reference.update({'status': 'declined'});
  }

  Widget _sectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Friends & Groups')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(context, "Pending Group Invites"),
            StreamBuilder<QuerySnapshot>(
              stream: getGroupInvites(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final invites = snapshot.data!.docs;
                if (invites.isEmpty) {
                  return const Text("No pending group invites.");
                }

                return Column(
                  children: invites.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(d['groupName'] ?? ''),
                        subtitle: Text('From ${d['fromUserName'] ?? ''}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              onPressed: () => acceptInvite(doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => declineInvite(doc),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            _sectionHeader(context, "Friend Requests"),
            StreamBuilder<QuerySnapshot>(
              stream: getFriendRequests(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final requests = snapshot.data!.docs;
                if (requests.isEmpty) {
                  return const Text("No friend requests yet.");
                }
                return Column(
                  children: requests.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(d['fromUserName'] ?? ''),
                        subtitle: const Text('Wants to be friends'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              onPressed: () async {
                                await doc.reference.update({
                                  'status': 'accepted',
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () async {
                                await doc.reference.update({
                                  'status': 'declined',
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
