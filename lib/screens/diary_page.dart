import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'diary_detail_page.dart'; // DiaryDetailPage 가져오기
import '../database/database_helper.dart';
import 'game_diary_screen.dart'; // GameDiaryScreen 가져오기

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  DiaryPageState createState() => DiaryPageState();
}

class DiaryPageState extends State<DiaryPage> {
  List<Map<String, dynamic>> diaries = [];
  bool isLoading = true;
  Color teamColor = const Color(0xFFCCCCCC); // 기본 색상 (회색)

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUserTeamColor(); // 사용자 팀 색상 로드
    _loadDiaries();
  }

  Future<void> _loadUserTeamColor() async {
    try {
      final userTeamID = await DatabaseHelper.instance.getUserTeam();
      if (userTeamID != null) {
        final fetchedColor =
            await DatabaseHelper.instance.getTeamColor(userTeamID);
        if (fetchedColor != null) {
          setState(() {
            teamColor = Color(int.parse(fetchedColor.replaceFirst(
                '#', '0xFF'))); // '#RRGGBB'를 '0xFFRRGGBB'로 변환
          });
        }
      }
    } catch (error) {
      print("Error loading user team color: $error");
    }
  }

  Future<void> _loadDiaries() async {
    setState(() {
      isLoading = true;
    });

    try {
      final fetchedDiaries =
          await DatabaseHelper.instance.fetchDiaryWithGameInfo();
      setState(() {
        diaries = fetchedDiaries;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching diaries: $error");
    }
  }

  String _formatDate(String date) {
    final parsedDate = DateTime.parse(date);
    return DateFormat('M월 d일').format(parsedDate);
  }

  String _parseTeamName(String teamName) {
    return teamName.split(' ').first; // 스페이스바 기준으로 첫 번째 단어 추출
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, bottom: 16.0),
                    child: Text(
                      "오늘의 야구 기록을\n남겨보세요!",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      // GameDiaryScreen으로 이동
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const GameDiaryScreen(), // GameDiaryScreen 연결
                        ),
                      );

                      // 돌아온 후 새로고침
                      if (result == true) {
                        _loadDiaries();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.add,
                            size: 32,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${_formatDate(DateTime.now().toString())} 기록 남기기",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  diaries.isEmpty
                      ? Expanded(
                          child: Center(
                            child: Text(
                              "작성된 일기가 없습니다",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      : Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: diaries.length,
                            itemBuilder: (context, index) {
                              final diary = diaries[index];
                              final scores = diary['score'].split('-');
                              final diaryId = diary['diaryID']; // diaryID 추출

                              return GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DiaryDetailPage(diaryId: diaryId),
                                    ),
                                  );

                                  if (result == true) {
                                    _loadDiaries();
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4,
                                              horizontal: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              diary['result'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "${_parseTeamName(diary['homeTeam'])} ${scores[0]}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const Text(" vs "),
                                              Text(
                                                "${_parseTeamName(diary['awayTeam'])} ${scores[1]}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}
