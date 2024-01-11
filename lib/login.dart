// ignore_for_file: use_build_context_synchronously, empty_catches, deprecated_member_use

import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:page_transition/page_transition.dart';
import 'package:schbang/chatlist.dart';
import 'package:schbang/usermodal.dart' as user;
import 'package:shared_preferences/shared_preferences.dart';

GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: scopes,
);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

const List<String> scopes = <String>[
  'email',
  'https://www.googleapis.com/auth/contacts.readonly',
];

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  final _formKey = GlobalKey<FormState>();

  TextEditingController emailcontroller = TextEditingController();

  TextEditingController passcontroller = TextEditingController();

  bool showpass = true;

  ScrollController scrollController = ScrollController();

  String? googleAccessToken = '';
  String generateDummyName() {
    List<String> prefixes = ['John', 'Jane', 'Bob', 'Alice', 'Charlie'];
    List<String> suffixes = ['Doe', 'Smith', 'Johnson', 'Williams', 'Brown'];

    String randomPrefix = prefixes[Random().nextInt(prefixes.length)];
    String randomSuffix = suffixes[Random().nextInt(suffixes.length)];

    return '$randomPrefix $randomSuffix';
  }

  String name = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      emailcontroller.text = '';
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animationController.forward();
  }

  Future<void> _handleSignIn() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;
        googleAccessToken = googleSignInAuthentication.accessToken;

        prefs.setString('token', googleAccessToken.toString());
        prefs.setString('loginType', 'google');

        prefs.setString('uid', googleSignInAccount.id.toString());
        QuerySnapshot<Map<String, dynamic>> userpresent =
            await FirebaseFirestore.instance
                .collection('Users')
                .where('email', isEqualTo: googleSignInAccount.email)
                .get();
        var token = await FirebaseMessaging.instance.getToken();
        prefs.setString('fcm_token', token.toString());
        if (userpresent.docs.isEmpty) {
          name = generateDummyName();

          FirebaseFirestore.instance.collection('Users').add({
            'email': googleSignInAccount.email.toString(),
            'name': googleSignInAccount.displayName ?? name,
            'profile': '${googleSignInAccount.photoUrl}',
            'id': googleSignInAccount.id.toString(),
            'created_at': DateTime.now().toString(),
            'token': token
          });
        } else {
          name = googleSignInAccount.displayName.toString();
          DocumentReference userRef = FirebaseFirestore.instance
              .collection('Users')
              .doc(userpresent.docs[0].id);
          userRef.update({'token': token});
        }

        Navigator.push(
            context,
            PageTransition(
                type: PageTransitionType.fade,
                duration: const Duration(milliseconds: 400),
                opaque: true,
                // alignment: Alignment.topRight,
                child: Chatlist(user.User(
                    name: name,
                    profile: googleSignInAccount.photoUrl.toString(),
                    id: googleSignInAccount.id.toString(),
                    type: 'user',
                    created_at: DateTime.now().toString()))));
      }
    } catch (error) {}
  }

  String? validateEmail(String? value) {
    const pattern = r"(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'"
        r'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-'
        r'\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*'
        r'[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4]'
        r'[0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9]'
        r'[0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\'
        r'x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])';
    final regex = RegExp(pattern);

    if (value!.isEmpty) {
      return 'Field cannot be empty';
    } else if (!regex.hasMatch(value)) {
      return 'Enter a valid email address';
    } else {
      return null;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        resizeToAvoidBottomInset: true,
        // appBar: AppBar(
        //   elevation: 0,
        //   backgroundColor: Colors.transparent,
        // ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Center(
                      child: Container(
                          width: 130,
                          height: 130,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                                image: AssetImage('assets/logo1.png'),
                                fit: BoxFit.fitWidth),
                          )),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      "Welcome",
                      textAlign: TextAlign.left,
                      style: GoogleFonts.poppins(
                          color: Theme.of(context).primaryColorDark,
                          fontSize: 25,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w500,
                          height: 1),
                    ),
                  ),
                  Container(
                      // width: 324,
                      // height: 60,
                      // color: Colors.red,
                      padding:
                          const EdgeInsets.only(left: 30, right: 30, top: 50.0),
                      child: TextFormField(
                        controller: emailcontroller,
                        maxLines: 1,
                        validator: validateEmail,
                        cursorColor: Theme.of(context).primaryColorDark,
                        decoration: InputDecoration(
                            filled: true,
                            enabled: true,
                            errorStyle: const TextStyle(fontSize: 16.0),
                            fillColor: Theme.of(context).canvasColor,
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 0.50,
                                  color: Theme.of(context).dividerColor),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15),
                                bottomLeft: Radius.circular(15),
                                bottomRight: Radius.circular(15),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 0.50,
                                  color: Theme.of(context).dividerColor),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 0.50,
                                  color: Theme.of(context).dividerColor),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                            hintText: 'Email',
                            hintStyle: TextStyle(
                                color: Theme.of(context).dividerColor,
                                fontSize: 15),
                            hintTextDirection: TextDirection.ltr,
                            contentPadding: const EdgeInsets.only(top: 15),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: SvgPicture.asset(
                                'assets/email.svg',
                                color: Theme.of(context).dividerColor,
                                height: 10,
                              ),
                            )),
                        style: GoogleFonts.poppins(
                            color: Theme.of(context).primaryColorDark,
                            // fontFamily: 'Poppins',
                            fontSize: 14,
                            letterSpacing: 0,
                            fontWeight: FontWeight.normal,
                            height: 1),
                      )),
                  Padding(
                      padding:
                          const EdgeInsets.only(left: 30, right: 30, top: 20.0),
                      child: TextFormField(
                          controller: passcontroller,
                          maxLines: 1,
                          cursorColor: Theme.of(context).primaryColorDark,
                          decoration: InputDecoration(
                            filled: true,
                            enabled: true,
                            errorStyle: const TextStyle(fontSize: 16.0),
                            fillColor: Theme.of(context).canvasColor,
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 0.50,
                                  color: Theme.of(context).dividerColor),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15),
                                bottomLeft: Radius.circular(15),
                                bottomRight: Radius.circular(15),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 0.50,
                                  color: Theme.of(context).dividerColor),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 0.50,
                                  color: Theme.of(context).dividerColor),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                            hintText: 'Password',
                            hintStyle: TextStyle(
                                color: Theme.of(context).dividerColor,
                                fontSize: 15),
                            hintTextDirection: TextDirection.ltr,
                            contentPadding: const EdgeInsets.only(top: 15),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: SvgPicture.asset(
                                'assets/icon_lock_.svg',
                                color: Theme.of(context).dividerColor,
                                height: 10,
                              ),
                            ),
                            suffixIcon: GestureDetector(
                              onTap: () {
                                setState(() {
                                  showpass = !showpass;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    top: 5.0, bottom: 5.0, left: 14, right: 14),
                                child: SvgPicture.asset(
                                  showpass
                                      ? 'assets/eye_slash.svg'
                                      : 'assets/eye.svg',
                                  // 'assets/icons/comment.svg',
                                  color: Theme.of(context).dividerColor,
                                  height: 5,
                                  width: 5,
                                ),
                              ),
                            ),
                          ),
                          style: GoogleFonts.poppins(
                              color: Theme.of(context).primaryColorDark,
                              // fontFamily: 'Poppins',
                              fontSize: 14,
                              letterSpacing: 0,
                              fontWeight: FontWeight.normal,
                              height: 1),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Field cannot be empty';
                            } else if (value.length < 8) {
                              return 'Enter a strong Password';
                            } else {
                              return null;
                            }
                          },
                          obscureText: showpass)),
                  Container(
                    padding: const EdgeInsets.only(top: 60.0),
                    child: SizedBox(
                        width: 156,
                        height: 37,
                        child: FilledButton(
                          onPressed: () async {
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            if (_formKey.currentState!.validate()) {
                              try {
                                final credential = await FirebaseAuth.instance
                                    .createUserWithEmailAndPassword(
                                  email: emailcontroller.text,
                                  password: passcontroller.text,
                                );

                                prefs.setString(
                                    'uid', credential.user!.uid.toString());
                                var token =
                                    await FirebaseMessaging.instance.getToken();
                                prefs.setString('fcm_token', token.toString());
                                await credential.user!.getIdToken().then(
                                    (value) => prefs.setString(
                                        'token', value.toString()));

                                String name = generateDummyName();
                                FirebaseFirestore.instance
                                    .collection('Users')
                                    .add({
                                  'email': emailcontroller.text,
                                  'name': credential.user!.displayName ?? name,
                                  'profile': '${credential.user!.photoURL}',
                                  'id': credential.user!.uid.toString(),
                                  'token': token,
                                  'created_at': DateTime.now().toString()
                                });

                                Navigator.push(
                                    context,
                                    PageTransition(
                                        type: PageTransitionType.fade,
                                        duration:
                                            const Duration(milliseconds: 400),
                                        opaque: true,
                                        // alignment: Alignment.topRight,
                                        child: Chatlist(user.User(
                                            name: name,
                                            profile: credential.user!.photoURL
                                                .toString(),
                                            id: credential.user!.uid.toString(),
                                            type: 'user',
                                            created_at:
                                                DateTime.now().toString()))));
                              } on FirebaseAuthException catch (e) {
                                if (e.code == 'weak-password') {
                                  Fluttertoast.showToast(
                                      msg: 'The password provided is too weak.',
                                      backgroundColor: Colors.red,
                                      textColor: Colors.white);
                                } else if (e.code == 'email-already-in-use') {
                                  try {
                                    final credential2 = await FirebaseAuth
                                        .instance
                                        .signInWithEmailAndPassword(
                                      email: emailcontroller.text,
                                      password: passcontroller.text,
                                    );
                                    var token = await FirebaseMessaging.instance
                                        .getToken();
                                    prefs.setString(
                                        'fcm_token', token.toString());

                                    QuerySnapshot<Map<String, dynamic>>
                                        currentuser = await FirebaseFirestore
                                            .instance
                                            .collection('Users')
                                            .where('email',
                                                isEqualTo: emailcontroller.text
                                                    .toString())
                                            .get();
                                    DocumentReference userRef =
                                        FirebaseFirestore.instance
                                            .collection('Users')
                                            .doc(currentuser.docs[0].id);
                                    userRef.update({'token': token});
                                    await credential2.user!.getIdToken().then(
                                        (value) => prefs.setString(
                                            'token', value.toString()));

                                    prefs.setString('uid',
                                        currentuser.docs[0]['id'].toString());
                                    Navigator.push(
                                        context,
                                        PageTransition(
                                            type: PageTransitionType.fade,
                                            duration: const Duration(
                                                milliseconds: 400),
                                            opaque: true,
                                            child: Chatlist(user.User(
                                                name: currentuser.docs[0]
                                                        ['name']
                                                    .toString(),
                                                profile: currentuser.docs[0]
                                                        ['profile']
                                                    .toString(),
                                                id: currentuser.docs[0]['id']
                                                    .toString(),
                                                type: 'user',
                                                created_at: DateTime.now()
                                                    .toString()))));
                                  } on FirebaseAuthException catch (e) {
                                    if (e.code == 'wrong-password') {
                                      Fluttertoast.showToast(
                                          msg: 'Password is incorrect.',
                                          backgroundColor: Colors.red,
                                          textColor: Colors.white);
                                    } else if (e.code == 'invalid-credential') {
                                      Fluttertoast.showToast(
                                          msg: 'Inavlid Credentials.',
                                          backgroundColor: Colors.red,
                                          textColor: Colors.white);
                                    }
                                  }
                                }
                              } catch (e) {}
                            }
                          },
                          style: ButtonStyle(
                              overlayColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.pressed)) {
                                    return Colors.white.withOpacity(0.8);
                                  }
                                  return Colors.transparent;
                                },
                              ),
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      30.0), // Adjust the radius as needed
                                ),
                              ),
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Theme.of(context).primaryColorDark)),
                          child: Text(
                            'Submit',
                            textAlign: TextAlign.left,
                            style: GoogleFonts.poppins(
                                color: Theme.of(context).primaryColor,
                                // fontFamily: 'Poppins',
                                fontSize: 15,
                                letterSpacing:
                                    0 /*percentages not used in flutter. defaulting to zero*/,
                                fontWeight: FontWeight.w400,
                                height: 1),
                          ),
                        )),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 60.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 132,
                              height: 1,
                              color: Theme.of(context).dividerColor,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0, right: 8.0),
                              child: Text(
                                'OR',
                                textAlign: TextAlign.left,
                                style: GoogleFonts.poppins(
                                    color: Theme.of(context).dividerColor,
                                    // fontFamily: 'Poppins',
                                    fontSize: 15,
                                    letterSpacing: 0,
                                    fontWeight: FontWeight.normal,
                                    height: 1),
                              ),
                            ),
                            Container(
                              width: 135,
                              height: 1,
                              color: Theme.of(context).dividerColor,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 30.0,
                          left: 30,
                          right: 30,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _handleSignIn,
                                child: Container(
                                    padding: const EdgeInsets.all(4.0),
                                    margin: const EdgeInsets.all(8.0),
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(
                                          10,
                                        ),
                                      ),
                                      border: Border.all(
                                        color:
                                            Theme.of(context).primaryColorDark,
                                        width: 1.0,
                                      ),
                                      color: Theme.of(context).primaryColorDark,
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(width: 20),
                                          Image.asset('assets/google.png'),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Google',
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 20),
                                        ],
                                      ),
                                    )),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
