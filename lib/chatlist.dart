// ignore_for_file: prefer_typing_uninitialized_variables, use_build_context_synchronously

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:schbang/chatpage.dart';
import 'package:schbang/creategroup.dart';
import 'package:schbang/groupmodal.dart';
import 'package:schbang/local_notification.dart';
import 'package:schbang/login.dart';
import 'package:schbang/main.dart';
import 'package:schbang/usermodal.dart' as user;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

List userList = [];
RefreshController _refreshController = RefreshController(initialRefresh: false);

class Chatlist extends StatefulWidget {
  final user;
  const Chatlist(this.user, {super.key});

  @override
  State<Chatlist> createState() => _ChatlistState();
}

class _ChatlistState extends State<Chatlist> {
  user.User currentuser =
      user.User(name: '', profile: '', id: '', type: '', created_at: '');
  Future getuser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var uid = prefs.getString('uid').toString();
    QuerySnapshot<Map<String, dynamic>> current = await FirebaseFirestore
        .instance
        .collection('Users')
        .where('id', isEqualTo: uid)
        .get();
    currentuser = user.User.fromMap(current.docs[0].data());
    QuerySnapshot<Map<String, dynamic>> users = await FirebaseFirestore.instance
        .collection('Users')
        .where('id', isNotEqualTo: uid)
        .get();

