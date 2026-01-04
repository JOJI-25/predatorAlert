/// Chat service for real-time messaging via Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate a consistent chat ID for two users
  String getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Stream messages for a chat between two users
  Stream<List<Message>> getMessages(String currentUserId, String otherUserId) {
    final chatId = getChatId(currentUserId, otherUserId);
    
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromFirestore(doc))
            .toList());
  }

  /// Send a text message
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    final chatId = getChatId(senderId, receiverId);
    final message = Message(
      id: '',
      senderId: senderId,
      receiverId: receiverId,
      text: text.trim(),
      type: MessageType.text,
      timestamp: DateTime.now(),
      isRead: false,
    );

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toFirestore());

    await _updateChatMetadata(chatId, senderId, receiverId, text.trim());
  }



  /// Update chat metadata
  Future<void> _updateChatMetadata(
    String chatId,
    String senderId,
    String receiverId,
    String lastMessage,
  ) async {
    await _firestore.collection('chats').doc(chatId).set({
      'participants': [senderId, receiverId],
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.now(),
      'lastSenderId': senderId,
    }, SetOptions(merge: true));
  }

  /// Mark messages as read
  Future<void> markAsRead(String currentUserId, String otherUserId) async {
    final chatId = getChatId(currentUserId, otherUserId);
    
    final unreadMessages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Get unread message count
  Stream<int> getUnreadCount(String currentUserId, String otherUserId) {
    final chatId = getChatId(currentUserId, otherUserId);
    
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
