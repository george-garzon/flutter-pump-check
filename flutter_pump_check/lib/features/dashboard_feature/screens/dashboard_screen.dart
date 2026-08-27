import 'dart:math' as math;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';
import 'package:flutter/rendering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_pump_check/features/onboarding_feature/screens/onboarding_screen.dart';
import 'package:flutter_pump_check/services/apple_health_service.dart';
import 'package:flutter_pump_check/services/auth/auth_service.dart';
import 'package:flutter_pump_check/services/onboarding_preferences.dart';
import 'package:flutter_pump_check/services/workout_service.dart';
import 'package:flutter_pump_check/features/dashboard_feature/widgets/dashboard_sections.dart';
import 'package:flutter_pump_check/theme/app_gradient_background.dart';
import 'package:flutter_pump_check/theme/app_theme_mode.dart';
import 'package:flutter_pump_check/theme/claude_palette.dart';
import 'package:flutter_pump_check/utils/messages.dart' as preset_messages;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_pump_check/theme/text_sizes.dart';

enum MetricPeriod { today, yesterday, week, month }

enum HistoryRange { day, week, month, calendar }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _accent = ClaudePalette.accent;
  static const _goalLime = ClaudePalette.goal;
  static const _freeGroupLimit = 5;

  bool get _isLight => Theme.of(context).brightness == Brightness.light;
  Color get _background =>
      _isLight ? ClaudePalette.cream : ClaudePalette.charcoal;
  Color get _selectedSurface =>
      _isLight ? const Color(0xFFFFEFE5) : ClaudePalette.selectedSurface;
  Color get _surface =>
      _isLight ? const Color(0xFFFFFFFF) : ClaudePalette.charcoalSurface;
  Color get _divider =>
      _isLight ? const Color(0xFFE6D8CA) : ClaudePalette.charcoalBorder;
  Color get _muted =>
      _isLight ? ClaudePalette.lightMutedText : ClaudePalette.mutedText;
  Color get _cream => _isLight ? ClaudePalette.charcoal : ClaudePalette.cream;
  Color get _onAccent => ClaudePalette.charcoal;

  int _selectedIndex = 0;
  MetricPeriod _period = MetricPeriod.today;
  HistoryRange _historyRange = HistoryRange.week;
  bool _historyShowsAverage = true;
  bool _showFriends = true;
  int _settingsRefresh = 0;
  bool _syncingAppleHealth = false;
  final TextEditingController _friendUsernameController =
      TextEditingController();

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _friendUsernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _homeTab(),
      _historyTab(),
      _socialTab(),
      _activityTab(),
      _settingsTab(),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _selectedIndex, children: screens),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: _surface,
        selectedItemColor: _accent,
        unselectedItemColor: _cream,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        iconSize: 29,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: ''),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart_outlined),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: '',
          ),
        ],
      ),
    );
  }

  Widget _homeTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: WorkoutService.watchSummaries(limit: 120),
      builder: (context, snapshot) {
        final summaries = snapshot.data ?? [];
        final aggregate = _aggregateForPeriod(summaries, _period);

        return Column(
          children: [
            _topHeader(
              title: 'Burn Camp',
              leading: Builder(
                builder: (buttonContext) {
                  return IconButton(
                    icon: Icon(
                      Icons.ios_share,
                      color: _cream,
                      size: context.dimensions.values.s27,
                    ),
                    onPressed: () {
                      _openStatsShareScreen(summaries);
                    },
                  );
                },
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.add,
                  color: _cream,
                  size: context.dimensions.values.s32,
                ),
                onPressed: _showHomeCreateMenu,
              ),
              bottom: _periodTabs(),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    SizedBox(height: context.dimensions.values.s26),
                    Text(
                      _metricLabel(_period),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _cream,
                        fontSize: context.textSizes.s20,
                      ),
                    ),
                    SizedBox(height: context.dimensions.values.s10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            NumberFormat.decimalPattern().format(
                              aggregate.calories,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: TextStyle(
                              color: _cream,
                              fontSize: context.textSizes.s68,
                              fontWeight: FontWeight.w300,
                              height: 0.95,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.chevron_right,
                            color: _muted,
                            size: context.dimensions.values.s44,
                          ),
                          onPressed: () => setState(() => _selectedIndex = 1),
                        ),
                      ],
                    ),
                    SizedBox(height: context.dimensions.values.s10),
                    Text(
                      _minutesLabel(aggregate, _period),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _cream,
                        fontSize: context.textSizes.s20,
                      ),
                    ),
                    SizedBox(height: context.dimensions.values.s28),
                    _leaderboardToggle(),
                    SizedBox(height: context.dimensions.values.s18),
                    _leaderboard(aggregate),
                    SizedBox(height: context.dimensions.values.s30),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.dimensions.values.s22,
                      ),
                      child: SizedBox(
                        height: context.dimensions.values.s56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: _onAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                context.dimensions.values.s14,
                              ),
                            ),
                          ),
                          onPressed: _showAddWorkoutSheet,
                          child: Text(
                            aggregate.calories == 0
                                ? 'Add today’s workout'
                                : 'Add another workout',
                            style: TextStyle(fontSize: context.textSizes.s20),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: context.dimensions.values.s28),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _historyTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: WorkoutService.watchSummaries(limit: 180),
      builder: (context, snapshot) {
        final summaries = snapshot.data ?? [];
        final longestStreak = _longestStreak(summaries);
        final bestWeek = _bestWindow(summaries, const Duration(days: 7));
        final bestMonth = _bestMonth(summaries);

        return Column(
          children: [
            _topHeader(
              title: 'History',
              leading: SizedBox(width: context.dimensions.values.s48),
              trailing: IconButton(
                tooltip: _historyShowsAverage
                    ? 'Show total calories'
                    : 'Show average calories',
                icon: Icon(
                  _historyShowsAverage
                      ? Icons.bar_chart
                      : Icons.format_list_numbered,
                  color: _cream,
                  size: context.dimensions.values.s30,
                ),
                onPressed: () {
                  setState(() => _historyShowsAverage = !_historyShowsAverage);
                },
              ),
              bottom: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.dimensions.values.s22,
                  context.dimensions.values.s12,
                  context.dimensions.values.s22,
                  context.dimensions.values.s0,
                ),
                child: Column(
                  children: [
                    _summaryLine(
                      'Daily goal:',
                      '${_goalCaloriesFromCachedSummaries(summaries)} cals',
                      valueColor: _goalLime,
                      icon: Icons.edit,
                      onTap: _showGoalSheet,
                    ),
                    _summaryLine('Longest streak:', '$longestStreak days'),
                    _summaryLine('Best week:', bestWeek),
                    _summaryLine('Best month:', bestMonth),
                    SizedBox(height: context.dimensions.values.s12),
                    _historyTabs(),
                  ],
                ),
              ),
            ),
            Expanded(child: _historyContent(summaries)),
          ],
        );
      },
    );
  }

  Widget _socialTab() {
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
                  backgroundColor: _accent,
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
            onRefresh: () async => setState(() {}),
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

  Widget _activityTab() {
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
              backgroundColor: _accent,
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
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
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
                                  color: isMine ? _accent : _selectedSurface,
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
        'Tip: update Default workout duration in Settings to make manual entry faster.',
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
            backgroundColor: _accent,
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
                          backgroundColor: _accent,
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
            backgroundColor: _accent,
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
                          backgroundColor: _accent,
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
            color: _accent,
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
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 28,
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
              context.dimensions.values.s28,
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
              backgroundColor: _accent,
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

  Widget _settingsTab() {
    final user = _user;
    if (user == null) {
      return FutureBuilder<Map<String, dynamic>>(
        key: ValueKey(_settingsRefresh),
        future: _localSettingsData(),
        builder: (context, snapshot) {
          final data = snapshot.data ?? {};
          final goal = _goalCalories(data);
          final defaultMinutes =
              (data['defaultWorkoutMinutes'] as num?)?.toInt() ?? 30;
          final workoutTrackingMode =
              (data['workoutTrackingMode'] as String?) ?? 'manual';
          final streakMode = (data['streakMode'] as String?) ?? 'strict';
          final themeMode = (data['themeMode'] as String?) ?? 'dark';
          final notificationsEnabled = data['notificationsEnabled'] != false;
          final hiddenFriends =
              (data['hiddenFriends'] as List<dynamic>? ?? const []).length;

          return Column(
            children: [
              _topHeader(
                title: 'Settings',
                leading: SizedBox(width: context.dimensions.values.s48),
                trailing: SizedBox(width: context.dimensions.values.s48),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    SizedBox(height: context.dimensions.values.s32),
                    _settingsRow(
                      'Workout tracking',
                      _workoutTrackingModeLabel(workoutTrackingMode),
                      onTap: () =>
                          _showWorkoutTrackingSheet(workoutTrackingMode),
                    ),
                    _settingsRow(
                      'Daily calorie goal',
                      '$goal',
                      onTap: _showGoalSheet,
                    ),
                    _settingsRow(
                      'Default workout duration',
                      '$defaultMinutes min',
                      onTap: () => _showDefaultDurationSheet(defaultMinutes),
                    ),
                    _settingsRow(
                      'Streak mode',
                      _streakModeLabel(streakMode),
                      onTap: () => _showStreakModeSheet(streakMode),
                    ),
                    _settingsRow(
                      'Theme',
                      themeModeLabel(themeMode),
                      onTap: () => _showThemeModeSheet(themeMode),
                    ),
                    _settingsRow(
                      'Notifications',
                      notificationsEnabled ? 'On' : 'Off',
                      onTap: () => _toggleNotifications(notificationsEnabled),
                    ),
                    SizedBox(
                      height: context.dimensions.values.s28,
                      child: ColoredBox(color: _surface),
                    ),
                    _settingsRow(
                      'Account',
                      'Save to email',
                      onTap: _signInFromSettings,
                    ),
                    _settingsRow(
                      'Reset personalization',
                      'Restart',
                      onTap: _resetPersonalization,
                    ),
                    _settingsRow('Recaps', 'View', onTap: _showRecapsSheet),
                    _settingsRow(
                      'Invite friends',
                      'Share',
                      onTap: _inviteFriends,
                    ),
                    _settingsRow(
                      'Hidden friends',
                      '$hiddenFriends',
                      onTap: () => _showHiddenFriendsSheet(data),
                    ),
                    _settingsRow(
                      'Manage groups',
                      '',
                      onTap: _showManageGroupsPage,
                    ),
                    SizedBox(
                      height: context.dimensions.values.s28,
                      child: ColoredBox(color: _surface),
                    ),
                    _settingsRow('Help and feedback', '', onTap: _showHelpPage),
                    _settingsRow(
                      'Support Burn Camp',
                      'Premium',
                      onTap: _showSupportPage,
                    ),
                    _settingsRow(
                      'Instagram',
                      '@burncamp',
                      onTap: () =>
                          _showSnack('Social links are placeholders for now.'),
                    ),
                    _settingsRow(
                      'TikTok',
                      '@burncamp',
                      onTap: () =>
                          _showSnack('Social links are placeholders for now.'),
                    ),
                    SizedBox(
                      height: context.dimensions.values.s28,
                      child: ColoredBox(color: _surface),
                    ),
                    _settingsRow(
                      'Privacy',
                      '',
                      onTap: () => _showInfoPage(
                        title: 'Privacy',
                        body:
                            'Burn Camp works locally first. Sign in only when you want to save and sync your data to an email account.',
                      ),
                    ),
                    _settingsRow(
                      'Terms',
                      '',
                      onTap: () => _showInfoPage(
                        title: 'Terms',
                        body:
                            'Burn Camp is for personal fitness tracking and friendly accountability. Manually entered workouts should reflect your best estimate.',
                      ),
                    ),
                    SizedBox(height: context.dimensions.values.s22),
                  ],
                ),
              ),
            ],
          );
        },
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final name = (data['name'] as String?)?.trim();
        final goal = _goalCalories(data);
        final defaultMinutes =
            (data['defaultWorkoutMinutes'] as num?)?.toInt() ?? 30;
        final workoutTrackingMode =
            (data['workoutTrackingMode'] as String?) ?? 'manual';
        final streakMode = (data['streakMode'] as String?) ?? 'strict';
        final themeMode = (data['themeMode'] as String?) ?? 'dark';
        final notificationsEnabled = data['notificationsEnabled'] != false;
        final hiddenFriends =
            (data['hiddenFriends'] as List<dynamic>? ?? const []).length;

        return Column(
          children: [
            _topHeader(
              title: 'Settings',
              leading: SizedBox(width: context.dimensions.values.s48),
              trailing: SizedBox(width: context.dimensions.values.s48),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  SizedBox(height: context.dimensions.values.s32),
                  _settingsRow(
                    'Workout tracking',
                    _workoutTrackingModeLabel(workoutTrackingMode),
                    onTap: () => _showWorkoutTrackingSheet(workoutTrackingMode),
                  ),
                  _settingsRow(
                    'Daily calorie goal',
                    '$goal',
                    onTap: _showGoalSheet,
                  ),
                  _settingsRow(
                    'Default workout duration',
                    '$defaultMinutes min',
                    onTap: () => _showDefaultDurationSheet(defaultMinutes),
                  ),
                  _settingsRow(
                    'Streak mode',
                    _streakModeLabel(streakMode),
                    onTap: () => _showStreakModeSheet(streakMode),
                  ),
                  _settingsRow(
                    'Theme',
                    themeModeLabel(themeMode),
                    onTap: () => _showThemeModeSheet(themeMode),
                  ),
                  _settingsRow(
                    'Notifications',
                    notificationsEnabled ? 'On' : 'Off',
                    onTap: () => _toggleNotifications(notificationsEnabled),
                  ),
                  SizedBox(
                    height: context.dimensions.values.s28,
                    child: ColoredBox(color: _surface),
                  ),
                  _settingsRow(
                    'Update profile',
                    name?.isNotEmpty == true ? name! : 'Profile',
                    onTap: () => _showProfileSheet(data),
                  ),
                  _settingsRow(
                    'Account',
                    user.email ?? 'Signed in',
                    onTap: () => _showInfoPage(
                      title: 'Account',
                      body:
                          'You are signed in. Burn Camp can sync workouts, groups, friends, and settings for this account.',
                    ),
                  ),
                  _settingsRow(
                    'Reset personalization',
                    'Restart',
                    onTap: _resetPersonalization,
                  ),
                  _settingsRow('Recaps', 'View', onTap: _showRecapsSheet),
                  _settingsRow(
                    'Invite friends',
                    'Share',
                    onTap: _inviteFriends,
                  ),
                  _settingsRow(
                    'Hidden friends',
                    '$hiddenFriends',
                    onTap: () => _showHiddenFriendsSheet(data),
                  ),
                  _settingsRow(
                    'Manage groups',
                    '',
                    onTap: _showManageGroupsPage,
                  ),
                  SizedBox(
                    height: context.dimensions.values.s28,
                    child: ColoredBox(color: _surface),
                  ),
                  _settingsRow('Help and feedback', '', onTap: _showHelpPage),
                  _settingsRow(
                    'Support Burn Camp',
                    'Premium',
                    onTap: _showSupportPage,
                  ),
                  _settingsRow(
                    'Instagram',
                    '@burncamp',
                    onTap: () =>
                        _showSnack('Social links are placeholders for now.'),
                  ),
                  _settingsRow(
                    'TikTok',
                    '@burncamp',
                    onTap: () =>
                        _showSnack('Social links are placeholders for now.'),
                  ),
                  SizedBox(
                    height: context.dimensions.values.s28,
                    child: ColoredBox(color: _surface),
                  ),
                  _settingsRow(
                    'Privacy',
                    '',
                    onTap: () => _showInfoPage(
                      title: 'Privacy',
                      body:
                          'Burn Camp stores workout entries, goals, and settings in your account so your calorie history can sync across devices.',
                    ),
                  ),
                  _settingsRow(
                    'Terms',
                    '',
                    onTap: () => _showInfoPage(
                      title: 'Terms',
                      body:
                          'Burn Camp is for personal fitness tracking and friendly accountability. Manually entered workouts should reflect your best estimate.',
                    ),
                  ),
                  SizedBox(height: context.dimensions.values.s22),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.dimensions.values.s22,
                    ),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _cream,
                        side: BorderSide(color: _divider),
                        padding: EdgeInsets.symmetric(
                          vertical: context.dimensions.values.s13,
                        ),
                      ),
                      onPressed: _logout,
                      child: Text(
                        'Sign out of Google',
                        style: TextStyle(fontSize: context.textSizes.s16),
                      ),
                    ),
                  ),
                  SizedBox(height: context.dimensions.values.s22),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _topHeader({
    required String title,
    required Widget leading,
    required Widget trailing,
    Widget? bottom,
  }) {
    return DashboardTopHeader(
      title: title,
      leading: leading,
      trailing: trailing,
      foreground: _cream,
      bottom: bottom,
    );
  }

  Widget _periodTabs() {
    final tabs = [
      DashboardSegmentTab.text(value: MetricPeriod.today, label: 'Today'),
      DashboardSegmentTab.text(
        value: MetricPeriod.yesterday,
        label: 'Yesterday',
      ),
      DashboardSegmentTab.text(value: MetricPeriod.week, label: 'Week'),
      DashboardSegmentTab.text(value: MetricPeriod.month, label: 'Month'),
    ];

    return DashboardSegmentedTabs<MetricPeriod>(
      tabs: tabs,
      selectedValue: _period,
      onSelected: (period) => setState(() => _period = period),
      height: context.dimensions.values.s54,
      foreground: _cream,
      selectedBackground: _selectedSurface,
      tabMargin: EdgeInsets.zero,
      tabPadding: EdgeInsets.symmetric(
        horizontal: context.dimensions.values.s4,
        vertical: context.dimensions.values.s6,
      ),
    );
  }

  Widget _historyTabs() {
    final tabs = [
      DashboardSegmentTab.text(value: HistoryRange.day, label: 'Day'),
      DashboardSegmentTab.text(value: HistoryRange.week, label: 'Week'),
      DashboardSegmentTab.text(value: HistoryRange.month, label: 'Month'),
      DashboardSegmentTab(
        value: HistoryRange.calendar,
        child: FaIcon(
          FontAwesomeIcons.calendar,
          size: context.dimensions.values.s18,
        ),
      ),
    ];
    return DashboardSegmentedTabs<HistoryRange>(
      tabs: tabs,
      selectedValue: _historyRange,
      onSelected: (range) => setState(() => _historyRange = range),
      height: context.dimensions.values.s46,
      foreground: _cream,
      selectedBackground: _selectedSurface,
    );
  }

  Widget _historyContent(List<Map<String, dynamic>> summaries) {
    if (summaries.isEmpty &&
        _historyRange != HistoryRange.month &&
        _historyRange != HistoryRange.calendar) {
      return Center(
        child: Text(
          'No workouts logged yet.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: context.textSizes.s17),
        ),
      );
    }

    switch (_historyRange) {
      case HistoryRange.day:
        return _dayHistoryContent(summaries);
      case HistoryRange.week:
        return _weekHistoryContent(summaries);
      case HistoryRange.month:
        return _monthHistoryContent(summaries);
      case HistoryRange.calendar:
        return _calendarHistoryContent(summaries);
    }
  }

  Widget _dayHistoryContent(List<Map<String, dynamic>> summaries) {
    final summariesByMondayWeek = <DateTime, List<Map<String, dynamic>>>{};
    var earliestYear = DateTime.now().year;
    for (final summary in summaries) {
      final date = _dateFromSummary(summary);
      if (date == null) continue;
      earliestYear = math.min(earliestYear, date.year);
      final week = WorkoutService.startOfWeek(date);
      summariesByMondayWeek.putIfAbsent(week, () => []).add(summary);
    }

    final now = WorkoutService.startOfDay(DateTime.now());
    final months = _historyMonthsThroughCurrent(earliestYear);
    final scaleValue = _averagePositiveHistoryValue(
      summaries.map((summary) => _historyValueForSummaries([summary])),
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.dimensions.values.s22,
        context.dimensions.values.s18,
        context.dimensions.values.s22,
        context.dimensions.values.s22,
      ),
      children: _dayHistoryRows(months, summariesByMondayWeek, now, scaleValue),
    );
  }

  Widget _weekHistoryContent(List<Map<String, dynamic>> summaries) {
    final summariesByMondayWeek = <DateTime, List<Map<String, dynamic>>>{};
    var earliestYear = DateTime.now().year;
    for (final summary in summaries) {
      final date = _dateFromSummary(summary);
      if (date == null) continue;
      earliestYear = math.min(earliestYear, date.year);
      final week = WorkoutService.startOfWeek(date);
      summariesByMondayWeek.putIfAbsent(week, () => []).add(summary);
    }

    final now = WorkoutService.startOfDay(DateTime.now());
    final months = _historyMonthsThroughCurrent(earliestYear);
    final scaleValue = _averagePositiveHistoryValue(
      summariesByMondayWeek.values.map(_historyValueForSummaries),
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.dimensions.values.s22,
        context.dimensions.values.s18,
        context.dimensions.values.s22,
        context.dimensions.values.s22,
      ),
      children: _weekHistoryRows(
        months,
        summariesByMondayWeek,
        now,
        scaleValue,
      ),
    );
  }

  List<Widget> _dayHistoryRows(
    List<DateTime> months,
    Map<DateTime, List<Map<String, dynamic>>> summariesByMondayWeek,
    DateTime today,
    int scaleValue,
  ) {
    final rows = <Widget>[];

    for (final month in months) {
      final mondayWeeks = _mondayWeeksForMonth(month, today);
      final monthSummaries = mondayWeeks
          .expand(
            (week) =>
                summariesByMondayWeek[week] ?? const <Map<String, dynamic>>[],
          )
          .toList();

      rows
        ..add(
          _historySectionHeader(
            DateFormat.MMMM().format(month),
            _formatHistoryValue(
              _sumCalories(monthSummaries),
              _distinctDays(monthSummaries),
            ),
          ),
        )
        ..add(SizedBox(height: context.dimensions.values.s14));

      if (mondayWeeks.isEmpty) {
        rows
          ..add(
            Text(
              'No data',
              style: TextStyle(color: _muted, fontSize: context.textSizes.s18),
            ),
          )
          ..add(SizedBox(height: context.dimensions.values.s18));
        continue;
      }

      for (final week in mondayWeeks) {
        final weekSummaries =
            [...(summariesByMondayWeek[week] ?? const <Map<String, dynamic>>[])]
              ..sort((a, b) {
                final aDate = _dateFromSummary(a) ?? DateTime(1970);
                final bDate = _dateFromSummary(b) ?? DateTime(1970);
                return bDate.compareTo(aDate);
              });

        rows
          ..add(
            _historySectionHeader(
              'Week of ${DateFormat.Md().format(week)}',
              _formatHistoryValue(
                _sumCalories(weekSummaries),
                _distinctDays(weekSummaries),
              ),
            ),
          )
          ..add(SizedBox(height: context.dimensions.values.s12));

        if (weekSummaries.isEmpty) {
          rows
            ..add(
              Text(
                'No data',
                style: TextStyle(
                  color: _muted,
                  fontSize: context.textSizes.s18,
                ),
              ),
            )
            ..add(SizedBox(height: context.dimensions.values.s14));
        } else {
          rows
            ..addAll(
              weekSummaries.map((summary) => _historyBar(summary, scaleValue)),
            )
            ..add(SizedBox(height: context.dimensions.values.s14));
        }
      }

      rows.add(SizedBox(height: context.dimensions.values.s18));
    }

    return rows;
  }

  List<Widget> _weekHistoryRows(
    List<DateTime> months,
    Map<DateTime, List<Map<String, dynamic>>> summariesByMondayWeek,
    DateTime today,
    int scaleValue,
  ) {
    final rows = <Widget>[];

    for (final month in months) {
      final mondayWeeks = _mondayWeeksForMonth(month, today);
      final monthSummaries = mondayWeeks
          .expand(
            (week) =>
                summariesByMondayWeek[week] ?? const <Map<String, dynamic>>[],
          )
          .toList();

      rows
        ..add(
          _historySectionHeader(
            DateFormat.MMMM().format(month),
            _formatHistoryValue(
              _sumCalories(monthSummaries),
              _distinctDays(monthSummaries),
            ),
          ),
        )
        ..add(SizedBox(height: context.dimensions.values.s14));

      if (mondayWeeks.isEmpty) {
        rows
          ..add(
            Text(
              'No data',
              style: TextStyle(color: _muted, fontSize: context.textSizes.s18),
            ),
          )
          ..add(SizedBox(height: context.dimensions.values.s18));
        continue;
      }

      for (final week in mondayWeeks) {
        rows
          ..add(
            _weekBar(week, summariesByMondayWeek[week] ?? const [], scaleValue),
          )
          ..add(SizedBox(height: context.dimensions.values.s14));
      }

      rows.add(SizedBox(height: context.dimensions.values.s18));
    }

    return rows;
  }

  Widget _monthHistoryContent(List<Map<String, dynamic>> summaries) {
    final groups = <DateTime, List<Map<String, dynamic>>>{};
    var earliestYear = DateTime.now().year;
    for (final summary in summaries) {
      final date = _dateFromSummary(summary);
      if (date == null) continue;
      earliestYear = math.min(earliestYear, date.year);
      final month = DateTime(date.year, date.month);
      groups.putIfAbsent(month, () => []).add(summary);
    }

    final allMonths = _historyMonthsThroughCurrent(earliestYear);

    final scaleValue = _averagePositiveHistoryValue(
      groups.values.map(_historyValueForSummaries),
    );
    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.dimensions.values.s22,
        context.dimensions.values.s18,
        context.dimensions.values.s22,
        context.dimensions.values.s22,
      ),
      children: _monthHistoryRows(allMonths, groups, scaleValue),
    );
  }

  List<Widget> _monthHistoryRows(
    List<DateTime> allMonths,
    Map<DateTime, List<Map<String, dynamic>>> groups,
    int scaleValue,
  ) {
    final rows = <Widget>[];
    int? currentYear;

    for (final month in allMonths) {
      if (currentYear != month.year) {
        currentYear = month.year;
        final yearSummaries = allMonths
            .where((item) => item.year == month.year)
            .expand((item) => groups[item] ?? const <Map<String, dynamic>>[])
            .toList();
        rows
          ..add(
            _historySectionHeader(
              '${month.year}',
              _formatHistoryValue(
                _sumCalories(yearSummaries),
                _distinctDays(yearSummaries),
              ),
            ),
          )
          ..add(SizedBox(height: context.dimensions.values.s14));
      }

      rows.add(
        _monthBar(
          DateFormat.MMM().format(month),
          groups[month] ?? const [],
          scaleValue,
        ),
      );
    }

    return rows;
  }

  Widget _calendarHistoryContent(List<Map<String, dynamic>> summaries) {
    final byDate = <DateTime, Map<String, dynamic>>{};
    for (final summary in summaries) {
      final date = _dateFromSummary(summary);
      if (date == null) continue;
      byDate[date] = summary;
    }

    final now = DateTime.now();
    final months = [
      DateTime(now.year, now.month),
      DateTime(now.year, now.month - 1),
      DateTime(now.year, now.month - 2),
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.dimensions.values.s22,
        context.dimensions.values.s18,
        context.dimensions.values.s22,
        context.dimensions.values.s22,
      ),
      children: [
        for (final month in months) ...[
          _calendarMonth(month, byDate),
          SizedBox(height: context.dimensions.values.s30),
        ],
      ],
    );
  }

  Widget _historySectionHeader(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: _cream, fontSize: context.textSizes.s23),
        ),
        Text(
          value,
          style: TextStyle(color: _muted, fontSize: context.textSizes.s18),
        ),
      ],
    );
  }

  Widget _weekBar(
    DateTime week,
    List<Map<String, dynamic>> summaries,
    int scaleValue,
  ) {
    final calories = _sumCalories(summaries);
    final minutes = _sumMinutes(summaries);
    final value = _historyValueForSummaries(summaries);
    final widthFactor = value == 0
        ? 0.0
        : math.min(1.0, value / math.max(1, scaleValue));

    return _periodBar(
      label: DateFormat.Md().format(week),
      valueText: calories == 0
          ? 'No data'
          : _formatHistoryValue(
              calories,
              _distinctDays(summaries),
              compact: false,
            ),
      subtitle: '$minutes min trained',
      widthFactor: widthFactor,
      hasData: calories > 0,
    );
  }

  Widget _monthBar(
    String label,
    List<Map<String, dynamic>> summaries,
    int scaleValue,
  ) {
    final calories = _sumCalories(summaries);
    final minutes = _sumMinutes(summaries);
    final value = _historyValueForSummaries(summaries);
    final widthFactor = value == 0
        ? 0.0
        : math.min(1.0, value / math.max(1, scaleValue));

    return _periodBar(
      label: label,
      valueText: calories == 0
          ? 'No data'
          : _formatHistoryValue(
              calories,
              _distinctDays(summaries),
              compact: false,
            ),
      subtitle: '$minutes min trained',
      widthFactor: widthFactor,
      hasData: calories > 0,
    );
  }

  Widget _periodBar({
    required String label,
    required String valueText,
    required String subtitle,
    required double widthFactor,
    required bool hasData,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.dimensions.values.s20),
      child: Row(
        children: [
          SizedBox(
            width: context.dimensions.values.s76,
            child: Text(
              label,
              style: TextStyle(color: _muted, fontSize: context.textSizes.s18),
            ),
          ),
          Expanded(
            child: !hasData
                ? Text(
                    valueText,
                    style: TextStyle(
                      color: _muted,
                      fontSize: context.textSizes.s18,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _historyValueBar(
                        valueText: valueText,
                        widthFactor: widthFactor,
                        fontSize: context.textSizes.s18,
                      ),
                      SizedBox(height: context.dimensions.values.s4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: _muted,
                          fontSize: context.textSizes.s13,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _historyValueBar({
    required String valueText,
    required double widthFactor,
    required double fontSize,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final measuredTextWidth = _measureTextWidth(
          valueText,
          TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
        );
        final minimumWidth = measuredTextWidth + 24;
        final calculatedWidth = availableWidth * widthFactor;
        final barWidth = math.min(
          availableWidth,
          math.max(minimumWidth, calculatedWidth),
        );

        return Container(
          width: barWidth,
          height: context.dimensions.values.s42,
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.symmetric(
            horizontal: context.dimensions.values.s12,
          ),
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(context.dimensions.values.s8),
          ),
          child: Text(
            valueText,
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: TextStyle(
              color: _background,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }

  Widget _calendarMonth(
    DateTime month,
    Map<DateTime, Map<String, dynamic>> byDate,
  ) {
    final firstDay = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday - DateTime.monday;
    final totalCells = leadingBlanks + daysInMonth;
    final trailingBlanks = (7 - totalCells % 7) % 7;

    final monthSummaries = byDate.entries
        .where(
          (entry) =>
              entry.key.year == month.year && entry.key.month == month.month,
        )
        .map((entry) => entry.value)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _historySectionHeader(
          DateFormat.yMMMM().format(month),
          _formatHistoryValue(
            _sumCalories(monthSummaries),
            _distinctDays(monthSummaries),
            compact: true,
          ),
        ),
        SizedBox(height: context.dimensions.values.s14),
        const Row(
          children: [
            _WeekdayLabel('M'),
            _WeekdayLabel('T'),
            _WeekdayLabel('W'),
            _WeekdayLabel('T'),
            _WeekdayLabel('F'),
            _WeekdayLabel('S'),
            _WeekdayLabel('S'),
          ],
        ),
        SizedBox(height: context.dimensions.values.s8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.95,
          children: [
            for (var i = 0; i < leadingBlanks; i++) SizedBox.shrink(),
            for (var day = 1; day <= daysInMonth; day++)
              _calendarDay(DateTime(month.year, month.month, day), byDate),
            for (var i = 0; i < trailingBlanks; i++) SizedBox.shrink(),
          ],
        ),
      ],
    );
  }

  Widget _calendarDay(
    DateTime date,
    Map<DateTime, Map<String, dynamic>> byDate,
  ) {
    final summary = byDate[date];
    final calories = WorkoutService.caloriesFromSummary(summary);
    final isToday = date == WorkoutService.startOfDay(DateTime.now());

    return Container(
      margin: EdgeInsets.all(context.dimensions.values.s3),
      decoration: BoxDecoration(
        color: isToday ? _selectedSurface : Colors.transparent,
        borderRadius: BorderRadius.circular(context.dimensions.values.s8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            calories > 0 ? NumberFormat.compact().format(calories) : '',
            style: TextStyle(
              color: calories > 0 ? _accent : _muted,
              fontSize: context.textSizes.s15,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${date.day}',
            style: TextStyle(color: _muted, fontSize: context.textSizes.s13),
          ),
        ],
      ),
    );
  }

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
                  backgroundColor: _showFriends ? _accent : Colors.transparent,
                  foregroundColor: _showFriends ? _cream : _accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      context.dimensions.values.s10,
                    ),
                  ),
                ),
                onPressed: () => setState(() => _showFriends = true),
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
                  backgroundColor: !_showFriends ? _accent : Colors.transparent,
                  foregroundColor: !_showFriends ? _cream : _accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      context.dimensions.values.s10,
                    ),
                  ),
                ),
                onPressed: () => setState(() => _showFriends = false),
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
              child: Text('Remove', style: TextStyle(color: _accent)),
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
      background: _accent,
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
                  subtitle: 'Free plan: up to $_freeGroupLimit created groups',
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

  Widget _historyBar(Map<String, dynamic> summary, int scaleValue) {
    final calories = WorkoutService.caloriesFromSummary(summary);
    final minutes = WorkoutService.minutesFromSummary(summary);
    final value = _historyValueForSummaries([summary]);
    final widthFactor = value == 0
        ? 0.0
        : math.min(1.0, value / math.max(1, scaleValue));
    final label = _friendlyDate(summary);
    final valueText = _formatHistoryValue(
      calories,
      1,
      compact: false,
      includeUnit: false,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: context.dimensions.values.s18),
      child: Row(
        children: [
          SizedBox(
            width: context.dimensions.values.s76,
            child: Text(
              label,
              style: TextStyle(color: _muted, fontSize: context.textSizes.s16),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _historyValueBar(
                  valueText: valueText,
                  widthFactor: widthFactor,
                  fontSize: context.textSizes.s19,
                ),
                SizedBox(height: context.dimensions.values.s5),
                Text('$minutes min trained', style: TextStyle(color: _muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(
    String label,
    String value, {
    Color? valueColor,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    final resolvedValueColor = valueColor ?? _cream;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.dimensions.values.s4),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(color: _cream, fontSize: context.textSizes.s20),
            ),
            const Spacer(),
            if (icon != null) ...[
              Icon(
                icon,
                color: resolvedValueColor,
                size: context.dimensions.values.s20,
              ),
              SizedBox(width: context.dimensions.values.s10),
            ],
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: resolvedValueColor,
                  fontSize: context.textSizes.s20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsRow(String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: context.dimensions.values.s58,
        padding: EdgeInsets.symmetric(
          horizontal: context.dimensions.values.s22,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _surface)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: _cream,
                  fontSize: context.textSizes.s20,
                ),
              ),
            ),
            if (value.isNotEmpty)
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _muted,
                    fontSize: context.textSizes.s20,
                  ),
                ),
              ),
            SizedBox(width: context.dimensions.values.s8),
            Icon(
              Icons.chevron_right,
              color: _muted,
              size: context.dimensions.values.s26,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddWorkoutSheet() async {
    final user = _user;
    var defaultMinutes = 30;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      defaultMinutes =
          (doc.data()?['defaultWorkoutMinutes'] as num?)?.toInt() ?? 30;
    }

    if (!mounted) return;

    final caloriesController = TextEditingController();
    final minutesController = TextEditingController(
      text: defaultMinutes.toString(),
    );
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool saving = false;

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
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> save() async {
              final calories =
                  int.tryParse(caloriesController.text.trim()) ?? 0;
              final minutes = int.tryParse(minutesController.text.trim()) ?? 0;

              if (calories <= 0 || minutes <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter calories and minutes greater than 0.'),
                  ),
                );
                return;
              }

              setSheetState(() => saving = true);
              await WorkoutService.logWorkout(
                caloriesBurned: calories,
                minutesTrained: minutes,
                date: selectedDate,
                notes: notesController.text.trim().isEmpty
                    ? null
                    : notesController.text.trim(),
              );

              if (!context.mounted) return;
              Navigator.of(context).pop();
            }

            return Padding(
              padding: EdgeInsets.only(
                left: context.dimensions.values.s24,
                right: context.dimensions.values.s24,
                top: context.dimensions.values.s18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Add workout',
                          style: TextStyle(
                            color: _cream,
                            fontSize: context.textSizes.s22,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: saving ? null : save,
                        child: Text(
                          'Save',
                          style: TextStyle(
                            color: _accent,
                            fontSize: context.textSizes.s18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.dimensions.values.s14),
                  _darkNumberField(
                    controller: caloriesController,
                    label: 'Calories burned',
                    suffix: 'cals',
                  ),
                  SizedBox(height: context.dimensions.values.s12),
                  _darkNumberField(
                    controller: minutesController,
                    label: 'Minutes trained',
                    suffix: 'min',
                  ),
                  SizedBox(height: context.dimensions.values.s12),
                  TextField(
                    controller: notesController,
                    style: TextStyle(color: _cream),
                    decoration: _inputDecoration('Notes optional'),
                  ),
                  SizedBox(height: context.dimensions.values.s12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _cream,
                      side: BorderSide(color: _surface),
                      padding: EdgeInsets.symmetric(
                        vertical: context.dimensions.values.s12,
                      ),
                    ),
                    onPressed: saving
                        ? null
                        : () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(
                                const Duration(days: 1),
                              ),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setSheetState(() => selectedDate = picked);
                            }
                          },
                    icon: Icon(Icons.calendar_today),
                    label: Text(DateFormat.yMMMd().format(selectedDate)),
                  ),
                  SizedBox(height: context.dimensions.values.s16),
                  SizedBox(
                    height: context.dimensions.values.s50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: _onAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            context.dimensions.values.s14,
                          ),
                        ),
                      ),
                      onPressed: saving ? null : save,
                      child: saving
                          ? CircularProgressIndicator(color: _cream)
                          : Text(
                              'Save workout',
                              style: TextStyle(fontSize: context.textSizes.s17),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showGoalSheet() async {
    final user = _user;
    final data = user == null
        ? await _localSettingsData()
        : (await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get())
                  .data() ??
              {};
    var goal = _goalCalories(data);

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.dimensions.values.s22),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> save() async {
              await _updateUserSettings({'goalCalories': goal});

              if (!context.mounted) return;
              Navigator.of(context).pop();
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                context.dimensions.values.s24,
                context.dimensions.values.s18,
                context.dimensions.values.s24,
                context.dimensions.values.s34,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Daily Calorie Goal',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _cream,
                            fontSize: context.textSizes.s21,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: save,
                        child: Text(
                          'Done',
                          style: TextStyle(
                            color: _accent,
                            fontSize: context.textSizes.s18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.dimensions.values.s20),
                  Text(
                    NumberFormat.decimalPattern().format(goal),
                    style: TextStyle(
                      color: _goalLime,
                      fontSize: context.textSizes.s52,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  SizedBox(height: context.dimensions.values.s18),
                  Container(
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(
                        context.dimensions.values.s28,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.remove,
                            color: _cream,
                            size: context.dimensions.values.s26,
                          ),
                          onPressed: () {
                            setSheetState(() => goal = math.max(50, goal - 50));
                          },
                        ),
                        Container(
                          width: context.dimensions.values.s1,
                          height: context.dimensions.values.s28,
                          color: _muted,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.add,
                            color: _cream,
                            size: context.dimensions.values.s26,
                          ),
                          onPressed: () => setSheetState(() => goal += 50),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.dimensions.values.s20),
                  Text(
                    'Set the calorie target you want to hit each training day. Streaks count days where this goal is met.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _cream,
                      fontSize: context.textSizes.s16,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDefaultDurationSheet(int currentMinutes) async {
    final controller = TextEditingController(text: currentMinutes.toString());

    await _showSettingsSheet(
      title: 'Default Workout Duration',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _darkNumberField(
            controller: controller,
            label: 'Minutes',
            suffix: 'min',
          ),
          SizedBox(height: context.dimensions.values.s16),
          _primarySheetButton(
            label: 'Save duration',
            onPressed: () async {
              final minutes = int.tryParse(controller.text.trim()) ?? 0;
              if (minutes <= 0) {
                _showSnack('Enter a duration greater than 0 minutes.');
                return;
              }
              await _updateUserSettings({'defaultWorkoutMinutes': minutes});
              if (!mounted) return;
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showStreakModeSheet(String currentMode) {
    return _showChoiceSheet(
      title: 'Streak Mode',
      currentValue: currentMode,
      options: const {
        'strict': 'Strict — every day must hit the calorie goal',
        'flexible': 'Flexible — rest days do not break momentum',
        'trainingDays': 'Training days — only logged workout days count',
      },
      onSelected: (value) async {
        await _updateUserSettings({'streakMode': value});
      },
    );
  }

  Future<void> _showThemeModeSheet(String currentMode) {
    return _showChoiceSheet(
      title: 'Theme',
      currentValue: currentMode,
      options: const {'dark': 'Dark', 'light': 'Light', 'system': 'System'},
      onSelected: (value) async {
        appThemeModeNotifier.value = themeModeFromString(value);
        await _updateUserSettings({'themeMode': value});
      },
    );
  }

  Future<void> _toggleNotifications(bool currentlyEnabled) async {
    final enabled = !currentlyEnabled;
    await _updateUserSettings({'notificationsEnabled': enabled});
    _showSnack(
      enabled ? 'Notifications turned on.' : 'Notifications turned off.',
    );
  }

  Future<void> _showProfileSheet(Map<String, dynamic> data) async {
    final user = _user;
    if (user == null) return;

    final nameController = TextEditingController(
      text: (data['name'] as String?) ?? user.displayName ?? '',
    );
    final usernameController = TextEditingController(
      text: (data['username'] as String?) ?? '',
    );
    var photoUrl = (data['photoUrl'] as String?) ?? user.photoURL ?? '';
    File? selectedPhoto;
    var saving = false;

    await _showSettingsSheet(
      title: 'Update Profile',
      child: StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> pickPhoto(ImageSource source) async {
            try {
              final picked = await ImagePicker().pickImage(
                source: source,
                imageQuality: 88,
                maxWidth: 900,
              );
              if (picked == null) return;
              setSheetState(() {
                selectedPhoto = File(picked.path);
              });
            } catch (e) {
              _showSnack('Could not choose profile photo: $e');
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: context.dimensions.values.s46,
                      backgroundColor: _accent,
                      backgroundImage: selectedPhoto != null
                          ? FileImage(selectedPhoto!)
                          : photoUrl.trim().isNotEmpty
                          ? NetworkImage(photoUrl.trim())
                          : null,
                      child: selectedPhoto == null && photoUrl.trim().isEmpty
                          ? Icon(
                              Icons.person,
                              color: _background,
                              size: context.dimensions.values.s46,
                            )
                          : null,
                    ),
                    Positioned(
                      right: -6,
                      bottom: -6,
                      child: IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: _onAccent,
                        ),
                        onPressed: () => _showProfilePhotoSourceSheet(
                          onCamera: () => pickPhoto(ImageSource.camera),
                          onGallery: () => pickPhoto(ImageSource.gallery),
                          onRemove:
                              photoUrl.trim().isEmpty && selectedPhoto == null
                              ? null
                              : () {
                                  setSheetState(() {
                                    selectedPhoto = null;
                                    photoUrl = '';
                                  });
                                },
                        ),
                        icon: Icon(Icons.camera_alt_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.dimensions.values.s22),
              TextField(
                controller: nameController,
                style: TextStyle(color: _cream),
                decoration: _inputDecoration('Display name'),
              ),
              SizedBox(height: context.dimensions.values.s12),
              TextField(
                controller: usernameController,
                style: TextStyle(color: _cream),
                decoration: _inputDecoration('Username'),
              ),
              SizedBox(height: context.dimensions.values.s16),
              _primarySheetButton(
                label: saving ? 'Saving…' : 'Save profile',
                onPressed: saving
                    ? () {}
                    : () async {
                        final name = nameController.text.trim();
                        final username = usernameController.text.trim();
                        if (name.isEmpty || username.isEmpty) {
                          _showSnack('Name and username are required.');
                          return;
                        }

                        setSheetState(() => saving = true);
                        try {
                          var nextPhotoUrl = photoUrl;
                          if (selectedPhoto != null) {
                            nextPhotoUrl = await _uploadProfilePhoto(
                              selectedPhoto!,
                            );
                          }

                          await user.updateDisplayName(name);
                          await user.updatePhotoURL(
                            nextPhotoUrl.trim().isEmpty ? null : nextPhotoUrl,
                          );
                          await _updateUserSettings({
                            'name': name,
                            'username': username,
                            'photoUrl': nextPhotoUrl,
                          });

                          if (!mounted) return;
                          Navigator.of(context).pop();
                          _showSnack('Profile updated.');
                        } catch (e) {
                          _showSnack('Profile update failed: $e');
                        } finally {
                          if (mounted) {
                            setSheetState(() => saving = false);
                          }
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showProfilePhotoSourceSheet({
    required VoidCallback onCamera,
    required VoidCallback onGallery,
    VoidCallback? onRemove,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: _background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.dimensions.values.s22),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.dimensions.values.s24,
              context.dimensions.values.s18,
              context.dimensions.values.s24,
              context.dimensions.values.s24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.camera_alt_outlined, color: _accent),
                  title: Text('Take photo', style: TextStyle(color: _cream)),
                  onTap: () {
                    Navigator.of(context).pop();
                    onCamera();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.photo_library_outlined, color: _accent),
                  title: Text(
                    'Choose from camera roll',
                    style: TextStyle(color: _cream),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    onGallery();
                  },
                ),
                if (onRemove != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline, color: _muted),
                    title: Text(
                      'Remove current photo',
                      style: TextStyle(color: _cream),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      onRemove();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> _uploadProfilePhoto(File imageFile) async {
    final user = _user;
    if (user == null) {
      throw StateError('Sign in to upload a profile photo.');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_photos')
        .child(user.uid)
        .child('profile-$timestamp.jpg');
    final task = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return task.ref.getDownloadURL();
  }

  Future<void> _showRecapsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.dimensions.values.s22),
        ),
      ),
      builder: (context) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: WorkoutService.watchSummaries(limit: 180),
          builder: (context, snapshot) {
            final summaries = snapshot.data ?? [];
            final today = _aggregateForPeriod(summaries, MetricPeriod.today);
            final week = _aggregateForPeriod(summaries, MetricPeriod.week);
            final month = _aggregateForPeriod(summaries, MetricPeriod.month);
            final lifetimeCalories = summaries.fold<int>(
              0,
              (total, summary) =>
                  total + WorkoutService.caloriesFromSummary(summary),
            );
            final lifetimeMinutes = summaries.fold<int>(
              0,
              (total, summary) =>
                  total + WorkoutService.minutesFromSummary(summary),
            );

            return Padding(
              padding: EdgeInsets.fromLTRB(
                context.dimensions.values.s24,
                context.dimensions.values.s18,
                context.dimensions.values.s24,
                context.dimensions.values.s28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Recaps',
                    style: TextStyle(
                      color: _cream,
                      fontSize: context.textSizes.s22,
                    ),
                  ),
                  SizedBox(height: context.dimensions.values.s16),
                  _recapRow('Today', today.calories, today.minutes),
                  _recapRow('This week', week.calories, week.minutes),
                  _recapRow('This month', month.calories, month.minutes),
                  _recapRow('All time', lifetimeCalories, lifetimeMinutes),
                  SizedBox(height: context.dimensions.values.s16),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _cream,
                      side: BorderSide(color: _divider),
                    ),
                    onPressed: () {
                      _shareText(
                        context,
                        'Burn Camp recap: ${NumberFormat.decimalPattern().format(month.calories)} calories and ${month.minutes} minutes trained this month.',
                      );
                    },
                    icon: Icon(Icons.ios_share),
                    label: Text('Share monthly recap'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _inviteFriends() async {
    await _shareText(
      context,
      'Join me on Burn Camp — track calories burned, training minutes, and compare workouts with friends.',
    );
  }

  Future<void> _showGroupDetailsDialog(
    QueryDocumentSnapshot<Map<String, dynamic>> groupDoc,
  ) async {
    final data = groupDoc.data();
    final name = (data['name'] as String?) ?? 'Workout group';
    final memberIds = List<String>.from(data['memberIds'] ?? const []);
    final ownerId =
        (data['ownerId'] as String?) ?? data['createdBy'] as String?;
    final pendingInvites =
        (data['pendingInviteIds'] as List<dynamic>? ?? const []).length;
    final currentUserId = _user?.uid;
    final detailsFuture = _groupDetailsData(memberIds);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.dimensions.values.s22),
            side: BorderSide(color: _divider),
          ),
          title: Text(name, style: TextStyle(color: _cream)),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder<_GroupDetailsData>(
              future: detailsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return SizedBox(
                    height: context.dimensions.values.s180,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final details = snapshot.data!;
                final members = details.members;
                final dialogFriendIds = {...details.friendIds};
                final calories = members.fold<int>(
                  0,
                  (total, member) => total + member.calories,
                );
                final minutes = members.fold<int>(
                  0,
                  (total, member) => total + member.minutes,
                );
                final goalsMet = members
                    .where((member) => member.goalMet)
                    .length;

                return StatefulBuilder(
                  builder: (context, setDialogState) {
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              _groupStatPill(
                                'Calories',
                                NumberFormat.compact().format(calories),
                              ),
                              SizedBox(width: context.dimensions.values.s10),
                              _groupStatPill('Minutes', '$minutes'),
                              SizedBox(width: context.dimensions.values.s10),
                              _groupStatPill(
                                'Goals',
                                '$goalsMet/${members.length}',
                              ),
                            ],
                          ),
                          if (pendingInvites > 0) ...[
                            SizedBox(height: context.dimensions.values.s12),
                            Text(
                              '$pendingInvites pending invite${pendingInvites == 1 ? '' : 's'}',
                              style: TextStyle(
                                color: _muted,
                                fontSize: context.textSizes.s13,
                              ),
                            ),
                          ],
                          SizedBox(height: context.dimensions.values.s16),
                          Divider(color: _divider),
                          SizedBox(height: context.dimensions.values.s6),
                          if (members.isEmpty)
                            Text(
                              'No members found yet.',
                              style: TextStyle(
                                color: _muted,
                                fontSize: context.textSizes.s16,
                              ),
                            )
                          else
                            ...members.indexed.map((entry) {
                              final index = entry.$1;
                              final member = entry.$2;
                              final isOwner = member.userId == ownerId;
                              final isCurrentUser =
                                  member.userId == currentUserId;
                              final isFriend =
                                  isCurrentUser ||
                                  dialogFriendIds.contains(member.userId);
                              return _groupMemberRow(
                                index + 1,
                                member,
                                isOwner,
                                isFriend: isFriend,
                                isCurrentUser: isCurrentUser,
                                onAddFriend: isFriend
                                    ? null
                                    : () async {
                                        final sent =
                                            await _sendFriendRequestToUser(
                                              friendId: member.userId,
                                              fallbackUsername:
                                                  member.username.isNotEmpty
                                                  ? member.username
                                                  : member.name,
                                            );
                                        if (sent) {
                                          setDialogState(() {
                                            dialogFriendIds.add(member.userId);
                                          });
                                        }
                                        return sent;
                                      },
                              );
                            }),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Close', style: TextStyle(color: _accent)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _showInviteToGroupSheet(groupDoc);
              },
              child: Text('Invite', style: TextStyle(color: _accent)),
            ),
          ],
        );
      },
    );
  }

  Widget _groupStatPill(String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.dimensions.values.s10,
          vertical: context.dimensions.values.s12,
        ),
        decoration: BoxDecoration(
          color: _selectedSurface,
          borderRadius: BorderRadius.circular(context.dimensions.values.s14),
        ),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _cream,
                fontWeight: FontWeight.w700,
                fontSize: context.textSizes.s17,
              ),
            ),
            SizedBox(height: context.dimensions.values.s3),
            Text(
              label,
              style: TextStyle(color: _muted, fontSize: context.textSizes.s12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupMemberRow(
    int rank,
    _GroupMemberPerformance member,
    bool isOwner, {
    required bool isFriend,
    required bool isCurrentUser,
    Future<bool> Function()? onAddFriend,
  }) {
    final progress = member.goalCalories <= 0
        ? 0.0
        : math.min(1.0, member.calories / member.goalCalories);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.dimensions.values.s10),
      child: Row(
        children: [
          SizedBox(
            width: context.dimensions.values.s30,
            child: Text(
              '$rank',
              style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
            ),
          ),
          CircleAvatar(
            radius: context.dimensions.values.s19,
            backgroundColor: member.goalMet ? _accent : _selectedSurface,
            child: Icon(
              member.goalMet ? Icons.local_fire_department : Icons.person,
              color: _background,
              size: context.dimensions.values.s20,
            ),
          ),
          SizedBox(width: context.dimensions.values.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _cream,
                          fontWeight: FontWeight.w700,
                          fontSize: context.textSizes.s16,
                        ),
                      ),
                    ),
                    if (isOwner) ...[
                      SizedBox(width: context.dimensions.values.s6),
                      Icon(
                        Icons.star,
                        color: _goalLime,
                        size: context.dimensions.values.s15,
                      ),
                    ],
                  ],
                ),
                SizedBox(height: context.dimensions.values.s6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    context.dimensions.values.s20,
                  ),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: _divider,
                    color: member.goalMet ? _accent : _goalLime,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: context.dimensions.values.s12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormat.compact().format(member.calories),
                style: TextStyle(
                  color: _cream,
                  fontSize: context.textSizes.s16,
                ),
              ),
              Text(
                '${member.minutes} min',
                style: TextStyle(
                  color: _muted,
                  fontSize: context.textSizes.s12,
                ),
              ),
            ],
          ),
          SizedBox(width: context.dimensions.values.s8),
          SizedBox(
            width: context.dimensions.values.s34,
            child: isFriend
                ? Icon(
                    isCurrentUser ? Icons.person : Icons.check_circle,
                    color: isCurrentUser ? _muted : _goalLime,
                    size: context.dimensions.values.s22,
                  )
                : IconButton(
                    tooltip: 'Add friend',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 34,
                      minHeight: 34,
                    ),
                    onPressed: onAddFriend == null
                        ? null
                        : () async {
                            final sent = await onAddFriend();
                            if (sent && mounted) setState(() {});
                          },
                    icon: Icon(
                      Icons.add_circle,
                      color: _accent,
                      size: context.dimensions.values.s24,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showInviteToGroupSheet(
    QueryDocumentSnapshot<Map<String, dynamic>> groupDoc,
  ) async {
    final user = _user;
    if (user == null) {
      _showSnack('Sign in to invite people.');
      return;
    }

    final groupData = groupDoc.data();
    final groupName = (groupData['name'] as String?) ?? 'Workout group';
    final usernameController = TextEditingController();
    bool sending = false;

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
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> sendInvite() async {
              final username = usernameController.text.trim().replaceFirst(
                '@',
                '',
              );
              if (username.isEmpty) {
                _showSnack('Enter a username to invite.');
                return;
              }

              setSheetState(() => sending = true);
              try {
                final invitedUserDoc = await _findUserByUsername(username);
                if (invitedUserDoc == null) {
                  _showSnack('Could not find @$username.');
                  return;
                }

                final invitedUserId = invitedUserDoc.id;
                final invitedUsername =
                    (invitedUserDoc.data()['username'] as String?) ?? username;

                if (invitedUserId == user.uid) {
                  _showSnack('You are already in this group.');
                  return;
                }

                final groupRef = FirebaseFirestore.instance
                    .collection('groups')
                    .doc(groupDoc.id);
                final invitationRef = groupRef
                    .collection('invitations')
                    .doc(invitedUserId);
                final inviteRef = FirebaseFirestore.instance
                    .collection('group_invites')
                    .doc();
                var didSend = false;
                var message = 'Invite already pending for @$invitedUsername.';

                await FirebaseFirestore.instance.runTransaction((
                  transaction,
                ) async {
                  final latestGroupDoc = await transaction.get(groupRef);
                  if (!latestGroupDoc.exists) {
                    throw StateError('Group no longer exists.');
                  }

                  final latestGroup = latestGroupDoc.data()!;
                  final memberIds = List<String>.from(
                    latestGroup['memberIds'] ?? const [],
                  );
                  final pendingInviteIds = List<String>.from(
                    latestGroup['pendingInviteIds'] ?? const [],
                  );

                  if (memberIds.contains(invitedUserId)) {
                    message = '@$invitedUsername is already in this group.';
                    return;
                  }

                  if (pendingInviteIds.contains(invitedUserId)) {
                    return;
                  }

                  final existingInviteDoc = await transaction.get(
                    invitationRef,
                  );
                  if (existingInviteDoc.exists &&
                      existingInviteDoc.data()?['status'] == 'pending') {
                    return;
                  }

                  final invitePayload = {
                    'fromUserId': user.uid,
                    'fromUserName': user.displayName ?? user.email ?? 'Burner',
                    'toUserId': invitedUserId,
                    'toUserName': invitedUsername,
                    'groupId': groupDoc.id,
                    'groupName': groupName,
                    'status': 'pending',
                    'createdAt': FieldValue.serverTimestamp(),
                  };

                  transaction.update(groupRef, {
                    'pendingInviteIds': FieldValue.arrayUnion([invitedUserId]),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  transaction.set(inviteRef, invitePayload);
                  transaction.set(invitationRef, {
                    ...invitePayload,
                    'inviteId': inviteRef.id,
                  });

                  didSend = true;
                  message = 'Invited @$invitedUsername to $groupName.';
                });

                if (!context.mounted) return;
                if (didSend) Navigator.of(context).pop();
                _showSnack(message);
              } catch (e) {
                _showSnack('Could not send invite: $e');
              } finally {
                if (context.mounted) setSheetState(() => sending = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: context.dimensions.values.s24,
                right: context.dimensions.values.s24,
                top: context.dimensions.values.s18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Invite to $groupName',
                      style: TextStyle(
                        color: _cream,
                        fontSize: context.textSizes.s22,
                      ),
                    ),
                    SizedBox(height: context.dimensions.values.s8),
                    Text(
                      'Enter a Burn Camp username. Existing members and pending invites will be skipped.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: context.textSizes.s14,
                      ),
                    ),
                    SizedBox(height: context.dimensions.values.s16),
                    TextField(
                      controller: usernameController,
                      style: TextStyle(color: _cream),
                      autofocus: true,
                      decoration: _inputDecoration('Username'),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        if (!sending) sendInvite();
                      },
                    ),
                    SizedBox(height: context.dimensions.values.s18),
                    SizedBox(
                      height: context.dimensions.values.s50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: _onAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              context.dimensions.values.s14,
                            ),
                          ),
                        ),
                        onPressed: sending ? null : sendInvite,
                        child: sending
                            ? CircularProgressIndicator(color: _cream)
                            : Text(
                                'Send invite',
                                style: TextStyle(
                                  fontSize: context.textSizes.s17,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    usernameController.dispose();
  }

  Future<void> _showCreateGroupSheet() async {
    final user = _user;
    if (user == null) {
      _showSnack('Sign in to create a group.');
      return;
    }

    final existingGroupCount = await _currentUserCreatedGroupCount();
    if (!mounted) return;
    if (existingGroupCount >= _freeGroupLimit) {
      _showSnack('Free accounts can create up to $_freeGroupLimit groups.');
      _showSupportPage();
      return;
    }

    final groupNameController = TextEditingController();
    final usernameController = TextEditingController();
    final friendsFuture = _loadFriendOptions(user.uid);
    final selectedFriendIds = <String>{};
    final manualUsernames = <String>{};
    bool saving = false;

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
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> createGroup() async {
              final groupName = groupNameController.text.trim();
              if (groupName.isEmpty) {
                _showSnack('Name your group first.');
                return;
              }

              setSheetState(() => saving = true);
              try {
                final currentGroupCount = await _currentUserCreatedGroupCount();
                if (currentGroupCount >= _freeGroupLimit) {
                  _showSnack(
                    'Free accounts can create up to $_freeGroupLimit groups.',
                  );
                  return;
                }

                final friends = await friendsFuture;
                final friendNamesById = {
                  for (final friend in friends) friend.userId: friend.name,
                };
                final resolution = await _resolveInviteIds(
                  ownerId: user.uid,
                  manualUsernames: manualUsernames,
                  selectedFriendIds: selectedFriendIds,
                );

                if (resolution.missingUsernames.isNotEmpty) {
                  _showSnack(
                    'Could not find: ${resolution.missingUsernames.join(', ')}',
                  );
                  return;
                }

                final groupRef = FirebaseFirestore.instance
                    .collection('groups')
                    .doc();
                final inviteIds = resolution.userIds.toList()..sort();

                final batch = FirebaseFirestore.instance.batch();
                batch.set(groupRef, {
                  'name': groupName,
                  'ownerId': user.uid,
                  'createdBy': user.uid,
                  'memberIds': [user.uid],
                  'pendingInviteIds': inviteIds,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                batch.set(
                  FirebaseFirestore.instance.collection('users').doc(user.uid),
                  {
                    'groups': FieldValue.arrayUnion([groupRef.id]),
                    'updatedAt': FieldValue.serverTimestamp(),
                  },
                  SetOptions(merge: true),
                );

                for (final inviteId in inviteIds) {
                  final inviteRef = FirebaseFirestore.instance
                      .collection('group_invites')
                      .doc();
                  final inviteName =
                      friendNamesById[inviteId] ??
                      resolution.usernamesById[inviteId] ??
                      'Friend';
                  final invitePayload = {
                    'fromUserId': user.uid,
                    'fromUserName': user.displayName ?? user.email ?? 'Burner',
                    'toUserId': inviteId,
                    'toUserName': inviteName,
                    'groupId': groupRef.id,
                    'groupName': groupName,
                    'status': 'pending',
                    'createdAt': FieldValue.serverTimestamp(),
                  };

                  batch.set(inviteRef, invitePayload);
                  batch.set(groupRef.collection('invitations').doc(inviteId), {
                    ...invitePayload,
                    'inviteId': inviteRef.id,
                  });
                }

                await batch.commit();

                if (!context.mounted) return;
                Navigator.of(context).pop();
                _showSnack(
                  inviteIds.isEmpty
                      ? 'Created $groupName.'
                      : 'Created $groupName and invited ${inviteIds.length}.',
                );
              } catch (e) {
                _showSnack('Could not create group: $e');
              } finally {
                if (mounted) setSheetState(() => saving = false);
              }
            }

            void addManualUsername() {
              final username = usernameController.text.trim().replaceFirst(
                '@',
                '',
              );
              if (username.isEmpty) return;
              setSheetState(() {
                manualUsernames.add(username);
                usernameController.clear();
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                left: context.dimensions.values.s24,
                right: context.dimensions.values.s24,
                top: context.dimensions.values.s18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Create group',
                        style: TextStyle(
                          color: _cream,
                          fontSize: context.textSizes.s22,
                        ),
                      ),
                      SizedBox(height: context.dimensions.values.s16),
                      TextField(
                        controller: groupNameController,
                        style: TextStyle(color: _cream),
                        decoration: _inputDecoration('Group name'),
                      ),
                      SizedBox(height: context.dimensions.values.s14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: usernameController,
                              style: TextStyle(color: _cream),
                              decoration: _inputDecoration('Invite username'),
                              onSubmitted: (_) => addManualUsername(),
                            ),
                          ),
                          SizedBox(width: context.dimensions.values.s10),
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: _onAccent,
                            ),
                            onPressed: addManualUsername,
                            icon: Icon(Icons.add),
                          ),
                        ],
                      ),
                      if (manualUsernames.isNotEmpty) ...[
                        SizedBox(height: context.dimensions.values.s10),
                        Wrap(
                          spacing: context.dimensions.values.s8,
                          runSpacing: context.dimensions.values.s8,
                          children: manualUsernames.map((username) {
                            return InputChip(
                              label: Text('@$username'),
                              onDeleted: () {
                                setSheetState(
                                  () => manualUsernames.remove(username),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ],
                      SizedBox(height: context.dimensions.values.s18),
                      Text(
                        'Pick from friends',
                        style: TextStyle(
                          color: _cream,
                          fontSize: context.textSizes.s16,
                        ),
                      ),
                      SizedBox(height: context.dimensions.values.s8),
                      FutureBuilder<List<_GroupInviteOption>>(
                        future: friendsFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: context.dimensions.values.s20,
                              ),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final friends = snapshot.data!;
                          if (friends.isEmpty) {
                            return Text(
                              'No friends yet. Add usernames manually above.',
                              style: TextStyle(color: _muted),
                            );
                          }

                          return Column(
                            children: friends.map((friend) {
                              final selected = selectedFriendIds.contains(
                                friend.userId,
                              );
                              return CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                value: selected,
                                activeColor: _accent,
                                checkColor: _onAccent,
                                title: Text(
                                  friend.name,
                                  style: TextStyle(color: _cream),
                                ),
                                subtitle: Text(
                                  '@${friend.username}',
                                  style: TextStyle(color: _muted),
                                ),
                                onChanged: (checked) {
                                  setSheetState(() {
                                    if (checked == true) {
                                      selectedFriendIds.add(friend.userId);
                                    } else {
                                      selectedFriendIds.remove(friend.userId);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
                      SizedBox(height: context.dimensions.values.s18),
                      SizedBox(
                        height: context.dimensions.values.s50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: _onAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                context.dimensions.values.s14,
                              ),
                            ),
                          ),
                          onPressed: saving ? null : createGroup,
                          child: saving
                              ? CircularProgressIndicator(color: _cream)
                              : Text(
                                  'Create group',
                                  style: TextStyle(
                                    fontSize: context.textSizes.s17,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<int> _currentUserCreatedGroupCount() async {
    final user = _user;
    if (user == null) return 0;

    final db = FirebaseFirestore.instance;
    final owned = await db
        .collection('groups')
        .where('ownerId', isEqualTo: user.uid)
        .get();
    final legacyCreated = await db
        .collection('groups')
        .where('createdBy', isEqualTo: user.uid)
        .get();

    return {
      ...owned.docs.map((doc) => doc.id),
      ...legacyCreated.docs.map((doc) => doc.id),
    }.length;
  }

  Future<List<_GroupInviteOption>> _loadFriendOptions(String userId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    final friendIds = List<String>.from(userDoc.data()?['friends'] ?? const []);
    if (friendIds.isEmpty) return [];

    final users = await _usersByIds(friendIds);
    return friendIds
        .where(users.containsKey)
        .map((friendId) {
          final data = users[friendId]!;
          final username = (data['username'] as String?)?.trim() ?? '';
          final name = (data['name'] as String?)?.trim();
          return _GroupInviteOption(
            userId: friendId,
            name: name?.isNotEmpty == true ? name! : username,
            username: username,
          );
        })
        .where((friend) => friend.username.isNotEmpty || friend.name.isNotEmpty)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _findUserByUsername(
    String rawUsername,
  ) async {
    final username = rawUsername.trim().replaceFirst('@', '');
    if (username.isEmpty) return null;

    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty && username != username.toLowerCase()) {
      snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();
    }

    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first;
  }

  Future<_InviteResolution> _resolveInviteIds({
    required String ownerId,
    required Set<String> manualUsernames,
    required Set<String> selectedFriendIds,
  }) async {
    final ids = selectedFriendIds.where((id) => id != ownerId).toSet();
    final usernamesById = <String, String>{};
    final missing = <String>[];

    for (final rawUsername in manualUsernames) {
      final username = rawUsername.trim().replaceFirst('@', '');
      if (username.isEmpty) continue;

      final doc = await _findUserByUsername(username);
      if (doc == null) {
        missing.add(username);
        continue;
      }

      if (doc.id == ownerId) continue;
      ids.add(doc.id);
      usernamesById[doc.id] = (doc.data()['username'] as String?) ?? username;
    }

    return _InviteResolution(
      userIds: ids,
      usernamesById: usernamesById,
      missingUsernames: missing,
    );
  }

  Future<void> _showHiddenFriendsSheet(Map<String, dynamic> data) async {
    final hidden = List<String>.from(data['hiddenFriends'] ?? []);
    final controller = TextEditingController();

    await _showSettingsSheet(
      title: 'Hidden Friends',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> saveHidden(List<String> next) async {
            await _updateUserSettings({'hiddenFriends': next});
            setSheetState(() {
              hidden
                ..clear()
                ..addAll(next);
            });
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                style: TextStyle(color: _cream),
                decoration: _inputDecoration('Friend username'),
              ),
              SizedBox(height: context.dimensions.values.s12),
              _primarySheetButton(
                label: 'Hide friend',
                onPressed: () async {
                  final username = controller.text.trim().replaceFirst('@', '');
                  if (username.isEmpty) return;

                  final friendDoc = await _findUserByUsername(username);
                  if (friendDoc == null) {
                    _showSnack('Could not find @$username.');
                    return;
                  }

                  final friendIds = List<String>.from(
                    data['friends'] ?? const [],
                  );
                  if (!friendIds.contains(friendDoc.id)) {
                    _showSnack('@$username is not in your friends list.');
                    return;
                  }

                  if (hidden.contains(friendDoc.id)) {
                    controller.clear();
                    return;
                  }
                  await saveHidden([...hidden, friendDoc.id]);
                  controller.clear();
                },
              ),
              SizedBox(height: context.dimensions.values.s16),
              if (hidden.isEmpty)
                Text(
                  'No hidden friends yet.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: context.textSizes.s15,
                  ),
                )
              else
                ...hidden.map(
                  (hiddenFriend) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: FutureBuilder<String>(
                      future: _hiddenFriendLabel(hiddenFriend),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? hiddenFriend,
                          style: TextStyle(color: _cream),
                        );
                      },
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.close, color: _muted),
                      onPressed: () async {
                        await saveHidden(
                          hidden.where((item) => item != hiddenFriend).toList(),
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<String> _hiddenFriendLabel(String hiddenFriend) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(hiddenFriend)
        .get();
    if (!doc.exists) return hiddenFriend;

    final data = doc.data() ?? {};
    final username = (data['username'] as String?)?.trim();
    if (username?.isNotEmpty == true) return '@$username';

    final name = (data['name'] as String?)?.trim();
    if (name?.isNotEmpty == true) return name!;

    return hiddenFriend;
  }

  Future<void> _showWorkoutTrackingSheet(String currentMode) async {
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.dimensions.values.s22),
        ),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.dimensions.values.s24,
              context.dimensions.values.s18,
              context.dimensions.values.s24,
              context.dimensions.values.s28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Workout tracking',
                  style: TextStyle(
                    color: _cream,
                    fontSize: context.textSizes.s22,
                  ),
                ),
                SizedBox(height: context.dimensions.values.s16),
                _trackingModeOption(
                  title: 'Manual entry',
                  subtitle: 'Type calories burned and minutes trained.',
                  icon: Icons.edit_note,
                  selected: currentMode == 'manual',
                  onTap: () async {
                    await _setWorkoutTrackingMode('manual');
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    _showManualTrackingPage();
                  },
                ),
                SizedBox(height: context.dimensions.values.s12),
                _trackingModeOption(
                  title: 'Sync Apple Health',
                  subtitle: isIos
                      ? 'Import workout calories and minutes from HealthKit.'
                      : 'Available on iPhone only.',
                  icon: Icons.favorite,
                  selected: currentMode == 'appleHealth',
                  enabled: isIos,
                  onTap: isIos
                      ? () async {
                          await _setWorkoutTrackingMode('appleHealth');
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                          _showAppleHealthTrackingPage();
                        }
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _trackingModeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(context.dimensions.values.s18),
      child: Container(
        padding: EdgeInsets.all(context.dimensions.values.s16),
        decoration: BoxDecoration(
          color: selected ? _selectedSurface : _surface,
          borderRadius: BorderRadius.circular(context.dimensions.values.s18),
          border: Border.all(color: selected ? _accent : _divider),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: context.dimensions.values.s22,
              backgroundColor: enabled ? _accent : _divider,
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
                      color: enabled ? _cream : _muted,
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
            if (selected)
              Icon(Icons.check_circle, color: _accent)
            else
              Icon(Icons.chevron_right, color: enabled ? _muted : _divider),
          ],
        ),
      ),
    );
  }

  Future<void> _setWorkoutTrackingMode(String mode) async {
    await _updateUserSettings({'workoutTrackingMode': mode});
    _showSnack(
      mode == 'appleHealth'
          ? 'Apple Health sync selected.'
          : 'Manual tracking selected.',
    );
  }

  String _workoutTrackingModeLabel(String mode) {
    return mode == 'appleHealth' ? 'Apple Health' : 'Manual';
  }

  void _showManualTrackingPage() {
    _pushDetailPage(
      title: 'Manual Tracking',
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          context.dimensions.values.s24,
          context.dimensions.values.s36,
          context.dimensions.values.s24,
          context.dimensions.values.s28,
        ),
        children: [
          Icon(
            Icons.check_circle,
            color: _goalLime,
            size: context.dimensions.values.s54,
          ),
          SizedBox(height: context.dimensions.values.s18),
          Text(
            'Connected to your manual workout log',
            textAlign: TextAlign.center,
            style: TextStyle(color: _cream, fontSize: context.textSizes.s24),
          ),
          SizedBox(height: context.dimensions.values.s16),
          Text(
            'Burn Camp is built around intentional manual entry. Add calories burned and minutes trained after each workout. Your daily totals, goals, alerts, recaps, and leaderboard use those entries.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: context.textSizes.s18,
              height: 1.35,
            ),
          ),
          SizedBox(height: context.dimensions.values.s34),
          _infoBlock(
            'Today from manual entries',
            'Calories and minutes are summed from every workout you save today.',
          ),
          _infoBlock(
            'Why manual?',
            'No wearable sync is required, and you stay in control of the numbers you log.',
          ),
          _infoBlock(
            'Tip',
            'Set your default workout duration to speed up the add-workout flow.',
          ),
          SizedBox(height: context.dimensions.values.s28),
          _primarySheetButton(
            label: 'Add workout',
            onPressed: _showAddWorkoutSheet,
          ),
        ],
      ),
    );
  }

  void _showAppleHealthTrackingPage() {
    _pushDetailPage(
      title: 'Apple Health',
      child: StatefulBuilder(
        builder: (context, setPageState) {
          return ListView(
            padding: EdgeInsets.fromLTRB(
              context.dimensions.values.s24,
              context.dimensions.values.s36,
              context.dimensions.values.s24,
              context.dimensions.values.s28,
            ),
            children: [
              Icon(
                Icons.favorite,
                color: _accent,
                size: context.dimensions.values.s54,
              ),
              SizedBox(height: context.dimensions.values.s18),
              Text(
                'Apple Health sync',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _cream,
                  fontSize: context.textSizes.s24,
                ),
              ),
              SizedBox(height: context.dimensions.values.s16),
              Text(
                'Burn Camp can read Health app workouts on iPhone and import active calories plus workout duration into your daily totals.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _muted,
                  fontSize: context.textSizes.s18,
                  height: 1.35,
                ),
              ),
              SizedBox(height: context.dimensions.values.s34),
              _infoBlock(
                'What syncs',
                'Workout duration and active energy burned from Apple Health workouts.',
              ),
              _infoBlock(
                'Duplicate safe',
                'HealthKit workout IDs are stored so repeated syncs do not double-count the same workout.',
              ),
              _infoBlock(
                'Manual backup',
                'You can still add a workout manually if Health sync is unavailable.',
              ),
              SizedBox(height: context.dimensions.values.s28),
              _primarySheetButton(
                label: _syncingAppleHealth
                    ? 'Syncing Apple Health...'
                    : 'Connect and sync last 7 days',
                onPressed: _syncingAppleHealth
                    ? () {}
                    : () => _syncAppleHealthWorkouts(setPageState),
              ),
              SizedBox(height: context.dimensions.values.s12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _cream,
                  side: BorderSide(color: _divider),
                  padding: EdgeInsets.symmetric(
                    vertical: context.dimensions.values.s13,
                  ),
                ),
                onPressed: _showAddWorkoutSheet,
                child: Text('Add manual workout'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _syncAppleHealthWorkouts(StateSetter setPageState) async {
    final service = AppleHealthService();
    if (!service.isAvailableOnDevice) {
      _showSnack('Apple Health sync is available on iPhone only.');
      return;
    }

    setPageState(() => _syncingAppleHealth = true);
    setState(() => _syncingAppleHealth = true);

    try {
      final result = await service.importRecentWorkouts();
      if (!mounted) return;
      _showSnack(
        result.importedWorkouts == 0
            ? 'No new Apple Health workouts found.'
            : 'Imported ${result.importedWorkouts} workouts: ${result.calories} cals · ${result.minutes} min.',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Apple Health sync failed: $e');
    } finally {
      if (mounted) {
        setPageState(() => _syncingAppleHealth = false);
        setState(() => _syncingAppleHealth = false);
      }
    }
  }

  void _showManageGroupsPage() {
    final user = _user;
    _pushDetailPage(
      title: 'Manage Groups',
      child: user == null
          ? Center(
              child: Text(
                'Sign in to manage groups.',
                style: TextStyle(color: _muted),
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .where('memberIds', arrayContains: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final groups = snapshot.data?.docs ?? [];
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    context.dimensions.values.s24,
                    context.dimensions.values.s24,
                    context.dimensions.values.s24,
                    context.dimensions.values.s28,
                  ),
                  children: [
                    _primarySheetButton(
                      label: 'Create group',
                      onPressed: _showCreateGroupSheet,
                    ),
                    SizedBox(height: context.dimensions.values.s20),
                    if (groups.isEmpty)
                      Text(
                        'No groups yet. Create one to compare calorie totals with friends.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: context.textSizes.s17,
                        ),
                      )
                    else
                      ...groups.map((doc) {
                        final data = doc.data();
                        final members =
                            (data['memberIds'] as List<dynamic>? ?? const [])
                                .length;
                        return _detailListTile(
                          title: (data['name'] as String?) ?? 'Workout group',
                          subtitle: '$members members',
                          icon: Icons.groups,
                          onTap: () => _showGroupDetailsDialog(doc),
                        );
                      }),
                  ],
                );
              },
            ),
    );
  }

  void _showHelpPage() {
    _pushDetailPage(
      title: 'Help and Feedback',
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          context.dimensions.values.s24,
          context.dimensions.values.s24,
          context.dimensions.values.s24,
          context.dimensions.values.s28,
        ),
        children: [
          _detailListTile(
            title: 'How tracking works',
            subtitle:
                'Calories and minutes are entered manually after each workout.',
            icon: Icons.info_outline,
          ),
          _detailListTile(
            title: 'Goals and streaks',
            subtitle:
                'A streak day counts when your logged calories meet your daily goal.',
            icon: Icons.local_fire_department,
          ),
          _detailListTile(
            title: 'Send feedback',
            subtitle: 'Share what should be improved next.',
            icon: Icons.feedback_outlined,
            onTap: () => _shareText(context, 'Burn Camp feedback: '),
          ),
          SizedBox(height: context.dimensions.values.s18),
          Text(
            'Support note: this screen is local for now. Hook it to email, a feedback form, or your support inbox when ready.',
            style: TextStyle(color: _muted, fontSize: context.textSizes.s15),
          ),
        ],
      ),
    );
  }

  void _showSupportPage() {
    _pushDetailPage(
      title: 'Support Burn Camp',
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          context.dimensions.values.s24,
          context.dimensions.values.s36,
          context.dimensions.values.s24,
          context.dimensions.values.s28,
        ),
        children: [
          Icon(
            Icons.local_fire_department,
            color: _accent,
            size: context.dimensions.values.s64,
          ),
          SizedBox(height: context.dimensions.values.s18),
          Text(
            'Enjoy Burn Camp?',
            textAlign: TextAlign.center,
            style: TextStyle(color: _cream, fontSize: context.textSizes.s26),
          ),
          SizedBox(height: context.dimensions.values.s12),
          Text(
            'Support development and unlock a cleaner premium experience as the app grows.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: context.textSizes.s18,
              height: 1.3,
            ),
          ),
          SizedBox(height: context.dimensions.values.s28),
          _supportPlan('Yearly', '\$12', '\$1/month', 'Best value'),
          _supportPlan('Monthly', '\$2/month', '', ''),
          _supportPlan('Lifetime', '\$25', '', ''),
          SizedBox(height: context.dimensions.values.s18),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Not now',
              style: TextStyle(color: _muted, fontSize: context.textSizes.s18),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoPage({required String title, required String body}) {
    _pushDetailPage(
      title: title,
      child: Padding(
        padding: EdgeInsets.all(context.dimensions.values.s24),
        child: Text(
          body,
          style: TextStyle(
            color: _cream,
            fontSize: context.textSizes.s18,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  void _pushDetailPage({required String title, required Widget child}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _DashboardDetailPage(title: title, child: child),
      ),
    );
  }

  Widget _infoBlock(String title, String body) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.dimensions.values.s16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: _cream, fontSize: context.textSizes.s18),
          ),
          SizedBox(height: context.dimensions.values.s6),
          Text(
            body,
            style: TextStyle(
              color: _muted,
              fontSize: context.textSizes.s15,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: _accent, size: context.dimensions.values.s30),
      title: Text(
        title,
        style: TextStyle(color: _cream, fontSize: context.textSizes.s18),
      ),
      subtitle: Text(subtitle, style: TextStyle(color: _muted)),
      trailing: onTap == null ? null : Icon(Icons.chevron_right, color: _muted),
      onTap: onTap,
    );
  }

  Widget _supportPlan(String title, String price, String right, String badge) {
    return Container(
      margin: EdgeInsets.only(bottom: context.dimensions.values.s16),
      padding: EdgeInsets.symmetric(
        horizontal: context.dimensions.values.s20,
        vertical: context.dimensions.values.s18,
      ),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(context.dimensions.values.s16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _background,
                    fontSize: context.textSizes.s22,
                  ),
                ),
                Text(
                  price,
                  style: TextStyle(
                    color: _selectedSurface,
                    fontSize: context.textSizes.s17,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (right.isNotEmpty)
                Text(
                  right,
                  style: TextStyle(
                    color: _background,
                    fontSize: context.textSizes.s20,
                  ),
                ),
              if (badge.isNotEmpty)
                Text(
                  badge,
                  style: TextStyle(
                    color: _accent,
                    fontSize: context.textSizes.s14,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showChoiceSheet({
    required String title,
    required String currentValue,
    required Map<String, String> options,
    required Future<void> Function(String value) onSelected,
  }) {
    return _showSettingsSheet(
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.entries.map((entry) {
          final selected = entry.key == currentValue;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(entry.value, style: TextStyle(color: _cream)),
            trailing: selected
                ? Icon(Icons.check, color: _accent)
                : Icon(Icons.chevron_right, color: _muted),
            onTap: () async {
              await onSelected(entry.key);
              if (!mounted) return;
              Navigator.of(context).pop();
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showSettingsSheet({
    required String title,
    required Widget child,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.dimensions.values.s22),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: context.dimensions.values.s24,
            right: context.dimensions.values.s24,
            top: context.dimensions.values.s18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: _cream,
                  fontSize: context.textSizes.s22,
                ),
              ),
              SizedBox(height: context.dimensions.values.s16),
              child,
            ],
          ),
        );
      },
    );
  }

  Widget _primarySheetButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: context.dimensions.values.s48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: _onAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.dimensions.values.s14),
          ),
        ),
        onPressed: onPressed,
        child: Text(label, style: TextStyle(fontSize: context.textSizes.s16)),
      ),
    );
  }

  Widget _recapRow(String label, int calories, int minutes) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.dimensions.values.s12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: _cream, fontSize: context.textSizes.s17),
            ),
          ),
          Text(
            '${NumberFormat.decimalPattern().format(calories)} cals · $minutes min',
            style: TextStyle(color: _muted, fontSize: context.textSizes.s15),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserSettings(Map<String, dynamic> values) async {
    final user = _user;
    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in values.entries) {
        final key = 'settings.${entry.key}';
        final value = entry.value;
        if (value is String) {
          await prefs.setString(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is List<String>) {
          await prefs.setStringList(key, value);
        }
      }
      if (mounted) setState(() => _settingsRefresh++);
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      ...values,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> _localSettingsData() async {
    final prefs = await SharedPreferences.getInstance();
    final onboarding = await OnboardingPreferences.load();
    return {
      'goalCalories':
          prefs.getInt('settings.goalCalories') ??
          (onboarding['goalCalories'] as int?) ??
          500,
      'defaultWorkoutMinutes':
          prefs.getInt('settings.defaultWorkoutMinutes') ?? 30,
      'workoutTrackingMode':
          prefs.getString('settings.workoutTrackingMode') ??
          onboarding['workoutTrackingMode'] as String? ??
          'manual',
      'streakMode': prefs.getString('settings.streakMode') ?? 'strict',
      'themeMode': prefs.getString('settings.themeMode') ?? 'dark',
      'notificationsEnabled':
          prefs.getBool('settings.notificationsEnabled') ?? true,
      'hiddenFriends': prefs.getStringList('settings.hiddenFriends') ?? [],
    };
  }

  Future<void> _signInFromSettings() async {
    try {
      await AuthService().signInWithGoogle();
      await OnboardingPreferences.syncToCurrentUser();
      await _syncLocalSettingsToCurrentUser();
      if (!mounted) return;
      setState(() {});
      _showSnack('Signed in. Your Burn Camp settings can now sync.');
    } catch (e) {
      _showSnack('Sign in failed: $e');
    }
  }

  Future<void> _syncLocalSettingsToCurrentUser() async {
    final user = _user;
    if (user == null) return;

    final settings = await _localSettingsData();
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      ...settings,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _resetPersonalization() async {
    await OnboardingPreferences.reset();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (_) => false,
    );
  }

  String _streakModeLabel(String mode) {
    switch (mode) {
      case 'flexible':
        return 'Flexible';
      case 'trainingDays':
        return 'Training days';
      case 'strict':
      default:
        return 'Strict';
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openStatsShareScreen(List<Map<String, dynamic>> summaries) {
    final data = _StatsShareData(
      periodAggregates: {
        for (final period in MetricPeriod.values)
          period: _aggregateForPeriod(summaries, period),
      },
      longestStreak: _longestStreak(summaries),
      bestWeek: _bestWindow(summaries, const Duration(days: 7)),
      bestMonth: _bestMonth(summaries),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _StatsShareScreen(initialPeriod: _period, shareData: data),
      ),
    );
  }

  Future<void> _shareText(BuildContext _, String text) async {
    try {
      final origin = _shareOriginForPlatform();
      await SharePlus.instance.share(
        ShareParams(text: text, sharePositionOrigin: origin),
      );
    } catch (e) {
      _showSnack('Share failed: $e');
    }
  }

  Rect? _shareOriginForPlatform() {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return null;
    }

    // The app-level scaling wrapper can report Flutter global coordinates that
    // are outside the native iOS source view. iOS rejects those rects. Passing a
    // tiny in-bounds rect is more reliable for the text-only share sheet.
    return const Rect.fromLTWH(1, 1, 1, 1);
  }

  Widget _darkNumberField({
    required TextEditingController controller,
    required String label,
    required String suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: TextStyle(color: _cream, fontSize: context.textSizes.s18),
      decoration: _inputDecoration(label).copyWith(
        suffixText: suffix,
        suffixStyle: TextStyle(color: _muted),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _muted),
      filled: true,
      fillColor: _surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(context.dimensions.values.s14),
        borderSide: BorderSide.none,
      ),
    );
  }

  _MetricAggregate _aggregateForPeriod(
    List<Map<String, dynamic>> summaries,
    MetricPeriod period,
  ) {
    final now = DateTime.now();
    late final DateTime start;
    late final DateTime end;

    switch (period) {
      case MetricPeriod.today:
        start = WorkoutService.startOfDay(now);
        end = start.add(const Duration(days: 1));
      case MetricPeriod.yesterday:
        end = WorkoutService.startOfDay(now);
        start = end.subtract(const Duration(days: 1));
      case MetricPeriod.week:
        start = WorkoutService.startOfWeek(now);
        end = start.add(const Duration(days: 7));
      case MetricPeriod.month:
        start = WorkoutService.startOfMonth(now);
        end = DateTime(now.year, now.month + 1);
    }

    var calories = 0;
    var minutes = 0;
    var daysWithEntries = 0;

    for (final summary in summaries) {
      final date = _dateFromSummary(summary);
      if (date == null || date.isBefore(start) || !date.isBefore(end)) continue;
      calories += WorkoutService.caloriesFromSummary(summary);
      minutes += WorkoutService.minutesFromSummary(summary);
      daysWithEntries++;
    }

    return _MetricAggregate(
      calories: calories,
      minutes: minutes,
      days: daysWithEntries,
    );
  }

  String _metricLabel(MetricPeriod period) {
    switch (period) {
      case MetricPeriod.today:
        return 'calories today';
      case MetricPeriod.yesterday:
        return 'calories yesterday';
      case MetricPeriod.week:
        return 'calories this week';
      case MetricPeriod.month:
        return 'calories this month';
    }
  }

  String _minutesLabel(_MetricAggregate aggregate, MetricPeriod period) {
    if (period == MetricPeriod.week || period == MetricPeriod.month) {
      final avg = aggregate.days == 0
          ? 0
          : (aggregate.minutes / aggregate.days).round();
      return '$avg min/day · ${aggregate.minutes} min trained';
    }

    return '${aggregate.minutes} min trained';
  }

  int _sumCalories(List<Map<String, dynamic>> summaries) {
    return summaries.fold<int>(
      0,
      (total, summary) => total + WorkoutService.caloriesFromSummary(summary),
    );
  }

  int _sumMinutes(List<Map<String, dynamic>> summaries) {
    return summaries.fold<int>(
      0,
      (total, summary) => total + WorkoutService.minutesFromSummary(summary),
    );
  }

  List<DateTime> _historyMonthsThroughCurrent(int earliestYear) {
    final now = DateTime.now();
    final months = <DateTime>[];

    for (var year = now.year; year >= earliestYear; year--) {
      final startMonth = year == now.year ? now.month : 12;
      for (var month = startMonth; month >= 1; month--) {
        months.add(DateTime(year, month));
      }
    }

    return months;
  }

  List<DateTime> _mondayWeeksForMonth(DateTime month, DateTime today) {
    final firstDay = DateTime(month.year, month.month);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final firstMondayOffset = firstDay.weekday == DateTime.monday
        ? 0
        : (DateTime.daysPerWeek + DateTime.monday - firstDay.weekday) %
              DateTime.daysPerWeek;
    var monday = firstDay.add(Duration(days: firstMondayOffset));
    final weeks = <DateTime>[];

    while (!monday.isAfter(lastDay) && !monday.isAfter(today)) {
      weeks.add(monday);
      monday = monday.add(const Duration(days: 7));
    }

    return weeks.reversed.toList();
  }

  int _distinctDays(List<Map<String, dynamic>> summaries) {
    return summaries.map(_dateFromSummary).whereType<DateTime>().toSet().length;
  }

  int _historyValueForSummaries(List<Map<String, dynamic>> summaries) {
    final calories = _sumCalories(summaries);
    if (!_historyShowsAverage) return calories;

    final days = _distinctDays(summaries);
    if (days == 0) return 0;
    return (calories / days).round();
  }

  int _averagePositiveHistoryValue(Iterable<int> values) {
    final positiveValues = values.where((value) => value > 0).toList();
    if (positiveValues.isEmpty) return 1;

    final total = positiveValues.fold<int>(
      0,
      (runningTotal, value) => runningTotal + value,
    );
    return math.max(1, (total / positiveValues.length).round());
  }

  double _measureTextWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: ui.TextDirection.ltr,
    )..layout();
    return painter.width;
  }

  String _formatHistoryValue(
    int calories,
    int days, {
    bool compact = false,
    bool includeUnit = true,
  }) {
    final value = _historyShowsAverage && days > 0
        ? (calories / days).round()
        : calories;
    final formatted = compact
        ? NumberFormat.compact().format(value)
        : NumberFormat.decimalPattern().format(value);

    if (!includeUnit) return formatted;
    return _historyShowsAverage ? '$formatted cals/day' : '$formatted cals';
  }

  String _friendlyDate(Map<String, dynamic> summary) {
    final date = _dateFromSummary(summary);
    if (date == null) return '--';
    return DateFormat.Md().format(date);
  }

  DateTime? _dateFromSummary(Map<String, dynamic> summary) {
    final timestamp = summary['dateTimestamp'];
    if (timestamp is Timestamp) {
      return WorkoutService.startOfDay(timestamp.toDate());
    }

    final date = summary['date'];
    if (date is String) {
      try {
        return WorkoutService.startOfDay(DateTime.parse(date));
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  int _goalCalories(Map<String, dynamic> data) {
    return (data['goalCalories'] as num?)?.toInt() ??
        (data['goalMinutes'] as num?)?.toInt() ??
        500;
  }

  int _goalCaloriesFromCachedSummaries(List<Map<String, dynamic>> summaries) {
    for (final summary in summaries) {
      final goal = (summary['goalCalories'] as num?)?.toInt();
      if (goal != null && goal > 0) return goal;
    }
    return 500;
  }

  int _longestStreak(List<Map<String, dynamic>> summaries) {
    final metDays = summaries
        .where((summary) => summary['goalMet'] == true)
        .map(_dateFromSummary)
        .whereType<DateTime>()
        .toSet();

    if (metDays.isEmpty) return 0;

    var longest = 0;
    var current = 0;
    var day = WorkoutService.startOfDay(DateTime.now());
    final oldest = metDays.reduce((a, b) => a.isBefore(b) ? a : b);

    while (!day.isBefore(oldest)) {
      if (metDays.contains(day)) {
        current++;
        longest = math.max(longest, current);
      } else {
        current = 0;
      }
      day = day.subtract(const Duration(days: 1));
    }

    return longest;
  }

  String _bestWindow(List<Map<String, dynamic>> summaries, Duration window) {
    if (summaries.isEmpty) return '—';

    final dates = summaries
        .map(_dateFromSummary)
        .whereType<DateTime>()
        .toList();
    if (dates.isEmpty) return '—';

    var bestCalories = 0;
    DateTime? bestStart;

    for (final candidate in dates) {
      final end = candidate.add(window);
      final total = summaries.fold<int>(0, (totalCalories, summary) {
        final date = _dateFromSummary(summary);
        if (date == null || date.isBefore(candidate) || !date.isBefore(end)) {
          return totalCalories;
        }
        return totalCalories + WorkoutService.caloriesFromSummary(summary);
      });

      if (total > bestCalories) {
        bestCalories = total;
        bestStart = candidate;
      }
    }

    if (bestStart == null) return '—';
    return '${DateFormat.Md().format(bestStart)} · ${NumberFormat.compact().format(bestCalories)} cals';
  }

  String _bestMonth(List<Map<String, dynamic>> summaries) {
    if (summaries.isEmpty) return '—';
    final totals = <String, int>{};

    for (final summary in summaries) {
      final date = _dateFromSummary(summary);
      if (date == null) continue;
      final key = DateFormat('MMM yyyy').format(date);
      totals[key] =
          (totals[key] ?? 0) + WorkoutService.caloriesFromSummary(summary);
    }

    if (totals.isEmpty) return '—';
    final best = totals.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return '${best.key} · ${NumberFormat.compact().format(best.value)} cals';
  }

  Future<void> _logout() async {
    try {
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.disconnect();
        await googleSignIn.signOut();
      }
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      _showSnack('Sign out failed: $e');
      return;
    }

    if (!mounted) return;
    setState(() {});
    _showSnack('Signed out of Google.');
  }
}

class _MetricAggregate {
  final int calories;
  final int minutes;
  final int days;

  const _MetricAggregate({
    required this.calories,
    required this.minutes,
    required this.days,
  });
}

class _StatsShareData {
  final Map<MetricPeriod, _MetricAggregate> periodAggregates;
  final int longestStreak;
  final String bestWeek;
  final String bestMonth;

  const _StatsShareData({
    required this.periodAggregates,
    required this.longestStreak,
    required this.bestWeek,
    required this.bestMonth,
  });

  _MetricAggregate aggregateFor(MetricPeriod period) {
    return periodAggregates[period] ??
        const _MetricAggregate(calories: 0, minutes: 0, days: 0);
  }
}

class _StatsShareScreen extends StatefulWidget {
  final MetricPeriod initialPeriod;
  final _StatsShareData shareData;

  const _StatsShareScreen({
    required this.initialPeriod,
    required this.shareData,
  });

  @override
  State<_StatsShareScreen> createState() => _StatsShareScreenState();
}

class _StatsShareScreenState extends State<_StatsShareScreen> {
  final GlobalKey _previewKey = GlobalKey();
  final ImagePicker _imagePicker = ImagePicker();
  late MetricPeriod _period = widget.initialPeriod;
  var _backgroundIndex = 0;
  var _largeType = true;
  var _squareFormat = false;
  var _saving = false;
  var _renderingExport = false;
  File? _customBackground;
  var _transparentBackground = false;

  static const _backgrounds = [
    _ShareBackground(
      name: 'Gradient',
      start: Color(0xFF17110E),
      end: Color(0xFFB85C38),
      textColor: ClaudePalette.cream,
    ),
    _ShareBackground(
      name: 'Light',
      start: Color(0xFFFFF2E3),
      end: Color(0xFFFFB28C),
      textColor: ClaudePalette.charcoal,
    ),
    _ShareBackground(
      name: 'Night',
      start: Color(0xFF090909),
      end: Color(0xFF202124),
      textColor: ClaudePalette.cream,
      checker: true,
    ),
  ];

  _MetricAggregate get _aggregate => widget.shareData.aggregateFor(_period);
  _ShareBackground get _background => _backgrounds[_backgroundIndex];
  Color get _textColor {
    if (_transparentBackground || _customBackground != null) {
      return ClaudePalette.cream;
    }
    return _background.textColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0C),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.dimensions.values.s24,
                context.dimensions.values.s20,
                context.dimensions.values.s24,
                context.dimensions.values.s0,
              ),
              child: Row(
                children: [
                  _roundButton(
                    icon: Icons.close,
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                  const Spacer(),
                  _roundTextButton(
                    label: _periodBadge,
                    onPressed: _cyclePeriod,
                    tooltip: 'Change stats range',
                  ),
                  SizedBox(width: context.dimensions.values.s12),
                  _roundTextButton(
                    label: 'A',
                    onPressed: () => setState(() => _largeType = !_largeType),
                    tooltip: 'Toggle text size',
                  ),
                  SizedBox(width: context.dimensions.values.s12),
                  _roundButton(
                    icon: _squareFormat
                        ? Icons.phone_iphone
                        : Icons.crop_square,
                    onPressed: () =>
                        setState(() => _squareFormat = !_squareFormat),
                    tooltip: _squareFormat
                        ? 'Use full-screen size'
                        : 'Use 1:1 size',
                  ),
                  SizedBox(width: context.dimensions.values.s12),
                  _roundButton(
                    icon: Icons.photo_library_outlined,
                    onPressed: _showBackgroundMenu,
                    tooltip: 'Choose background',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.dimensions.values.s24,
                    context.dimensions.values.s24,
                    context.dimensions.values.s24,
                    context.dimensions.values.s16,
                  ),
                  child: AspectRatio(
                    aspectRatio: _squareFormat ? 1 : 9 / 16,
                    child: RepaintBoundary(
                      key: _previewKey,
                      child: _statsPreview(),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.dimensions.values.s26,
                context.dimensions.values.s8,
                context.dimensions.values.s26,
                context.dimensions.values.s24,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _socialButton(
                    label: 'Instagram',
                    child: const _InstagramGlyph(),
                    onPressed: () => _comingSoon('Instagram'),
                  ),
                  _socialButton(
                    label: 'Snap',
                    child: const _SnapGlyph(),
                    onPressed: () => _comingSoon('Snapchat'),
                  ),
                  _socialButton(
                    label: 'Facebook',
                    child: const _FacebookGlyph(),
                    onPressed: () => _comingSoon('Facebook'),
                  ),
                  _socialButton(
                    label: 'Save',
                    child: Icon(
                      Icons.file_download_outlined,
                      color: Colors.white,
                      size: context.dimensions.values.s34,
                    ),
                    onPressed: _saving ? null : _savePreview,
                  ),
                  _socialButton(
                    label: 'Share',
                    child: Icon(
                      Icons.ios_share,
                      color: Colors.white,
                      size: context.dimensions.values.s34,
                    ),
                    onPressed: _saving ? null : _sharePreview,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsPreview() {
    final textColor = _textColor;
    final calories = NumberFormat.decimalPattern().format(_aggregate.calories);
    final minutes = NumberFormat.decimalPattern().format(_aggregate.minutes);
    final titleSize = _largeType
        ? (_squareFormat ? context.textSizes.s66 : context.textSizes.s84)
        : (_squareFormat ? context.textSizes.s52 : context.textSizes.s66);
    final subtitleSize = _largeType
        ? context.textSizes.s25
        : context.textSizes.s21;

    return ClipRRect(
      borderRadius: BorderRadius.circular(_squareFormat ? 28 : 34),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!_transparentBackground && _customBackground == null)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_background.start, _background.end],
                ),
              ),
            ),
          if (!_transparentBackground && _customBackground != null)
            Image.file(_customBackground!, fit: BoxFit.cover),
          if (_transparentBackground && !_renderingExport)
            const CustomPaint(painter: _CheckerPainter()),
          if (!_transparentBackground)
            Container(color: Colors.black.withValues(alpha: 0.18)),
          Padding(
            padding: EdgeInsets.all(context.dimensions.values.s28),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.dimensions.values.s14,
                      vertical: context.dimensions.values.s8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(
                        context.dimensions.values.pill,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Text(
                      _periodLabel,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'calories burned',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.88),
                    fontSize: subtitleSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: context.dimensions.values.s8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    calories,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: titleSize,
                      fontWeight: FontWeight.w300,
                      height: 0.95,
                    ),
                  ),
                ),
                SizedBox(height: context.dimensions.values.s12),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: context.dimensions.values.s12,
                  runSpacing: context.dimensions.values.s8,
                  children: [
                    _previewMetric('$minutes min'),
                    _previewMetric(
                      '${widget.shareData.longestStreak} day streak',
                    ),
                    _previewMetric('${_aggregate.days} active days'),
                  ],
                ),
                const Spacer(),
                if (!_squareFormat)
                  Container(
                    padding: EdgeInsets.all(context.dimensions.values.s16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(
                        context.dimensions.values.s22,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      children: [
                        _miniStat('Best week', widget.shareData.bestWeek),
                        SizedBox(height: context.dimensions.values.s8),
                        _miniStat('Best month', widget.shareData.bestMonth),
                      ],
                    ),
                  ),
                SizedBox(height: context.dimensions.values.s28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: textColor,
                      size: context.dimensions.values.s26,
                    ),
                    SizedBox(width: context.dimensions.values.s8),
                    Text(
                      'Burn Camp',
                      style: TextStyle(
                        color: textColor,
                        fontSize: context.textSizes.s27,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
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

  Widget _previewMetric(String value) {
    return Text(
      value,
      style: TextStyle(
        color: _textColor.withValues(alpha: 0.88),
        fontSize: context.textSizes.s21,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: _textColor.withValues(alpha: 0.72),
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(width: context.dimensions.values.s10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: _textColor, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _roundButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: context.dimensions.values.s58,
            height: context.dimensions.values.s58,
            child: Icon(
              icon,
              color: Colors.white,
              size: context.dimensions.values.s30,
            ),
          ),
        ),
      ),
    );
  }

  Widget _roundTextButton({
    required String label,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: context.dimensions.values.s58,
            height: context.dimensions.values.s58,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.textSizes.s19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton({
    required String label,
    required Widget child,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: label,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: context.dimensions.values.s64,
          height: context.dimensions.values.s64,
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  Future<void> _sharePreview() async {
    try {
      final file = await _writePreviewPng(toDocuments: false);
      await SharePlus.instance.share(
        ShareParams(
          text: _shareText,
          files: [XFile(file.path, mimeType: 'image/png')],
          fileNameOverrides: ['burn-camp-stats.png'],
          sharePositionOrigin: _shareOriginForPlatform(),
        ),
      );
    } catch (e) {
      _showSnack('Share failed: $e');
    }
  }

  Future<void> _savePreview() async {
    setState(() => _saving = true);
    try {
      final file = await _writePreviewPng(toDocuments: true);
      _showSnack('Saved stats image to ${file.path}');
    } catch (e) {
      _showSnack('Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<File> _writePreviewPng({required bool toDocuments}) async {
    if (_transparentBackground && !_renderingExport) {
      setState(() => _renderingExport = true);
    }
    await WidgetsBinding.instance.endOfFrame;
    try {
      final boundary =
          _previewKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError('Stats preview is not ready yet.');
      }

      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();
      if (bytes == null) {
        throw StateError('Could not render stats image.');
      }

      final directory = toDocuments
          ? await getApplicationDocumentsDirectory()
          : await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
      final file = File('${directory.path}/burn-camp-stats-$timestamp.png');
      return await file.writeAsBytes(bytes, flush: true);
    } finally {
      if (_renderingExport && mounted) {
        setState(() => _renderingExport = false);
      }
    }
  }

  void _cyclePeriod() {
    final values = MetricPeriod.values;
    final nextIndex = (values.indexOf(_period) + 1) % values.length;
    setState(() => _period = values[nextIndex]);
  }

  Future<void> _showBackgroundMenu() {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xEE161616),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.dimensions.values.s24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.dimensions.values.s24,
              context.dimensions.values.s18,
              context.dimensions.values.s24,
              context.dimensions.values.s24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: context.dimensions.values.s42,
                  height: context.dimensions.values.s4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(
                      context.dimensions.values.pill,
                    ),
                  ),
                ),
                SizedBox(height: context.dimensions.values.s18),
                _backgroundOption(
                  icon: Icons.camera_alt_outlined,
                  title: 'Camera',
                  onTap: () => _pickBackground(ImageSource.camera),
                ),
                _backgroundOption(
                  icon: Icons.photo_library_outlined,
                  title: 'Camera roll',
                  onTap: () => _pickBackground(ImageSource.gallery),
                ),
                _backgroundOption(
                  icon: Icons.texture_outlined,
                  title: 'Transparent',
                  onTap: _useTransparentBackground,
                ),
                _backgroundOption(
                  icon: Icons.gradient_outlined,
                  title: 'App background',
                  onTap: _cycleBackgroundFromSheet,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _backgroundOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: Colors.white,
        size: context.dimensions.values.s28,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: context.textSizes.s22,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
  }

  Future<void> _pickBackground(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 92,
      );
      if (image == null) return;
      setState(() {
        _customBackground = File(image.path);
        _transparentBackground = false;
      });
    } catch (e) {
      _showSnack('Could not pick image: $e');
    }
  }

  void _useTransparentBackground() {
    setState(() {
      _customBackground = null;
      _transparentBackground = true;
    });
  }

  void _cycleBackgroundFromSheet() {
    _cycleBackground();
    _showSnack('Using ${_background.name} background.');
  }

  void _cycleBackground() {
    setState(() {
      _backgroundIndex = (_backgroundIndex + 1) % _backgrounds.length;
      _customBackground = null;
      _transparentBackground = false;
    });
  }

  void _comingSoon(String appName) {
    _showSnack('$appName sharing is coming soon. Use Share or Save for now.');
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Rect? _shareOriginForPlatform() {
    if (defaultTargetPlatform != TargetPlatform.iOS) return null;
    return const Rect.fromLTWH(1, 1, 1, 1);
  }

  String get _shareText {
    final calories = NumberFormat.decimalPattern().format(_aggregate.calories);
    final minutes = NumberFormat.decimalPattern().format(_aggregate.minutes);
    return 'Burn Camp ${_periodLabel.toLowerCase()}: $calories calories burned and $minutes minutes trained.';
  }

  String get _periodLabel {
    switch (_period) {
      case MetricPeriod.today:
        return 'Today';
      case MetricPeriod.yesterday:
        return 'Yesterday';
      case MetricPeriod.week:
        return 'This week';
      case MetricPeriod.month:
        return 'This month';
    }
  }

  String get _periodBadge {
    switch (_period) {
      case MetricPeriod.today:
        return '1D';
      case MetricPeriod.yesterday:
        return 'Y';
      case MetricPeriod.week:
        return '7D';
      case MetricPeriod.month:
        return '30';
    }
  }
}

class _ShareBackground {
  final String name;
  final Color start;
  final Color end;
  final Color textColor;
  final bool checker;

  const _ShareBackground({
    required this.name,
    required this.start,
    required this.end,
    required this.textColor,
    this.checker = false,
  });
}

class _CheckerPainter extends CustomPainter {
  const _CheckerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const square = 34.0;
    final dark = Paint()..color = const Color(0xFF242424);
    final light = Paint()..color = const Color(0xFF3B3B3B);

    for (var y = 0.0; y < size.height; y += square) {
      for (var x = 0.0; x < size.width; x += square) {
        final useLight = ((x / square).floor() + (y / square).floor()).isEven;
        canvas.drawRect(
          Rect.fromLTWH(x, y, square, square),
          useLight ? light : dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InstagramGlyph extends StatelessWidget {
  const _InstagramGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.dimensions.values.s38,
      height: context.dimensions.values.s38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.dimensions.values.s11),
        gradient: const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xFFFFD600),
            Color(0xFFFF7A00),
            Color(0xFFFF0069),
            Color(0xFFD300C5),
            Color(0xFF7638FA),
          ],
        ),
      ),
      child: Icon(
        Icons.camera_alt,
        color: Colors.white,
        size: context.dimensions.values.s24,
      ),
    );
  }
}

class _SnapGlyph extends StatelessWidget {
  const _SnapGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.dimensions.values.s38,
      height: context.dimensions.values.s38,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFC00),
        borderRadius: BorderRadius.circular(context.dimensions.values.s10),
      ),
      child: Center(
        child: Text('👻', style: TextStyle(fontSize: context.textSizes.s22)),
      ),
    );
  }
}

class _FacebookGlyph extends StatelessWidget {
  const _FacebookGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.dimensions.values.s38,
      height: context.dimensions.values.s38,
      decoration: const BoxDecoration(
        color: Color(0xFF1877F2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'f',
          style: TextStyle(
            color: Colors.white,
            fontSize: context.textSizes.s32,
            fontWeight: FontWeight.w900,
            height: context.dimensions.values.s1,
          ),
        ),
      ),
    );
  }
}

class _GroupTotals {
  final int calories;
  final int minutes;

  const _GroupTotals({required this.calories, required this.minutes});
}

class _GroupLeaderboardItem {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String name;
  final int memberCount;
  final _GroupTotals totals;

  const _GroupLeaderboardItem({
    required this.doc,
    required this.name,
    required this.memberCount,
    required this.totals,
  });
}

class _LeaderboardMember {
  final String userId;
  final String name;
  final int calories;
  final int minutes;
  final String photoUrl;
  final bool isCurrentUser;
  final bool isBot;

  const _LeaderboardMember({
    required this.userId,
    required this.name,
    required this.calories,
    required this.minutes,
    this.photoUrl = '',
    this.isCurrentUser = false,
    this.isBot = false,
  });

  bool get canRemove => !isCurrentUser && !isBot;
  bool get canMessage => !isCurrentUser && !isBot;

  IconData get icon {
    if (isCurrentUser) return Icons.person;
    if (isBot) return Icons.smart_toy_outlined;
    return Icons.local_fire_department;
  }
}

class _ConversationThread {
  final String conversationId;
  final String otherUserId;
  final String otherName;
  final String lastText;
  final DateTime lastAt;

  const _ConversationThread({
    required this.conversationId,
    required this.otherUserId,
    required this.otherName,
    required this.lastText,
    required this.lastAt,
  });
}

class _GroupDetailsData {
  final List<_GroupMemberPerformance> members;
  final Set<String> friendIds;

  const _GroupDetailsData({required this.members, required this.friendIds});
}

class _GroupMemberPerformance {
  final String userId;
  final String name;
  final String username;
  final int calories;
  final int minutes;
  final int goalCalories;

  const _GroupMemberPerformance({
    required this.userId,
    required this.name,
    required this.username,
    required this.calories,
    required this.minutes,
    required this.goalCalories,
  });

  bool get goalMet => goalCalories > 0 && calories >= goalCalories;
}

class _GroupInviteOption {
  final String userId;
  final String name;
  final String username;

  const _GroupInviteOption({
    required this.userId,
    required this.name,
    required this.username,
  });
}

class _InviteResolution {
  final Set<String> userIds;
  final Map<String, String> usernamesById;
  final List<String> missingUsernames;

  const _InviteResolution({
    required this.userIds,
    required this.usernamesById,
    required this.missingUsernames,
  });
}

class _WeekdayLabel extends StatelessWidget {
  final String label;

  const _WeekdayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isLight
              ? ClaudePalette.lightMutedText
              : ClaudePalette.mutedText,
          fontSize: context.textSizes.s13,
        ),
      ),
    );
  }
}

class _DashboardDetailPage extends StatelessWidget {
  final String title;
  final Widget child;

  const _DashboardDetailPage({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final foreground = isLight ? ClaudePalette.charcoal : ClaudePalette.cream;

    return AppGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: foreground,
              size: context.dimensions.values.s34,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          centerTitle: true,
          title: Text(
            title,
            style: TextStyle(
              color: foreground,
              fontSize: context.textSizes.s22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: child,
      ),
    );
  }
}
