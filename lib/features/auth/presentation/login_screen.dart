import 'dart:async';
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
          // Gradient header
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
                  onPressed: () =>
                      otpStep ? setState(() {
                        _confirmation = null;
                        _otpCtrl.clear();
                        _error = null;
                      }) : context.go('/'),
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

          // Form card
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
                              prefixIcon: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('🇮🇳', style: TextStyle(fontSize: 18)),
                                    SizedBox(width: 6),
                                    Text('+91',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
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
                                  border:
                                      Border.all(color: _color, width: 2)),
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