import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'app_widgets.dart';

/// Serif heading style (Tamil-ku Noto Serif Tamil)
TextStyle serif(BuildContext context,
    {double size = 20, FontWeight weight = FontWeight.w700, Color? color}) {
  final ta = Localizations.localeOf(context).languageCode == 'ta';
  final c = color ?? AppColors.ink;
  if (ta) {
    return GoogleFonts.notoSerifTamil(
        fontSize: size, fontWeight: weight, color: c);
  }
  return GoogleFonts.playfairDisplay(
      fontSize: size, fontWeight: weight, color: c);
}

/// Staggered fade + slide-up entry
class FadeSlide extends StatefulWidget {
  final Widget child;
  final int index;
  const FadeSlide({super.key, required this.child, this.index = 0});

  @override
  State<FadeSlide> createState() => _FadeSlideState();
}

class _FadeSlideState extends State<FadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));
  late final Animation<double> _a =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(Duration(milliseconds: math.min(widget.index, 8) * 70), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
            .animate(_a),
        child: widget.child,
      ),
    );
  }
}

/// Tap pannumbodhu konjam chinnadhaagum
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const Pressable({super.key, required this.child, this.onTap});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

/// Classical header: gradient + decorative circles + gold rule
class ClassicHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? leading;
  final List<Widget> actions;
  const ClassicHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.leading,
    this.actions = const [],
  });

  Widget _circle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(opacity)),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFC2410C), Color(0xFF7C2D12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Stack(
        children: [
          Positioned(right: -30, top: -30, child: _circle(160, 0.08)),
          Positioned(left: -24, bottom: -44, child: _circle(120, 0.07)),
          Padding(
            padding: EdgeInsets.fromLTRB(
                12, MediaQuery.of(context).padding.top + 8, 12, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (leading != null) leading!,
                    Expanded(
                      child: Wrap(
                          alignment: WrapAlignment.end, children: actions),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: serif(context,
                              size: 28,
                              weight: FontWeight.w800,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 10),
                      Container(
                          width: 48,
                          height: 3,
                          decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(2))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Section title with gold rule
class SectionTitle extends StatelessWidget {
  final String text;
  final IconData icon;
  const SectionTitle(this.text, this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(children: [
        Icon(icon, color: AppColors.gold, size: 20),
        const SizedBox(width: 8),
        Text(text, style: serif(context, size: 20)),
        const SizedBox(width: 12),
        Expanded(
            child: Container(
                height: 1, color: AppColors.gold.withOpacity(0.45))),
      ]),
    );
  }
}

/// White card, gold hairline border, colored left stripe
class ClassicCard extends StatelessWidget {
  final Widget child;
  final Color accent;
  final EdgeInsets padding;
  const ClassicCard({
    super.key,
    required this.child,
    this.accent = AppColors.orange,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF2B2118).withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: accent),
              Expanded(child: Padding(padding: padding, child: child)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Requested -> Accepted -> Paid timeline
class StatusTimeline extends StatelessWidget {
  final List<String> steps;
  final int current; // 0-based, index varai fill aagum
  final Color color;
  const StatusTimeline({
    super.key,
    required this.steps,
    required this.current,
    this.color = AppColors.success,
  });

  @override
  Widget build(BuildContext context) {
    Widget dot(int i) {
      final done = i <= current;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? color : Colors.white,
          border: Border.all(color: done ? color : AppColors.grey200, width: 2),
        ),
        child: done
            ? const Icon(Icons.check, size: 14, color: Colors.white)
            : null,
      );
    }

    return Column(
      children: [
        Row(children: [
          for (var i = 0; i < steps.length; i++) ...[
            dot(i),
            if (i < steps.length - 1)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: 3,
                  color: i < current ? color : AppColors.grey200,
                ),
              ),
          ],
        ]),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: steps
              .map((s) => Text(s,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.grey600)))
              .toList(),
        ),
      ],
    );
  }
}

/// Animated job card (classic)
class ClassicJobCard extends StatelessWidget {
  final bool isEvent;
  final String title, business, area, wageLabel, workersText;
  final int wage;
  final Widget? footer;
  final int index;
  const ClassicJobCard({
    super.key,
    required this.isEvent,
    required this.title,
    required this.business,
    required this.area,
    required this.wage,
    required this.wageLabel,
    required this.workersText,
    this.footer,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = isEvent ? Colors.purple : AppColors.blue;
    return FadeSlide(
      index: index,
      child: ClassicCard(
        accent: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.1),
                  border: Border.all(color: AppColors.gold.withOpacity(0.6)),
                ),
                child: Icon(isEvent ? Icons.celebration : Icons.factory,
                    color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: serif(context, size: 17)),
                    if (business.isNotEmpty)
                      Text(business,
                          style: const TextStyle(
                              color: AppColors.grey600, fontSize: 12.5)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹$wage',
                      style: serif(context,
                          size: 22,
                          weight: FontWeight.w800,
                          color: AppColors.orangeDark)),
                  Text(wageLabel,
                      style: const TextStyle(
                          fontSize: 10.5, color: AppColors.grey600)),
                ],
              ),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 6, children: [
              Pill(area, icon: Icons.location_on, color: AppColors.blue),
              Pill(workersText, icon: Icons.groups, color: AppColors.grey600),
            ]),
            if (footer != null) ...[const SizedBox(height: 12), footer!],
          ],
        ),
      ),
    );
  }
}