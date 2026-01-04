/// Firebase service wrapper for Firestore access.
/// 
/// Note: Image storage is handled by Cloudinary via the backend.
/// Images are loaded directly using HTTPS URLs stored in Firestore.

import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  FirebaseService._();
  
  static final FirebaseService instance = FirebaseService._();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  FirebaseFirestore get firestore => _firestore;
  
  /// Get detections collection reference
  CollectionReference<Map<String, dynamic>> get detectionsRef =>
      _firestore.collection('detections');
  
  /// Get alert config document reference
  DocumentReference<Map<String, dynamic>> get alertConfigRef =>
      _firestore.collection('alert_config').doc('global');
  
  /// Stream of detection documents, sorted by timestamp descending
  Stream<QuerySnapshot<Map<String, dynamic>>> getDetectionsStream({
    int limit = 50,
    bool predatorsOnly = false,
  }) {
    Query<Map<String, dynamic>> query = detectionsRef
        .orderBy('created_at', descending: true)
        .limit(limit);
    
    if (predatorsOnly) {
      query = query.where('is_predator', isEqualTo: true);
    }
    
    return query.snapshots();
  }
  
  /// Stream of alert configuration
  Stream<DocumentSnapshot<Map<String, dynamic>>> getAlertConfigStream() {
    return alertConfigRef.snapshots();
  }
  
  /// Get a single detection by ID
  Future<DocumentSnapshot<Map<String, dynamic>>> getDetection(String id) {
    return detectionsRef.doc(id).get();
  }
}
