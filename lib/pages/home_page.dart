import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mate_app/components/constants.dart';
import 'package:mate_app/pages/chat_page.dart';
import 'package:mate_app/services/auth/auth_service.dart';
import 'package:mate_app/services/chat/chat_service.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //instance of auth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChatService _chatService = ChatService();
  AuthService _authService = AuthService();
  FirebaseStorage storage = FirebaseStorage.instance;

  final TextEditingController _usernameController = TextEditingController();

  bool isLoading = false;
  File? _photo;
  final ImagePicker _picker = ImagePicker();
  String? fileNameUpdate;
  String username = 'username';
  String email = 'email';
  String imageUrl = '';
  String? profilPhotoUrl;

  void signOut(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);

    authService.signOut();
  }

  selectImage(ImageSource source, BuildContext context) async {
    final pickedFile = await _picker.pickImage(source: source);

    setState(() {
      if (pickedFile != null) {
        _photo = File(pickedFile.path);
        uploadFile();
      } else {
        print('No image selected.');
      }
    });
  }

  Future uploadFile() async {
    if (_photo == null) return;
    final fileName = _auth.currentUser!.uid + '_' + basename(_photo!.path);
    final destination = 'files/$fileName';

    try {
      final ref = storage.ref(destination).child('file/');
      await ref.putFile(_photo!);
      imageUrl = await ref.getDownloadURL();
      updateProfile();
    } catch (e) {
      print('error occured');
    }
  }

  void updateProfile() async {
    if (_photo != null) {
      // final fileName = _auth.currentUser!.uid + '_' + basename(_photo!.path);

      setState(() {
        isLoading = false;
      });
    }
    await _authService.updateProfile(
        _auth.currentUser!.uid, _usernameController.text, imageUrl);

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(
          color: Colors.black, //change your color here
        ),
        backgroundColor: firstColor,
        title: const Text(
          'Mate App',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        // actions: [
        //   IconButton(
        //     onPressed: () => signOut(context),
        //     icon: const Icon(
        //       Icons.logout,
        //       color: Colors.black,
        //     ),
        //   ),
        // ],
      ),
      drawer: _drawer(),
      body: _buildUserList(),
    );
  }

  Widget _drawer() {
    return Drawer(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: LinearProgressIndicator());
          }

          try {
            var data = snapshot.data!.data();
            username = data!['username'] != null
                ? data['username'].toString()
                : 'Username';
            _usernameController.text =
                data['username'] != null ? data['username'].toString() : '';
            email = data['email'] != null ? data['email'].toString() : 'Email';
            profilPhotoUrl = data['profile_photo'] ?? null;
          } catch (e) {
            print('Error: ${e.toString()}');
          }

          return ListView(
            // Important: Remove any padding from the ListView.
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                // <-- SEE HERE
                decoration: BoxDecoration(color: firstColor),
                accountName: Row(
                  children: [
                    Text(
                      username,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 5),
                    GestureDetector(
                      onTap: () => showDialog(
                        barrierDismissible: false,
                        barrierColor: Colors.black87.withOpacity(0.5),
                        context: context,
                        builder: (context) => AlertDialog(
                          actions: [
                            MaterialButton(
                              color: secondColor,
                              textColor: Colors.black,
                              shape: BeveledRectangleBorder(
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.pop(context),
                            ),
                            MaterialButton(
                              color: firstColor,
                              textColor: Colors.black,
                              shape: BeveledRectangleBorder(
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: const Text('Ok'),
                              onPressed: () {
                                updateProfile();
                                Navigator.pop(context);
                              },
                            ),
                          ],
                          title: Text('Edit Username'),
                          content: TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(hintText: 'Username'),
                          ),
                        ),
                      ),
                      child: Icon(
                        Icons.edit,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                accountEmail: Text(
                  email,
                  style: TextStyle(
                    color: Colors.black,
                    // fontWeight: FontWeight.bold,
                  ),
                ),
                currentAccountPicture: GestureDetector(
                  child: GestureDetector(
                    onTap: () => _showModalBottomSheet(context),
                    child: profilPhotoUrl != null
                        ? CachedNetworkImage(
                            progressIndicatorBuilder:
                                (context, url, downloadProgress) =>
                                    CircularProgressIndicator(
                                        value: downloadProgress.progress),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error),
                            imageUrl: profilPhotoUrl!,
                            imageBuilder: (context, imageProvider) => Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                    image: imageProvider, fit: BoxFit.cover),
                              ),
                            ),
                          )
                        : FlutterLogo(),
                  ),
                  onTap: () => _showModalBottomSheet(context),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.logout,
                ),
                title: const Text('Logout'),
                onTap: () {
                  signOut(context);
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  //build a list of users except for the current logged in user
  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error!');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return ListView(
          children: snapshot.data!.docs
              .map<Widget>((doc) => _buildUserListItem(doc))
              .toList(),
        );
      },
    );
  }

  Widget _buildUserListItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;
    String lastMessage = 'click to start a new message';
    String lastMessageUser = '';
    String lastMessageTime = '';
    int unreadMessageCount = 0;

    if (_auth.currentUser!.email != data['email']) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: StreamBuilder(
            stream: _chatService.getAllRoomChat(
                _auth.currentUser!.uid, data['uid']),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: LinearProgressIndicator(),
                );
              }

              try {
                Map<String, dynamic> a =
                    snapshot.data!.docs[0].data()! as Map<String, dynamic>;
                lastMessage = a['last_message'].isEmpty
                    ? 'Lets start a new message'
                    : a['last_message'].toString();

                unreadMessageCount = a['from_id'] == _auth.currentUser!.uid
                    ? a['to_count_message'] != null
                        ? a['to_count_message']
                        : 0
                    : a['from_count_message'] != null
                        ? a['from_count_message']
                        : 0;
                DateTime time = (a['timestamp'] as Timestamp).toDate();
                lastMessageTime =
                    time.hour.toString() + ':' + time.minute.toString();
                lastMessageUser = a['last_message_id'] != _auth.currentUser!.uid
                    ? 'you : '
                    : data['email'] + ' : ';

                // print(a['from_count_message']);
              } catch (e) {
                print(e.toString());
              }

              return ListTile(
                leading: data['profile_photo'] != null
                    ? CachedNetworkImage(
                        progressIndicatorBuilder:
                            (context, url, downloadProgress) =>
                                CircularProgressIndicator(
                                    value: downloadProgress.progress),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                        height: 50,
                        width: 50,
                        imageUrl: data['profile_photo'].toString(),
                        imageBuilder: (context, imageProvider) => Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                                image: imageProvider, fit: BoxFit.cover),
                          ),
                        ),
                      )
                    : Container(
                        height: 50,
                        width: 50,
                        child: Icon(Icons.person),
                      ),
                // minLeadingWidth: 0,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(height: 5),
                    Text(lastMessageTime),
                    if (unreadMessageCount != 0)
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: firstColor, shape: BoxShape.circle
                            // borderRadius: BorderRadius.circular(50),
                            ),
                        child: Text(unreadMessageCount > 999
                            ? '999+'
                            : unreadMessageCount.toString()),
                      ),
                    SizedBox(width: 5),
                  ],
                ),
                subtitle: Text(lastMessageUser + lastMessage),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(
                    width: 0.5,
                    color: Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(8), //<-- SEE HERE
                ),
                title: Text(
                    data['username'] ?? (data['username'] ?? data['email'])),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        receiveUsername: data['username'] ?? '',
                        receiveUserEmail: data['email'],
                        receiveUserID: data['uid'],
                      ),
                    ),
                  );
                },
              );
            }),
      );
    } else {
      return Container();
    }
  }

  void _showModalBottomSheet(BuildContext context) {
    showModalBottomSheet(
      barrierColor: Colors.black87.withOpacity(0.5),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
        top: Radius.circular(30),
      )),
      context: context,
      builder: (context) => Container(
        height: 150,
        padding: EdgeInsets.symmetric(horizontal: 35, vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    selectImage(ImageSource.camera, context);
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.camera_alt,
                    size: 50,
                  ),
                ),
                Text('Camera'),
              ],
            ),
            SizedBox(width: 35),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    selectImage(ImageSource.gallery, context);
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.drive_folder_upload_rounded,
                    size: 50,
                  ),
                ),
                Text('Gallery'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
