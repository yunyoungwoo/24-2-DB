import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class DiaryDetailPage extends StatefulWidget {
  final int diaryId; // 일기 ID를 전달받음

  const DiaryDetailPage({super.key, required this.diaryId});

  @override
  DiaryDetailPageState createState() => DiaryDetailPageState();
}

class DiaryDetailPageState extends State<DiaryDetailPage> {
  Color userTeamColor = Colors.grey; // 기본 색상 (회색)
  Map<String, dynamic>? diary; // 일기 데이터를 저장
  String? photoPath; // 사진 경로 저장
  bool isLoading = true; // 로딩 상태

  @override
  void initState() {
    super.initState();
    _loadUserTeamColor();
    _loadDiary();
  }

  // 사용자 팀 색상을 가져오는 메서드
  Future<void> _loadUserTeamColor() async {
    try {
      final userTeamID = await DatabaseHelper.instance.getUserTeam();
      if (userTeamID != null) {
        final fetchedColor =
            await DatabaseHelper.instance.getTeamColor(userTeamID);
        if (fetchedColor != null) {
          setState(() {
            userTeamColor = DatabaseHelper.instance.parseColor(fetchedColor);
          });
        }
      }
    } catch (error) {
      print("Error loading user team color: $error");
    }
  }

  // 특정 ID의 일기 데이터를 로드하는 메서드
  Future<void> _loadDiary() async {
    try {
      final fetchedDiary =
          await DatabaseHelper.instance.fetchDiaryById(widget.diaryId);

      if (fetchedDiary != null) {
        setState(() {
          diary = fetchedDiary;
        });

        // diary에서 photoID를 가져와서 사진 경로 로드
        final photoId = diary!['photoID'] as int?;
        if (photoId != null) {
          final fetchedPhotoPath =
              await DatabaseHelper.instance.fetchPhotoPathById(photoId);
          setState(() {
            photoPath = fetchedPhotoPath;
          });
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (error) {
      print("Error loading diary: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  // 삭제 확인 다이얼로그
  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Padding(
            padding: EdgeInsets.only(top: 16.0), // 텍스트를 아래로 약간 내림
            child: Center(child: Text("삭제 확인")),
          ),
          backgroundColor: Colors.white, // 창 배경색 흰색으로 설정
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          actionsPadding: const EdgeInsets.all(0),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: const SizedBox(height: 0), // 추가 공간 제거
          actions: [
            SizedBox(
              height: 80, // 전체 버튼 영역의 높이
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false); // 취소 선택
                        },
                        child: const Text("취소"),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true); // 확인 선택
                        },
                        child: const Text("확인"),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      // 삭제 실행
      await _deleteDiary();
    }
  }

  // 데이터베이스에서 일기 삭제 메서드
  Future<void> _deleteDiary() async {
    try {
      await DatabaseHelper.instance.deleteDiary(widget.diaryId);

      // 현재 위젯이 트리에서 유효한 경우에만 Navigator.pop 호출
      if (mounted) {
        Navigator.of(context).pop(true); // 삭제 성공 후 true 반환
      }
    } catch (error) {
      print("Error deleting diary: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (diary == null) {
      return const Scaffold(
        body: Center(child: Text("일기를 찾을 수 없습니다.")),
      );
    }

    // 경기 정보를 가져오기
    final homeTeam = diary!['homeTeam'];
    final awayTeam = diary!['awayTeam'];
    final score = diary!['score'];
    final gameDate = diary!['gameDate'];
    final result = diary!['result'];
    final mvp = diary!['MVP'] ?? "MVP 없음";
    final comment = diary!['review'] ?? "한줄평 없음";

    // 스코어 분리
    final scores = score.split('-');
    final homeScore = int.parse(scores[0]);
    final awayScore = int.parse(scores[1]);

    // 승리 시 사용자 팀 색상을 적용, 패배나 무승부는 회색
    Color resultColor = result == "승리" ? userTeamColor : Colors.grey;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.black),
            onPressed: () => _confirmDelete(context), // 삭제 확인 다이얼로그 호출
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 경기 결과 박스
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: resultColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "직관 ${result[0]}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          homeTeam,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            scores[0],
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: result == "승리" && homeScore > awayScore
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                          const Text(
                            " : ",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            scores[1],
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: result == "승리" && awayScore > homeScore
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Text(
                          awayTeam,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    gameDate,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 내 마음 속 MVP
            const Text(
              "내 마음 속 MVP",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                mvp,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            // 경기 한줄평
            const Text(
              "경기 한줄평",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                comment,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            // 사진
            const Text(
              "관람 사진",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            photoPath != null
                ? Image.network(photoPath!) // 사진 경로 표시
                : Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "사진 없음",
                        style: TextStyle(fontSize: 16, color: Colors.black45),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
