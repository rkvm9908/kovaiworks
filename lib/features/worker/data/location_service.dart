import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  StreamSubscription<Position>? _sub;

  Future<bool> start() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return false;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseFirestore.instance.collection('users').doc(uid);

    // First position udane
    final first = await Geolocator.getCurrentPosition();
    await ref.update({
      'location': GeoPoint(first.latitude, first.longitude),
      'locationUpdatedAt': FieldValue.serverTimestamp(),
    });

    // distanceFilter 50m: neraya write aagaama Firestore quota save aagum
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      ),
    ).listen((p) {
      ref.update({
        'location': GeoPoint(p.latitude, p.longitude),
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });
    });
    return true;
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }
}