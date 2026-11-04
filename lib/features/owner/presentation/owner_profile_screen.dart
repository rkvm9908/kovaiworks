import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/areas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/user_avatar.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  final _nameCtrl = TextEditingController();
  final _bizCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();
  String _area = kovaiAreas.first;
  String _type = 'mill';
  String? _photo;
  String _phone = '';
  bool _loading = true;
  bool _saving = false;
  int _jobs = 0;
  int _hired = 0;

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
    _bizCtrl.text = d['businessName'] ?? '';
    _addrCtrl.text = d['address'] ?? '';
    _aboutCtrl.text = d['about'] ?? '';
    final a = d['area'] as String?;
    if (a != null && kovaiAreas.contains(a)) _area = a;
    _type = d['businessType'] ?? 'mill';
    _photo = d['photoBase64'] as String?;
    _phone = d['phone'] ?? '';

    final jobs = await FirebaseFirestore.instance
        .collection('jobs')
        .where('ownerId', isEqualTo: _uid)
        .get();
    final reqs = await FirebaseFirestore.instance
        .collection('requests')
        .where('ownerId', isEqualTo: _uid)
        .get();
    _jobs = jobs.docs.length;
    _hired = reqs.docs
        .where((e) => e.data()['status'] == 'completed')
        .length;
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
    if (_nameCtrl.text.trim().isEmpty || _bizCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await _ref.update({
      'name': _nameCtrl.text.trim(),
      'businessName': _bizCtrl.text.trim(),
      'businessType': _type,
      'area': _area,
      'address': _addrCtrl.text.trim(),
      'about': _aboutCtrl.text.trim(),
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
            Icon(icon, color: AppColors.blue),
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final types = {
      'mill': t.typeMill,
      'foundry': t.typeFoundry,
      'event': t.typeEvent,
      'other': t.typeOther,
    };

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                GradientHeader(
                  title: t.ownerProfile,
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
                                backgroundColor: AppColors.blue,
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
                              child: Text(t.changeLogo)),
                          if (_photo != null)
                            TextButton(
                              onPressed: () => setState(() => _photo = null),
                              child: Text(t.removePhoto),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        _stat('$_jobs', t.jobsPosted, Icons.work_outline),
                        const SizedBox(width: 10),
                        _stat('$_hired', t.workersHired, Icons.groups),
                      ]),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _bizCtrl,
                        decoration:
                            InputDecoration(labelText: t.businessName),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(labelText: t.fullName),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _type,
                        decoration:
                            InputDecoration(labelText: t.businessType),
                        items: types.entries
                            .map((e) => DropdownMenuItem(
                                value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (v) => setState(() => _type = v!),
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
                        controller: _addrCtrl,
                        decoration: InputDecoration(
                            labelText: '${t.address} (${t.optional})'),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _aboutCtrl,
                        maxLines: 3,
                        maxLength: 200,
                        decoration: InputDecoration(
                          labelText: '${t.aboutBusiness} (${t.optional})',
                          hintText: t.aboutBusinessHint,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.blue),
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