import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/areas.dart';
import '../../../core/constants/skills.dart';
import '../../../l10n/app_localizations.dart';

class WorkerProfileSetup extends StatefulWidget {
  const WorkerProfileSetup({super.key});

  @override
  State<WorkerProfileSetup> createState() => _WorkerProfileSetupState();
}

class _WorkerProfileSetupState extends State<WorkerProfileSetup> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();
  final Set<String> _skills = {};
  String _area = kovaiAreas.first;
  bool _saving = false;

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_skills.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.pickSkill)));
      return;
    }
    setState(() => _saving = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'name': _nameCtrl.text.trim(),
      'skills': _skills.toList(),
      'area': _area,
      'aadhaarLast4': _aadhaarCtrl.text.trim(),
      'available': true,
      'profileDone': true,
    });
    if (mounted) context.go('/worker-home');
  }

  Widget _skillGroup(String title, JobCategory cat, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: skillsFor(cat)
              .map((s) => FilterChip(
                    label: Text(lang == 'ta' ? s.ta : s.en),
                    selected: _skills.contains(s.id),
                    onSelected: (v) => setState(
                        () => v ? _skills.add(s.id) : _skills.remove(s.id)),
                  ))
              .toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(t.profileSetup)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: t.fullName),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? t.required : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _area,
              decoration: InputDecoration(labelText: t.selectArea),
              items: kovaiAreas
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) => setState(() => _area = v!),
            ),
            const SizedBox(height: 16),
            Text(t.selectSkills,
                style: Theme.of(context).textTheme.titleMedium),
            _skillGroup(t.industrialSkills, JobCategory.industrial, lang),
            _skillGroup(t.eventSkills, JobCategory.event, lang),
            const SizedBox(height: 16),
            TextFormField(
              controller: _aadhaarCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(
                  labelText: t.aadhaarLast4,
                  helperText: t.aadhaarNote,
                  counterText: ''),
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