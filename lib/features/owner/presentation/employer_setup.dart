import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/areas.dart';
import '../../../l10n/app_localizations.dart';

class EmployerSetup extends StatefulWidget {
  const EmployerSetup({super.key});

  @override
  State<EmployerSetup> createState() => _EmployerSetupState();
}

class _EmployerSetupState extends State<EmployerSetup> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bizCtrl = TextEditingController();
  String _area = kovaiAreas.first;
  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'name': _nameCtrl.text.trim(),
      'businessName': _bizCtrl.text.trim(),
      'area': _area,
      'profileDone': true,
    });
    if (mounted) context.go('/owner-home');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    String? req(String? v) =>
        (v == null || v.trim().isEmpty) ? t.required : null;
    return Scaffold(
      appBar: AppBar(title: Text(t.employerSetup)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: t.fullName),
                validator: req),
            const SizedBox(height: 16),
            TextFormField(
                controller: _bizCtrl,
                decoration: InputDecoration(labelText: t.businessName),
                validator: req),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _area,
              decoration: InputDecoration(labelText: t.selectArea),
              items: kovaiAreas
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) => setState(() => _area = v!),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(t.saveContinue),
            ),
          ],
        ),
      ),
    );
  }
}