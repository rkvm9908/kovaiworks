import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/skills.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../notifications/notification_service.dart';

class NearbyWorkersMap extends StatelessWidget {
  const NearbyWorkersMap({super.key});

  static const _coimbatore = LatLng(11.0168, 76.9558);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(t.nearbyWorkers)),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'worker')
            .where('available', isEqualTo: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          final docs = (snap.data?.docs ?? [])
              .where((d) => d.data()['location'] != null)
              .toList();

          final markers = docs.map((d) {
            final data = d.data();
            final gp = data['location'] as GeoPoint;
            return Marker(
              point: LatLng(gp.latitude, gp.longitude),
              width: 48,
              height: 48,
              child: GestureDetector(
                onTap: () => _showWorker(context, d.id, data, lang, t),
                child: const Icon(Icons.location_pin,
                    color: AppColors.orange, size: 44),
              ),
            );
          }).toList();

          return Stack(
            children: [
              FlutterMap(
                options: const MapOptions(
                  initialCenter: _coimbatore,
                  initialZoom: 12,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.kovaiworks.kovaiworks',
                  ),
                  MarkerLayer(markers: markers),
                  const RichAttributionWidget(attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                  ]),
                ],
              ),
              if (docs.isEmpty)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(t.noWorkersNearby,
                          textAlign: TextAlign.center),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showWorker(BuildContext context, String workerId,
      Map<String, dynamic> d, String lang, AppLocalizations t) {
    final skillIds = List<String>.from(d['skills'] ?? []);
    final names = skillIds.map((id) {
      final s = allSkills.where((x) => x.id == id);
      return s.isEmpty ? id : (lang == 'ta' ? s.first.ta : s.first.en);
    }).join(', ');

    showModalBottomSheet(
      context: context,
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              UserAvatar(photoBase64: d['photoBase64'], radius: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(d['name'] ?? '-',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ]),
            if ((d['about'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(d['about']),
            ],
            if (d['experienceYears'] != null)
              Text('${d['experienceYears']} yrs experience'),
            const SizedBox(height: 8),
            Text('${d['area'] ?? ''}'),
            const SizedBox(height: 4),
            Text(names),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.send),
              label: Text(t.sendRequest),
              onPressed: () {
                Navigator.pop(sheetCtx);
                _pickJob(context, workerId, d['name'] ?? '', lang, t);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickJob(BuildContext context, String workerId,
      String workerName, String lang, AppLocalizations t) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final jobs = await FirebaseFirestore.instance
        .collection('jobs')
        .where('ownerId', isEqualTo: uid)
        .where('status', isEqualTo: 'open')
        .get();
    if (!context.mounted) return;

    if (jobs.docs.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.noOpenJobs)));
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (sheetCtx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(t.selectJob,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          ...jobs.docs.map((doc) {
            final j = doc.data();
            final skill = allSkills.firstWhere((s) => s.id == j['skillId']);
            return ListTile(
              title: Text(lang == 'ta' ? skill.ta : skill.en),
              subtitle: Text('₹${j['wagePerDay']} • ${j['area']}'),
              onTap: () async {
                Navigator.pop(sheetCtx);
                await FirebaseFirestore.instance.collection('requests').add({
                  'jobId': doc.id,
                  'ownerId': uid,
                  'workerId': workerId,
                  'businessName': j['businessName'] ?? '',
                  'skillId': j['skillId'],
                  'wagePerDay': j['wagePerDay'],
                  'area': j['area'],
                  'status': 'pending',
                  'createdAt': FieldValue.serverTimestamp(),
                });
                await NotificationService.send(
                  toUid: workerId,
                  type: 'request',
                  body: '${j['businessName']} • ₹${j['wagePerDay']}',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t.requestSent)));
                }
              },
            );
          }),
        ],
      ),
    );
  }
}