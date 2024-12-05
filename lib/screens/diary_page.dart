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
  int _currentIndex = 0;
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

  /// 승리/무승부/패배를 한 글자로 변환
  String _shortenResult(String result) {
    if (result == "승리") {
      return "승";
    } else if (result == "무승부") {
      return "무";
    } else if (result == "패배") {
      return "패";
    }
    return ""; // 예상치 못한 값일 경우 빈 문자열 반환
  }

  Color _getOvalColor(String result) {
    return result == "승리" ? teamColor : Colors.grey; // 승리 시 팀 색상, 그렇지 않으면 회색
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
                      child: const Column(
                        children: [
                          Icon(
                            Icons.add,
                            size: 32,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "기록 남기기",
                            style: TextStyle(
                              color: Colors.grey,
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
                                          // 직관 및 승무패
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4,
                                              horizontal: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getOvalColor(
                                                  diary['result']),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              "${diary['watchingType']} ${_shortenResult(diary['result'])}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      _parseTeamName(
                                                          diary['homeTeam']),
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  // 홈팀 스코어
                                                  Text(
                                                    scores[0], // 홈팀 점수
                                                    style: TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: diary['result'] ==
                                                              "무승부"
                                                          ? Colors
                                                              .grey // 무승부일 경우 회색
                                                          : (int.parse(scores[
                                                                      0]) >
                                                                  int.parse(
                                                                      scores[1])
                                                              ? Colors.black
                                                              : Colors
                                                                  .grey), // 승리/패배
                                                    ),
                                                  ),
                                                  const Text(
                                                    " : ", // 구분자
                                                    style: TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Colors.grey, // 항상 회색
                                                    ),
                                                  ),
                                                  // 원정팀 스코어
                                                  Text(
                                                    scores[1], // 원정팀 점수
                                                    style: TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: diary['result'] ==
                                                              "무승부"
                                                          ? Colors
                                                              .grey // 무승부일 경우 회색
                                                          : (int.parse(scores[
                                                                      1]) >
                                                                  int.parse(
                                                                      scores[0])
                                                              ? Colors.black
                                                              : Colors
                                                                  .grey), // 승리/패배
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Expanded(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      _parseTeamName(
                                                          diary['awayTeam']),
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 8),
                                          // 날짜
                                          Text(
                                            _formatDate(diary['gameDate']),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black,
                                            ),
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
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: teamColor, // 사용자 팀 색상 적용
        unselectedItemColor: const Color(0xFF4A4A4A),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.note_add),
            label: '기록',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '분석',
          ),
        ],
      ),
    );
  }
}

class SlowScrollPhysics extends BouncingScrollPhysics {
  const SlowScrollPhysics({super.parent});

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return super.applyPhysicsToUserOffset(position, offset * 0.5); // 스크롤 속도 절반
  }

  @override
  SlowScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SlowScrollPhysics(parent: buildParent(ancestor));
  }
}
