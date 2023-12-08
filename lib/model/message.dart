import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final String isRead;
  final Timestamp timestamp;

  Message({
    required this.id,
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.message,
    required this.isRead,
    required this.timestamp,
  });

  //convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'message': message,
      'isRead': isRead,
      'timestamp': timestamp,
    };
  }
}
