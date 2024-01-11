// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:schbang/chatlist.dart';
import 'package:schbang/groupmodal.dart';
import 'package:schbang/usermodal.dart' as user;
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;

import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<user.User> adduserList = [];
List membersList = [];
String uid = '';
String groupid = '';

class CreateGroupForm extends StatefulWidget {
  const CreateGroupForm({Key? key}) : super(key: key);

  @override
  _CreateGroupFormState createState() => _CreateGroupFormState();
}

class _CreateGroupFormState extends State<CreateGroupForm> {
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  String uploadedImage = '';
  String filepath = '';
  bool loading = false;
  getuser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    uid = prefs.getString('uid').toString();
    QuerySnapshot<Map<String, dynamic>> users = await FirebaseFirestore.instance
        .collection('Users')
        .where('id', isNotEqualTo: uid)
        .get();
    adduserList = [];
    for (var i = 0; i < users.docs.length; i++) {
      setState(() {
        adduserList.add(user.User.fromMap(users.docs[i].data()));
      });
    }
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

  getgroups() async {
    QuerySnapshot<Map<String, dynamic>> groups =
        await FirebaseFirestore.instance.collection('Groups').get();
    return groups.docs.length;
  }

  @override
  void initState() {
    super.initState();
    getuser();
    membersList = [];
    loading = false;
  }

