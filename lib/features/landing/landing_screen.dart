import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final user = await FirebaseAuth.instance.authStateChanges().first;
      if (user != null) {
        final d = (await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get())
            .data();
        if (d != null && mounted) {
          final done = d['profileDone'] == true;
          final w = d['role'] == 'worker';
          context.go(w
              ? (done ? '/worker-home' : '/worker-setup')
              : (done ? '/owner-home' : '/owner-setup'));
          return;
        }
      }
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('seenOnboarding') != true && mounted) {
        context.go('/onboarding');
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _checking = false);
  }

  Widget _cta(String label, IconData icon, bool filled, VoidCallback onTap) {
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(label)],
    );
    return SizedBox(
      height: 54,
      child: filled
          ? FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.orangeDark,
                  shape: shape),
              onPressed: onTap,
              child: child)
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 1.5),
                  shape: shape),
              onPressed: onTap,
              child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final t = AppLocalizations.of(context)!;
    final isTa = Localizations.localeOf(context).languageCode == 'ta';

    final features = [
      (Icons.location_on, t.onb1Title, t.onb1Desc, AppColors.orange),
      (Icons.verified_user, t.onb2Title, t.onb2Desc, AppColors.blue),
      (Icons.currency_rupee, t.onb3Title, t.onb3Desc, AppColors.success),
    ];
    final steps = [t.how1, t.how2, t.how3];

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                  24, MediaQuery.of(context).padding.top + 16, 24, 48),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.orange, AppColors.orangeDark, Color(0xFFC2410C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(36)),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.factory_rounded,
                              color: Colors.white, size: 30),
                          const SizedBox(width: 8),
                          Text(t.appName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                          const Spacer(),
                          TextButton(
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.white24),
                            onPressed: () => ref
                                .read(localeProvider.notifier)
                                .setLocale(isTa ? 'en' : 'ta'),
                            child: Text(isTa ? 'English' : 'தமிழ்'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Text(t.tagline,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              height: 1.15,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      Text(t.heroSub,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              height: 1.5)),
                      const SizedBox(height: 28),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _cta(t.iAmWorker, Icons.engineering_rounded, true,
                              () => context.go('/login?role=worker')),
                          _cta(t.iAmOwner, Icons.factory_rounded, false,
                              () => context.go('/login?role=owner')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Features
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: features
                        .map((f) => Container(
                              width: 270,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4))
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: f.$4.withOpacity(0.12),
                                    child: Icon(f.$1, color: f.$4),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(f.$2,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(f.$3,
                                      style: const TextStyle(
                                          color: AppColors.grey600)),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),

            // How it works
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.howItWorks,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      ...List.generate(
                        steps.length,
                        (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.orange,
                              child: Text('${i + 1}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(steps[i],
                                    style: const TextStyle(fontSize: 15))),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            Text(t.madeInKovai,
                style: const TextStyle(color: AppColors.grey600)),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}