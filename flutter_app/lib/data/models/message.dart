/// Message model for chat functionality

import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, audio }

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final MessageType type;
  final String? audioUrl;
  final int? audioDuration; // in seconds
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.type = MessageType.text,
    this.audioUrl,
    this.audioDuration,
    required this.timestamp,
    this.isRead = false,
  });

  factory Message.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? '',
      type: data['type'] == 'audio' ? MessageType.audio : MessageType.text,
      audioUrl: data['audioUrl'],
      audioDuration: data['audioDuration'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'type': type == MessageType.audio ? 'audio' : 'text',
      'audioUrl': audioUrl,
      'audioDuration': audioDuration,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }

  bool get isAudio => type == MessageType.audio;
}
