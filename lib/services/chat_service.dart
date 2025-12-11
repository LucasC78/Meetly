import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String getChatId(String userA, String userB) {
    return userA.compareTo(userB) < 0 ? '$userA\_$userB' : '$userB\_$userA';
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    final chatId = getChatId(senderId, receiverId);
    final timestamp = FieldValue.serverTimestamp();

    final messageData = {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': message,
      'timestamp': timestamp,
      'seen': false,
    };

    // 1. Ajouter le message à la sous-collection 'messages'
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);

    // 2. Mettre à jour le document principal du chat avec le dernier message et timestamp
    await _firestore.collection('chats').doc(chatId).set({
      'lastMessage': message,
      'lastTimestamp': timestamp,
      'participants': [senderId, receiverId],
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> getMessages(String userA, String userB) {
    final chatId = getChatId(userA, userB);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> markMessageAsSeen(String chatId, String messageId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'seen': true});
  }
}
