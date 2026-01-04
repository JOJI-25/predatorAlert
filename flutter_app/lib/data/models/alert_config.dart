/// Alert configuration data model

import 'package:cloud_firestore/cloud_firestore.dart';

class Contact {
  final String name;
  final String phone;

  Contact({
    required this.name,
    required this.phone,
  });

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
    };
  }
}

class AlertConfig {
  final bool alertEnabled;
  final bool sirenEnabled;
  final bool smsEnabled;
  final List<Contact> ownerContacts;
  final List<Contact> authorityContacts;
  final List<String> fcmTopics;

  AlertConfig({
    required this.alertEnabled,
    required this.sirenEnabled,
    required this.smsEnabled,
    required this.ownerContacts,
    required this.authorityContacts,
    required this.fcmTopics,
  });

  /// Create AlertConfig from Firestore document
  factory AlertConfig.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    return AlertConfig(
      alertEnabled: data['alert_enabled'] ?? true,
      sirenEnabled: data['siren_enabled'] ?? true,
      smsEnabled: data['sms_enabled'] ?? false,
      ownerContacts: _parseContacts(data['owner_contacts']),
      authorityContacts: _parseContacts(data['authority_contacts']),
      fcmTopics: List<String>.from(data['fcm_topics'] ?? ['predator_alerts']),
    );
  }

  static List<Contact> _parseContacts(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];
    
    return value
        .map((item) => Contact.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// Default configuration when document doesn't exist
  factory AlertConfig.defaultConfig() {
    return AlertConfig(
      alertEnabled: true,
      sirenEnabled: true,
      smsEnabled: false,
      ownerContacts: [],
      authorityContacts: [],
      fcmTopics: ['predator_alerts'],
    );
  }

  /// Check if there are any contacts configured
  bool get hasContacts => 
      ownerContacts.isNotEmpty || authorityContacts.isNotEmpty;

  /// Total number of contacts
  int get totalContacts => 
      ownerContacts.length + authorityContacts.length;
}
