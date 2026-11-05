import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/skills.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/classic_widgets.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../payment/bill_service.dart';

class MyWorkScreen extends StatelessWidget {
  const MyWorkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: Column(
        children: [
          ClassicHeader(
            title: t.myWork,
            subtitle: t.appName,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/worker-home');
                }
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .where('workerId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) return Center(child: Text('${snap.error}'));
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs.where((d) {
                  final s = d.data()['status'];
                  return s == 'accepted' ||
                      s == 'completed' ||
                      (s == 'pending' && d.data()['initiatedBy'] == 'worker');
                }).toList();
                if (docs.isEmpty) {
                  return EmptyState(
                      icon: Icons.work_history, message: t.noWork);
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final r = docs[i].data();
                    final skill =
                        allSkills.firstWhere((s) => s.id == r['skillId']);
                    final status = r['status'] as String;
                    final done = status == 'completed';
                    final pending = status == 'pending';
                    return FadeSlide(
                      index: i,
                      child: ClassicCard(
                        accent: done ? AppColors.success : AppColors.gold,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(lang == 'ta' ? skill.ta : skill.en,
                                        style: serif(context, size: 18)),
                                    Text('${r['businessName']} • ${r['area']}',
                                        style: const TextStyle(
                                            color: AppColors.grey600,
                                            fontSize: 13)),
                                  ],
                                ),
                              ),
                              Text('₹${r['wagePerDay']}',
                                  style: serif(context,
                                      size: 22,
                                      weight: FontWeight.w800,
                                      color: AppColors.orangeDark)),
                            ]),
                            const SizedBox(height: 14),
                            StatusTimeline(
                              steps: [t.stepRequested, t.accepted, t.paid],
                              current: done ? 2 : (pending ? 0 : 1),
                            ),
                            if (pending) ...[
                              const SizedBox(height: 8),
                              Text(t.awaitingOwner,
                                  style: const TextStyle(
                                      color: AppColors.grey600,
                                      fontSize: 12)),
                            ],
                            if (r['rating'] != null) ...[
                              const SizedBox(height: 10),
                              Row(children: [
                                Text('${t.yourRating}: ',
                                    style: const TextStyle(fontSize: 13)),
                                ...List.generate(
                                  5,
                                  (k) => Icon(
                                      k < (r['rating'] as num)
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: AppColors.gold,
                                      size: 18),
                                ),
                              ]),
                            ],
                            if (!pending) ...[
                              const SizedBox(height: 12),
                              Wrap(spacing: 8, runSpacing: 8, children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.chat, size: 18),
                                  label: Text(t.chat),
                                  onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => ChatScreen(
                                              requestId: docs[i].id))),
                                ),
                                if (done)
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.receipt_long,
                                        size: 18),
                                    label: Text(t.bill),
                                    onPressed: () =>
                                        BillService.show(docs[i].id, r),
                                  ),
                              ]),
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