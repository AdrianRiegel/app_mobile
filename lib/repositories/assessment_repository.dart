import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assessment.dart';

class AssessmentRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Assessment>> getAssessments() {
    return _db
        .collection('assessments')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Assessment.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> addAssessment(Assessment assessment) async {
    await _db.collection('assessments').add(assessment.toMap());
  }
}