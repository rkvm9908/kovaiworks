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
import '../data/location_service.dart';

class WorkerHome extends StatefulWidget {
  const WorkerHome({super.key});

  @override
  State<WorkerHome> createState() => _WorkerHomeState();
}

class _WorkerHomeState extends State<WorkerHome> {
  final _loc = LocationService();
  bool _sharing = false;

  @override
  void dispose() {
    _loc.stop();
    super.dispose();
  }

  Future<void> _toggleShare(bool v) async {
    final t = AppLocalizations.of(context)!;
    if (v) {
      final ok = await _loc.start();
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(t.locationDenied)));
        }
        return;
      }
    } else {
      _loc.stop();
    }
    if (mounted) setState(() => _sharing = v);
  }

  Future<void> _respond(
      QueryDocumentSnapshot<Map<String, dynamic>> d, String status) async {
    final r = d.data();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await d.reference.update({'status': status});
    final me =
        (await FirebaseFirestore.instance.collection('users').doc(uid).get())
            .data();
    await NotificationService.send(
      toUid: r['ownerId'],
      type: status,
      body: '${me?['name'] ?? ''}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    return Scaffold(
      body: Column(
        children: [
          ClassicHeader(
            title: t.appName,
            subtitle: t.tagline,
            actions: [
              const NotifBell(),
              IconButton(
                  icon: const Icon(Icons.account_circle, color: Colors.white),
                  onPressed: () => context.push('/profile')),
              IconButton(
                  icon: const Icon(Icons.work_history, color: Colors.white),
                  onPressed: () => context.push('/my-work')),
              IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () => context.push('/settings')),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  _loc.stop();
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) context.go('/');
                },
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              children: [
                // Availability (animated)
                FadeSlide(
                  index: 0,
                  child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: userRef.snapshots(),
                    builder: (context, snap) {
                      final on = snap.data?.data()?['available'] == true;
                      final colors = on
                          ? const [Color(0xFF16A34A), Color(0xFF166534)]
                          : const [Color(0xFF9CA3AF), Color(0xFF4B5563)];
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: colors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                                color: colors.first.withOpacity(0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 8)),
                          ],
                        ),
                        child: Row(children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 450),
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: on ? Colors.white : Colors.white38,
                              boxShadow: on
                                  ? [
                                      BoxShadow(
                                          color: Colors.white.withOpacity(0.7),
                                          blurRadius: 10,
                                          spreadRadius: 2)
                                    ]
                                  : [],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.youAre,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Text(on ? t.available : t.busy,
                                      key: ValueKey(on),
                                      style: serif(context,
                                          size: 24,
                                          weight: FontWeight.w800,
                                          color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: on,
                            activeColor: Colors.white,
                            activeTrackColor: Colors.white38,
                            onChanged: (v) => userRef.update({'available': v}),
                          ),
                        ]),
                      );
                    },
                  ),
                ),

                // Location
                FadeSlide(
                  index: 1,
                  child: ClassicCard(
                    accent: AppColors.blue,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary:
                          const Icon(Icons.my_location, color: AppColors.blue),
                      title: Text(t.shareLocation,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: _sharing ? Text(t.locationOn) : null,
                      value: _sharing,
                      onChanged: _toggleShare,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Requests
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('requests')
                      .where('workerId', isEqualTo: uid)
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.hasError) return Text('${snap.error}');
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionTitle(
                            t.jobRequests, Icons.notifications_active),
                        ...docs.asMap().entries.map((e) {
                          final d = e.value;
                          final r = d.data();
                          final skill = allSkills
                              .firstWhere((s) => s.id == r['skillId']);
                          return ClassicJobCard(
                            index: e.key + 2,
                            isEvent: skill.category == JobCategory.event,
                            title: lang == 'ta' ? skill.ta : skill.en,
                            business: '${r['businessName']}',
                            area: '${r['area']}',
                            wage: (r['wagePerDay'] as num).toInt(),
                            wageLabel: t.perDay,
                            workersText: t.jobRequests,
                            footer: Row(children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(46)),
                                  onPressed: () => _respond(d, 'rejected'),
                                  child: Text(t.reject),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.success),
                                  onPressed: () => _respond(d, 'accepted'),
                                  child: Text(t.accept),
                                ),
                              ),
                            ]),
                          );
                        }),
                        const SizedBox(height: 6),
                      ],
                    );
                  },
                ),

                // Open jobs
                SectionTitle(t.openJobs, Icons.work_outline),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('jobs')
                      .where('status', isEqualTo: 'open')
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
                          index: e.key + 3,
                          isEvent: j['category'] == 'event',
                          title: lang == 'ta' ? skill.ta : skill.en,
                          business: '${j['businessName']}',
                          area: '${j['area']}',
                          wage: (j['wagePerDay'] as num).toInt(),
                          wageLabel: t.perDay,
                          workersText:
                              '${j['workersNeeded']} ${t.workersLabel}',
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
    );
  }
}