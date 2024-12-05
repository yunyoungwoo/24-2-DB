import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../styles/text_styles.dart';
import '../styles/app_colors.dart';

class SelectTeamScreen extends StatefulWidget {
  const SelectTeamScreen({super.key}); // super-parameter 사용

  @override
  SelectTeamScreenState createState() => SelectTeamScreenState();
}

class SelectTeamScreenState extends State<SelectTeamScreen> {
  List<Map<String, dynamic>> teams = [];
  int? selectedTeamID; // 선택된 팀 ID
  Color selectedColor = Colors.grey; // 선택된 팀 색상

  @override
  void initState() {
    super.initState();
    _loadTeams(); // Teams 데이터 불러오기
  }

  Future<void> _loadTeams() async {
    // Teams 테이블에서 팀 정보 가져오기
    final fetchedTeams = await DatabaseHelper.instance.fetchTeams();
    setState(() {
      teams = fetchedTeams;
    });
  }

  Future<void> _saveSelectedTeam() async {
    if (selectedTeamID != null) {
      // 선택된 팀 ID를 Users 테이블에 저장
      await DatabaseHelper.instance.saveTeamToUser(selectedTeamID!);
      // 선택 완료 후 일기 화면으로 이
      if (!mounted) return; // 현재 위젯이 트리에 없는 경우, 종료
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: teams.isEmpty
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Padding(
                padding: const EdgeInsets.only(
                  top: 24.0,
                  left: 20.0,
                  right: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        "응원하는\n팀을 골라주세요!",
                        textAlign: TextAlign.start,
                        style: AppTextStyle.h1,
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, //  행에 두 개의 버튼
                          mainAxisSpacing: 16, // 버튼 간 세로 간격
                          crossAxisSpacing: 16, // 버튼 간 가로 간격
                          childAspectRatio: 2.5, // 버튼 가로:세로 비율
                        ),
                        itemCount: teams.length,
                        itemBuilder: (context, index) {
                          final team = teams[index];
                          final isSelected = selectedTeamID == team['teamID'];

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedTeamID = team['teamID'];
                                selectedColor = Color(int.parse(
                                        team['color'].substring(1),
                                        radix: 16) +
                                    0xFF000000);
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? selectedColor
                                    : AppColors.gray2,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  team['teamName'],
                                  style: AppTextStyle.team.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.gray1,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    ElevatedButton(
                      onPressed:
                          selectedTeamID != null ? _saveSelectedTeam : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: selectedTeamID != null
                            ? selectedColor
                            : AppColors.gray2, // 선택 여부에 따라 색상 변경
                      ),
                      child: Text(
                        "선택 완료",
                        style: AppTextStyle.body1SemiBold
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