  final int maxLengths = 30;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              centerTitle: true,
              leading: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: IconButton(
                    // padding: const EdgeInsets.only(right: 10.0, top: 5.0, bottom: 0.0, left: 0),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.arrow_back_ios,
                      size: 19,
                      color: Theme.of(context).primaryColorDark,
                    )),
              ),
              title: Padding(
                padding: const EdgeInsets.only(left: 0.0, bottom: 5),
                child: Text(
                  'Create Group',
                  style: GoogleFonts.poppins(
                      color: Theme.of(context).dividerColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
              ),
              actions: [
                GestureDetector(
                  onTap: () async {
                    if (nameController.text.isEmpty) {
                      Fluttertoast.showToast(
                          msg: 'Name Cannot be empty',
                          backgroundColor: Colors.red,
                          textColor: Colors.white);
                    } else if (membersList.isEmpty) {
                      Fluttertoast.showToast(
                          msg: 'Add atleast 1 members',
                          backgroundColor: Colors.red,
                          textColor: Colors.white);
                    } else {
                      setState(() {
                        loading = true;
                      });

                      membersList.add(uid);
                      groupid = (await getgroups() + 1).toString();
                      if (uploadedImage != '') {
                        filepath = await uploadMedia(uploadedImage);
                      }
                      FirebaseFirestore.instance.collection('Groups').add({
                        'groupname': nameController.text,
                        'groupdescription': descriptionController.text,
                        'profile': filepath,
                        'create_at': DateTime.now().toString(),
                        'members': membersList,
                        'type': 'group',
                        'id': groupid
                      });
                      userList.add(Group.fromMap({
                        'groupname': nameController.text,
                        'groupdescription': descriptionController.text,
                        'profile': filepath,
                        'create_at': DateTime.now().toString(),
                        'members': membersList,
                        'type': 'group',
                        'id': groupid
                      }));
                      Fluttertoast.showToast(msg: 'Group Created Sucessfully');
                      setState(() {
                        loading = false;
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: loading
                            ? const CupertinoActivityIndicator()
                            : Text('Create',
                                style: GoogleFonts.montserrat(
                                    color: Theme.of(context).primaryColorDark,
                                    textStyle: const TextStyle(
                                        fontSize: 16.5,
                                        letterSpacing: .05,
                                        fontWeight: FontWeight.w500)))),
                  ),
                ),
              ]),
          body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                  color: Theme.of(context).cardColor,
                  margin: const EdgeInsets.only(
                      left: 15.0, right: 15, top: 5, bottom: 5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 0.0, bottom: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                XFile? file = await ImagePicker()
                                    .pickImage(source: ImageSource.gallery);
                                if (file != null) {
                                  uploadedImage = file.path;
                                  setState(() {});
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(0),
                                child: Container(
                                  height: 90,
                                  width: 75,

                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        topRight: Radius.circular(10)),
                                  ),
                                  // child: ClipOval(
                                  child: uploadedImage != ''
                                      ? Image.file(
                                          File(uploadedImage),
                                          fit: BoxFit.cover,
                                        )
                                      : Center(
                                          child: Icon(
                                            Icons.camera,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                  // ),
                                ),
                              ),
                            ),
                            Expanded(
                                // width: 315,
                                // height: 40,
                                child: TextFormField(
                              cursorColor: Theme.of(context).primaryColorDark,
                              // inputFormatters: [
                              //   LengthLimitingTextInputFormatter(25),
                              // ],
                              controller: nameController,
                              maxLength: 25,
                              decoration: InputDecoration(
                                // border: InputBorder.none,

                                // counter: SizedBox( width: 0,
                                //   height: 0,),
                                // counterStyle: TextStyle(height: double.minPositive,color: Colors.black),
                                labelStyle: GoogleFonts.inter(
                                  color: Colors.grey.shade600,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                                filled: true,
                                fillColor: Theme.of(context).cardColor,

                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,

                                labelText: 'Group Name',

                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,

                                contentPadding: const EdgeInsets.only(
                                    bottom: 0, left: 15, right: 10),
                              ),
                              style: GoogleFonts.poppins(
                                color: Theme.of(context).primaryColorDark,
                                // fontFamily: 'Poppins',
                                fontSize: 14,
                                letterSpacing: 0,
                                fontWeight: FontWeight.normal,
                                // height: 1
                              ),
                              // (v) => null,
                              // false
                            )),
                          ],
                        ),
                      ],
                    ),
                  )),
              Container(
                margin: const EdgeInsets.only(
                    left: 15.0, right: 15, top: 0, bottom: 0),
                child: SizedBox(
                  // width: 315,
                  // height: 38,
                  child: TextFormField(
                    autofocus: false,
                    onChanged: (value) {
                      setState(() {});
                    },
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Description cannot be empty';
                      }
                      return null;
                    },
                    cursorColor: Theme.of(context).primaryColorDark,
                    minLines: 1,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    controller: descriptionController,
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).primaryColorDark,
                      // fontFamily: 'Poppins',
                      fontSize: 14,
                      letterSpacing: 0,
                      fontWeight: FontWeight.normal,
                      // height: 1
                    ),
                    decoration: InputDecoration(
                      // border: InputBorder.none,
                      errorStyle: const TextStyle(fontSize: 16.0),
                      labelStyle: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        // fontFamily: 'Poppins',
                        fontSize: 14.5,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w400,
                        // height: 1
                      ),

                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      errorBorder: InputBorder.none,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(7),
                          topRight: Radius.circular(7),
                          bottomLeft: Radius.circular(7),
                          bottomRight: Radius.circular(7),
                        ),
                        // borderSide: BorderSide(
                        //     width: 0.30, color:  Theme.of(context).primaryColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(7),
                          topRight: Radius.circular(7),
                          bottomLeft: Radius.circular(7),
                          bottomRight: Radius.circular(7),
                        ),
                        borderSide: BorderSide(
                            width: 0.30, color: Theme.of(context).primaryColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            width: 0.30, color: Theme.of(context).primaryColor),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(9),
                        ),
                      ),
                      labelText: 'Group Description',

                      floatingLabelBehavior: FloatingLabelBehavior.never,

                      contentPadding: const EdgeInsets.only(top: 10, left: 15),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: adduserList.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {},
                      child: Card(
                        elevation: 0,
                        margin:
                            const EdgeInsets.only(left: 2, right: 2, top: 5),
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
                                      child: Checkbox(
                                        activeColor:
                                            Theme.of(context).primaryColorDark,
                                        value: membersList
                                            .contains(adduserList[index].id),
                                        onChanged: (value) {
                                          if (value!) {
                                            setState(() {
                                              membersList
                                                  .add(adduserList[index].id);
                                            });
                                          } else {
                                            setState(() {
                                              membersList.remove(
                                                  adduserList[index].id);
                                            });
                                          }
                                        },
                                      )),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  Text(
                                                    adduserList[index].name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style:
                                                        GoogleFonts.varelaRound(
                                                            color: Theme.of(
                                                                    context)
                                                                .dividerColor,
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
                                                        // chat.createdAtMobile.toString(),
                                                        //  chat.createdAtMobile.toString().contains('.')? timeago.format(DateTime.parse(chat.createdAtMobile.toString().split('.')[0].toString())):timeago.format(DateTime.parse(chat.createdAtMobile.toString())),
                                                        '1 min ago',
                                                        style: GoogleFonts
                                                            .montserrat(
                                                                color: Theme.of(
                                                                        context)
                                                                    .dividerColor,
                                                                fontSize: 12,
                                                                letterSpacing:
                                                                    0,
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
                                        padding:
                                            const EdgeInsets.only(top: 20.0),
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
            ],
          ),
        ));
  }
}
