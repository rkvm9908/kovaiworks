import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/areas.dart';
import '../../../core/constants/skills.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../notifications/notification_service.dart';
import 'package:geolocator/geolocator.dart';

class JobsMapScreen extends StatefulWidget {
  const JobsMapScreen({super.key});

  @override
  State<JobsMapScreen> createState() => _JobsMapScreenState();
}

class _JobsMapScreenState extends State<JobsMapScreen> {
  static const _center = LatLng(11.0168, 76.9558);
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  LatLng? _me;

  @override
  void initState() {
    super.initState();
    _getMe();
  }

  Future<void> _getMe() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final p = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _me = LatLng(p.latitude, p.longitude));
    } catch (_) {}
  }

  /// Job-oda LatLng (exact illana area center)
  LatLng _jobLatLng(Map<String, dynamic> j) {
    if (j['location'] is GeoPoint) {
      final g = j['location'] as GeoPoint;
      return LatLng(g.latitude, g.longitude);
    }
    final c = areaCoords[j['area']] ?? [_center.latitude, _center.longitude];
    return LatLng(c[0], c[1]);
  }

  String? _distanceText(Map<String, dynamic> j) {
    if (_me == null) return null;
    final km = const Distance().as(LengthUnit.Kilometer, _me!, _jobLatLng(j));
    return km < 1
        ? '${(km * 1000).round()} m'
        : '${km.toStringAsFixed(1)} km';
  }

  // Same area-la neraya jobs irundha, chinna circle-la spread pannu
  LatLng _pos(String area, int idx, int total) {
    final c = areaCoords[area] ?? [_center.latitude, _center.longitude];
    if (total <= 1) return LatLng(c[0], c[1]);
    final angle = 2 * math.pi * idx / total;
    const r = 0.004;
    return LatLng(c[0] + r * math.sin(angle), c[1] + r * math.cos(angle));
  }

  Future<void> _apply(QueryDocumentSnapshot<Map<String, dynamic>> jd) async {
    final t = AppLocalizations.of(context)!;
    final j = jd.data();
    final db = FirebaseFirestore.instance;
    final me = (await db.collection('users').doc(_uid).get()).data();
    await db.collection('requests').add({
      'jobId': jd.id,
      'ownerId': j['ownerId'],
      'workerId': _uid,
      'businessName': j['businessName'] ?? '',
      'skillId': j['skillId'],
      'wagePerDay': j['wagePerDay'],
      'area': j['area'],
      'status': 'pending',
      'initiatedBy': 'worker',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await NotificationService.send(
      toUid: j['ownerId'],
      type: 'applied',
      body: '${me?['name'] ?? ''} • ${j['area']}',
    );
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.applySent)));
    }
  }

  void _showJob(QueryDocumentSnapshot<Map<String, dynamic>> jd, bool applied,
      String lang, AppLocalizations t) {
    final j = jd.data();
    final skill = allSkills.firstWhere((s) => s.id == j['skillId']);
    final isEvent = j['category'] == 'event';
    final color = isEvent ? Colors.purple : AppColors.blue;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.12),
                child: Icon(isEvent ? Icons.celebration : Icons.factory,
                    color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lang == 'ta' ? skill.ta : skill.en,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    Text('${j['businessName']}',
                        style: const TextStyle(color: AppColors.grey600)),
                  ],
                ),
              ),
              Text('₹${j['wagePerDay']}',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.orangeDark)),
            ]),
            const SizedBox(height: 12),
            Text('📍 ${j['area']}   👥 ${j['workersNeeded']} ${t.workersLabel}'),
            if (_distanceText(j) != null)
              Text('🧭 ${_distanceText(j)} ${t.distanceKm}'),
            if ((j['ownerPhone'] ?? '').toString().isNotEmpty)
              Text('📞 ${j['ownerPhone']}'),
            const SizedBox(height: 16),
            applied
                ? OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48)),
                    onPressed: null,
                    icon: const Icon(Icons.check),
                    label: Text(t.applied),
                  )
                : FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      _apply(jd);
                    },
                    icon: const Icon(Icons.send),
                    label: Text(t.apply),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.jobsMap),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/worker-home'),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('workerId', isEqualTo: _uid)
            .snapshots(),
        builder: (context, reqSnap) {
          final applied = (reqSnap.data?.docs ?? [])
              .map((d) => d.data()['jobId'])
              .toSet();
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('jobs')
                .where('status', isEqualTo: 'open')
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) return Center(child: Text('${snap.error}'));
              final docs = snap.data?.docs ?? [];

              // area-wise group
              final byArea = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
              for (final d in docs) {
                byArea.putIfAbsent('${d.data()['area']}', () => []).add(d);
              }

              final markers = <Marker>[];
              byArea.forEach((area, list) {
                for (var i = 0; i < list.length; i++) {
                  final jd = list[i];
                  final j = jd.data();
                  final isEvent = j['category'] == 'event';
                  final color = isEvent ? Colors.purple : AppColors.orange;
                  final isApplied = applied.contains(jd.id);
                  markers.add(Marker(
                    point: (j['location'] is GeoPoint)
                        ? LatLng((j['location'] as GeoPoint).latitude,
                            (j['location'] as GeoPoint).longitude)
                        : _pos(area, i, list.length),
                    width: 76,
                    height: 56,
                    child: GestureDetector(
                      onTap: () => _showJob(jd, isApplied, lang, t),
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isApplied ? AppColors.grey600 : color,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2))
                            ],
                          ),
                          child: Text(
                            _distanceText(j) == null
                                ? '₹${j['wagePerDay']}'
                                : '₹${j['wagePerDay']} • ${_distanceText(j)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                        Icon(Icons.location_pin,
                            color: isApplied ? AppColors.grey600 : color,
                            size: 30),
                      ]),
                    ),
                  ));
                }
              });

              return Stack(children: [
                FlutterMap(
                  options: const MapOptions(
                      initialCenter: _center, initialZoom: 11.5),
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
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        docs.isEmpty
                            ? t.noJobsMap
                            : '${docs.length} ${t.jobsOnMap}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ]);
            },
          );
        },
      ),
    );
  }
}