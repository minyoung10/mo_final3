import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../info/room.dart';
import '../../bottom/home.dart';

class EditNotification extends StatefulWidget {
  final String roomId;
  final String docId;

  const EditNotification({
    super.key,
    required this.roomId,
    required this.docId,
  });

  @override
  // ignore: library_private_types_in_public_api
  _EditNotificationState createState() => _EditNotificationState();
}

class _EditNotificationState extends State<EditNotification> {
  bool isFavorite = false;
  XFile? _pickedFile;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: firestore
            .collection('Smallinfo')
            .doc(widget.roomId)
            .collection('notifications')
            .snapshots(),
        builder: (BuildContext context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          final filteredDocs =
              docs.where((doc) => doc['id'] == widget.docId).toList();
          final roomSnapshot = filteredDocs.first;
          final roomData = roomSnapshot.data();
          final image = roomData['image'] as String;
          final title = roomData['title'] as String;
          final content = roomData['context'] as String;

          return Scaffold(
            appBar: AppBar(
              leading: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Center(
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              title: const Text('Edit'),
              actions: <Widget>[
                TextButton(
                  onPressed: () async {
                    final docRef = FirebaseFirestore.instance
                        .collection('Smallinfo')
                        .doc(widget.roomId)
                        .collection('notifications')
                        .doc(widget.docId);

                    await docRef.update({
                      "title": RoomProvider.title ?? roomData['title'],
                      "image": RoomProvider.image ?? roomData['image'],
                      "content": RoomProvider.context ?? roomData['content']
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _pickedFile != null
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          image: DecorationImage(
                              image: FileImage(File(_pickedFile!.path)),
                              fit: BoxFit.fitHeight),
                        ),
                        width: double.infinity,
                        height: 300,
                      )
                    : AspectRatio(
                        aspectRatio: 1 / 0.7,
                        child: Image.network(
                          width: MediaQuery.of(context).size.width,
                          image,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: () {
                        _getPhotoLibraryImage();
                      },
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        key: const ValueKey(1),
                        decoration: const InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFEFEFEF)),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFEFEFEF)),
                          ),
                        ),
                        initialValue: title,
                        onChanged: (value) {
                          setState(() {
                            RoomProvider.title = value;
                          });
                        },
                        onSaved: (value) {
                          RoomProvider.title = value;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        key: const ValueKey(2),
                        decoration: const InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFEFEFEF)),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFEFEFEF)),
                          ),
                        ),
                        initialValue: content,
                        onChanged: (value) {
                          setState(() {
                            RoomProvider.context = value;
                          });
                        },
                        onSaved: (value) {
                          RoomProvider.context = value;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }

  _getPhotoLibraryImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedFile = pickedFile;
      });
      _uploadImageToFirebase();
    } else {
      if (kDebugMode) {
        print('이미지 선택안함');
      }
    }
  }

  String? _uploadedImageUrl;
  Future<void> _uploadImageToFirebase() async {
    if (_pickedFile == null) {
      if (kDebugMode) {
        print('이미지가 선택되지 않았습니다.');
      }
      return;
    }

    final imageBytes = await File(_pickedFile!.path).readAsBytes();
    final imageName = DateTime.now().second.toString() + '.jpg';
    final storageReference = FirebaseStorage.instance.ref(imageName);

    try {
      await storageReference.putData(imageBytes);
      final TaskSnapshot taskSnapshot =
          await storageReference.putData(imageBytes);
      final imageUrl = await taskSnapshot.ref.getDownloadURL();
      setState(() {
        _uploadedImageUrl = imageUrl;
        RoomProvider.image = _uploadedImageUrl;
      });
      if (kDebugMode) {
        print('이미지 업로드 성공\n');
      }
    } catch (e) {
      if (kDebugMode) {
        print('이미지 업로드 실패: $e');
      }
    }
  }
}
