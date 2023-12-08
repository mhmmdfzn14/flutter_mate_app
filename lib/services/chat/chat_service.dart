import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mate_app/model/message.dart';

class ChatService extends ChangeNotifier {
  //get instance of auth and firestore
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;

  //SEND MESSAGE
  Future<void> sendMessage(String receiverId, String message) async {
    //get current user info
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String currentUserEmail = _firebaseAuth.currentUser!.email.toString();
    final Timestamp timestamp = Timestamp.now();
    String docID =
        DateTime.now().millisecondsSinceEpoch.toString() + '_' + currentUserId;

    //create a new message
    Message newMessage = Message(
      id: docID,
      senderId: currentUserId,
      senderEmail: currentUserEmail,
      receiverId: receiverId,
      message: message,
      isRead: '',
      timestamp: timestamp,
    );

    //contstruct chat room id from current user id and receiver id(sorted to insure uniqueness)
    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    int countMessage = 0;
    Map<String, dynamic> dt;
    _fireStore.collection('chat_rooms').doc(chatRoomId).get().then((value) => {
          dt = value.data()!,
          // print('to_count_message : ' + dt['to_count_message']),
          print('from_count_message : ' + dt['from_count_message'].toString()),
          // countMessage = dt['from_count_message'],
          countMessage = dt['from_id'] != currentUserId
              ? dt['to_count_message'] != null
                  ? dt['to_count_message']
                  : 0
              : dt['from_count_message'] != null
                  ? dt['from_count_message']
                  : 0,
          print('IDNYA INI : ' + dt['id']),
          print('JUMLAH PESAN : ' + countMessage.toString()),

          dt['from_id'] != currentUserId
              ? _fireStore.collection('chat_rooms').doc(chatRoomId).update({
                  'last_message': message,
                  'to_count_message': countMessage + 1,
                  'last_message_id': receiverId,
                  'timestamp': timestamp,
                })
              : _fireStore.collection('chat_rooms').doc(chatRoomId).update({
                  'last_message': message,
                  'from_count_message': countMessage + 1,
                  'last_message_id': currentUserId,
                  'timestamp': timestamp,
                })
        });

    //add new message to database
    _fireStore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(docID)
        .set(newMessage.toMap());
    return;
  }

  //GET MESSAGE
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    //construct chat room id from user ids(sorted to ensure it matches the id used when sending messages)
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');
    _fireStore.collection('chat_rooms').doc(chatRoomId).set({
      'id': chatRoomId,
      'from_id': userId,
      'to_id': otherUserId,
    }, SetOptions(merge: true));
    return _fireStore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  //READ Message
  Future<void> readAllMessage(String userId, String otherUserId) async {
    // print('USERID : ' + userId);
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    Map<String, dynamic> dt;
    _fireStore.collection('chat_rooms').doc(chatRoomId).get().then((value) => {
          dt = value.data()!,
          print('from_count_message : ' + dt['from_count_message'].toString()),
          dt['from_id'] != userId
              ? _fireStore
                  .collection('chat_rooms')
                  .doc(chatRoomId)
                  .update({'from_count_message': 0})
              : _fireStore
                  .collection('chat_rooms')
                  .doc(chatRoomId)
                  .update({'to_count_message': 0})
        });

    try {
      var snapshots = _fireStore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: '')
          .get()
          .asStream();
      await snapshots.forEach((snapshot) async {
        List<DocumentSnapshot> documents = snapshot.docs;

        for (var document in documents) {
          // print('Update untuk id : ' + document.reference.id);
          if (document.reference.id.isNotEmpty) {
            await document.reference.update(<String, dynamic>{
              'isRead': 'read',
            });
          }
        }
      });
      return;
    } catch (e) {
      print('Error' + e.toString());
      return;
    }
  }

  Stream<QuerySnapshot> getAllRoomChat(String userID, String otherUserID) {
    return _fireStore
        .collection('chat_rooms')
        .where(Filter.and(
          Filter('from_id', whereIn: [userID, otherUserID]),
          Filter('to_id', whereIn: [userID, otherUserID]),
        ))
        .snapshots();
  }
}
