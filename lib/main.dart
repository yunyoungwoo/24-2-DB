import 'package:flutter/material.dart';
import 'writeDiary.dart'; // GameDiaryScreen을 사용하기 위해 import
import 'database_helper.dart'; // DatabaseHelper 초기화를 위해 import

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 비동기 초기화를 위해 필요
  await DatabaseHelper().initializeDatabase(); // 앱 시작 시 데이터베이스 초기화
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // 디버그 배너 제거
      theme: ThemeData(
        fontFamily: 'Pretendard', // pubspec.yaml에서 설정한 폰트 이름
        primarySwatch: Colors.blue, // 기본 색상 설정
      ),
      home: GameDiaryScreen(), // 초기 화면 설정
    );
  }
}

