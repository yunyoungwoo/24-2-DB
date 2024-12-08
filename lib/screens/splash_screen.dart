import 'package:flutter/material.dart';
import 'select_team_screen.dart';
import '../database/database_helper.dart'; // DatabaseHelper import
import 'main_tab_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key}); // super-parameter 사용

  Future<Widget> _determineNextScreen() async {
    final teamID = await DatabaseHelper.instance.getUserTeam(); // Users 테이블 확인
    if (teamID != null) {
      return const MainTabScreen(); // 유저 정보가 있으면 일기 화면으로 이동
    }
    return const SelectTeamScreen(); // 유저 정보가 없으면 팀 선택 화면으로 이동
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _determineNextScreen(), // 다음 화면 결정
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // 로딩 완료 후 다음 화면으로 이동
          return snapshot.data!;
        }
        // 로딩 중인 경우
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
