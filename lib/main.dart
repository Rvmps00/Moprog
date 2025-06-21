import 'package:fitcourse/screens/home.dart';
import 'package:fitcourse/screens/login.dart';
import 'package:fitcourse/screens/register.dart';
import 'package:fitcourse/screens/exercise.dart';
import 'package:fitcourse/screens/navigator.dart';
import 'package:fitcourse/screens/settings.dart';
 import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fitcourse/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitcourse/screens/get_started.dart';
import 'package:fitcourse/utils/page_route_builder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool hasSeenGetStarted = prefs.getBool('hasSeenGetStarted') ?? false;
  runApp(MyApp(hasSeenGetStarted: hasSeenGetStarted));
}

class MyApp extends StatelessWidget {
  final bool hasSeenGetStarted;
  const MyApp({Key? key, required this.hasSeenGetStarted}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.orange,
        hintColor: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFF111214),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
        fontFamily: 'PlusJakartaSans',
      ),
      onGenerateRoute: (settings) {
        if (settings.name == 'navigator') {
          return pageRouteBuilder(
            (context) => const NavigatorScreen(),
          );
        }
        return null;
      },
      home: hasSeenGetStarted
          ? StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasData) {
                  return const NavigatorScreen();
                }
                return const LoginScreen();
              },
            )
          : const GetStartedScreen(),
    );
  }
}
