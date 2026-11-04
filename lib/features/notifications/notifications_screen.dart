import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/empty_state.dart';
import 'notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  // Screen-ai vittu pogumbodhu ellathaiyum read-ah mark pannum
  @override
  void dispose() {
    _markRead();
    super.dispose();
  }

  Future<void> _markRead() async {
    final db = FirebaseFirestore.instance;
    final q = await db
        .collection('notifications')
        .where('toUid', isEqualTo: _uid)
        .where('read', isEqualTo: false)
        .get();
    if (q.docs.isEmpty) return;
    final batch = db.batch();
    for (final d in q.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: t.notifications,
            subtitle: t.appName,
            actions: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('toUid', isEqualTo: _uid)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) return Center(child: Text('${snap.error}'));
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs.toList()
                  ..sort((a, b) {
                    final x = a.data()['createdAt'] as Timestamp?;
                    final y = b.data()['createdAt'] as Timestamp?;
                    return (y?.millisecondsSinceEpoch ?? 1 << 50)
                        .compareTo(x?.millisecondsSinceEpoch ?? 1 << 50);
                  });
                if (docs.isEmpty) {
                  return EmptyState(
                      icon: Icons.notifications_off, message: t.noNotifs);
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final n = docs[i].data();
                    final type = '${n['type']}';
                    final unread = n['read'] != true;
                    final ts = (n['createdAt'] as Timestamp?)?.toDate();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: unread ? const Color(0xFFFFF7ED) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: unread
                                ? AppColors.orange.withOpacity(0.4)
                                : AppColors.grey200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: notifColor(type).withOpacity(0.12),
                          child: Icon(notifIcon(type), color: notifColor(type)),
                        ),
                        title: Text(notifTitle(t, type),
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${n['body']}'),
                        trailing: Text(
                          ts == null ? '' : DateFormat('dd MMM\nhh:mm a').format(ts),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.grey600),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}