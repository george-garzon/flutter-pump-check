part of 'dashboard_screen.dart';

extension _DashboardLeaderboardGroups on _DashboardScreenState {
  Widget _leaderboardToggle() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.dimensions.values.s22),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: context.dimensions.values.s44,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: _showFriends
                      ? _DashboardScreenState._accent
                      : Colors.transparent,
                  foregroundColor: _showFriends
                      ? _cream
                      : _DashboardScreenState._accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      context.dimensions.values.s10,
                    ),
                  ),
                ),
                onPressed: () => _updateState(() => _showFriends = true),
                child: Text(
                  'Friends',
                  style: TextStyle(fontSize: context.textSizes.s17),
                ),
              ),
            ),
          ),
          SizedBox(width: context.dimensions.values.s24),
          Expanded(
            child: SizedBox(
              height: context.dimensions.values.s44,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: !_showFriends
                      ? _DashboardScreenState._accent
                      : Colors.transparent,
                  foregroundColor: !_showFriends
                      ? _cream
                      : _DashboardScreenState._accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      context.dimensions.values.s10,
                    ),
                  ),
                ),
                onPressed: () => _updateState(() => _showFriends = false),
                child: Text(
                  'Groups',
                  style: TextStyle(fontSize: context.textSizes.s17),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _leaderboard(_MetricAggregate aggregate) {
    if (!_showFriends) {
      return _groupsLeaderboard();
    }

    final user = _user;
    if (user == null) {
      final members = _botLeaderboardMembers(aggregate);
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.dimensions.values.s26,
              context.dimensions.values.s16,
              context.dimensions.values.s26,
              context.dimensions.values.s10,
            ),
            child: Text(
              'Active Bot and Chill Bot are included in the free app. Sign in from Settings to add real friends.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontSize: context.textSizes.s17,
                height: 1.25,
              ),
            ),
          ),
          ...members.indexed.map((entry) {
            final index = entry.$1;
            final member = entry.$2;
            return _rankRow(
              rank: index + 1,
              icon: member.icon,
              name: member.name,
              value: member.calories,
              subtitle: member.calories > 0
                  ? '${member.minutes} min'
                  : 'benchmark bot',
            );
          }),
        ],
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() ?? {};
        final friendIds = List<String>.from(userData['friends'] ?? const []);
        final hiddenFriends = List<String>.from(
          userData['hiddenFriends'] ?? const [],
        ).toSet();

        return FutureBuilder<List<_LeaderboardMember>>(
          future: _friendLeaderboardMembers(
            friendIds: friendIds,
            hiddenFriends: hiddenFriends,
            currentUserAggregate: aggregate,
            currentUserData: userData,
          ),
          builder: (context, memberSnapshot) {
            final members = memberSnapshot.data ?? const <_LeaderboardMember>[];

            if (memberSnapshot.connectionState == ConnectionState.waiting &&
                members.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  vertical: context.dimensions.values.s26,
                ),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            return Column(
              children: [
                if (members.where((member) => member.canRemove).isEmpty)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.dimensions.values.s26,
                      context.dimensions.values.s16,
                      context.dimensions.values.s26,
                      context.dimensions.values.s10,
                    ),
                    child: Text(
                      'No friends yet. Send a request from Chats or add group members from a group.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _muted,
                        fontSize: context.textSizes.s17,
                        height: 1.25,
                      ),
                    ),
                  ),
                ...members.indexed.map((entry) {
                  final index = entry.$1;
                  final member = entry.$2;
                  return _rankRow(
                    rank: index + 1,
                    icon: member.icon,
                    name: member.name,
                    photoUrl: member.photoUrl,
                    value: member.calories,
                    subtitle: member.calories > 0
                        ? '${member.minutes} min'
                        : 'no workout yet',
                    onTap: member.canMessage
                        ? () => _showPresetMessageSheet(
                            recipientId: member.userId,
                            recipientName: member.name,
                          )
                        : null,
                    onRemove: member.canRemove
                        ? () => _confirmRemoveFriend(member)
                        : null,
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<_LeaderboardMember>> _friendLeaderboardMembers({
    required List<String> friendIds,
    required Set<String> hiddenFriends,
    required _MetricAggregate currentUserAggregate,
    required Map<String, dynamic> currentUserData,
  }) async {
    final user = _user;
    if (user == null) return [];

    final visibleFriendIds = friendIds
        .where((id) => id != user.uid)
        .toSet()
        .toList();
    final friendUsers = await _usersByIds(visibleFriendIds);
    final members = <_LeaderboardMember>[
      _LeaderboardMember(
        userId: user.uid,
        name: _displayNameForUserData(
          currentUserData,
          fallback: user.displayName ?? user.email ?? 'You',
        ),
        calories: currentUserAggregate.calories,
        minutes: currentUserAggregate.minutes,
        photoUrl:
            (currentUserData['photoUrl'] as String?) ?? user.photoURL ?? '',
        isCurrentUser: true,
      ),
    ];

    for (final friendId in visibleFriendIds) {
      final friendData = friendUsers[friendId];
      if (friendData == null) continue;
      if (_isHiddenFriend(
        friendId: friendId,
        friendData: friendData,
        hiddenFriends: hiddenFriends,
      )) {
        continue;
      }

      final aggregate = await _aggregateForUserPeriod(friendId, _period);
      members.add(
        _LeaderboardMember(
          userId: friendId,
          name: _displayNameForUserData(friendData, fallback: 'Friend'),
          calories: aggregate.calories,
          minutes: aggregate.minutes,
          photoUrl: (friendData['photoUrl'] as String?) ?? '',
          isCurrentUser: false,
        ),
      );
    }

    members.addAll(_botLeaderboardMembers(currentUserAggregate));
    _sortLeaderboardMembers(members);

    return members;
  }

  List<_LeaderboardMember> _botLeaderboardMembers(
    _MetricAggregate currentUserAggregate,
  ) {
    final members = [
      _LeaderboardMember(
        userId: 'active_bot',
        name: 'Active Bot',
        calories: _botValue(currentUserAggregate.calories, 1.25),
        minutes: math.max(35, (currentUserAggregate.minutes * 1.15).round()),
        photoUrl: '',
        isBot: true,
      ),
      _LeaderboardMember(
        userId: 'chill_bot',
        name: 'Chill Bot',
        calories: _botValue(currentUserAggregate.calories, 0.82),
        minutes: math.max(20, (currentUserAggregate.minutes * 0.75).round()),
        photoUrl: '',
        isBot: true,
      ),
    ];

    _sortLeaderboardMembers(members);
    return members;
  }

  void _sortLeaderboardMembers(List<_LeaderboardMember> members) {
    members.sort((a, b) {
      final calorieCompare = b.calories.compareTo(a.calories);
      if (calorieCompare != 0) return calorieCompare;
      if (a.isCurrentUser) return -1;
      if (b.isCurrentUser) return 1;
      return a.name.compareTo(b.name);
    });
  }

  bool _isHiddenFriend({
    required String friendId,
    required Map<String, dynamic> friendData,
    required Set<String> hiddenFriends,
  }) {
    final normalizedHidden = hiddenFriends
        .map((item) => item.trim().replaceFirst('@', '').toLowerCase())
        .toSet();

    if (hiddenFriends.contains(friendId) ||
        normalizedHidden.contains(friendId)) {
      return true;
    }

    final username = (friendData['username'] as String?)?.trim();
    if (username != null && username.isNotEmpty) {
      if (hiddenFriends.contains(username)) return true;
      if (hiddenFriends.contains('@$username')) return true;
      if (hiddenFriends.contains(username.toLowerCase())) return true;
      if (normalizedHidden.contains(username.toLowerCase())) return true;
    }

    final name = (friendData['name'] as String?)?.trim();
    return name != null &&
        name.isNotEmpty &&
        (hiddenFriends.contains(name) ||
            normalizedHidden.contains(name.toLowerCase()));
  }

  Future<_MetricAggregate> _aggregateForUserPeriod(
    String userId,
    MetricPeriod period,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('workouts')
        .where('userId', isEqualTo: userId)
        .limit(180)
        .get();
    final summaries = snapshot.docs.map((doc) => doc.data()).toList();
    return _aggregateForPeriod(summaries, period);
  }

  String _displayNameForUserData(
    Map<String, dynamic> data, {
    required String fallback,
  }) {
    final name = (data['name'] as String?)?.trim();
    if (name?.isNotEmpty == true) return name!;

    final username = (data['username'] as String?)?.trim();
    if (username?.isNotEmpty == true) return username!;

    return fallback;
  }

  int _botValue(int userCalories, double factor) {
    if (userCalories <= 0) return (350 * factor).round();
    return (userCalories * factor).round();
  }

  Future<void> _confirmRemoveFriend(_LeaderboardMember friend) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.dimensions.values.s22),
            side: BorderSide(color: _divider),
          ),
          title: Text('Remove friend?', style: TextStyle(color: _cream)),
          content: Text(
            'Remove ${friend.name} from your friends list?',
            style: TextStyle(color: _muted, fontSize: context.textSizes.s16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: TextStyle(color: _muted)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _removeFriend(friend.userId, friend.name);
              },
              child: Text(
                'Remove',
                style: TextStyle(color: _DashboardScreenState._accent),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeFriend(String friendId, String friendName) async {
    final user = _user;
    if (user == null) return;

    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      batch.set(db.collection('users').doc(user.uid), {
        'friends': FieldValue.arrayRemove([friendId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batch.set(db.collection('users').doc(friendId), {
        'friends': FieldValue.arrayRemove([user.uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await batch.commit();
      _showSnack('Removed $friendName from friends.');
    } catch (e) {
      _showSnack('Could not remove friend: $e');
    }
  }

  Widget _rankRow({
    required int rank,
    required IconData icon,
    required String name,
    required int value,
    required String subtitle,
    String photoUrl = '',
    VoidCallback? onTap,
    VoidCallback? onRemove,
  }) {
    final medalColors = {
      1: Colors.amber,
      2: Colors.grey.shade300,
      3: Colors.brown.shade400,
    };

    return InkWell(
      onTap: onTap,
      child: Container(
        height: context.dimensions.values.s78,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _divider)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: context.dimensions.values.s58,
              child: Center(
                child: rank <= 3
                    ? Icon(
                        Icons.emoji_events,
                        color: medalColors[rank],
                        size: context.dimensions.values.s22,
                      )
                    : Text(
                        '$rank',
                        style: TextStyle(
                          color: _cream,
                          fontSize: context.textSizes.s18,
                        ),
                      ),
              ),
            ),
            _profileAvatar(
              photoUrl: photoUrl,
              icon: icon,
              radius: context.dimensions.values.s23,
            ),
            SizedBox(width: context.dimensions.values.s24),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _cream,
                  fontSize: context.textSizes.s21,
                ),
              ),
            ),
            SizedBox(width: context.dimensions.values.s16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormat.decimalPattern().format(value),
                  style: TextStyle(
                    color: _cream,
                    fontSize: context.textSizes.s21,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: _muted,
                    fontSize: context.textSizes.s13,
                  ),
                ),
              ],
            ),
            SizedBox(width: onRemove == null ? 24 : 8),
            if (onRemove != null)
              IconButton(
                tooltip: 'Remove friend',
                visualDensity: VisualDensity.compact,
                onPressed: onRemove,
                icon: Icon(
                  Icons.person_remove_alt_1,
                  color: _muted,
                  size: context.dimensions.values.s22,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _profileAvatar({
    required String photoUrl,
    required IconData icon,
    double radius = 23,
  }) {
    return DashboardProfileAvatar(
      photoUrl: photoUrl,
      icon: icon,
      radius: radius,
      background: _DashboardScreenState._accent,
      foreground: _background,
    );
  }

  Widget _groupsLeaderboard() {
    final user = _user;
    if (user == null) {
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.dimensions.values.s26,
              context.dimensions.values.s16,
              context.dimensions.values.s26,
              context.dimensions.values.s10,
            ),
            child: Text(
              'Group creation is included in the free app. Sign in from Settings to create and compete in groups.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontSize: context.textSizes.s17,
                height: 1.25,
              ),
            ),
          ),
          _rankRow(
            rank: 1,
            icon: Icons.group_add_outlined,
            name: 'Create a group',
            value: 0,
            subtitle: 'Free with Google sign-in',
            onTap: _showCreateGroupSheet,
          ),
        ],
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .where('memberIds', arrayContains: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final groups = snapshot.data?.docs ?? [];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: context.dimensions.values.s26,
            ),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return FutureBuilder<List<_GroupLeaderboardItem>>(
          future: _groupLeaderboardItems(groups),
          builder: (context, groupSnapshot) {
            final rankedGroups =
                groupSnapshot.data ?? const <_GroupLeaderboardItem>[];

            if (groupSnapshot.connectionState == ConnectionState.waiting &&
                rankedGroups.isEmpty &&
                groups.isNotEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  vertical: context.dimensions.values.s26,
                ),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            return Column(
              children: [
                if (groups.isEmpty)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.dimensions.values.s26,
                      context.dimensions.values.s16,
                      context.dimensions.values.s26,
                      context.dimensions.values.s10,
                    ),
                    child: Text(
                      'No groups yet. Create one to compare calories and workout minutes with friends.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _muted,
                        fontSize: context.textSizes.s17,
                        height: 1.25,
                      ),
                    ),
                  )
                else
                  ...rankedGroups.indexed.map((entry) {
                    final index = entry.$1;
                    final group = entry.$2;

                    return _rankRow(
                      rank: index + 1,
                      icon: Icons.groups,
                      name: group.name,
                      value: group.totals.calories,
                      subtitle:
                          '${group.memberCount} members · ${group.totals.minutes} min',
                      onTap: () => _showGroupDetailsDialog(group.doc),
                    );
                  }),
                _rankRow(
                  rank: rankedGroups.length + 1,
                  icon: Icons.group_add_outlined,
                  name: 'Create a group',
                  value: 0,
                  subtitle:
                      'Free plan: up to ${_DashboardScreenState._freeGroupLimit} created groups',
                  onTap: _showCreateGroupSheet,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<_GroupLeaderboardItem>> _groupLeaderboardItems(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> groups,
  ) async {
    final items = <_GroupLeaderboardItem>[];

    for (final doc in groups) {
      final data = doc.data();
      final members = List<String>.from(data['memberIds'] ?? const []);
      final totals = await _groupTotalsForMemberIds(members, _period);
      items.add(
        _GroupLeaderboardItem(
          doc: doc,
          name: (data['name'] as String?) ?? 'Workout group',
          memberCount: members.length,
          totals: totals,
        ),
      );
    }

    items.sort((a, b) {
      final calorieCompare = b.totals.calories.compareTo(a.totals.calories);
      if (calorieCompare != 0) return calorieCompare;
      return a.name.compareTo(b.name);
    });

    return items;
  }

  Future<_GroupTotals> _groupTotalsForMemberIds(
    List<String> memberIds,
    MetricPeriod period,
  ) async {
    final uniqueIds = memberIds.toSet().toList();
    var calories = 0;
    var minutes = 0;

    for (final memberId in uniqueIds) {
      final aggregate = await _aggregateForUserPeriod(memberId, period);
      calories += aggregate.calories;
      minutes += aggregate.minutes;
    }

    return _GroupTotals(calories: calories, minutes: minutes);
  }

  Future<List<_GroupMemberPerformance>> _groupMemberPerformance(
    List<String> memberIds,
  ) async {
    final uniqueIds = memberIds.toSet().toList();
    if (uniqueIds.isEmpty) return [];

    final users = await _usersByIds(uniqueIds);
    final today = WorkoutService.dateKey(DateTime.now());
    final results = <_GroupMemberPerformance>[];

    for (final memberId in uniqueIds) {
      final userData = users[memberId] ?? {};
      final workout = await FirebaseFirestore.instance
          .collection('workouts')
          .doc('${memberId}_$today')
          .get();
      final summary = workout.data();
      final calories = WorkoutService.caloriesFromSummary(summary);
      final minutes = WorkoutService.minutesFromSummary(summary);
      final goal =
          (userData['goalCalories'] as num?)?.toInt() ??
          (summary?['goalCalories'] as num?)?.toInt() ??
          0;

      results.add(
        _GroupMemberPerformance(
          userId: memberId,
          name: (userData['name'] as String?)?.trim().isNotEmpty == true
              ? (userData['name'] as String).trim()
              : (userData['username'] as String?)?.trim().isNotEmpty == true
              ? (userData['username'] as String).trim()
              : 'Member',
          username: (userData['username'] as String?) ?? '',
          calories: calories,
          minutes: minutes,
          goalCalories: goal,
        ),
      );
    }

    results.sort((a, b) => b.calories.compareTo(a.calories));
    return results;
  }

  Future<Map<String, Map<String, dynamic>>> _usersByIds(
    List<String> userIds,
  ) async {
    final db = FirebaseFirestore.instance;
    final users = <String, Map<String, dynamic>>{};

    for (var start = 0; start < userIds.length; start += 10) {
      final chunk = userIds.skip(start).take(10).toList();
      if (chunk.isEmpty) continue;

      final snapshot = await db
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final doc in snapshot.docs) {
        users[doc.id] = doc.data();
      }
    }

    return users;
  }

  Future<Set<String>> _currentFriendIds() async {
    final user = _user;
    if (user == null) return {};

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return List<String>.from(doc.data()?['friends'] ?? const []).toSet();
  }

  Future<_GroupDetailsData> _groupDetailsData(List<String> memberIds) async {
    final results = await Future.wait([
      _groupMemberPerformance(memberIds),
      _currentFriendIds(),
    ]);

    return _GroupDetailsData(
      members: results[0] as List<_GroupMemberPerformance>,
      friendIds: results[1] as Set<String>,
    );
  }
}
