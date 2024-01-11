import 'package:flutter/material.dart';
import 'package:schbang/chatlist.dart';
import 'package:schbang/login.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings setting) {
    final args = setting.arguments;
    switch (setting.name) {
      case '/login':
        return MaterialPageRoute(
            builder: (BuildContext context) => const LoginPage());
      case '/chatlist':
        return MaterialPageRoute(
            builder: (BuildContext context) => Chatlist(args));
      default:
        return _errorRoute(setting.name);
    }
  }

  static Route<dynamic> _errorRoute(name) {
    return MaterialPageRoute(builder: (context) {
      return Scaffold(
        appBar: AppBar(title: const Text('ERROR')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Page Not Found $name'),
              Center(
                  child: ElevatedButton(
                style: ButtonStyle(
                    elevation: MaterialStateProperty.all(0),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.0),
                            side: const BorderSide(
                              color: Color(0xff00acee),
                            ))),
                    backgroundColor: MaterialStateProperty.all(
                        Theme.of(context).primaryColor)),
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (route) => false,
                      arguments: 0);
                },
                child: Text(
                  'Go to Login',
                  style: TextStyle(color: Theme.of(context).dividerColor),
                ),
              )),
            ],
          ),
        ),
      );
    });
  }
}
