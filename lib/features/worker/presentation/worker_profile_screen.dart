import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/areas.dart';
import '../../../core/constants/skills.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/user_avatar.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  final _nameCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final Set<String> _skills = {};
  String _area = kovaiAreas.first;
  String? _photo;
  String _phone = '';
  bool _verified = false;
  bool _loading = true;
  bool _saving = false;
  double _avg = 0;
  int _done = 0;

  DocumentReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection('users').doc(_uid);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = (await _ref.get()).data() ?? {};
    _nameCtrl.text = d['name'] ?? '';
    _aboutCtrl.text = d['about'] ?? '';
    _expCtrl.text = '${d['experienceYears'] ?? ''}';
    _skills.addAll(List<String>.from(d['skills'] ?? []));
    final a = d['area'] as String?;
    if (a != null && kovaiAreas.contains(a)) _area = a;
    _photo = d['photoBase64'] as String?;
    _phone = d['phone'] ?? '';
    _verified = d['verified'] == true;

    // Stats: completed jobs + average rating
    final reqs = await FirebaseFirestore.instance
        .collection('requests')
        .where('workerId', isEqualTo: _uid)
        .get();
    final done = reqs.docs.where((e) => e.data()['status'] == 'completed');
    final rated = done.where((e) => e.data()['rating'] != null).toList();
    _done = done.length;
    if (rated.isNotEmpty) {
      _avg = rated
              .map((e) => (e.data()['rating'] as num).toDouble())
              .reduce((a, b) => a + b) /
          rated.length;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickPhoto() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 256,
      maxHeight: 256,
      imageQuality: 70,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() => _photo = base64Encode(bytes));
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await _ref.update({
      'name': _nameCtrl.text.trim(),
      'area': _area,
      'skills': _skills.toList(),
      'about': _aboutCtrl.text.trim(),
      'experienceYears': int.tryParse(_expCtrl.text.trim()),
      'photoBase64': _photo ?? FieldValue.delete(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(t.profileSaved)));
  }

  Widget _stat(String value, String label, IconData icon) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Column(children: [
            Icon(icon, color: AppColors.orange),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.grey600)),
          ]),
        ),
      );

  Widget _skillGroup(String title, JobCategory cat, String lang) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                GradientHeader(
                  title: t.myProfile,
                  subtitle: _phone,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            UserAvatar(photoBase64: _photo, radius: 56),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.orange,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.camera_alt,
                                      size: 18, color: Colors.white),
                                  onPressed: _pickPhoto,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                              onPressed: _pickPhoto,
                              child: Text(t.changePhoto)),
                          if (_photo != null)
                            TextButton(
                              onPressed: () => setState(() => _photo = null),
                              child: Text(t.removePhoto),
                            ),
                        ],
                      ),
                      Center(
                        child: Pill(
                          _verified ? t.verifiedBadge : t.notVerified,
                          icon: _verified ? Icons.verified : Icons.info_outline,
                          color:
                              _verified ? AppColors.success : AppColors.grey600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(children: [
                        _stat(_avg == 0 ? '-' : _avg.toStringAsFixed(1),
                            t.avgRating, Icons.star),
                        const SizedBox(width: 10),
                        _stat('$_done', t.jobsDone, Icons.work),
                      ]),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(labelText: t.fullName),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _area,
                        decoration: InputDecoration(labelText: t.selectArea),
                        items: kovaiAreas
                            .map((a) =>
                                DropdownMenuItem(value: a, child: Text(a)))
                            .toList(),
                        onChanged: (v) => setState(() => _area = v!),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _expCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            labelText:
                                '${t.experienceYears} (${t.optional})'),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _aboutCtrl,
                        maxLines: 3,
                        maxLength: 200,
                        decoration: InputDecoration(
                          labelText: '${t.aboutMe} (${t.optional})',
                          hintText: t.aboutHint,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(t.selectSkills,
                          style: Theme.of(context).textTheme.titleMedium),
                      _skillGroup(
                          t.industrialSkills, JobCategory.industrial, lang),
                      _skillGroup(t.eventSkills, JobCategory.event, lang),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: Text(t.saveChanges),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}