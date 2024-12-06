import 'package:flutter/material.dart';
import 'diary_page.dart';
import 'analysis_screen.dart';
import '../styles/text_styles.dart';
import '../database/database_helper.dart';
import '../styles/app_colors.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({Key? key}) : super(key: key);

  @override
  State<MainTabScreen> createState() => MainTabScreenState();
}

class MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;
  Color teamColor = Colors.grey;
  final analysisScreenKey = GlobalKey<AnalysisScreenState>();

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      const DiaryPage(),
      AnalysisScreen(key: analysisScreenKey),
    ]);
    _loadTeamColor();
  }

  Future<void> _loadTeamColor() async {
    try {
      final userTeamID = await DatabaseHelper.instance.getUserTeam();
      if (userTeamID != null) {
        final colorHex = await DatabaseHelper.instance.getTeamColor(userTeamID);
        if (colorHex != null) {
          setState(() {
            teamColor = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
          });
        }
      }
    } catch (e) {
      print('Error loading team color: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // 분석 탭으로 이동할 때 데이터 새로고침
          if (index == 1) {
            analysisScreenKey.currentState?.loadAllData();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.note_alt),
            label: '기록',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '분석',
          ),
        ],
        backgroundColor: Colors.white, // 배경색 흰색
        selectedItemColor: teamColor, // 선택된 아이템 색상을 팀 컬러로
        unselectedItemColor: AppColors.gray1, // gray1 색상
        selectedLabelStyle:
            AppTextStyle.body2Medium.copyWith(color: Colors.white),
        unselectedLabelStyle:
            AppTextStyle.body2Medium.copyWith(color: Colors.white),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
