import 'package:cloud_firestore/cloud_firestore.dart';

class JobService {
  /// Request accepted aana apram call pannu.
  /// Accepted/completed count >= workersNeeded na job-ah 'filled' aakkum.
  static Future<void> checkFilled(String jobId, String ownerId) async {
    final db = FirebaseFirestore.instance;
    final jobRef = db.collection('jobs').doc(jobId);
    final job = await jobRef.get();
    if (!job.exists) return;
    final needed = (job.data()!['workersNeeded'] as num).toInt();

    final reqs = await db
        .collection('requests')
        .where('ownerId', isEqualTo: ownerId)
        .where('jobId', isEqualTo: jobId)
        .get();
    final hired = reqs.docs.where((d) {
      final s = d.data()['status'];
      return s == 'accepted' || s == 'completed';
    }).length;

    if (hired >= needed && job.data()!['status'] == 'open') {
      await jobRef.update({'status': 'filled'});
    }
  }
}