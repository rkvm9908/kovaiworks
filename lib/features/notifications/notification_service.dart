import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

String notifTitle(AppLocalizations t, String type) {
  switch (type) {
    case 'request':
      return t.notifRequest;
    case 'accepted':
      return t.notifAccepted;
    case 'rejected':
      return t.notifRejected;
    case 'paid':
      return t.notifPaid;
    default:
      return t.notifications;
  }
}

IconData notifIcon(String type) {
  switch (type) {
    case 'accepted':
      return Icons.check_circle;
    case 'rejected':
      return Icons.cancel;
    case 'paid':
      return Icons.currency_rupee;
    default:
      return Icons.work;
  }
}

Color notifColor(String type) {
  switch (type) {
    case 'accepted':
      return AppColors.success;
    case 'rejected':
      return AppColors.danger;
    case 'paid':
      return AppColors.blue;
    default:
      return AppColors.orange;
  }
}

class NotificationService {
  static Future<void> send({
    required String toUid,
    required String type,
    required String body,
  }) {
    return FirebaseFirestore.instance.collection('notifications').add({
      'toUid': toUid,
      'fromUid': FirebaseAuth.instance.currentUser!.uid,
      'type': type,
      'body': body,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

/// Header-la podura bell. Badge + live toast.
class NotifBell extends StatefulWidget {
  const NotifBell({super.key});

  @override
  State<NotifBell> createState() => _NotifBellState();
}

class _NotifBellState extends State<NotifBell> {
  StreamSubscription? _sub;
  final _alerted = <String>{};
  bool _first = true;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _sub = FirebaseFirestore.instance
        .collection('notifications')
        .where('toUid', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      setState(() => _unread = snap.docs.length);
      if (!_first) {
        for (final c in snap.docChanges) {
          if (c.type == DocumentChangeType.added && _alerted.add(c.doc.id)) {
            _toast(c.doc.data()!);
          }
        }
      }
      _first = false;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _toast(Map<String, dynamic> n) {
    final t = AppLocalizations.of(context)!;
    final type = '${n['type']}';
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.grey900,
      duration: const Duration(seconds: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: notifColor(type),
          child: Icon(notifIcon(type), color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(notifTitle(t, type),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              Text('${n['body']}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ]),
      action: SnackBarAction(
        label: t.view,
        textColor: AppColors.orange,
        onPressed: () => context.push('/notifications'),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => context.push('/notifications'),
      icon: Badge(
        isLabelVisible: _unread > 0,
        label: Text('$_unread'),
        child: const Icon(Icons.notifications, color: Colors.white),
      ),
    );
  }
}