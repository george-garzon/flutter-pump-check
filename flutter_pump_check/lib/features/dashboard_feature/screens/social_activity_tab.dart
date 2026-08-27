part of 'dashboard_screen.dart';

extension _DashboardSocialActivityTab on _DashboardScreenState {
  Widget _buildSocialTab() {
    return Column(
      children: [
        _topHeader(
          title: 'Chats',
          leading: SizedBox(width: context.dimensions.values.s48),
          trailing: IconButton(
            icon: Icon(
              Icons.person_add_alt,
              color: _cream,
              size: context.dimensions.values.s28,
            ),
            onPressed: _showAddFriendSheet,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.dimensions.values.s22,
            context.dimensions.values.s18,
            context.dimensions.values.s22,
            context.dimensions.values.s0,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _friendUsernameController,
                  style: TextStyle(color: _cream),
                  decoration: _inputDecoration('Add friend by username'),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendFriendRequest(),
                ),
              ),
              SizedBox(width: context.dimensions.values.s10),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: _DashboardScreenState._accent,
                  foregroundColor: _onAccent,
                ),
                onPressed: _sendFriendRequest,
                icon: Icon(Icons.send),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _updateState(() {}),
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _messageStream(),
              builder: (context, snapshot) {
                final threads = _conversationThreads(snapshot.data?.docs ?? []);

                if (snapshot.connectionState == ConnectionState.waiting &&
                    threads.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: context.dimensions.values.s160),
                      Center(child: CircularProgressIndicator()),
                    ],
                  );
                }

