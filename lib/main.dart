import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/select_team_screen.dart';
import 'screens/diary_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // MyApp 클래스 생성자에 const 추가
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'esamanru', // 앱 전역 폰트로 설정
      ),
      home: const SplashScreen(),
      routes: {
        '/SelectTeam': (context) => const SelectTeamScreen(), // 팀 선택 화면
        '/DiaryPage': (context) => const DiaryPage(), // 여기에 경로 추가
      },
    );
  }
}
