import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/select_team_screen.dart';
import 'screens/main_tab_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'esamanru',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/select_team': (context) => const SelectTeamScreen(),
        '/main': (context) => const MainTabScreen(),
      },
    );
  }
}
