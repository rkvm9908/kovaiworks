import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../data/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _repo = AuthRepository();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  ConfirmationResult? _confirmation;
  bool _loading = false;
  String? _error;
  int _secs = 0;
  Timer? _timer;

  bool get _isWorker => widget.role == 'worker';
  Color get _color => _isWorker ? AppColors.orange : AppColors.blue;
  String get _demo => _isWorker ? '9999900001' : '9999900002';

  @override
  void dispose() {
    _timer?.cancel();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secs = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (tm) {
      if (!mounted) return tm.cancel();
      setState(() => _secs--);
      if (_secs <= 0) tm.cancel();
    });
  }

  Future<void> _goHome(String role) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final done = doc.data()?['profileDone'] == true;
    if (!mounted) return;
    if (role == 'worker') {
      context.go(done ? '/worker-home' : '/worker-setup');
    } else {
      context.go(done ? '/owner-home' : '/owner-setup');
    }
  }

  Future<void> _askPhoneIfMissing() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseFirestore.instance.collection('users').doc(uid);
    final phone = ((await ref.get()).data()?['phone'] ?? '').toString();
    if (phone.isNotEmpty || !mounted) return;

    final t = AppLocalizations.of(context)!;
    final ctrl = TextEditingController();
    String? err;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(t.enterMobileTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.enterMobileDesc,
                    style: const TextStyle(color: AppColors.grey600)),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: t.phoneLabel,
                    prefixText: '+91  ',
                    counterText: '',
                    errorText: err,
                  ),
                ),
              ],
            ),
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: _color,
                    minimumSize: const Size.fromHeight(48)),
                onPressed: () async {
                  final v = ctrl.text.trim();
                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) {
                    setS(() => err = t.invalidPhone);
                    return;
                  }
                  await ref.update({'phone': '+91$v'});
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(t.saveNumber),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _google() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final role = await _repo.signInWithGoogle(widget.role);
      await _askPhoneIfMissing();
      await _goHome(role);
    } on FirebaseAuthException catch (e) {
      debugPrint('GOOGLE ERROR: ${e.code} | ${e.message}');
      if (e.code != 'popup-closed-by-user' &&
          e.code != 'cancelled-popup-request' &&
          e.code != 'canceled') {
        setState(() => _error = e.code);
      }
    } catch (e) {
      debugPrint('GOOGLE ERROR: $e');
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendOtp() async {
    final t = AppLocalizations.of(context)!;
    final phone = _phoneCtrl.text.trim();
    if (phone.length != 10) {
      setState(() => _error = t.invalidPhone);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repo.sendOtp(phone);
      setState(() => _confirmation = result);
      _startTimer();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? e.code);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    final t = AppLocalizations.of(context)!;
    final code = _otpCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = t.invalidOtp);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final role = await _repo.verifyOtp(_confirmation!, code, widget.role);
      await _goHome(role);
    } on FirebaseAuthException catch (e) {
      _otpCtrl.clear();
      setState(() => _error = e.code == 'invalid-verification-code'
          ? t.wrongOtp
          : (e.message ?? e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final otpStep = _confirmation != null;
    final gradient = _isWorker
        ? const [AppColors.orange, AppColors.orangeDark]
        : const [AppColors.blue, Color(0xFF1E3A8A)];

    final pin = PinTheme(
      width: 46,
      height: 56,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
    );

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                8, MediaQuery.of(context).padding.top + 4, 20, 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => otpStep
                      ? setState(() {
                          _confirmation = null;
                          _otpCtrl.clear();
                          _error = null;
                        })
                      : context.go('/'),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: Icon(
                            _isWorker
                                ? Icons.engineering_rounded
                                : Icons.factory_rounded,
                            color: gradient.first,
                            size: 30),
                      ),
                      const SizedBox(height: 14),
                      Text(_isWorker ? t.welcomeWorker : t.welcomeEmployer,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(t.tagline,
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 20,
                            offset: const Offset(0, 6))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(otpStep ? t.enterOtp : t.loginTitle,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(
                          otpStep
                              ? '${t.otpSentTo} +91 ${_phoneCtrl.text}'
                              : t.loginDesc,
                          style: const TextStyle(color: AppColors.grey600),
                        ),
                        const SizedBox(height: 22),
                        if (!otpStep) ...[
                          TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            style: const TextStyle(
                                fontSize: 18,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w600),
                            onSubmitted: (_) => _sendOtp(),
                            decoration: InputDecoration(
                              labelText: t.phoneLabel,
                              counterText: '',
                              prefixText: '+91  ',
                            ),
                          ),
                          const SizedBox(height: 8),
                          ActionChip(
                            avatar: const Icon(Icons.bolt, size: 18),
                            label: Text('${t.demoHint}: $_demo'),
                            onPressed: () =>
                                setState(() => _phoneCtrl.text = _demo),
                          ),
                        ] else ...[
                          Center(
                            child: Pinput(
                              length: 6,
                              controller: _otpCtrl,
                              autofocus: true,
                              defaultPinTheme: pin,
                              focusedPinTheme: pin.copyDecorationWith(
                                  border: Border.all(color: _color, width: 2)),
                              onCompleted: (_) => _verify(),
                            ),
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Row(children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.danger, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(
                                      color: AppColors.danger)),
                            ),
                          ]),
                        ],
                        const SizedBox(height: 22),
                        FilledButton(
                          style:
                              FilledButton.styleFrom(backgroundColor: _color),
                          onPressed:
                              _loading ? null : (otpStep ? _verify : _sendOtp),
                          child: _loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text(otpStep ? t.verify : t.sendOtp),
                        ),
                        if (otpStep) ...[
                          const SizedBox(height: 8),
                          Center(
                            child: _secs > 0
                                ? Text('${t.resendIn} ${_secs}s',
                                    style: const TextStyle(
                                        color: AppColors.grey600))
                                : TextButton(
                                    onPressed: _loading ? null : _sendOtp,
                                    child: Text(t.resend)),
                          ),
                        ],
                        if (!otpStep) ...[
                          const SizedBox(height: 18),
                          Row(children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(t.orLabel,
                                  style: const TextStyle(
                                      color: AppColors.grey600)),
                            ),
                            const Expanded(child: Divider()),
                          ]),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: _color,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _loading ? null : _google,
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const _GoogleLogo(size: 18),
                            ),
                            label: Text(t.continueGoogle),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  final double size;
  const _GoogleLogo({this.size = 22});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final stroke = s.width * 0.2;
    final rect = Rect.fromLTWH(
        stroke / 2, stroke / 2, s.width - stroke, s.height - stroke);

    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(rect, 0, math.pi * 0.5, false, arc(const Color(0xFF4285F4)));
    canvas.drawArc(
        rect, math.pi * 0.5, math.pi * 0.5, false, arc(const Color(0xFF34A853)));
    canvas.drawArc(
        rect, math.pi, math.pi * 0.5, false, arc(const Color(0xFFFBBC05)));
    canvas.drawArc(
        rect, math.pi * 1.5, math.pi * 0.4, false, arc(const Color(0xFFEA4335)));

    final bar = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
        Rect.fromLTWH(
            s.width * 0.5, s.height * 0.42, s.width * 0.45, stroke * 0.95),
        bar);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}