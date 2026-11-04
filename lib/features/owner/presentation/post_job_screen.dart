import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/areas.dart';
import '../../../core/constants/skills.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/classic_widgets.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _wageCtrl = TextEditingController();
  JobCategory _category = JobCategory.industrial;
  String? _skillId;
  int _workers = 1;
  String _area = kovaiAreas.first;
  String _eventType = 'Wedding';
  DateTime? _eventDate;
  bool _saving = false;

  static const eventTypes = [
    'Wedding',
    'Trade Fair',
    'Temple Festival',
    'Exhibition',
    'Other'
  ];

  int get _wage => int.tryParse(_wageCtrl.text) ?? 0;

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _post() async {
    final t = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_skillId == null) return _snack(t.pickSkill);
    if (_category == JobCategory.event && _eventDate == null) {
      return _snack(t.pickDate);
    }
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final owner =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      await FirebaseFirestore.instance.collection('jobs').add({
        'ownerId': uid,
        'businessName': owner.data()?['businessName'] ?? '',
        'category': _category.name,
        'skillId': _skillId,
        'workersNeeded': _workers,
        'wagePerDay': _wage,
        'area': _area,
        if (_category == JobCategory.event) ...{
          'eventType': _eventType,
          'eventDate': Timestamp.fromDate(_eventDate!),
        },
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) => Pressable(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold, width: 1.5),
          ),
          child: Icon(icon, color: AppColors.ink),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final total = _workers * _wage;

    return Scaffold(
      body: Column(
        children: [
          ClassicHeader(
            title: t.postJob,
            subtitle: t.appName,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                children: [
                  FadeSlide(
                    index: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionTitle(t.jobCategory, Icons.category_outlined),
                        Row(children: [
                          _CatTile(
                            selected: _category == JobCategory.industrial,
                            icon: Icons.factory,
                            label: t.industrial,
                            color: AppColors.blue,
                            onTap: () => setState(() {
                              _category = JobCategory.industrial;
                              _skillId = null;
                            }),
                          ),
                          const SizedBox(width: 12),
                          _CatTile(
                            selected: _category == JobCategory.event,
                            icon: Icons.celebration,
                            label: t.event,
                            color: Colors.purple,
                            onTap: () => setState(() {
                              _category = JobCategory.event;
                              _skillId = null;
                            }),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  FadeSlide(
                    index: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionTitle(t.skillNeeded, Icons.build_outlined),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Wrap(
                            key: ValueKey(_category),
                            spacing: 8,
                            runSpacing: 8,
                            children: skillsFor(_category)
                                .map((s) => ChoiceChip(
                                      label: Text(lang == 'ta' ? s.ta : s.en),
                                      selected: _skillId == s.id,
                                      selectedColor:
                                          AppColors.orange.withOpacity(0.2),
                                      side: BorderSide(
                                          color: _skillId == s.id
                                              ? AppColors.orange
                                              : AppColors.gold
                                                  .withOpacity(0.4)),
                                      onSelected: (_) =>
                                          setState(() => _skillId = s.id),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  FadeSlide(
                    index: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionTitle(t.jobDetails, Icons.edit_note),
                        ClassicCard(
                          accent: AppColors.gold,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.workersNeeded,
                                  style: const TextStyle(
                                      color: AppColors.grey600,
                                      fontSize: 13)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _stepBtn(Icons.remove, () {
                                    if (_workers > 1) {
                                      setState(() => _workers--);
                                    }
                                  }),
                                  AnimatedSwitcher(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    transitionBuilder: (c, a) =>
                                        ScaleTransition(scale: a, child: c),
                                    child: Text('$_workers',
                                        key: ValueKey(_workers),
                                        style: serif(context,
                                            size: 32,
                                            weight: FontWeight.w800)),
                                  ),
                                  _stepBtn(Icons.add, () {
                                    if (_workers < 100) {
                                      setState(() => _workers++);
                                    }
                                  }),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _wageCtrl,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                    labelText: t.wagePerDay,
                                    prefixIcon: const Icon(
                                        Icons.currency_rupee,
                                        size: 20)),
                                validator: (v) =>
                                    (int.tryParse(v ?? '') ?? 0) <= 0
                                        ? t.required
                                        : null,
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<String>(
                                value: _area,
                                decoration:
                                    InputDecoration(labelText: t.selectArea),
                                items: kovaiAreas
                                    .map((a) => DropdownMenuItem(
                                        value: a, child: Text(a)))
                                    .toList(),
                                onChanged: (v) => setState(() => _area = v!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Event extras
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _category == JobCategory.event
                        ? ClassicCard(
                            accent: Colors.purple,
                            child: Column(children: [
                              DropdownButtonFormField<String>(
                                value: _eventType,
                                decoration:
                                    InputDecoration(labelText: t.eventType),
                                items: eventTypes
                                    .map((e) => DropdownMenuItem(
                                        value: e, child: Text(e)))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _eventType = v!),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48)),
                                icon: const Icon(Icons.calendar_today),
                                label: Text(_eventDate == null
                                    ? t.pickDate
                                    : '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}'),
                                onPressed: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 365)),
                                  );
                                  if (d != null) {
                                    setState(() => _eventDate = d);
                                  }
                                },
                              ),
                            ]),
                          )
                        : const SizedBox(width: double.infinity),
                  ),

                  const SizedBox(height: 10),
                  // Total summary (classic dark card)
                  FadeSlide(
                    index: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.gold, width: 1.2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(t.totalPerDay,
                              style: const TextStyle(color: Colors.white70)),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Text('₹$total',
                                key: ValueKey(total),
                                style: serif(context,
                                    size: 28,
                                    weight: FontWeight.w800,
                                    color: AppColors.gold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _saving ? null : _post,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline),
                    label: Text(t.postNow),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatTile extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _CatTile({
    required this.selected,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: selected ? color : AppColors.gold.withOpacity(0.4),
                width: 1.5),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: color.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6))
                  ]
                : [],
          ),
          child: Column(children: [
            Icon(icon, size: 30, color: selected ? Colors.white : color),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.ink)),
          ]),
        ),
      ),
    );
  }
}