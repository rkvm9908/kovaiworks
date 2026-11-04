import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<ConfirmationResult> sendOtp(String phone10) {
    return _auth.signInWithPhoneNumber('+91$phone10');
  }

  /// OTP verify pannitu, user doc illana create pannum.
  /// Already irundha, stored role-ah return pannum.
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

  Future<void> signOut() => _auth.signOut();
}