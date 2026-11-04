import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/skills.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/classic_widgets.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../notifications/notification_service.dart';
import '../../payment/bill_service.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  Future<void> _completeAndPay(
      BuildContext context,
      DocumentReference<Map<String, dynamic>> ref,
      Map<String, dynamic> r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pay via UPI (test)'),
        content: Text(
            'Pay ₹${r['wagePerDay']} to worker?\n\nTest mode: no real money.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Pay')),
        ],
      ),
    );
    if (ok != true) return;

    await ref.update({
      'status': 'completed',
      'paid': true,
      'paymentMethod': 'UPI (test)',
      'paidAt': FieldValue.serverTimestamp(),
    });
    await NotificationService.send(
      toUid: r['workerId'],
      type: 'paid',
      body: '₹${r['wagePerDay']} • ${r['businessName']}',
    );
    if (!context.mounted) return;
    _rateDialog(context, ref);
  }

  void _rateDialog(
      BuildContext context, DocumentReference<Map<String, dynamic>> ref) {
    final t = AppLocalizations.of(context)!;
    int stars = 5;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(t.rateWorker),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (i) => IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (c, a) =>
                      ScaleTransition(scale: a, child: c),
                  child: Icon(
                      i < stars ? Icons.star : Icons.star_border,
                      key: ValueKey(i < stars),
                      color: AppColors.gold,
                      size: 34),
                ),
                onPressed: () => setS(() => stars = i + 1),
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () async {
                await ref.update({'rating': stars});
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(t.submit),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: Column(
        children: [
          ClassicHeader(
            title: t.myRequests,
            subtitle: t.appName,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .where('ownerId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) return Center(child: Text('${snap.error}'));
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return EmptyState(icon: Icons.inbox, message: t.noRequests);
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final r = docs[i].data();
                    final skill =
                        allSkills.firstWhere((s) => s.id == r['skillId']);
                    final status = r['status'] as String;
                    final rejected = status == 'rejected';
                    final step = status == 'completed'
                        ? 2
                        : status == 'accepted'
                            ? 1
                            : 0;
                    final accent = rejected
                        ? AppColors.danger
                        : status == 'pending'
                            ? AppColors.gold
                            : AppColors.success;

                    return FadeSlide(
                      index: i,
                      child: ClassicCard(
                        accent: accent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(lang == 'ta' ? skill.ta : skill.en,
                                    style: serif(context, size: 18)),
                              ),
                              Text('₹${r['wagePerDay']}',
                                  style: serif(context,
                                      size: 20,
                                      weight: FontWeight.w800,
                                      color: AppColors.orangeDark)),
                            ]),
                            const SizedBox(height: 2),
                            Text('${r['area']}',
                                style: const TextStyle(
                                    color: AppColors.grey600, fontSize: 13)),
                            const SizedBox(height: 14),
                            if (rejected)
                              Row(children: [
                                const Icon(Icons.cancel,
                                    color: AppColors.danger, size: 18),
                                const SizedBox(width: 6),
                                Text(t.rejected,
                                    style: const TextStyle(
                                        color: AppColors.danger,
                                        fontWeight: FontWeight.w700)),
                              ])
                            else
                              StatusTimeline(
                                steps: [t.stepRequested, t.accepted, t.paid],
                                current: step,
                              ),
                            if (r['rating'] != null) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: List.generate(
                                  5,
                                  (k) => Icon(
                                      k < (r['rating'] as num)
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: AppColors.gold,
                                      size: 18),
                                ),
                              ),
                            ],
                            if (status == 'accepted' ||
                                status == 'completed') ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.chat, size: 18),
                                    label: Text(t.chat),
                                    onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => ChatScreen(
                                                requestId: docs[i].id))),
                                  ),
                                  if (status == 'accepted') ...[
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.location_on,
                                          size: 18),
                                      label: Text(t.trackWorker),
                                      onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => TrackingScreen(
                                                  workerId: r['workerId']))),
                                    ),
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                          minimumSize: const Size(0, 40)),
                                      icon: const Icon(Icons.currency_rupee,
                                          size: 18),
                                      label: Text(t.completePay),
                                      onPressed: () => _completeAndPay(
                                          context, docs[i].reference, r),
                                    ),
                                  ],
                                  if (status == 'completed')
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.receipt_long,
                                          size: 18),
                                      label: Text(t.bill),
                                      onPressed: () =>
                                          BillService.show(docs[i].id, r),
                                    ),
                                ],
                              ),
                            ],
                          ],
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

class TrackingScreen extends StatelessWidget {
  final String workerId;
  const TrackingScreen({super.key, required this.workerId});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.trackWorker)),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(workerId)
            .snapshots(),
        builder: (context, snap) {
          final gp = snap.data?.data()?['location'] as GeoPoint?;
          if (gp == null) {
            return Center(child: Text(t.noWorkersNearby));
          }
          final p = LatLng(gp.latitude, gp.longitude);
          return FlutterMap(
            key: ValueKey('${p.latitude}${p.longitude}'),
            options: MapOptions(initialCenter: p, initialZoom: 15),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.kovaiworks.kovaiworks',
              ),
              MarkerLayer(markers: [
                Marker(
                  point: p,
                  width: 48,
                  height: 48,
                  child: const Icon(Icons.location_pin,
                      color: AppColors.orange, size: 44),
                ),
              ]),
              const RichAttributionWidget(attributions: [
                TextSourceAttribution('© OpenStreetMap contributors'),
              ]),
            ],
          );
        },
      ),
    );
  }
}