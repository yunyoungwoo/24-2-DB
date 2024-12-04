import 'package:flutter/material.dart';
import '../database/database_helper.dart';

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
      // 선택 완료 후 일기 화면으로 이동
      if (!mounted) return; // 현재 위젯이 트리에 없는 경우, 종료
      Navigator.pushReplacementNamed(context, '/DiaryPage');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Scaffold의 전체 배경색을 흰색으로 설정
      body: teams.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            ) // 로딩 중 화면 배경 흰색으로 설정
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // 텍스트 왼쪽 정렬
                children: [
                  // 왼쪽 정렬된 텍스트
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0, left: 8.0), // 여백 추가
                    child: Text(
                      "응원하는\n팀을 골라주세요!", // 2줄 텍스트
                      textAlign: TextAlign.start, // 텍스트를 왼쪽 정렬
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 24, // 텍스트 크기를 더 크게 설정
                      ),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 한 행에 두 개의 버튼
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
                              selectedTeamID = team['teamID']; // 팀 ID 저장
                              selectedColor = Color(int.parse(
                                      team['color'].substring(1),
                                      radix: 16) +
                                  0xFF000000); // 팀 색상 설정
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? selectedColor
                                  : Colors.grey.shade300, // 선택 여부에 따라 색상 변경
                              borderRadius: BorderRadius.circular(10), // 둥근 모서리
                            ),
                            child: Center(
                              child: Text(
                                team['teamName'], // 팀 이름 표시
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isSelected ? Colors.white : Colors.black,
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
                          : Colors.grey, // 선택 여부에 따라 색상 변경
                    ),
                    child: const Text(
                      "선택 완료",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
