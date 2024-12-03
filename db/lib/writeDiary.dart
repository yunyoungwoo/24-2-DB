import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // ImagePicker import
import 'dart:io'; // File import
import 'database_helper.dart'; // DatabaseHelper import
import 'package:intl/intl.dart'; // DateFormat import

class GameDiaryScreen extends StatefulWidget {
  @override
  _GameDiaryScreenState createState() => _GameDiaryScreenState();
}

class _GameDiaryScreenState extends State<GameDiaryScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
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
  Map<String, Color> teamColors = {};
  Color userSelectedTeamColor = Colors.grey;

  XFile? _image;
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    initializeDatabase();
  }

  Future<void> initializeDatabase() async {
    await dbHelper.initializeDatabase();

    final teamResults = await dbHelper.fetchTeams();
    setState(() {
      teams = teamResults.map((team) {
        return {
          'teamID': team['teamID'],
          'teamName': team['teamName'],
          'color': team['color'],
        };
      }).toList();

      for (var team in teams) {
        String colorHex = team['color'];
        teamColors[team['teamName']] = _hexToColor(colorHex);
      }
    });

    final userTeamResult = await dbHelper.fetchUserTeam(1); // 사용자 ID를 1로 가정
    if (userTeamResult.isNotEmpty) {
      setState(() {
        userTeamID = userTeamResult.first['teamID'] as int;
      });
    }

    await fetchUserTeamColor();
  }

  Future<void> fetchUserTeamColor() async {
    final result = await dbHelper.fetchUserTeamColor(1); // 사용자 ID를 1로 가정
    if (result.isNotEmpty) {
      String colorHex = result.first['color'] as String;
      setState(() {
        userSelectedTeamColor = _hexToColor(colorHex);
      });
    }
  }

  Color _hexToColor(String hex) {
    if (!hex.startsWith('#')) hex = '#$hex';
    hex = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  Future<void> getImageFromGallery() async {
    try {
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = pickedFile;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택에 실패했습니다: $e')),
      );
    }
  }


  Future<void> saveGameAndDiary() async {
    if (viewingMode.isEmpty || selectedHomeTeam == null || selectedAwayTeam == null || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모든 정보를 입력해주세요.')),
      );
      return;
    }

    if (userTeamID == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사용자 팀 정보가 없습니다.')),
      );
      return;
    }

    String homeScore = homeScoreController.text;
    String awayScore = awayScoreController.text;

    if (homeScore.isEmpty || awayScore.isEmpty || int.tryParse(homeScore) == null || int.tryParse(awayScore) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('점수를 올바르게 입력해주세요.')),
      );
      return;
    }

    try {
      // 날짜 포맷
      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
      String createdAt = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      // 게임 정보 저장
      int gameID = await dbHelper.insertGame({
        'date': formattedDate,
        'homeTeamID': selectedHomeTeam,
        'awayTeamID': selectedAwayTeam,
        'score': '$homeScore-$awayScore',
      });

      // 사진 정보 저장
      int? photoID;
      if (_image != null) {
        photoID = await dbHelper.insertPhoto({'photoPath': _image!.path});
      }

      // 다이어리 정보 저장
      await dbHelper.insertDiary({
        'gameID': gameID,
        'photoID': photoID,
        'watchingType': viewingMode,
        'MVP': mvpController.text,
        'review': reviewController.text,
        'result': calculateResult(homeScore, awayScore),
        'createdAt': createdAt, // 포맷된 날짜 저장
      });

      // 데이터 삽입 후 상태 출력
      print('--- Games Table ---');
      final games = await dbHelper.fetchGames();
      for (var game in games) {
        print(game);
      }

      print('--- Diary Table ---');
      final diaries = await dbHelper.fetchDiaries();
      for (var diary in diaries) {
        print(diary);
      }

      print('--- Photo Table ---');
      final photos = await dbHelper.fetchPhotos();
      for (var photo in photos) {
        print(photo);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('경기 일지가 저장되었습니다!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')),
      );
    }
  }


  String calculateResult(String homeScore, String awayScore) {
    int home = int.parse(homeScore);
    int away = int.parse(awayScore);

    if (selectedHomeTeam == null || selectedAwayTeam == null) {
      throw Exception('선택된 팀 ID가 올바르지 않습니다.');
    }

    if (home == away) {
      return '무승부';
    } else if (home > away) {
      return userTeamID == selectedHomeTeam ? '승리' : '패배';
    } else {
      return userTeamID == selectedAwayTeam ? '승리' : '패배';
    }
  }

  Widget _buildPhotoArea() {
    return GestureDetector(
      onTap: getImageFromGallery,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black),
        ),
        clipBehavior: Clip.hardEdge,
        child: _image == null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 24, color: Colors.black),
              SizedBox(height: 8),
              Text('사진을 추가해주세요', style: TextStyle(color: Colors.black, fontSize: 14)),
            ],
          ),
        )
            : Image.file(File(_image!.path), fit: BoxFit.cover),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('경기 일지 작성'),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedDate != null
                        ? '${selectedDate!.year}년 ${selectedDate!.month}월 ${selectedDate!.day}일'
                        : '날짜를 선택해주세요',
                    style: TextStyle(fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData(
                              primaryColor: userSelectedTeamColor,
                              colorScheme: ColorScheme.light(primary: userSelectedTeamColor),
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
                    child: Text('날짜 선택', style: TextStyle(color: userSelectedTeamColor)),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        DropdownButton<int>(
                          value: selectedHomeTeam,
                          hint: Text('홈 팀'),
                          isExpanded: true,
                          items: teams.map<DropdownMenuItem<int>>((team) { // 명시적으로 타입 지정
                            return DropdownMenuItem<int>(
                              value: team['teamID'], // 팀 ID를 value로 사용
                              child: Text(team['teamName']), // 팀 이름을 UI에 표시
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedHomeTeam = value; // 선택한 팀 ID 저장
                            });
                          },
                        ),
                        TextField(
                          controller: homeScoreController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(hintText: '홈 점수', border: OutlineInputBorder()),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(':'),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        DropdownButton<int>(
                          value: selectedAwayTeam,
                          hint: Text('원정 팀'),
                          isExpanded: true,
                          items: teams.map<DropdownMenuItem<int>>((team) { // 명시적으로 타입 지정
                            return DropdownMenuItem<int>(
                              value: team['teamID'], // 팀 ID를 value로 사용
                              child: Text(team['teamName']), // 팀 이름을 UI에 표시
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedAwayTeam = value; // 선택한 팀 ID 저장
                            });
                          },
                        ),
                        TextField(
                          controller: awayScoreController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(hintText: '원정 점수', border: OutlineInputBorder()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text('관람 방식', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => viewingMode = '직관'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: viewingMode == '직관' ? userSelectedTeamColor : Colors.grey,
                      ),
                      child: Text('직관', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => viewingMode = '집관'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: viewingMode == '집관' ? userSelectedTeamColor : Colors.grey,
                      ),
                      child: Text('집관', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text('내 마음 속 MVP', style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: mvpController,
                decoration: InputDecoration(hintText: '선수 이름', border: OutlineInputBorder()),
              ),
              SizedBox(height: 16),
              Text('경기 한줄평', style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: reviewController,
                maxLines: 3,
                decoration: InputDecoration(hintText: '한줄평을 적어주세요', border: OutlineInputBorder()),
              ),
              SizedBox(height: 16),
              Text('관람 사진', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildPhotoArea(),
            ],
          ),
        ),
      ),
    );
  }
}
