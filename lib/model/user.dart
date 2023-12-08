import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String email;
  final String username;
  final String profilePhoto;
  final String token;
  final Timestamp createdAt;
  final Timestamp modifiedAt;

  User({
    required this.uid,
    required this.email,
    required this.username,
    required this.profilePhoto,
    required this.token,
    required this.createdAt,
    required this.modifiedAt,
  });

  //convert to Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'profilePhoto': profilePhoto,
      'token': token,
      'createdAt': createdAt,
      'modifiedAt': modifiedAt,
    };
  }
}
