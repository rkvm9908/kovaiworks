import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../l10n/app_localizations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pc = PageController();
  late final AnimationController _ctrl;
  int _page = 0;

  static const _gradients = [
    [Color(0xFFF97316), Color(0xFFC2410C)], // orange
    [Color(0xFF1E40AF), Color(0xFF1E3A8A)], // blue
    [Color(0xFF16A34A), Color(0xFF166534)], // green
  ];
  static const _icons = [
    Icons.factory_rounded,
    Icons.verified_user_rounded,
    Icons.currency_rupee_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _pc.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    if (mounted) context.go('/');
  }

  void _next() {
    if (_page == 2) {
      _finish();
    } else {
      _pc.nextPage(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic);
    }
  }

  Widget _hero(int i) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final float = math.sin(_ctrl.value * 2 * math.pi) * 8;
        return SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ripple rings
              for (var k = 0; k < 3; k++)
                Builder(builder: (_) {
                  final phase = (_ctrl.value + k / 3) % 1;
                  return Container(
                    width: 150 + phase * 150,
                    height: 150 + phase * 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white
                              .withOpacity((1 - phase) * 0.35),
                          width: 2),
                    ),
                  );
                }),
              // floating icon card
              Transform.translate(
                offset: Offset(0, float),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 30,
                          offset: const Offset(0, 14)),
                    ],
                  ),
                  child: Icon(_icons[i], size: 78, color: _gradients[i][0]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isTa = Localizations.localeOf(context).languageCode == 'ta';
    final titles = [t.onb1Title, t.onb2Title, t.onb3Title];
    final descs = [t.onb1Desc, t.onb2Desc, t.onb3Desc];
    final last = _page == 2;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _gradients[_page],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // top bar: language + skip
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                child: Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white24),
                      onPressed: () => ref
                          .read(localeProvider.notifier)
                          .setLocale(isTa ? 'en' : 'ta'),
                      child: Text(isTa ? 'English' : 'தமிழ்'),
                    ),
                    const Spacer(),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: last ? 0 : 1,
                      child: TextButton(
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.white),
                        onPressed: last ? null : _finish,
                        child: Text(t.skip),
                      ),
                    ),
                  ],
                ),
              ),

              // pages
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  itemCount: 3,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) {
                    return AnimatedBuilder(
                      animation: _pc,
                      builder: (_, __) {
                        final current =
                            _pc.hasClients ? (_pc.page ?? 0.0) : 0.0;
                        final delta = (current - i).clamp(-1.0, 1.0);
                        final opacity = 1 - delta.abs();
                        return Opacity(
                          opacity: opacity,
                          child: Transform.translate(
                            offset: Offset(-delta * 80, 0),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _hero(i),
                                  const SizedBox(height: 24),
                                  Transform.translate(
                                    offset: Offset(-delta * 40, 0),
                                    child: Text(
                                      titles[i],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 30,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 420),
                                    child: Text(
                                      descs[i],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                          height: 1.5),
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
                ),
              ),

              // dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.all(4),
                    width: _page == i ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _page == i ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              // button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _gradients[_page][0],
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _next,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Row(
                            key: ValueKey(last),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(last ? t.getStarted : t.next),
                              const SizedBox(width: 8),
                              Icon(
                                  last
                                      ? Icons.rocket_launch_rounded
                                      : Icons.arrow_forward_rounded,
                                  size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}