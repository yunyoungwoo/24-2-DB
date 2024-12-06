import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'dart:io';
import '../styles/app_colors.dart';
import '../styles/text_styles.dart';
import 'package:intl/intl.dart';

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
            print(photoPath);
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
          title: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Center(
              child: Text(
                "정말 삭제하시겠습니까?",
                style: AppTextStyle.h3,
              ),
            ),
          ),
          backgroundColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          actionsPadding: const EdgeInsets.all(0),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: const SizedBox(height: 0),
          actions: [
            SizedBox(
              height: 80,
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: Text(
                          "취소",
                          style: AppTextStyle.body1SemiBold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        child: Text(
                          "확인",
                          style: AppTextStyle.body1SemiBold,
                        ),
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

  // 팀 이름 파싱 메서드 추가
  String _parseTeamName(String teamName) {
    return teamName.split(' ').first; // 스페이스바 기준으로 첫 번째 단어 추출
  }

  // 날짜 포맷팅 메서드 추가
  String _formatDate(String date) {
    final parsedDate = DateTime.parse(date);
    return DateFormat('M월 d일').format(parsedDate); // diary_page와 동일한 형식
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
      backgroundColor: Colors.white, // Scaffold 배경색 설정
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더 추가
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: AppColors.gray1, // 뒤로가기 아이콘 gray1
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: AppColors.gray1, // 삭제 아이콘 gray1
                    ),
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 24.0, // 컨텐츠 영역의 상단 여백을 24px로 설정
                  left: 20.0,
                  right: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 경기 결과 박스
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: AppColors.gray2,
                          width: 2.0, // 테두리 두께 2px
                        ),
                        borderRadius: BorderRadius.circular(10), // 모서리 둥글기 10
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20.0, // 상하 패딩 20px
                          horizontal: 16.0, // 좌우 패딩 16px
                        ),
                        child: Column(
                          children: [
                            // 직관 및 승무패
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0, // 상하 패딩 4px
                                horizontal: 16.0, // 좌우 패딩 16px
                              ),
                              decoration: BoxDecoration(
                                color: resultColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                "직관 ${result[0]}",
                                style: AppTextStyle.body2SemiBold.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _parseTeamName(homeTeam), // 팀 이름 파싱
                                        textAlign: TextAlign.center,
                                        style: AppTextStyle.h2,
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      scores[0],
                                      style: AppTextStyle.score.copyWith(
                                        // 스코어 스타일도 통일
                                        color: result == "무승부"
                                            ? Colors.grey
                                            : (homeScore > awayScore
                                                ? AppColors.text
                                                : Colors.grey),
                                      ),
                                    ),
                                    Text(
                                      " : ",
                                      style: AppTextStyle.score
                                          .copyWith(color: Colors.grey),
                                    ),
                                    Text(
                                      scores[1],
                                      style: AppTextStyle.score.copyWith(
                                        color: result == "무승부"
                                            ? Colors.grey
                                            : (awayScore > homeScore
                                                ? AppColors.text
                                                : Colors.grey),
                                      ),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _parseTeamName(awayTeam), // 팀 이름 파싱
                                        textAlign: TextAlign.center,
                                        style: AppTextStyle.h2,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatDate(gameDate), // 날짜 포맷팅 적용
                              style: AppTextStyle
                                  .body2Medium, // diary_page와 동일한 스타일
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24), // 16px에서 24px로 변경
                    // MVP 섹션
                    Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "내 마음 속 MVP",
                            style: AppTextStyle.body1SemiBold,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: AppColors.gray2,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              mvp,
                              style: AppTextStyle.body1Medium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24), // 섹션 간 간격

                    // 한줄평 섹션
                    Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "경기 한줄평",
                            style: AppTextStyle.body1SemiBold,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: AppColors.gray2,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              comment,
                              style: AppTextStyle.body1Medium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24), // 섹션 간 간격

                    // 사진 섹션
                    Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "관람 사진",
                            style: AppTextStyle.body1SemiBold,
                          ),
                          const SizedBox(height: 8),
                          photoPath != null
                              ? Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: AppColors.gray2,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      File(photoPath!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: double.infinity,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: AppColors.gray2,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "사진 없음",
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.black45),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
