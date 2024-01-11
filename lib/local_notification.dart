import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:schbang/main.dart';

Future<void> showNotification(String title, String body, String payload) async {
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails('your channel id', 'your channel name',
          channelDescription: 'your channel description',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker');
  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidNotificationDetails);
  await flutterLocalNotificationsPlugin
      .show(1, title, body, notificationDetails, payload: payload);
}
