import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/user_avatar.dart';

class ChatScreen extends StatefulWidget {
  final String requestId;
  const ChatScreen({super.key, required this.requestId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  String? _otherId;

  static const _bgColor = Color(0xFFFFF3E6);

  DocumentReference<Map<String, dynamic>> get _reqRef => FirebaseFirestore
      .instance
      .collection('requests')
      .doc(widget.requestId);

  CollectionReference<Map<String, dynamic>> get _col =>
      _reqRef.collection('messages');

  @override
  void initState() {
    super.initState();
    _loadOther();
  }

  Future<void> _loadOther() async {
    final r = (await _reqRef.get()).data();
    if (r == null) return;
    final other = r['ownerId'] == _uid ? r['workerId'] : r['ownerId'];
    if (mounted) setState(() => _otherId = other as String);
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    await _col.add({
      'senderId': _uid,
      'text': text,
      'seen': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Ethirla irukkaravanga anuppina unseen messages-ah seen-ah mark pannu
  void _markSeen(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final unseen = docs.where((d) {
      final m = d.data();
      return m['senderId'] != _uid && m['seen'] != true;
    }).toList();
    if (unseen.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final d in unseen) {
      batch.update(d.reference, {'seen': true});
    }
    batch.commit();
  }

  String _dayLabel(DateTime d, AppLocalizations t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return t.today;
    if (diff == 1) return t.yesterday;
    return DateFormat('dd MMM yyyy').format(d);
  }

  Widget _appBarTitle(AppLocalizations t) {
    if (_otherId == null) return Text(t.chat);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_otherId)
          .snapshots(),
      builder: (context, snap) {
        final u = snap.data?.data() ?? {};
        final isWorker = u['role'] == 'worker';
        final name = (isWorker ? u['name'] : u['businessName']) ??
            u['name'] ??
            '...';
        final online = isWorker ? u['available'] == true : false;
        return Row(
          children: [
            UserAvatar(photoBase64: u['photoBase64'], radius: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$name',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  if (isWorker)
                    Text(online ? t.online : t.offline,
                        style: TextStyle(
                            fontSize: 12,
                            color: online
                                ? AppColors.success
                                : AppColors.grey600)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _bubble(Map<String, dynamic> m, bool mine) {
    final ts = (m['createdAt'] as Timestamp?)?.toDate();
    final time = ts == null ? '' : DateFormat('hh:mm a').format(ts);
    final seen = m['seen'] == true;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.fromLTRB(12, 8, 10, 6),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFFFFE0C2) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(mine ? 14 : 2),
            bottomRight: Radius.circular(mine ? 2 : 14),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 3,
                offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(m['text'] ?? '',
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.grey900)),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(time,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.grey600)),
                if (mine) ...[
                  const SizedBox(width: 3),
                  Icon(
                    ts == null ? Icons.access_time : Icons.done_all,
                    size: 15,
                    color: seen ? Colors.blue : AppColors.grey600,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayChip(String label) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey600)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _appBarTitle(t),
      ),
      body: Container(
        color: _bgColor,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _col
                    .orderBy('createdAt', descending: true)
                    .limit(100)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(child: Text('${snap.error}'));
                  }
                  final docs = snap.data?.docs ?? [];
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _markSeen(docs));

                  if (docs.isEmpty) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(t.sayHi),
                      ),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final m = docs[i].data();
                      final mine = m['senderId'] == _uid;
                      final ts = (m['createdAt'] as Timestamp?)?.toDate();

                      // reverse list: i+1 = pazhaya message
                      bool showDay = false;
                      if (ts != null) {
                        if (i == docs.length - 1) {
                          showDay = true;
                        } else {
                          final prev = (docs[i + 1].data()['createdAt']
                                  as Timestamp?)
                              ?.toDate();
                          showDay = prev == null ||
                              prev.day != ts.day ||
                              prev.month != ts.month ||
                              prev.year != ts.year;
                        }
                      }
                      return Column(
                        children: [
                          if (showDay) _dayChip(_dayLabel(ts!, t)),
                          _bubble(m, mine),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // Input bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _ctrl,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: t.typeMessage,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.orange,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _send,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}