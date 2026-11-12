import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
class AuthRepository {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<ConfirmationResult> sendOtp(String phone10) {
    return _auth.signInWithPhoneNumber('+91$phone10');
  }

  /// Phone OTP verify. User doc illana create pannum, irundha role return.
  Future<String> verifyOtp(
      ConfirmationResult result, String code, String selectedRole) async {
    final cred = await result.confirm(code);
    final user = cred.user!;
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return snap.data()!['role'] as String;

    await ref.set({
      'role': selectedRole,
      'phone': user.phoneNumber,
      'verified': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return selectedRole;
  }

  /// Google sign-in. User doc illana create pannum (phone blank).
  /// Web + Android rendulayum work aagum.
  Future<String> signInWithGoogle(String selectedRole) async {
    final provider = GoogleAuthProvider();
    final cred = kIsWeb
        ? await _auth.signInWithPopup(provider)
        : await _auth.signInWithProvider(provider);
    final user = cred.user!;
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return snap.data()!['role'] as String;

    await ref.set({
      'role': selectedRole,
      'phone': '',
      'email': user.email ?? '',
      'name': user.displayName ?? '',
      'verified': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return selectedRole;
  }

  Future<void> signOut() => _auth.signOut();
}