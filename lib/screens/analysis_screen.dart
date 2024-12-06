import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../styles/text_styles.dart';
import '../styles/app_colors.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({Key? key}) : super(key: key);

  @override
  AnalysisScreenState createState() => AnalysisScreenState();
}

class AnalysisScreenState extends State<AnalysisScreen> {
  Color teamColor = Colors.grey;
  Map<String, int> winRates = {'직관': 0, '집관': 0};
  Map<String, int> record = {'total': 0, 'wins': 0, 'losses': 0, 'draws': 0};
  List<Map<String, dynamic>> topMVPs = [];
  String headerText = '직관';

  Future<void> loadAllData() async {
    await _loadTeamColor();
    await _loadWinRates();
    await _loadRecord();
    await _loadTopMVPs();
  }

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  Future<void> _loadTeamColor() async {
    try {
      final userTeamID = await DatabaseHelper.instance.getUserTeam();
      if (userTeamID != null) {
        final colorHex = await DatabaseHelper.instance.getTeamColor(userTeamID);
        if (colorHex != null) {
          setState(() {
            teamColor = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
          });
        }
      }
    } catch (e) {
      print('Error loading team color: $e');
    }
  }

  Future<void> _loadWinRates() async {
    try {
      final userTeamID = await DatabaseHelper.instance.getUserTeam();
      if (userTeamID != null) {
        final rates = await DatabaseHelper.instance
            .calculateWinRatesByViewType(userTeamID);
        setState(() {
          winRates = rates;
          headerText =
              (winRates['직관'] ?? 0) >= (winRates['집관'] ?? 0) ? '직관' : '집관';
        });
      }
    } catch (e) {
      print('Error loading win rates: $e');
    }
  }

  Future<void> _loadRecord() async {
    try {
      final userTeamID = await DatabaseHelper.instance.getUserTeam();
      if (userTeamID != null) {
        final teamRecord =
            await DatabaseHelper.instance.getTeamRecord(userTeamID);
        setState(() {
          record = teamRecord;
        });
      }
    } catch (e) {
      print('Error loading team record: $e');
    }
  }

  Future<void> _loadTopMVPs() async {
    try {
      final mvps = await DatabaseHelper.instance.getTopMVPs(limit: 3);
      setState(() {
        topMVPs = mvps;
      });
    } catch (e) {
      print('Error loading MVPs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: loadAllData,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 24.0,
                  left: 20.0,
                  right: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$headerText 승률이',
                      style: AppTextStyle.h1,
                    ),
                    Text(
                      '더 높아요!',
                      style: AppTextStyle.h1,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: AppColors.gray2,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('총 ${record['total']}경기',
                                    style: AppTextStyle.body2Medium),
                                const SizedBox(height: 4),
                                Text(
                                    '${record['wins']}승 ${record['draws']}무 ${record['losses']}패',
                                    style: AppTextStyle.h2),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: (winRates['직관'] ?? 0) >=
                                          (winRates['집관'] ?? 0)
                                      ? teamColor
                                      : AppColors.gray2,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '직관 승률',
                                      style: AppTextStyle.body2Medium.copyWith(
                                        color: (winRates['직관'] ?? 0) >=
                                                (winRates['집관'] ?? 0)
                                            ? Colors.white
                                            : AppColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${winRates['직관']}%',
                                      style: AppTextStyle.h2.copyWith(
                                        color: (winRates['직관'] ?? 0) >=
                                                (winRates['집관'] ?? 0)
                                            ? Colors.white
                                            : AppColors.text,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: (winRates['집관'] ?? 0) >
                                          (winRates['직관'] ?? 0)
                                      ? teamColor
                                      : AppColors.gray2,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '집관 승률',
                                      style: AppTextStyle.body2Medium.copyWith(
                                        color: (winRates['집관'] ?? 0) >
                                                (winRates['직관'] ?? 0)
                                            ? Colors.white
                                            : AppColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${winRates['집관']}%',
                                      style: AppTextStyle.h2.copyWith(
                                        color: (winRates['집관'] ?? 0) >
                                                (winRates['직관'] ?? 0)
                                            ? Colors.white
                                            : AppColors.text,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 56), // MVP 섹션과의 간격
                        Text('나만의 MVP TOP3', style: AppTextStyle.h3),
                        const SizedBox(height: 16), // 헤더와 첫 번째 순위 박스 사이 간격
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: topMVPs.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final mvp = topMVPs[index];
                            return Container(
                              padding: const EdgeInsets.all(24.0),
                              decoration: BoxDecoration(
                                color: AppColors.gray2,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '${index + 1}위',
                                    style: AppTextStyle.body1SemiBold,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    mvp['name'],
                                    style: AppTextStyle.body1SemiBold,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${mvp['count']}회',
                                    style: AppTextStyle.body1SemiBold,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
