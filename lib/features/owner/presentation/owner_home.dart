import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/skills.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/classic_widgets.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../notifications/notification_service.dart';

class OwnerHome extends StatelessWidget {
  const OwnerHome({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: Column(
        children: [
          ClassicHeader(
            title: t.appName,
            subtitle: t.myJobs,
            actions: [
              const NotifBell(),
              IconButton(
                  icon: const Icon(Icons.account_circle, color: Colors.white),
                  onPressed: () => context.push('/owner-profile')),
              IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () => context.push('/settings')),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) context.go('/');
                },
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              children: [
                FadeSlide(
                  index: 0,
                  child: Row(children: [
                    _Tile(Icons.map_outlined, t.findWorkers, AppColors.orange,
                        '/nearby'),
                    const SizedBox(width: 12),
                    _Tile(Icons.inbox_outlined, t.myRequests, AppColors.blue,
                        '/requests'),
                  ]),
                ),
                const SizedBox(height: 22),
                SectionTitle(t.myJobs, Icons.work_outline),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('jobs')
                      .where('ownerId', isEqualTo: uid)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.hasError) return Text('${snap.error}');
                    if (!snap.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final docs = snap.data!.docs;
                    if (docs.isEmpty) {
                      return SizedBox(
                        height: 260,
                        child: EmptyState(
                            icon: Icons.work_off, message: t.emptyJobs),
                      );
                    }
                    return Column(
                      children: docs.asMap().entries.map((e) {
                        final j = e.value.data();
                        final skill =
                            allSkills.firstWhere((s) => s.id == j['skillId']);
                        return ClassicJobCard(
                          index: e.key + 1,
                          isEvent: j['category'] == 'event',
                          title: lang == 'ta' ? skill.ta : skill.en,
                          business: '',
                          area: '${j['area']}',
                          wage: (j['wagePerDay'] as num).toInt(),
                          wageLabel: t.perDay,
                          workersText:
                              '${j['workersNeeded']} ${t.workersLabel}',
                          footer: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.danger, size: 18),
                              label: const Text('Delete',
                                  style: TextStyle(color: AppColors.danger)),
                              onPressed: () => e.value.reference.delete(),
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.gold,
        onPressed: () => context.push('/post-job'),
        icon: const Icon(Icons.add),
        label: Text(t.postJob,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  const _Tile(this.icon, this.label, this.color, this.route);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Pressable(
        onTap: () => context.push(route),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gold.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Column(children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(label,
                textAlign: TextAlign.center,
                style: serif(context, size: 15)),
          ]),
        ),
      ),
    );
  }
}