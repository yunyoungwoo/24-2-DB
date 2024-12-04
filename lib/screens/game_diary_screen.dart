import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../database/database_helper.dart';
import 'package:intl/intl.dart';

class GameDiaryScreen extends StatefulWidget {
  const GameDiaryScreen({super.key});

  @override
  GameDiaryScreenState createState() => GameDiaryScreenState();
}

class GameDiaryScreenState extends State<GameDiaryScreen> {
  String viewingMode = '';
  final TextEditingController mvpController = TextEditingController();
  final TextEditingController reviewController = TextEditingController();
  final TextEditingController homeScoreController = TextEditingController();
  final TextEditingController awayScoreController = TextEditingController();

  int? selectedHomeTeam;
  int? selectedAwayTeam;
  int? userTeamID;
  DateTime? selectedDate;
  List<Map<String, dynamic>> teams = [];
  Color userSelectedTeamColor = Colors.grey;

  XFile? _image;
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 팀 데이터 및 사용자 팀 색상 로드
  Future<void> _loadData() async {
    try {
      final teamResults = await DatabaseHelper.instance.fetchTeams();
      final userTeamID = await DatabaseHelper.instance.getUserTeam();

      setState(() {
        teams = teamResults.map((team) {
          return {
            'teamID': team['teamID'],
            'teamName': team['teamName'],
            'color': team['color'],
          };
        }).toList();
        this.userTeamID = userTeamID;
      });

      if (userTeamID != null) {
        final colorHex = await DatabaseHelper.instance.getTeamColor(userTeamID);
        if (colorHex != null) {
          setState(() {
            userSelectedTeamColor = _hexToColor(colorHex);
          });
        }
      }
    } catch (e) {
      _showSnackBar('데이터 로드 중 오류가 발생했습니다: $e');
    }
  }

  /// HEX 컬러를 Flutter Color로 변환
  Color _hexToColor(String hex) {
    if (!hex.startsWith('#')) hex = '#$hex';
    return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
  }

  /// 갤러리에서 이미지 선택
  Future<void> getImageFromGallery() async {
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = pickedFile;
        });
      }
    } catch (e) {
      _showSnackBar('이미지 선택에 실패했습니다: $e');
    }
  }

  /// 일지 저장
  Future<void> saveGameAndDiary() async {
    if (viewingMode.isEmpty ||
        selectedHomeTeam == null ||
        selectedAwayTeam == null ||
        selectedDate == null) {
      _showSnackBar('모든 필드를 입력해주세요.');
      return;
    }

    if (userTeamID == null) {
      _showSnackBar('사용자 팀 정보가 없습니다.');
      return;
    }

    // Check if user's team is involved in the game
    if (userTeamID != selectedHomeTeam && userTeamID != selectedAwayTeam) {
      _showSnackBar('기록하려는 경기에 사용자 팀이 포함되어 있지 않습니다.');
      return;
    }

    String homeScore = homeScoreController.text;
    String awayScore = awayScoreController.text;

    if (homeScore.isEmpty ||
        awayScore.isEmpty ||
        int.tryParse(homeScore) == null ||
        int.tryParse(awayScore) == null) {
      _showSnackBar('유효한 점수를 입력해주세요.');
      return;
    }

    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
      String createdAt = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      int gameID = await DatabaseHelper.instance.insertGame({
        'date': formattedDate,
        'homeTeamID': selectedHomeTeam,
        'awayTeamID': selectedAwayTeam,
        'score': '$homeScore-$awayScore',
      });

      int? photoID;
      if (_image != null) {
        photoID = await DatabaseHelper.instance.insertPhoto({'photoPath': _image!.path});
      }

      await DatabaseHelper.instance.insertDiary({
        'gameID': gameID,
        'photoID': photoID,
        'watchingType': viewingMode,
        'MVP': mvpController.text,
        'review': reviewController.text,
        'result': _calculateResult(homeScore, awayScore),
        'createdAt': createdAt,
      });

      print('--- Photo Table ---');
      final photos = await DatabaseHelper.instance.fetchPhotos(); // Fixed the method call
      for (var photo in photos) {
        print(photo);
      }

      _showSnackBar('경기 일지가 성공적으로 저장되었습니다!', isSuccess: true);
      Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('저장 중 오류가 발생했습니다: $e');
    }
  }


  /// 경기 결과 계산
  String _calculateResult(String homeScore, String awayScore) {
    int home = int.parse(homeScore);
    int away = int.parse(awayScore);

    if (home == away) {
      return '무승부';
    } else if (home > away) {
      return userTeamID == selectedHomeTeam ? '승리' : '패배';
    } else {
      return userTeamID == selectedAwayTeam ? '승리' : '패배';
    }
  }

  /// 스낵바 메시지 표시
  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isSuccess ? Colors.green : Colors.red,
        ),
      );
    }
  }

  /// 사진 업로드 영역
  Widget buildPhotoArea() {
    return GestureDetector(
      onTap: getImageFromGallery,
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade200,
        ),
        child: _image == null
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 30, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                '사진을 추가해주세요',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        )
            : ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(_image!.path),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Game Diary'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: saveGameAndDiary,
            child: Text(
              '완료',
              style: TextStyle(color: userSelectedTeamColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    builder: (BuildContext context, Widget? child) {
                      return Theme(
                        data: ThemeData.light().copyWith(
                          primaryColor: userSelectedTeamColor, // Apply user's team color
                          colorScheme: ColorScheme.light(primary: userSelectedTeamColor), // Adjust color scheme
                          buttonTheme: ButtonThemeData(
                            textTheme: ButtonTextTheme.primary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    selectedDate != null
                        ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                        : '날짜 선택',
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: DropdownButton<int>(
                      value: selectedHomeTeam,
                      hint: const Text('홈 팀'),
                      isExpanded: true,
                      items: teams.map<DropdownMenuItem<int>>((team) {
                        return DropdownMenuItem<int>(
                          value: team['teamID'],
                          child: Text(team['teamName']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedHomeTeam = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('vs'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<int>(
                      value: selectedAwayTeam,
                      hint: const Text('원정 팀'),
                      isExpanded: true,
                      items: teams.map<DropdownMenuItem<int>>((team) {
                        return DropdownMenuItem<int>(
                          value: team['teamID'],
                          child: Text(team['teamName']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedAwayTeam = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 기존 내용 유지
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: homeScoreController,
                      decoration: const InputDecoration(
                        labelText: '홈 팀 점수',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: awayScoreController,
                      decoration: const InputDecoration(
                        labelText: '원정 팀 점수',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('관람 방식'),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => viewingMode = '직관'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: viewingMode == '직관'
                            ? userSelectedTeamColor
                            : Colors.grey.shade200,
                        foregroundColor: viewingMode == '직관'
                            ? Colors.white
                            : Colors.black,
                      ),
                      child: const Text('직관'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => viewingMode = '집관'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: viewingMode == '집관'
                            ? userSelectedTeamColor
                            : Colors.grey.shade200,
                        foregroundColor: viewingMode == '집관'
                            ? Colors.white
                            : Colors.black,
                      ),
                      child: const Text('집관'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('MVP 입력'),
              TextField(
                controller: mvpController,
                decoration: const InputDecoration(
                  hintText: '선수 이름',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('한줄평'),
              TextField(
                controller: reviewController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: '경기에 대한 한줄평',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('사진 추가'),
              buildPhotoArea(),
            ],
          ),
        ),
      ),
    );
  }
}
