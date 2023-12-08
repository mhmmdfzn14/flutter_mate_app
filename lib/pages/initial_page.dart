import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mate_app/components/constants.dart';
import 'package:mate_app/pages/home_page.dart';
import 'package:mate_app/services/auth/auth_service.dart';
// import 'package:mate_app/services/utils.dart';

class InitialPage extends StatefulWidget {
  const InitialPage({super.key});

  @override
  State<InitialPage> createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage> {
  final TextEditingController _usernameController = TextEditingController();
  AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseStorage storage = FirebaseStorage.instance;
  bool isLoading = false;
  File? _photo;
  Uint8List? _photoView;
  final ImagePicker _picker = ImagePicker();
  String? fileNameUpdate;
  String? urlPhoto;

  selectImage(ImageSource source, BuildContext context) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      Uint8List _photoViewBytes = await pickedFile.readAsBytes();
      setState(() {
        _photoView = _photoViewBytes;
      });
    }
    setState(() {
      if (pickedFile != null) {
        _photo = File(pickedFile.path);
        uploadFile();
        updateProfile(context);
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
      urlPhoto = await ref.getDownloadURL();
    } catch (e) {
      print('error occured');
    }
  }

  void updateProfile(BuildContext context) async {
    await _authService.updateProfile(
        _auth.currentUser!.uid, _usernameController.text, urlPhoto);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HomePage(),
      ),
    );
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Text(
          'Profile info',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Column(
            children: [
              Text('Please provide your name and optional profile photo'),
              SizedBox(height: 25),
              _photoView != null
                  ? GestureDetector(
                      onTap: () => _showModalBottomSheet(context),
                      child: CircleAvatar(
                        radius: 64,
                        backgroundImage: MemoryImage(_photoView!),
                      ),
                    )
                  : Container(
                      padding: EdgeInsets.all(35.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        color: Colors.grey[600],
                        onPressed: () => _showModalBottomSheet(context),
                        icon: Icon(
                          Icons.add_a_photo,
                          size: 50.0,
                        ),
                      ),
                    ),
              SizedBox(height: 25),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Type your name here',
                ),
                controller: _usernameController,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: firstColor, // Background color
                        ),
                        onPressed: isLoading
                            ? () {}
                            : () {
                                setState(() {
                                  isLoading = true;
                                });
                                updateProfile(context);
                              },
                        child: isLoading
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: LinearProgressIndicator(),
                              )
                            : Text(
                                'NEXT',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }

  void _showModalBottomSheet(BuildContext context) {
    showModalBottomSheet(
      barrierColor: Colors.black87.withOpacity(0.5),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
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
