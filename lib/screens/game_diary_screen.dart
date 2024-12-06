import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../database/database_helper.dart';
import 'package:intl/intl.dart';
import '../styles/text_styles.dart';
import '../styles/app_colors.dart';

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
    selectedDate = DateTime.now();
    _loadData();
  }

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

  Color _hexToColor(String hex) {
    if (!hex.startsWith('#')) hex = '#$hex';
    return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
  }

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

  Future<void> saveGameAndDiary() async {
    if (viewingMode.isEmpty ||
        selectedHomeTeam == null ||
        selectedAwayTeam == null ||
        selectedDate == null) {
      _showSnackBar('모든 필드를 입력해주세요');
      return;
    }

    if (userTeamID == null) {
      _showSnackBar('사용자 팀 정보가 없습니다');
      return;
    }

    if (userTeamID != selectedHomeTeam && userTeamID != selectedAwayTeam) {
      _showSnackBar('기록하려는 경기에 사용자 팀이 포함되어 있지 않습니다');
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
        'result': _calculateResult(homeScore, awayScore),
        'createdAt': createdAt,
      });

      _showSnackBar('경기 일지가 성공적으로 저장되었습니다', isSuccess: true);

      // `mounted`를 확인하여 위젯이 여전히 활성 상태인지 확인
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar('저장 중 오류가 발생했습니다: $e');
    }
  }

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

  Widget buildPhotoArea() {
    return GestureDetector(
      onTap: () async {
        try {
          final pickedFile =
              await picker.pickImage(source: ImageSource.gallery);
          if (pickedFile != null) {
            setState(() {
              _image = pickedFile;
            });
          }
        } catch (e) {
          _showSnackBar('이미지 선택에 실패했습니다: $e');
        }
      },
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.gray2,
        ),
        child: _image == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 30, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      '사진을 추가해주세요',
                      style: AppTextStyle.body3.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(10),
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
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.gray1,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (BuildContext context, Widget? child) {
                return Theme(
                  data: ThemeData.light().copyWith(
                    primaryColor: userSelectedTeamColor,
                    colorScheme:
                        ColorScheme.light(primary: userSelectedTeamColor),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedDate != null
                    ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                    : '날짜 선택',
                style: AppTextStyle.body1SemiBold,
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, color: Colors.black),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: saveGameAndDiary,
            child: Text(
              '완료',
              style: AppTextStyle.body1SemiBold.copyWith(
                color: userSelectedTeamColor,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedHomeTeam,
                        hint: Center(
                            child: Text('홈팀', style: AppTextStyle.body1Medium)),
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        items: teams.map<DropdownMenuItem<int>>((team) {
                          return DropdownMenuItem<int>(
                            value: team['teamID'],
                            child: Center(
                              child: Text(team['teamName'],
                                  style: AppTextStyle.body1Medium),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedHomeTeam = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedAwayTeam,
                        hint: Center(
                            child:
                                Text('원정팀', style: AppTextStyle.body1SemiBold)),
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        items: teams.map<DropdownMenuItem<int>>((team) {
                          return DropdownMenuItem<int>(
                            value: team['teamID'],
                            child: Center(
                              child: Text(
                                team['teamName'],
                                style: AppTextStyle.body1SemiBold,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedAwayTeam = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: homeScoreController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.gray2,
                        hintText: '...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      textAlign: TextAlign.center,
                      style: AppTextStyle.body1Medium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: awayScoreController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.gray2,
                        hintText: '...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      textAlign: TextAlign.center,
                      style: AppTextStyle.body1Medium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('관람 방식', style: AppTextStyle.body1SemiBold),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => viewingMode = '직관'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: viewingMode == '직관'
                            ? userSelectedTeamColor
                            : Colors.grey.shade200,
                        foregroundColor:
                            viewingMode == '직관' ? Colors.white : Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text('직관', style: AppTextStyle.body1Medium),
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
                        foregroundColor:
                            viewingMode == '집관' ? Colors.white : Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text('집관', style: AppTextStyle.body1Medium),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('내 마음 속 MVP', style: AppTextStyle.body1SemiBold),
              const SizedBox(height: 8),
              TextField(
                controller: mvpController,
                style: AppTextStyle.body1Medium,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.gray2,
                  hintText: '선수 이름을 적어주세요',
                  hintStyle:
                      AppTextStyle.body2Medium.copyWith(color: AppColors.gray1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),
              Text('경기 한줄평', style: AppTextStyle.body1SemiBold),
              const SizedBox(height: 8),
              TextField(
                controller: reviewController,
                style: AppTextStyle.body1Medium,
                maxLines: 4,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.gray2,
                  hintText: '한줄평을 적어주세요',
                  hintStyle:
                      AppTextStyle.body2Medium.copyWith(color: AppColors.gray1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),
              Text('관람 사진', style: AppTextStyle.body1SemiBold),
              const SizedBox(height: 8),
              buildPhotoArea(),
            ],
          ),
        ),
      ),
    );
  }
}
