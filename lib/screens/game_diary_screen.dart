import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // ImagePicker import
import 'dart:io'; // File import
import '../database/database_helper.dart'; // DatabaseHelper import
import 'package:intl/intl.dart'; // DateFormat import

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
  Map<String, Color> teamColors = {};
  Color userSelectedTeamColor = Colors.grey;

  XFile? _image;
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 팀 정보 로드
      final teamResults = await DatabaseHelper.instance.fetchTeams();
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

      // 사용자 팀 정보 로드
      final userTeamID = await DatabaseHelper.instance.getUserTeam();
      setState(() {
        this.userTeamID = userTeamID;
      });

      // 사용자 팀 색상 로드
      if (userTeamID != null) {
        await _fetchUserTeamColor(userTeamID);
      }
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  Future<void> _fetchUserTeamColor(int teamID) async {
    final colorHex = await DatabaseHelper.instance.getTeamColor(teamID);
    if (colorHex != null) {
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
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = pickedFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택에 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> saveGameAndDiary() async {
    if (viewingMode.isEmpty ||
        selectedHomeTeam == null ||
        selectedAwayTeam == null ||
        selectedDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모든 정보를 입력해주세요.')),
        );
      }
      return;
    }

    if (userTeamID == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사용자 팀 정보가 없습니다.')),
        );
      }
      return;
    }

    String homeScore = homeScoreController.text;
    String awayScore = awayScoreController.text;

    if (homeScore.isEmpty ||
        awayScore.isEmpty ||
        int.tryParse(homeScore) == null ||
        int.tryParse(awayScore) == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('점수를 올바르게 입력해주세요.')),
        );
      }
      return;
    }

    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
      String createdAt =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      int gameID = await DatabaseHelper.instance.insertGame({
        'date': formattedDate,
        'homeTeamID': selectedHomeTeam,
        'awayTeamID': selectedAwayTeam,
        'score': '$homeScore-$awayScore',
      });

      int? photoID;
      if (_image != null) {
        photoID = await DatabaseHelper.instance
            .insertPhoto({'photoPath': _image!.path});
      }

      await DatabaseHelper.instance.insertDiary({
        'gameID': gameID,
        'photoID': photoID,
        'watchingType': viewingMode,
        'MVP': mvpController.text,
        'review': reviewController.text,
        'result': calculateResult(homeScore, awayScore),
        'createdAt': createdAt,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('경기 일지가 저장되었습니다!')),
        );
        Navigator.pop(context, true); // 저장 성공 시 true 반환
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  String calculateResult(String homeScore, String awayScore) {
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

  Widget buildPhotoArea() {
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
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 24, color: Colors.black),
                    SizedBox(height: 8),
                    Text('사진을 추가해주세요',
                        style: TextStyle(color: Colors.black, fontSize: 14)),
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
      appBar: AppBar(
        title: const Text('경기 일지 작성'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: saveGameAndDiary,
            child: Text(
              '완료',
              style: TextStyle(
                  color: userSelectedTeamColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 날짜 선택, 팀 선택, 점수 입력 등 추가 코드
              // (기존 코드를 유지하며 생략)
            ],
          ),
        ),
      ),
    );
  }
}
