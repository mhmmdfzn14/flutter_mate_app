import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mate_app/components/chat_bubble.dart';
import 'package:mate_app/components/constants.dart';
import 'package:mate_app/components/my_text_field_widget.dart';
import 'package:mate_app/services/chat/chat_service.dart';

class ChatPage extends StatefulWidget {
  final String receiveUserEmail;
  final String receiveUserID;
  final String? receiveUsername;

  const ChatPage({
    super.key,
    this.receiveUsername,
    required this.receiveUserEmail,
    required this.receiveUserID,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  ScrollController _listScrollController = ScrollController();
  Offset _tapPosition = Offset.zero;
  void _getTapPosition(TapDownDetails details) {
    final RenderBox referenceBox = context.findRenderObject() as RenderBox;
    // setState(() {
    _tapPosition = referenceBox.globalToLocal(details.globalPosition);
    // });
  }

  void sendMessage() async {
    //only send the message if the message is already
    if (_messageController.text.isNotEmpty) {
      await _chatService
          .sendMessage(widget.receiveUserID, _messageController.text)
          .then((value) => _scrollDown());
      //clear the messagecontroller after sending the message
      _messageController.clear();
    }
  }

  void _scrollDown() {
    _listScrollController
        .jumpTo(_listScrollController.position.minScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    _chatService.readAllMessage(
        _firebaseAuth.currentUser!.uid, widget.receiveUserID);
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.black, //change your color here
        ),
        backgroundColor: firstColor,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.receiveUsername != null && widget.receiveUsername != '')
              Text(
                widget.receiveUsername!,
                style: const TextStyle(color: Colors.black),
              ),
            (widget.receiveUsername != null && widget.receiveUsername != '')
                ? Text(
                    widget.receiveUserEmail,
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                  )
                : Text(
                    widget.receiveUserEmail,
                    style: const TextStyle(color: Colors.black),
                  ),
          ],
        ),
      ),
      body: Column(
        children: [
          //messages
          const SizedBox(height: 12),
          Expanded(
            child: _buildMessageList(),
          ),

          //user input message
          _buildMessageInput(),
        ],
      ),
    );
  }

  //build message list
  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _chatService.getMessages(
          widget.receiveUserID, _firebaseAuth.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        return ListView(
          controller: _listScrollController,
          reverse: true,
          children:
              snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
        );
      },
    );
  }

  //build message item
  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    //align the message to the right if the sender is current user
    var alignment = (data['senderId'] == _firebaseAuth.currentUser!.uid)
        ? Alignment.centerRight
        : Alignment.centerLeft;

    // var crossAxisAlignment =
    //     (data['senderId'] == _firebaseAuth.currentUser!.uid)
    //         ? CrossAxisAlignment.end
    //         : CrossAxisAlignment.start;

    var mainAxisAlignment = (data['senderId'] == _firebaseAuth.currentUser!.uid)
        ? MainAxisAlignment.end
        : MainAxisAlignment.start;

    var color = (data['senderId'] == _firebaseAuth.currentUser!.uid)
        ? firstColor
        : secondColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
      alignment: alignment,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: mainAxisAlignment,
        children: [
          _readIndicatorCurrentUser(data),
          Flexible(
            child: GestureDetector(
              onTapDown: (details) => _getTapPosition(details),
              onLongPress: () => _showContextMenu(context, data['id']),
              child: ChatBubble(
                message: data['message'],
                color: color,
              ),
            ),
          ),
          _readIndicatorOtherUser(data),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context, String chatId) async {
    final RenderObject? overlay =
        Overlay.of(context).context.findRenderObject();

    final result = await showMenu(
        context: context,

        // Show the context menu at the tap location
        position: RelativeRect.fromRect(
            Rect.fromLTWH(_tapPosition.dx, _tapPosition.dy, 30, 30),
            Rect.fromLTWH(0, 0, overlay!.paintBounds.size.width,
                overlay.paintBounds.size.height)),

        // set a list of choices for the context menu
        items: [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit),
                SizedBox(width: 5),
                Text('Edit'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete),
                SizedBox(width: 5),
                Text('Delete'),
              ],
            ),
          ),
        ]);

    // Implement the logic for each choice here
    switch (result) {
      case 'edit':
        debugPrint('Edit Selected');
        break;
      case 'delete':
        // debugPrint('');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirm'),
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
                onPressed: () async {
                  List<String> ids = [
                    _firebaseAuth.currentUser!.uid,
                    widget.receiveUserID
                  ];
                  ids.sort();
                  String chatRoomId = ids.join('_');

                  await FirebaseFirestore.instance
                      .collection('chat_rooms')
                      .doc(chatRoomId)
                      .collection('messages')
                      .doc(chatId)
                      .delete();

                  print(chatId);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );

        break;
    }
  }

  Widget _readIndicatorCurrentUser(Map<String, dynamic> data) {
    var icon = (data['isRead'] != '') ? Icon(Icons.done_all) : Icon(Icons.done);
    DateTime dt = (data['timestamp'] as Timestamp).toDate();

    if (data['senderId'] == _firebaseAuth.currentUser!.uid) {
      return Row(
        children: [
          Column(
            children: [
              icon,
              const SizedBox(width: 10),
              Text(
                // data['isRead'] +
                //     ' ' +
                dt.hour.toString() + ':' + dt.minute.toString(),
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      );
    } else {
      return Container();
    }
  }

  Widget _readIndicatorOtherUser(Map<String, dynamic> data) {
    DateTime dt = (data['timestamp'] as Timestamp).toDate();
    var icon = (data['isRead'] != '') ? Icon(Icons.done_all) : Icon(Icons.done);

    if (data['senderId'] != _firebaseAuth.currentUser!.uid) {
      return Row(
        children: [
          const SizedBox(width: 10),
          Column(
            children: [
              icon,
              Text(
                // data['isRead'] +
                //     ' ' +
                dt.hour.toString() + ':' + dt.minute.toString(),
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      );
    } else {
      return Container();
    }
  }

  //build message input
  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          //textfield
          Expanded(
            child: MyTextField(
              controller: _messageController,
              hintText: 'Enter Message',
              obsecureText: false,
            ),
          ),

          //send button
          IconButton(
              onPressed: sendMessage,
              icon: const Icon(
                Icons.send,
                color: firstColor,
                size: 40,
              ))
        ],
      ),
    );
  }
}
