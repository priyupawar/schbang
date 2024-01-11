import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:schbang/custom_theme.dart';
import 'package:schbang/route_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

String initialroute = '';
bool isLoggedin = false;
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final StreamController<String?> selectNotificationStream =
    StreamController<String?>.broadcast();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ignore: non_constant_identifier_names
  FirebaseApp App = await Firebase.initializeApp(
      options: const FirebaseOptions(
    apiKey: 'AIzaSyCosScBfgilF75z5ucFx23m5OSzJ9pQFrc',
    appId: '1:870894418611:android:06768f650adc002fc64ec6',
    messagingSenderId: '870894418611',
    projectId: 'schbang-c29a7',
    databaseURL: 'https://schbang-c29a7-default-rtdb.firebaseio.com',
    storageBucket: 'gs://schbang-c29a7.appspot.com',
  ));

  FirebaseFirestore.instanceFor(app: App);
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (prefs.getString('token').toString() != 'null') {
    initialroute = '/chatlist';
  } else {
    initialroute = '/login';
  }
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) {
      switch (notificationResponse.notificationResponseType) {
        case NotificationResponseType.selectedNotification:
          selectNotificationStream.add(notificationResponse.payload);
          break;
        case NotificationResponseType.selectedNotificationAction:
          selectNotificationStream.add(notificationResponse.payload);

          break;
      }
    },
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<void> checkAuthentication() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('token').toString() != 'null') {
      initialroute = '/chatlist';
    } else {
      initialroute = '/login';
    }
  }

  ThemeData _getThemeData(BuildContext context) {
    final Brightness brightnessValue =
        MediaQuery.of(context).platformBrightness;
    bool isDark = brightnessValue == Brightness.dark;

    return isDark ? darkTheme : lightTheme;
  }

  @override
  Widget build(BuildContext context) {
    checkAuthentication();
    return MaterialApp(
      title: 'Schbang',
      debugShowCheckedModeBanner: false,
      theme: _getThemeData(context),
      initialRoute: initialroute,
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