    userList = [];
    for (var i = 0; i < users.docs.length; i++) {
      setState(() {
        userList.add(user.User.fromMap(users.docs[i].data()));
      });
    }
    QuerySnapshot<Map<String, dynamic>> groups = await FirebaseFirestore
        .instance
        .collection('Groups')
        .where('members', arrayContains: uid)
        .get();
    for (var i = 0; i < groups.docs.length; i++) {
      setState(() {
        // print('${users.docs[i].data()}');

        userList.add(Group.fromMap(groups.docs[i].data()));
      });
    }
    return true;
  }

  getpermission() async {
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
    } else {}
  }

  setupnotification() async {
    await FirebaseMessaging.instance.subscribeToTopic('chat_notification');

    FirebaseMessaging.onMessage.listen(
      (RemoteMessage messsage) async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        print('onmessage ${prefs.getBool('chat_${messsage.data['from_id']}')}');
        if (prefs.getBool('chat_${messsage.data['from_id']}') == null ||
            !prefs.getBool('chat_${messsage.data['from_id']}')!) {
          showNotification(
              messsage.notification!.title.toString(),
              messsage.notification!.body.toString(),
              jsonEncode(messsage.data));
        }

        // print('event $event');
      },
    );
    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage messsage) async {
        Navigator.push(
            context,
            PageTransition(
                type: PageTransitionType.fade,
                duration: const Duration(milliseconds: 400),
                opaque: true,
                // alignment: Alignment.topRight,
                child: ChatPage(
                    messsage.data['name'],
                    messsage.data['from_id'],
                    messsage.data['profile'].toString(),
                    messsage.data['type'],
                    messsage.data['groupdescription'])));
      },
    );

    selectNotificationStream.stream.listen((String? payload) async {
      print('payload $payload');
      var data = jsonDecode(payload.toString());
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.fade,
              duration: const Duration(milliseconds: 400),
              opaque: true,
              // alignment: Alignment.topRight,
              child: ChatPage(
                  data['name'],
                  data['from_id'],
                  data['profile'].toString(),
                  data['type'],
                  data['groupdescription'])));
    });
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      getuser();
      getpermission();
      setupnotification();
    });
  }

  @override
  void dispose() {
    selectNotificationStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Hero(
          tag: 'UserAvatar',
          child: Padding(
              padding: const EdgeInsets.only(left: 13.0, bottom: 8),
              child: GestureDetector(
                onTap:
                    currentuser.profile != 'null' && currentuser.profile != ''
                        ? () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return GestureDetector(
                                  onVerticalDragEnd: (DragEndDetails details) {
                                    if (details.primaryVelocity! > 0) {
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Image.network(
                                        currentuser.profile.toString(),
                                      ),
                                      // ),
                                      Positioned(
                                        top: 40,
                                        right: 20,
                                        child: GestureDetector(
                                          onTap: () => Navigator.pop(context),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .dividerColor
                                                  .withOpacity(0.5),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.all(8),
                                            child: const Icon(Icons.close,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          }
                        : () {},
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.grey,
                    child: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      radius: 50,
                      backgroundImage:
                          currentuser.profile.toString() != 'null' &&
                                  currentuser.profile.toString() != ''
                              ? NetworkImage(
                                  currentuser.profile,
                                )
                              : null,
                      child: Center(
                          child: currentuser.profile.toString() == 'null' ||
                                  currentuser.profile.toString() == ''
                              ? Text(
                                  currentuser.name != ''
                                      ? currentuser.name
                                          .toString()
                                          .toUpperCase()
                                          .substring(0, 1)
                                          .toString()
                                      : "",
                                  style: GoogleFonts.varelaRound(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  )
                                  //  textstyle.copyWith(
                                  //     color: Colors.white,fontSize: 18,fontWeight:FontWeight.bold, )

                                  )
                              : null),
                    ),
                  ),
                ),
              )),
        ),
        actions: [
          IconButton(
              onPressed: () async {
                Navigator.push(
                        context,
                        PageTransition(
                            type: PageTransitionType.fade,
                            duration: const Duration(milliseconds: 400),
                            opaque: true,
                            // alignment: Alignment.topRight,
                            child: const CreateGroupForm()))
                    .whenComplete(() => setState(() {}));
              },
              icon: const Icon(
                Icons.add,
                color: Colors.blue,
              )),
          IconButton(
              onPressed: () async {
                showDialog(
                  context: context,
                  builder: (context) {
                    return Dialog(
                      backgroundColor: Theme.of(context).primaryColor,
                      insetPadding: const EdgeInsets.all(20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Are you sure you want to logout?',
                                  style: TextStyle(
                                      fontSize: 20,
                                      color:
                                          Theme.of(context).primaryColorDark),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  if (prefs.getString('loginType') ==
                                      'google') {
                                    googleSignIn.signOut();
                                  } else {
                                    FirebaseAuth.instance.signOut();
                                  }
                                  prefs.clear();

                                  Navigator.pushAndRemoveUntil<void>(
                                    context,
                                    MaterialPageRoute<void>(
                                        builder: (BuildContext context) =>
                                            const LoginPage()),
                                    ModalRoute.withName('/login'),
                                  );
                                },
                                child: Card(
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Center(
                                          child: Text("YES",
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.blue))),
                                    )),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                child: Card(
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    child: const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Center(
                                          child: Text("NO",
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.red)),
                                        ))),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              icon: const Icon(
                Icons.power_settings_new_rounded,
                color: Colors.red,
              ))
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SmartRefresher(
              enablePullDown: true,
              enablePullUp: false,
              header: CustomHeader(
                builder: (BuildContext context, RefreshStatus? mode) {
                  Widget body;
                  if (mode == RefreshStatus.idle) {
                    body = const Text("pull up load");
                  } else if (mode == RefreshStatus.refreshing) {
                    body = const CupertinoActivityIndicator();
                  } else if (mode == RefreshStatus.failed) {
                    body = const Text("Load Failed!Click retry!");
                  } else {
                    body = const Text("No more Data");
                  }
                  return SizedBox(
                    height: 55.0,
                    child: Center(child: body),
                  );
                },
              ),
              controller: _refreshController,
              onRefresh: () {
                getuser().then((value) {
                  if (value) {
                    _refreshController.refreshCompleted();
                    setState(() {});
                  }
                });
              },
              child: ListView.builder(
                itemCount: userList.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          PageTransition(
                              type: PageTransitionType.fade,
                              duration: const Duration(milliseconds: 400),
                              opaque: true,
                              // alignment: Alignment.topRight,
                              child: ChatPage(
                                "${userList[index].name}",
                                userList[index].id.toString(),
                                userList[index].profile,
                                userList[index].type,
                                userList[index].type == 'group'
                                    ? userList[index].description
                                    : '',
                              )));
                    },
                    child: Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(left: 2, right: 2, top: 5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                      // color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5.0, right: 5),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 0,
                                child: Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 0.0, left: 5, right: 5),
                                    child: GestureDetector(
                                      onTap: userList[index]
                                                      .profile
                                                      .toString() !=
                                                  'null' &&
                                              userList[index]
                                                      .profile
                                                      .toString() !=
                                                  ''
                                          ? () {
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return GestureDetector(
                                                    onVerticalDragEnd:
                                                        (DragEndDetails
                                                            details) {
                                                      if (details
                                                              .primaryVelocity! >
                                                          0) {
                                                        Navigator.pop(context);
                                                      }
                                                    },
                                                    child: Stack(
                                                      alignment:
                                                          Alignment.center,
                                                      children: [
                                                        Image.network(
                                                          userList[index]
                                                              .profile
                                                              .toString(),
                                                        ),
                                                        // ),
                                                        Positioned(
                                                          top: 40,
                                                          right: 20,
                                                          child:
                                                              GestureDetector(
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
                                            }
                                          : () {},
                                      child: SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: CircleAvatar(
                                          radius: 55,
                                          backgroundColor: Colors.grey,
                                          child: CircleAvatar(
                                            backgroundColor: Colors.transparent,
                                            radius: 50,
                                            backgroundImage: userList[index]
                                                            .profile
                                                            .toString() !=
                                                        'null' &&
                                                    userList[index]
                                                            .profile
                                                            .toString() !=
                                                        ''
                                                ? NetworkImage(
                                                    userList[index].profile,
                                                  )
                                                : null,
                                            child: Center(
                                                child: userList[index]
                                                                .profile
                                                                .toString() ==
                                                            'null' ||
                                                        userList[index]
                                                                .profile
                                                                .toString() ==
                                                            ''
                                                    ? Text(
                                                        userList[index]
                                                            .name
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
                                      ),
                                    )),
                              ),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 7.0, bottom: 0, top: 10),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Text(
                                                  "${userList[index].name}",
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style:
                                                      GoogleFonts.varelaRound(
                                                          color: Theme.of(
                                                                  context)
                                                              .primaryColorDark,
                                                          fontSize: 17,
                                                          letterSpacing: 0,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          height: 1.2),
                                                  // style: GoogleFonts.hind(
                                                  //     fontSize: 15,
                                                  //     fontWeight: FontWeight.w700,
                                                  //     color: Theme.of(context).dividerColor),
                                                ),
                                                const SizedBox(
                                                  height: 8,
                                                ),
                                                Text(
                                                  'Message',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 13,
                                                      height: 1,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 5.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    // Padding(
                                                    //   padding: const EdgeInsets
                                                    //           .only(
                                                    //       right:
                                                    //           6.0),
                                                    //   child: SvgPicture
                                                    //       .asset(
                                                    //     'assets/Shape.svg',
                                                    //     height:
                                                    //         8,
                                                    //     width:
                                                    //         8,
                                                    //   ),
                                                    // ),
                                                    Text(
                                                      DateFormat('h:mm a')
                                                          .format(DateTime
                                                              .parse((userList[
                                                                      index]
                                                                  .created_at
                                                                  .toString()))),
                                                      style: GoogleFonts
                                                          .montserrat(
                                                              color: Theme.of(
                                                                      context)
                                                                  .dividerColor,
                                                              fontSize: 12,
                                                              letterSpacing: 0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w300,
                                                              height: 1.2),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 20.0),
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        height: 0,
                                        color: Colors.grey.shade400,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
