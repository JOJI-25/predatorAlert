/// Detection data model

import 'package:cloud_firestore/cloud_firestore.dart';

class Detection {
  final String id;
  final String deviceId;
  final String animal;
  final double confidence;
  final bool isPredator;
  final String? imageUrl;
  final DateTime? detectionTime;
  final DateTime? createdAt;
  final bool alertSent;

  Detection({
    required this.id,
    required this.deviceId,
    required this.animal,
    required this.confidence,
    required this.isPredator,
    this.imageUrl,
    this.detectionTime,
    this.createdAt,
    this.alertSent = false,
  });

  /// Create Detection from Firestore document
  factory Detection.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    return Detection(
      id: doc.id,
      deviceId: data['device_id'] ?? '',
      animal: data['animal'] ?? 'Unknown',
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
      isPredator: data['is_predator'] ?? false,
      imageUrl: data['image_url'],
      detectionTime: _parseTimestamp(data['detection_time']),
      createdAt: _parseTimestamp(data['created_at']),
      alertSent: data['alert_sent'] ?? false,
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Confidence as percentage string
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(0)}%';

  /// Animal name with first letter capitalized
  String get animalName {
    if (animal.isEmpty) return 'Unknown';
    return animal[0].toUpperCase() + animal.substring(1).toLowerCase();
  }

  /// Formatted timestamp string
  String get formattedTime {
    final time = createdAt ?? detectionTime;
    if (time == null) return 'Unknown time';
    
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  /// Full formatted date and time
  String get fullFormattedTime {
    final time = createdAt ?? detectionTime;
    if (time == null) return 'Unknown';
    
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    
    return '$day/$month/${time.year} at $hour:$minute';
  }
}