                if (threads.isEmpty) {
                  return DashboardEmptyState(
                    icon: Icons.forum_outlined,
                    muted: _muted,
                    message:
                        'Tap a friend from the leaderboard to send a preset message. Those conversations will show up here.',
                  );
                }

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    context.dimensions.values.s22,
                    context.dimensions.values.s18,
                    context.dimensions.values.s22,
                    context.dimensions.values.s22,
                  ),
                  children: threads.map(_conversationTile).toList(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTab() {
    final user = _user;

    return Column(
      children: [
        _topHeader(
          title: 'Alerts',
          leading: SizedBox(width: context.dimensions.values.s48),
          trailing: Builder(
            builder: (buttonContext) {
              return IconButton(
                icon: Icon(
                  Icons.ios_share,
                  color: _cream,
                  size: context.dimensions.values.s27,
                ),
                onPressed: () {
                  _shareText(
                    buttonContext,
                    'Burn Camp keeps me accountable for calories burned and workout minutes.',
                  );
                },
              );
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: user == null
                ? const Stream.empty()
                : FirebaseFirestore.instance
                      .collection('group_invites')
                      .where('toUserId', isEqualTo: user.uid)
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
            builder: (context, inviteSnapshot) {
              final invites = inviteSnapshot.data?.docs ?? [];

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: user == null
                    ? const Stream.empty()
                    : FirebaseFirestore.instance
                          .collection('friend_requests')
                          .where('toUserId', isEqualTo: user.uid)
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                builder: (context, friendSnapshot) {
                  final friendRequests = friendSnapshot.data?.docs ?? [];

                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: WorkoutService.watchSummaries(limit: 60),
                    builder: (context, summarySnapshot) {
                      final summaries = summarySnapshot.data ?? [];

                      return ListView(
                        padding: EdgeInsets.fromLTRB(
                          context.dimensions.values.s22,
                          context.dimensions.values.s24,
                          context.dimensions.values.s22,
                          context.dimensions.values.s22,
                        ),
                        children: _alertItems(
                          summaries,
                          invites,
                          friendRequests,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _messageStream() {
    final user = _user;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('messages')
        .where('participants', arrayContains: user.uid)
        .snapshots();
  }

  List<_ConversationThread> _conversationThreads(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final user = _user;
    if (user == null) return [];

    final grouped =
        <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    for (final doc in docs) {
      final data = doc.data();
      final participants = List<String>.from(data['participants'] ?? const []);
      if (!participants.contains(user.uid) || participants.length < 2) continue;

      final conversationId =
          (data['conversationId'] as String?) ??
          _conversationIdForParticipants(participants[0], participants[1]);
      grouped.putIfAbsent(conversationId, () => []).add(doc);
    }

    final threads = grouped.entries.map((entry) {
      final messages = entry.value
        ..sort(
          (a, b) => _messageTimestamp(
            a.data(),
          ).compareTo(_messageTimestamp(b.data())),
        );
      final last = messages.last;
      final lastData = last.data();
      final participants = List<String>.from(
        lastData['participants'] ?? const [],
      );
      final otherUserId = participants.firstWhere(
        (id) => id != user.uid,
        orElse: () => '',
      );
      final otherName = lastData['fromUserId'] == otherUserId
          ? (lastData['fromUserName'] as String?) ?? 'Friend'
          : (lastData['toUserName'] as String?) ?? 'Friend';

      return _ConversationThread(
        conversationId: entry.key,
        otherUserId: otherUserId,
        otherName: otherName,
        lastText: (lastData['text'] as String?) ?? '',
        lastAt: _messageTimestamp(lastData),
      );
    }).toList();

    threads.sort((a, b) => b.lastAt.compareTo(a.lastAt));
    return threads;
  }

  Widget _conversationTile(_ConversationThread thread) {
    return InkWell(
      onTap: () => _showPresetMessageSheet(
        recipientId: thread.otherUserId,
        recipientName: thread.otherName,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: context.dimensions.values.s18),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _divider)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: context.dimensions.values.s24,
              backgroundColor: _DashboardScreenState._accent,
              child: Icon(Icons.chat_bubble_outline, color: _background),
            ),
            SizedBox(width: context.dimensions.values.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thread.otherName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _cream,
                      fontSize: context.textSizes.s19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: context.dimensions.values.s5),
                  Text(
                    thread.lastText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _muted,
                      fontSize: context.textSizes.s15,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: context.dimensions.values.s12),
            Text(
              _messageTimeLabel(thread.lastAt),
              style: TextStyle(color: _muted, fontSize: context.textSizes.s12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPresetMessageSheet({
    required String recipientId,
    required String recipientName,
  }) async {
    final user = _user;
    if (user == null || recipientId.isEmpty || recipientId == user.uid) return;

    final conversationId = _conversationIdForParticipants(
      user.uid,
      recipientId,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.dimensions.values.s22),
        ),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: context.dimensions.values.s22,
                right: context.dimensions.values.s22,
                top: context.dimensions.values.s18,
                bottom: _sheetBottomPadding(context, 18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          recipientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _cream,
                            fontSize: context.textSizes.s22,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: _muted),
                      ),
                    ],
                  ),
                  SizedBox(height: context.dimensions.values.s8),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('messages')
                          .where('conversationId', isEqualTo: conversationId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final docs = [...(snapshot.data?.docs ?? const [])]
                          ..sort(
                            (a, b) => _messageTimestamp(
                              a.data(),
                            ).compareTo(_messageTimestamp(b.data())),
                          );

                        if (docs.isEmpty) {
                          return Center(
                            child: Text(
                              'Send a preset message to start the conversation.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _muted,
                                fontSize: context.textSizes.s16,
                              ),
                            ),
                          );
                        }

                        return ListView(
                          children: docs.map((doc) {
                            final data = doc.data();
                            final isMine = data['fromUserId'] == user.uid;
                            return Align(
                              alignment: isMine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: EdgeInsets.only(
                                  bottom: context.dimensions.values.s10,
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.dimensions.values.s14,
                                  vertical: context.dimensions.values.s11,
                                ),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.68,
                                ),
                                decoration: BoxDecoration(
                                  color: isMine
                                      ? _DashboardScreenState._accent
                                      : _selectedSurface,
                                  borderRadius: BorderRadius.circular(
                                    context.dimensions.values.s16,
                                  ),
                                ),
                                child: Text(
                                  (data['text'] as String?) ?? '',
                                  style: TextStyle(
                                    color: isMine ? _onAccent : _cream,
                                    fontSize: context.textSizes.s16,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: context.dimensions.values.s12),
                  Text(
                    'Preset messages only',
                    style: TextStyle(
                      color: _muted,
                      fontSize: context.textSizes.s13,
                    ),
                  ),
                  SizedBox(height: context.dimensions.values.s8),
                  Wrap(
                    spacing: context.dimensions.values.s8,
                    runSpacing: context.dimensions.values.s8,
                    children: preset_messages.messages.map((message) {
                      return ActionChip(
                        backgroundColor: _selectedSurface,
                        side: BorderSide(color: _divider),
                        label: Text(message, style: TextStyle(color: _cream)),
                        onPressed: () => _sendPresetMessage(
                          recipientId: recipientId,
                          recipientName: recipientName,
                          text: message,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendPresetMessage({
    required String recipientId,
    required String recipientName,
    required String text,
  }) async {
    final user = _user;
    if (user == null) return;

    final db = FirebaseFirestore.instance;
    final myDoc = await db.collection('users').doc(user.uid).get();
    final myName = _displayNameForUserData(
      myDoc.data() ?? {},
      fallback: user.displayName ?? user.email ?? 'Burner',
    );
    final conversationId = _conversationIdForParticipants(
      user.uid,
      recipientId,
    );

    await db.collection('messages').add({
      'conversationId': conversationId,
      'participants': [user.uid, recipientId],
      'fromUserId': user.uid,
      'fromUserName': myName,
      'toUserId': recipientId,
      'toUserName': recipientName,
      'from': user.uid,
      'to': recipientId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  String _conversationIdForParticipants(String a, String b) {
    final ids = [a, b]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  DateTime _messageTimestamp(Map<String, dynamic> data) {
    return (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
  }

  String _messageTimeLabel(DateTime timestamp) {
    if (timestamp.year == 1970) return '';
    final now = DateTime.now();
    if (WorkoutService.dateKey(timestamp) == WorkoutService.dateKey(now)) {
      return DateFormat.jm().format(timestamp);
    }
    return DateFormat.Md().format(timestamp);
  }

  List<Widget> _alertItems(
    List<Map<String, dynamic>> summaries,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> groupInvites,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> friendRequests,
  ) {
    final items = <Widget>[
      ...friendRequests.map(_friendRequestAlertTile),
      ...groupInvites.map(_groupInviteAlertTile),
    ];

    if (summaries.isEmpty) {
      if (items.isNotEmpty) return items;

      return [
        SizedBox(height: context.dimensions.values.s160),
        Icon(
          Icons.notifications_none,
          color: _muted,
          size: context.dimensions.values.s70,
        ),
        SizedBox(height: context.dimensions.values.s18),
        Text(
          'Your friend requests, group invites, workout recaps, goal streaks, and calorie trends will show up here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: context.textSizes.s19),
        ),
      ];
    }

    final week = _aggregateForPeriod(summaries, MetricPeriod.week);
    final month = _aggregateForPeriod(summaries, MetricPeriod.month);
    final bestDay = summaries.reduce((a, b) {
      return WorkoutService.caloriesFromSummary(a) >=
              WorkoutService.caloriesFromSummary(b)
          ? a
          : b;
    });

    items.addAll([
      _alertTile(
        'You burned ${NumberFormat.decimalPattern().format(week.calories)} calories this week across ${week.minutes} workout minutes.',
        'Now',
      ),
      _alertTile(
        'This month you have logged ${NumberFormat.decimalPattern().format(month.calories)} calories burned.',
        DateFormat.yMMMd().format(DateTime.now()),
      ),
      _alertTile(
        'Best logged day: ${NumberFormat.decimalPattern().format(WorkoutService.caloriesFromSummary(bestDay))} calories and ${WorkoutService.minutesFromSummary(bestDay)} minutes.',
        _friendlyDate(bestDay),
      ),
      _alertTile(
        'Tip: keep Apple Health permissions enabled so Burn Camp can import workout calories and minutes.',
        'Settings',
      ),
    ]);

    return items;
  }

  Widget _friendRequestAlertTile(
    QueryDocumentSnapshot<Map<String, dynamic>> request,
  ) {
    final data = request.data();
    final fromName = (data['fromUserName'] as String?) ?? 'Someone';

    return Container(
      padding: EdgeInsets.symmetric(vertical: context.dimensions.values.s22),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: context.dimensions.values.s23,
            backgroundColor: _DashboardScreenState._accent,
            child: Icon(
              Icons.person_add_alt,
              color: _background,
              size: context.dimensions.values.s24,
            ),
          ),
          SizedBox(width: context.dimensions.values.s18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$fromName sent you a friend request.',
                  style: TextStyle(
                    color: _cream,
                    fontSize: context.textSizes.s20,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: context.dimensions.values.s8),
                Text(
                  'Friend request',
                  style: TextStyle(
                    color: _muted,
                    fontSize: context.textSizes.s14,
                  ),
                ),
                SizedBox(height: context.dimensions.values.s14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _muted,
                          side: BorderSide(color: _divider),
                        ),
                        onPressed: () => _declineFriendRequest(request),
                        child: Text('Decline'),
                      ),
                    ),
                    SizedBox(width: context.dimensions.values.s10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _DashboardScreenState._accent,
                          foregroundColor: _onAccent,
                        ),
                        onPressed: () => _acceptFriendRequest(request),
                        child: Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _groupInviteAlertTile(
    QueryDocumentSnapshot<Map<String, dynamic>> invite,
  ) {
    final data = invite.data();
    final groupName = (data['groupName'] as String?) ?? 'a group';
    final fromName = (data['fromUserName'] as String?) ?? 'Someone';

    return Container(
      padding: EdgeInsets.symmetric(vertical: context.dimensions.values.s22),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: context.dimensions.values.s23,
            backgroundColor: _DashboardScreenState._accent,
            child: Icon(
              Icons.group_add,
              color: _background,
              size: context.dimensions.values.s24,
            ),
          ),
          SizedBox(width: context.dimensions.values.s18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$fromName invited you to $groupName.',
                  style: TextStyle(
                    color: _cream,
                    fontSize: context.textSizes.s20,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: context.dimensions.values.s8),
                Text(
                  'Group invite',
                  style: TextStyle(
                    color: _muted,
                    fontSize: context.textSizes.s14,
                  ),
                ),
                SizedBox(height: context.dimensions.values.s14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _muted,
                          side: BorderSide(color: _divider),
                        ),
                        onPressed: () => _declineGroupInvite(invite),
                        child: Text('Decline'),
                      ),
                    ),
                    SizedBox(width: context.dimensions.values.s10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _DashboardScreenState._accent,
                          foregroundColor: _onAccent,
                        ),
                        onPressed: () => _acceptGroupInvite(invite),
                        child: Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertTile(String message, String dateLabel) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.dimensions.values.s22),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.show_chart,
            color: _DashboardScreenState._accent,
            size: context.dimensions.values.s44,
          ),
          SizedBox(width: context.dimensions.values.s22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: _cream,
                    fontSize: context.textSizes.s20,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: context.dimensions.values.s8),
                Text(
                  dateLabel,
                  style: TextStyle(
                    color: _muted,
                    fontSize: context.textSizes.s14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendFriendRequest() async {
    final username = _friendUsernameController.text.trim().replaceFirst(
      '@',
      '',
    );
    final sent = await _sendFriendRequestForUsername(username);
    if (sent) _friendUsernameController.clear();
  }

  Future<bool> _sendFriendRequestForUsername(String username) async {
    final user = _user;
    if (user == null) {
      _showSnack('Sign in to send friend requests.');
      return false;
    }

    final normalizedUsername = username.trim().replaceFirst('@', '');
    if (normalizedUsername.isEmpty) {
      _showSnack('Enter a username to add.');
      return false;
    }

    try {
      final friendDoc = await _findUserByUsername(normalizedUsername);
      if (friendDoc == null) {
        _showSnack('Could not find @$normalizedUsername.');
        return false;
      }

      return await _sendFriendRequestToUser(
        friendId: friendDoc.id,
        fallbackUsername: normalizedUsername,
      );
    } catch (e) {
      _showSnack('Could not send friend request: $e');
      return false;
    }
  }

  Future<void> _showAddFriendSheet() async {
    final controller = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.dimensions.values.s22),
        ),
      ),
      builder: (sheetContext) {
        var sending = false;

        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> send() async {
              if (sending) return;

              setSheetState(() => sending = true);
              final sent = await _sendFriendRequestForUsername(controller.text);
              if (!sheetContext.mounted) return;
              setSheetState(() => sending = false);

              if (sent) {
                Navigator.of(sheetContext).pop();
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: context.dimensions.values.s24,
                right: context.dimensions.values.s24,
                top: context.dimensions.values.s18,
                bottom: _sheetBottomPadding(sheetContext, 28),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Add friend',
                      style: TextStyle(
                        color: _cream,
                        fontSize: context.textSizes.s22,
                      ),
                    ),
                    SizedBox(height: context.dimensions.values.s8),
                    Text(
                      _user == null
                          ? 'Sign in to send friend requests, or share Burn Camp with someone.'
                          : 'Enter a Burn Camp username to send a friend request.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: context.textSizes.s15,
                      ),
                    ),
                    SizedBox(height: context.dimensions.values.s16),
                    TextField(
                      controller: controller,
                      enabled: _user != null && !sending,
                      autofocus: _user != null,
                      style: TextStyle(color: _cream),
                      decoration: _inputDecoration('Username'),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => send(),
                    ),
                    SizedBox(height: context.dimensions.values.s16),
                    if (_user == null)
                      _primarySheetButton(
                        label: 'Sign in to add friends',
                        onPressed: _signInFromSettings,
                      )
                    else
                      _primarySheetButton(
                        label: sending ? 'Sending...' : 'Send friend request',
                        onPressed: sending ? () {} : send,
                      ),
                    SizedBox(height: context.dimensions.values.s10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _cream,
                        side: BorderSide(color: _divider),
                        padding: EdgeInsets.symmetric(
                          vertical: context.dimensions.values.s13,
                        ),
                      ),
                      onPressed: () => _shareText(
                        sheetContext,
                        'Join me on Burn Camp — track calories burned, training minutes, and compare workouts with friends.',
                      ),
                      icon: Icon(Icons.ios_share),
                      label: Text('Share invite'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showHomeCreateMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.dimensions.values.s22),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.dimensions.values.s24,
              context.dimensions.values.s18,
              context.dimensions.values.s24,
              _sheetBottomPadding(sheetContext, context.dimensions.values.s28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create',
                  style: TextStyle(
                    color: _cream,
                    fontSize: context.textSizes.s22,
                  ),
                ),
                SizedBox(height: context.dimensions.values.s16),
                _homeCreateOption(
                  icon: Icons.person_add_alt,
                  title: 'Add friend',
                  subtitle: 'Send a friend request by username.',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showAddFriendSheet();
                  },
                ),
                SizedBox(height: context.dimensions.values.s12),
                _homeCreateOption(
                  icon: Icons.group_add_outlined,
                  title: 'Create group',
                  subtitle: 'Start a group and invite friends.',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showCreateGroupSheet();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _homeCreateOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.dimensions.values.s18),
      child: Container(
        padding: EdgeInsets.all(context.dimensions.values.s16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(context.dimensions.values.s18),
          border: Border.all(color: _divider),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: context.dimensions.values.s22,
              backgroundColor: _DashboardScreenState._accent,
              child: Icon(
                icon,
                color: _background,
                size: context.dimensions.values.s24,
              ),
            ),
            SizedBox(width: context.dimensions.values.s14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _cream,
                      fontSize: context.textSizes.s17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: context.dimensions.values.s4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _muted,
                      fontSize: context.textSizes.s14,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: context.dimensions.values.s10),
            Icon(Icons.chevron_right, color: _muted),
          ],
        ),
      ),
    );
  }

  Future<bool> _sendFriendRequestToUser({
    required String friendId,
    required String fallbackUsername,
  }) async {
    final user = _user;
    if (user == null) {
      _showSnack('Sign in to send friend requests.');
      return false;
    }

    final db = FirebaseFirestore.instance;
    final friendDoc = await db.collection('users').doc(friendId).get();
    if (!friendDoc.exists) {
      _showSnack('Could not find @$fallbackUsername.');
      return false;
    }

    final friendData = friendDoc.data() ?? {};
    final friendUsername =
        (friendData['username'] as String?)?.trim().isNotEmpty == true
        ? (friendData['username'] as String).trim()
        : fallbackUsername;

    if (friendId == user.uid) {
      _showSnack('You cannot add yourself.');
      return false;
    }

    final myDoc = await db.collection('users').doc(user.uid).get();
    final myData = myDoc.data() ?? {};
    final friends = List<String>.from(myData['friends'] ?? const []);
    if (friends.contains(friendId)) {
      _showSnack('You are already friends with @$friendUsername.');
      return false;
    }

    final sentPending = await db
        .collection('friend_requests')
        .where('fromUserId', isEqualTo: user.uid)
        .where('toUserId', isEqualTo: friendId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (sentPending.docs.isNotEmpty) {
      _showSnack('Friend request already sent to @$friendUsername.');
      return false;
    }

    final receivedPending = await db
        .collection('friend_requests')
        .where('fromUserId', isEqualTo: friendId)
        .where('toUserId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (receivedPending.docs.isNotEmpty) {
      _showSnack('@$friendUsername already sent you a request.');
      return false;
    }

    final myUsername =
        (myData['username'] as String?) ?? user.displayName ?? user.email;
    await db.collection('friend_requests').doc('${user.uid}_$friendId').set({
      'fromUserId': user.uid,
      'fromUserName': myUsername ?? 'Burner',
      'toUserId': friendId,
      'toUserName': friendUsername,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    _showSnack('Friend request sent to @$friendUsername.');
    return true;
  }

  Future<void> _acceptFriendRequest(
    QueryDocumentSnapshot<Map<String, dynamic>> request,
  ) async {
    final user = _user;
    if (user == null) return;

    final data = request.data();
    final fromUserId = data['fromUserId'] as String?;
    final toUserId = data['toUserId'] as String?;
    final fromName = (data['fromUserName'] as String?) ?? 'this user';

    if (fromUserId == null || toUserId == null || toUserId != user.uid) {
      _showSnack('This friend request is invalid.');
      return;
    }

    final db = FirebaseFirestore.instance;
    try {
      await db.runTransaction((transaction) async {
        transaction.update(request.reference, {
          'status': 'accepted',
          'respondedAt': FieldValue.serverTimestamp(),
        });
        transaction.set(db.collection('users').doc(fromUserId), {
          'friends': FieldValue.arrayUnion([toUserId]),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        transaction.set(db.collection('users').doc(toUserId), {
          'friends': FieldValue.arrayUnion([fromUserId]),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      _showSnack('You are now friends with $fromName.');
    } catch (e) {
      _showSnack('Could not accept friend request: $e');
    }
  }

  Future<void> _declineFriendRequest(
    QueryDocumentSnapshot<Map<String, dynamic>> request,
  ) async {
    try {
      await request.reference.update({
        'status': 'declined',
        'respondedAt': FieldValue.serverTimestamp(),
      });
      _showSnack('Friend request declined.');
    } catch (e) {
      _showSnack('Could not decline friend request: $e');
    }
  }

  Future<void> _acceptGroupInvite(
    QueryDocumentSnapshot<Map<String, dynamic>> invite,
  ) async {
    final user = _user;
    if (user == null) return;

    final data = invite.data();
    final groupId = data['groupId'] as String?;
    final groupName = (data['groupName'] as String?) ?? 'group';
    if (groupId == null || groupId.isEmpty) {
      _showSnack('This invite is missing a group.');
      return;
    }

    final db = FirebaseFirestore.instance;
    final groupRef = db.collection('groups').doc(groupId);
    final userRef = db.collection('users').doc(user.uid);
    final groupInviteRef = groupRef.collection('invitations').doc(user.uid);

    try {
      await db.runTransaction((transaction) async {
        transaction.set(groupRef, {
          'memberIds': FieldValue.arrayUnion([user.uid]),
          'pendingInviteIds': FieldValue.arrayRemove([user.uid]),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        transaction.set(userRef, {
          'groups': FieldValue.arrayUnion([groupId]),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        transaction.update(invite.reference, {
          'status': 'accepted',
          'respondedAt': FieldValue.serverTimestamp(),
        });
        transaction.set(groupInviteRef, {
          'status': 'accepted',
          'respondedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      _showSnack('Joined $groupName.');
    } catch (e) {
      _showSnack('Could not accept invite: $e');
    }
  }

  Future<void> _declineGroupInvite(
    QueryDocumentSnapshot<Map<String, dynamic>> invite,
  ) async {
    final user = _user;
    if (user == null) return;

    final data = invite.data();
    final groupId = data['groupId'] as String?;
    final db = FirebaseFirestore.instance;
    final batch = db.batch();

    batch.update(invite.reference, {
      'status': 'declined',
      'respondedAt': FieldValue.serverTimestamp(),
    });

    if (groupId != null && groupId.isNotEmpty) {
      final groupRef = db.collection('groups').doc(groupId);
      batch.set(groupRef, {
        'pendingInviteIds': FieldValue.arrayRemove([user.uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batch.set(groupRef.collection('invitations').doc(user.uid), {
        'status': 'declined',
        'respondedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    try {
      await batch.commit();
      _showSnack('Group invite declined.');
    } catch (e) {
      _showSnack('Could not decline invite: $e');
    }
  }
}
