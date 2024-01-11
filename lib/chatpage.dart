// ignore_for_file: non_constant_identifier_names, empty_catches, use_build_context_synchronously

import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;
import 'package:schbang/usermodal.dart' as user;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

List registrationTokens = [];

class ChatPage extends StatefulWidget {
  final String name;
  final String id;
  final String profile;
  final String type;
  final String groupdescription;

  const ChatPage(
      this.name, this.id, this.profile, this.type, this.groupdescription,
      {super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textEditingController = TextEditingController();
  List<Map<String, dynamic>> messagelist = [];
  String uid = '';
  String fcm_token = '';
  ScrollController scrollcontroller = ScrollController(initialScrollOffset: 0);
  user.User currentuser =
      user.User(name: '', profile: '', id: '', type: '', created_at: '');

  String constructFCMPayload(String? token, user.User? currentuser) {
    return jsonEncode({
      'registration_ids': registrationTokens,
      'notification': {
        'title': 'Schbang',
        'body': 'New Message',
      },
      'data': {
        'name': widget.type == 'group' ? widget.name : currentuser!.name,
        'id': widget.type == 'group' ? widget.id : currentuser!.id,
        'profile':
            widget.type == 'group' ? widget.profile : currentuser!.profile,
        'type': widget.type,
        'groupdescription':
            widget.type == 'group' ? widget.groupdescription : '',
      }
    });
  }

  final Reference _mediaStorageReference =
      FirebaseStorage.instance.ref().child('media_messages');

  Future<String> uploadMedia(String filePath) async {
    final Reference storageReference =
        _mediaStorageReference.child(p.basename(filePath));
    final UploadTask uploadTask = storageReference.putFile(File(filePath));

    await uploadTask;
    final String downloadUrl = await storageReference.getDownloadURL();

    return downloadUrl;
  }

  Future<void> sendPushMessage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    uid = prefs.getString('uid').toString();
    if (widget.type == 'group') {
      QuerySnapshot<Map<String, dynamic>> group = await FirebaseFirestore
          .instance
          .collection('Groups')
          .where('id', isEqualTo: widget.id)
          .get();
      registrationTokens = [];
      for (var i = 0; i < group.docs[0]['members'].length; i++) {
        if (group.docs[0]['members'][i] != uid) {
          QuerySnapshot<Map<String, dynamic>> user = await FirebaseFirestore
              .instance
              .collection('Users')
              .where('id', isEqualTo: group.docs[0]['members'][i])
              .get();
          registrationTokens.add(user.docs[0]['token']);
        }
      }

      try {
        var res =
            await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
                headers: <String, String>{
                  'Content-Type': 'application/json; charset=UTF-8',
                  'Authorization':
                      'key=AAAAysVaOrM:APA91bHQy68qLNZ-zow4IslZGqAExS1AhMWgcMtNmqadM8S8nrq7N8kCVHTD5ur8FsLtLXPicTlzwTLg9xIYF2BpJa6c2Od-SrxYawo8YlKXlDopdpzGafaI7a8lWvtwZaC9ynduxB5r'
                },
                body: jsonEncode({
                  'registration_ids': registrationTokens,
                  'notification': {
                    'title': 'Schbang',
                    'body': 'New Message',
                  },
                  'data': {
                    'name':
                        widget.type == 'group' ? widget.name : currentuser.name,
                    'id': widget.type == 'group' ? widget.id : currentuser.id,
                    'profile': widget.type == 'group'
                        ? widget.profile
                        : currentuser.profile,
                    'type': widget.type,
                    'from_id': widget.id,
                    'groupdescription':
                        widget.type == 'group' ? widget.groupdescription : '',
                  }
                }));

        log('FCM request for device sent! ${res.body}');
      } catch (e) {}
    } else {
      QuerySnapshot<Map<String, dynamic>> user = await FirebaseFirestore
          .instance
          .collection('Users')
          .where('id', isEqualTo: widget.id)
          .get();
      fcm_token = user.docs[0]['token'];

      try {
        var res =
            await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
                headers: <String, String>{
                  'Content-Type': 'application/json; charset=UTF-8',
                  'Authorization':
                      'key=AAAAysVaOrM:APA91bHQy68qLNZ-zow4IslZGqAExS1AhMWgcMtNmqadM8S8nrq7N8kCVHTD5ur8FsLtLXPicTlzwTLg9xIYF2BpJa6c2Od-SrxYawo8YlKXlDopdpzGafaI7a8lWvtwZaC9ynduxB5r'
                },
                body: jsonEncode({
                  'to': fcm_token.toString(),
                  'notification': {
                    'title': 'Schbang',
                    'body': 'New Message',
                  },
                  'data': {
                    'name': currentuser.name,
                    'id': widget.id,
                    'from_id': currentuser.id,
                    'profile': currentuser.profile,
                    'type': 'user',
                    'groupdescription':
                        widget.type == 'group' ? widget.groupdescription : '',
                  }
                }));
        log('FCM request for device sent! ${res.body}');
      } catch (e) {}
    }
  }

  getuid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    uid = prefs.getString('uid').toString();
    print('uid $uid ${widget.id}');
    prefs.setBool('chat_${widget.id}', true);

    QuerySnapshot<Map<String, dynamic>> current = await FirebaseFirestore
        .instance
        .collection('Users')
        .where('id', isEqualTo: uid)
        .get();
    setState(() {
      currentuser = user.User.fromMap(current.docs[0].data());
    });
  }

  getmessage() async {
    QuerySnapshot<Map<String, dynamic>> messages = await FirebaseFirestore
        .instance
        .collection('Messages')
        .orderBy('create_at')
        .get();
    messagelist = [];
    for (var i = 0; i < messages.docs.length; i++) {
      var message = messages.docs[i].data();
      if (widget.type == 'group') {
        if (message['group_id'] == widget.id.toString()) {
          messagelist.add(messages.docs[i].data());
        }
      } else {
        if ((message['from_user_id'] == widget.id.toString() &&
                message['to_user_id'] == uid) ||
            (message['from_user_id'] == uid &&
                message['to_user_id'] == widget.id.toString())) {
          messagelist.add(messages.docs[i].data());
        }
      }
    }
    messagelist = messagelist.reversed.toList();
  }

  insertmessage(snapshot) async {
    messagelist = [];
    for (var i = 0; i < snapshot.data!.docs.length; i++) {
      var message = snapshot.data!.docs[i].data();
      if (widget.type == 'group') {
        if (message['group_id'] == widget.id.toString()) {
          messagelist.add(snapshot.data!.docs[i].data());
        }
      } else {
        if ((message['from_user_id'] == widget.id.toString() &&
                message['to_user_id'] == uid) ||
            (message['from_user_id'] == uid &&
                message['to_user_id'] == widget.id.toString())) {
          messagelist.add(snapshot.data!.docs[i].data());
        }
      }
    }
    messagelist = messagelist.reversed.toList();
  }

  @override
  void initState() {
    super.initState();

    getuid();
    getmessage();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Stack(
        children: [
          Container(
            color: Colors.grey,
            child: Image.asset(
              'assets/${MediaQuery.of(context).platformBrightness == Brightness.dark ? 'chatbgdark.jpg' : 'chatbg.jpg'}',
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.cover,
            ),
          ),
          PopScope(
            canPop: true,
            onPopInvoked: (didPop) async {
              SharedPreferences prefs = await SharedPreferences.getInstance();

              prefs.setBool('chat_${widget.id}', false);
            },
            child: Scaffold(
              backgroundColor: Colors.transparent,
              extendBodyBehindAppBar: true,
              appBar: PreferredSize(
                  preferredSize: const Size.fromHeight(50),
                  child: ClipRRect(
                      child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: AppBar(
                            elevation: 0,
                            backgroundColor:
                                Theme.of(context).primaryColor.withOpacity(.4),
                            centerTitle: true,
                            title: Column(
                              children: [
                                Text(
                                  widget.name,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColorDark,
                                    fontSize: 17,
                                    fontFamily: 'SF Pro Text',
                                    fontWeight: FontWeight.w500,
                                    height: 1.29,
                                    letterSpacing: -0.40,
                                  ),
                                ),
                                Text(
                                  widget.groupdescription,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                    fontFamily: 'SF Pro Text',
                                    fontWeight: FontWeight.w400,
                                    // height: 1.29,
                                    letterSpacing: -0.40,
                                  ),
                                )
                              ],
                            ),
                            leading: GestureDetector(
                              onTap: () async {
                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();

                                prefs.setBool('chat_${widget.id}', false);
                                Navigator.pop(context);
                              },
                              child: Container(
                                color: Colors.transparent,
                                child: Icon(
                                  Icons.arrow_back_ios,
                                  color: Theme.of(context).primaryColorDark,
                                  size: 22,
                                ),
                              ),
                            ),
                            actions: [
                              GestureDetector(
                                onTap: () {},
                                child: Hero(
                                  tag: 'ImageAvatar',
                                  child: Padding(
                                      padding: const EdgeInsets.only(
                                          right: 13.0, bottom: 8),
                                      child: SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: CircleAvatar(
                                          radius: 55,
                                          backgroundColor: Colors.grey,
                                          child: CircleAvatar(
                                            backgroundColor: Colors.transparent,
                                            radius: 50,
                                            backgroundImage: widget.profile
                                                            .toString() !=
                                                        'null' &&
                                                    widget.profile.toString() !=
                                                        ''
                                                ? NetworkImage(
                                                    widget.profile,
                                                  )
                                                : null,
                                            child: Center(
                                                child: widget.profile
                                                                .toString() ==
                                                            'null' ||
                                                        widget.profile
                                                                .toString() ==
                                                            ''
                                                    ? Text(
                                                        widget.name
                                                            .toString()
                                                            .toUpperCase()
                                                            .substring(0, 1)
                                                            .toString(),
                                                        style: GoogleFonts
                                                            .varelaRound(
                                                          color: Colors.white,
                                                          fontSize: 17,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        )
                                                        //  textstyle.copyWith(
                                                        //     color: Colors.white,fontSize: 18,fontWeight:FontWeight.bold, )

                                                        )
                                                    : null),
                                          ),
                                        ),
                                      )),
                                ),
                              ),
                            ],
                          )))),
              body: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('Messages')
                      .orderBy('create_at')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    insertmessage(snapshot);

                    return ListView.builder(
                      itemCount: messagelist.length,
                      controller: scrollcontroller,
                      reverse: true,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return messagelist[index]['from_user_id'].toString() !=
                                uid.toString()
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: const Color(0xffE7E7ED),
                                      borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.only(
                                      top: 5, bottom: 5, left: 5, right: 5),
                                  margin: const EdgeInsets.only(
                                      top: 5, left: 5, bottom: 5),
                                  constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.7,
                                      maxHeight: 450),
                                  child: messagelist[index]['media'] != ''
                                      ? GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return GestureDetector(
                                                  onVerticalDragEnd:
                                                      (DragEndDetails details) {
                                                    if (details
                                                            .primaryVelocity! >
                                                        0) {
                                                      Navigator.pop(context);
                                                    }
                                                  },
                                                  child: Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      Image.network(
                                                        messagelist[index]
                                                                ['media']
                                                            .toString(),
                                                      ),
                                                      // ),
                                                      Positioned(
                                                        top: 40,
                                                        right: 20,
                                                        child: GestureDetector(
                                                          onTap: () =>
                                                              Navigator.pop(
                                                                  context),
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Theme.of(
                                                                      context)
                                                                  .dividerColor
                                                                  .withOpacity(
                                                                      0.5),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20),
                                                            ),
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8),
                                                            child: const Icon(
                                                                Icons.close,
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                          child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Stack(
                                                children: [
                                                  CachedNetworkImage(
                                                      imageUrl:
                                                          messagelist[index]
                                                              ['media']),
                                                  Positioned(
                                                    bottom: 5,
                                                    right: 5,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                          color: Colors.black26,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10)),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              3),
                                                      child: Text(
                                                        DateFormat('h:mm a').format(
                                                            DateTime.parse((messagelist[
                                                                        index][
                                                                    'create_at']
                                                                .toString()))),
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 12),
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 5,
                                                    left: 5,
                                                    child:
                                                        widget.type == 'group'
                                                            ? Container(
                                                                decoration: BoxDecoration(
                                                                    color: Colors
                                                                        .black26,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            10)),
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(3),
                                                                child: Text(
                                                                  '${messagelist[index]['name']}',
                                                                  style: const TextStyle(
                                                                      color: Colors
                                                                          .black,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          12),
                                                                ),
                                                              )
                                                            : SizedBox.shrink(),
                                                  ),
                                                ],
                                              )),
                                        )
                                      : IntrinsicWidth(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              widget.type == 'group'
                                                  ? Text(
                                                      '${messagelist[index]['name']}',
                                                      style: const TextStyle(
                                                          color: Colors.black,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12),
                                                    )
                                                  : SizedBox.shrink(),
                                              Text(
                                                messagelist[index]['message']
                                                    .toString(),
                                                style: const TextStyle(
                                                    color: Colors.black),
                                              ),
                                              Align(
                                                alignment:
                                                    Alignment.bottomRight,
                                                child: Text(
                                                  DateFormat('h:mm a').format(
                                                      DateTime.parse(
                                                          (messagelist[index]
                                                                  ['create_at']
                                                              .toString()))),
                                                  style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                ),
                              )
                            : Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.only(
                                      top: 5, bottom: 5, right: 5, left: 5),
                                  margin: const EdgeInsets.only(
                                      top: 5, right: 5, bottom: 5),
                                  constraints: BoxConstraints(
                                    maxHeight: 450,
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  child: messagelist[index]['media'] != '' &&
                                          messagelist[index]['media_type'] ==
                                              '1'
                                      ? GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return GestureDetector(
                                                  onVerticalDragEnd:
                                                      (DragEndDetails details) {
                                                    if (details
                                                            .primaryVelocity! >
                                                        0) {
                                                      Navigator.pop(context);
                                                    }
                                                  },
                                                  child: Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      Image.network(
                                                        messagelist[index]
                                                                ['media']
                                                            .toString(),
                                                      ),
                                                      // ),
                                                      Positioned(
                                                        top: 40,
                                                        right: 20,
                                                        child: GestureDetector(
                                                          onTap: () =>
                                                              Navigator.pop(
                                                                  context),
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Theme.of(
                                                                      context)
                                                                  .dividerColor
                                                                  .withOpacity(
                                                                      0.5),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20),
                                                            ),
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8),
                                                            child: const Icon(
                                                                Icons.close,
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                          child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Stack(
                                                children: [
                                                  CachedNetworkImage(
                                                    imageUrl: messagelist[index]
                                                        ['media'],
                                                    progressIndicatorBuilder:
                                                        (context, url,
                                                            progress) {
                                                      return const CircularProgressIndicator();
                                                    },
                                                  ),
                                                  Positioned(
                                                    bottom: 5,
                                                    right: 5,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                          color: Colors.black26,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10)),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              3),
                                                      child: Text(
                                                        DateFormat('h:mm a').format(
                                                            DateTime.parse((messagelist[
                                                                        index][
                                                                    'create_at']
                                                                .toString()))),
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 12),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )),
                                        )
                                      : IntrinsicWidth(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                messagelist[index]['message']
                                                    .toString(),
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                              Align(
                                                alignment: Alignment.bottomLeft,
                                                child: Text(
                                                  DateFormat('h:mm a').format(
                                                      DateTime.parse(
                                                          (messagelist[index]
                                                                  ['create_at']
                                                              .toString()))),
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                ),
                              );
                      },
                    );
                  }),
              bottomNavigationBar: Padding(
                padding: MediaQuery.of(context).viewInsets,
                child: Container(
                  color: Theme.of(context).primaryColor.withOpacity(.4),
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      GestureDetector(
                          onTap: () async {
                            XFile? file = await ImagePicker()
                                .pickImage(source: ImageSource.gallery);
                            if (file != null) {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return Dialog(
                                    backgroundColor:
                                        Theme.of(context).cardColor,
                                    insetPadding: const EdgeInsets.all(20),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: SizedBox(
                                      width:
                                          MediaQuery.of(context).size.width / 2,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text(
                                                'Sending Image',
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            const Text(
                                              '1/1',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w400),
                                            ),
                                            const SizedBox(height: 10),
                                            LinearProgressIndicator(
                                                color: Theme.of(context)
                                                    .indicatorColor,
                                                backgroundColor: Colors.grey),
                                            const SizedBox(height: 20)
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );

                              var uploadedeFile1 = await uploadMedia(file.path);

                              setState(() {
                                messagelist.add({
                                  'media_type': '1',
                                  'to_user_id': widget.id,
                                  'media': uploadedeFile1,
                                  'create_at': DateTime.now().toString(),
                                  'message': _textEditingController.text,
                                  'from_user_id': uid,
                                  'group_id':
                                      widget.type == 'group' ? widget.id : ''
                                });
                                FirebaseFirestore.instance
                                    .collection('Messages')
                                    .add({
                                  'media_type': '1',
                                  'to_user_id': widget.id,
                                  'media': uploadedeFile1,
                                  'name': currentuser.name,
                                  'create_at': DateTime.now().toString(),
                                  'message': _textEditingController.text,
                                  'from_user_id': uid,
                                  'group_id':
                                      widget.type == 'group' ? widget.id : ''
                                });
                              });
                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            color: Colors.transparent,
                            child: const Padding(
                              padding: EdgeInsets.only(left: 8.0, bottom: 10),
                              child: Icon(Icons.image),
                            ),
                          )),
                      Expanded(
                        flex: 6,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 0,
                          ),
                          child: Container(
                            padding: const EdgeInsets.only(
                                left: 13, right: 5, bottom: 10),
                            width: 250,
                            // height:
                            //     35,
                            child: CupertinoTextField(
                                onTap: () {},
                                onChanged: (value) {
                                  setState(() {});
                                },
                                padding: const EdgeInsets.only(
                                    top: 5, bottom: 5, left: 8),
                                cursorColor: Theme.of(context).dividerColor,
                                keyboardType: TextInputType.multiline,
                                minLines: 1,
                                maxLines: 6,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                controller: _textEditingController,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColorDark,
                                ),
                                placeholder: 'Message',
                                placeholderStyle: GoogleFonts.inter(
                                  color: Theme.of(context).dividerColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                                // cursorHeight: 15,
                                scrollPadding: EdgeInsets.zero,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      width: 0.50, color: Colors.grey),
                                  // color: Color(0xffC9CCD1).withOpacity(.25),
                                  borderRadius: BorderRadius.circular(10),
                                )),
                          ),
                        ),
                      ),
                      Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: _textEditingController.text != '' &&
                                    _textEditingController.text
                                        .replaceAll(RegExp(r'\s'), '')
                                        .isNotEmpty
                                ? () async {
                                    try {
                                      messagelist.add({
                                        'media_type': '',
                                        'to_user_id': widget.id,
                                        'media': '',
                                        'name': currentuser.name,
                                        'create_at': DateTime.now().toString(),
                                        'message': _textEditingController.text,
                                        'from_user_id': uid,
                                        'group_id': widget.type == 'group'
                                            ? widget.id
                                            : ''
                                      });
                                      FirebaseFirestore.instance
                                          .collection('Messages')
                                          .add({
                                        'media_type': '',
                                        'to_user_id': widget.id,
                                        'media': '',
                                        'name': currentuser.name,
                                        'create_at': DateTime.now().toString(),
                                        'message': _textEditingController.text,
                                        'from_user_id': uid,
                                        'group_id': widget.type == 'group'
                                            ? widget.id
                                            : ''
                                      });
                                      sendPushMessage();
                                      try {
                                        scrollcontroller.animateTo(0,
                                            duration: const Duration(
                                                microseconds: 10),
                                            curve: Curves.linear);
                                      } catch (e) {}

                                      _textEditingController.clear();
                                      setState(() {});
                                    } catch (E) {}
                                  }
                                : () {},
                            child: Container(
                              color: Colors.transparent,
                              child: const Padding(
                                  padding: EdgeInsets.only(
                                      left: 5.0, bottom: 10, right: 5, top: 5),
                                  child: Icon(Icons.send)),
                            ),
                          ))
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
