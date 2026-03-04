import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_pump_check/theme/theme.dart';

import '../../dashboard_feature/widgets/section_header.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final db = FirebaseFirestore.instance;
  String? myUsername;

  @override
  void initState() {
    super.initState();
    loadUsername();
  }

  Future<void> loadUsername() async {
    final doc = await db.collection('users').doc(user.uid).get();
    print("User UID: ${user.uid}");
    final data = doc.data();

    setState(() {
      myUsername = data?['username'];
      print("Username: ${myUsername}");    });
  }
  // Pending group invites
  Stream<QuerySnapshot> getGroupInvites() {
    return db
        .collection('group_invites')
        .where('toUserId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // Pending friend requests
  Stream<QuerySnapshot> getFriendRequests() {
    return db
        .collection('friend_requests')
        .where('toUserId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // Messages sent to me
  Stream<QuerySnapshot> getMessagesToMe() {
    if (myUsername == null) {
      return const Stream.empty();
    }

    return db
        .collection('messages')
        .where('to', isEqualTo: myUsername)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Accept a group invite
  Future<void> acceptInvite(DocumentSnapshot doc) async {
    debugPrint("🔥 Accepting group invite ${doc.id}");
    try {
      final data = doc.data() as Map<String, dynamic>;
      final groupId = data['groupId'];
      final userId = user.uid;

      if (groupId == null) {
        debugPrint("⚠️ Missing groupId on invite ${doc.id}");
        return;
      }

      final groupRef = db.collection('groups').doc(groupId);
      await db.runTransaction((t) async {
        final snap = await t.get(groupRef);
        final members = List<String>.from(snap['memberIds'] ?? []);
        if (!members.contains(userId)) members.add(userId);
        t.update(groupRef, {'memberIds': members});
        t.update(doc.reference, {'status': 'accepted'});
      });

      debugPrint("✅ Added $userId to group $groupId successfully");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Joined ${data['groupName']}!')));
    } catch (e, st) {
      debugPrint("❌ Error accepting group invite: $e\n$st");
    }
  }

  // 🔹 Decline a group invite
  Future<void> declineInvite(DocumentSnapshot doc) async {
    await doc.reference.update({'status': 'declined'});
  }

  // 🔹 Accept friend request
  Future<void> acceptFriendRequest(DocumentSnapshot doc) async {
    debugPrint("🔥 Starting acceptFriendRequest for ${doc.id}");
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) {
        debugPrint("⚠️ No data in document ${doc.id}");
        return;
      }

      final fromUserId = data['fromUserId'];
      final toUserId = data['toUserId'];
      debugPrint("📦 Request data: $data");

      if (fromUserId == null || toUserId == null) {
        debugPrint("⚠️ Missing fromUserId or toUserId fields");
        return;
      }

      // Make sure these users exist
      final fromUserDoc = await db.collection('users').doc(fromUserId).get();
      final toUserDoc = await db.collection('users').doc(toUserId).get();

      debugPrint("👤 FromUser exists: ${fromUserDoc.exists}");
      debugPrint("👤 ToUser exists: ${toUserDoc.exists}");

      if (!fromUserDoc.exists || !toUserDoc.exists) {
        debugPrint("❌ One or both users don't exist in Firestore");
        return;
      }

      // Perform updates
      await db.runTransaction((txn) async {
        txn.update(doc.reference, {'status': 'accepted'});
        txn.update(db.collection('users').doc(fromUserId), {
          'friends': FieldValue.arrayUnion([toUserId]),
        });
        txn.update(db.collection('users').doc(toUserId), {
          'friends': FieldValue.arrayUnion([fromUserId]),
        });
      });

      debugPrint(
        "✅ Transaction committed successfully for $fromUserId <-> $toUserId",
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You are now friends with ${data['fromUserName']}!"),
        ),
      );
    } catch (e, st) {
      debugPrint("❌ Error in acceptFriendRequest: $e\n$st");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error adding friend: $e")));
    }
  }

  // 🔹 Decline friend request
  Future<void> declineFriendRequest(DocumentSnapshot doc) async {
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
    final colors = context.theme.appColors;


    return Scaffold(
      appBar: AppBar(title: const Text('Friends & Groups')),
      backgroundColor: colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: "Pending Group Invites",
              ),
              StreamBuilder<QuerySnapshot>(
                stream: getGroupInvites(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final invites = snapshot.data!.docs;
                  if (invites.isEmpty) {
                    return Text(
                        "No pending group invites.",
                        style: TextStyle(
                          color: colors.gray
                        ),
                    );
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
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                ),
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
              SectionHeader(
                title: "Friend Requests",
              ),
              StreamBuilder<QuerySnapshot>(
                stream: getFriendRequests(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final requests = snapshot.data!.docs;
                  if (requests.isEmpty) {
                    return Text(
                        "No friend requests yet.",
                        style: TextStyle(
                            color: colors.gray
                        ),
                    );
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
                                  debugPrint(
                                    "Accept button pressed for ${doc.id}",
                                  );
                                  await acceptFriendRequest(doc);
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                ),
                                onPressed: () => declineFriendRequest(doc),
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

              SectionHeader(
                title: "My Friends",
              ),
              StreamBuilder<DocumentSnapshot>(
                stream: db.collection('users').doc(user.uid).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const CircularProgressIndicator();
                  final data =
                      snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  final friends = List<String>.from(data['friends'] ?? []);
                  if (friends.isEmpty) {
                    return Text(
                        "You have no friends yet.",
                        style: TextStyle(
                            color: colors.gray
                        ),
                    );
                  }

                  return FutureBuilder<QuerySnapshot>(
                    future: db
                        .collection('users')
                        .where(FieldPath.documentId, whereIn: friends)
                        .get(),
                    builder: (context, snap) {
                      if (!snap.hasData)
                        return const CircularProgressIndicator();
                      final friendDocs = snap.data!.docs;
                      return Column(
                        children: friendDocs.map((f) {
                          final fd = f.data() as Map<String, dynamic>;
                          return Card(
                            color: colors.gray,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: fd['photoUrl'] != null
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        fd['photoUrl'],
                                      ),
                                    )
                                  : const CircleAvatar(
                                      child: Icon(Icons.person),
                                    ),
                              title: Text(fd['name'] ?? 'Unknown'),
                              subtitle: Text('@${fd['username'] ?? ''}'),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  );
                },
              ),


              const SizedBox(height: 20),

              SectionHeader(
                title: "Messages",
              ),

              StreamBuilder<QuerySnapshot>(
                stream: getMessagesToMe(),
                builder: (context, snapshot) {

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    print("waiting for messages...");
                    return const CircularProgressIndicator();
                  }

                  final messages = snapshot.data?.docs ?? [];

                  print("messages found: ${messages.length}");

                  if (messages.isEmpty) {
                    return Text(
                      "No messages yet.",
                      style: TextStyle(color: colors.gray),
                    );
                  }

                  return Column(
                    children: messages.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.mail),
                          ),
                          title: Text(data['text'] ?? ''),
                          subtitle: Text("From ${data['from'] ?? ''}"),
                          trailing: Text(
                            data['timestamp'] != null
                                ? (data['timestamp'] as Timestamp)
                                .toDate()
                                .toString()
                                .substring(0, 16)
                                : '',
                            style: TextStyle(fontSize: 12, color: colors.gray),
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
      ),
    );
  }
}
