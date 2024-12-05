import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../styles/text_styles.dart';
import '../styles/app_colors.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({Key? key}) : super(key: key);

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  Color teamColor = Colors.grey; // 기본값 설정

  @override
  void initState() {
    super.initState();
    _loadTeamColor();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
                    '직관 승률이',
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
                              Text('총 6경기', style: AppTextStyle.body2Medium),
                              const SizedBox(height: 4),
                              Text('4승 1무 1패', style: AppTextStyle.h2),
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
                                color: teamColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('직관 승률',
                                      style: AppTextStyle.body2Medium
                                          .copyWith(color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Text('72%',
                                      style: AppTextStyle.h2
                                          .copyWith(color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: AppColors.gray2,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('집관 승률',
                                      style: AppTextStyle.body2Medium),
                                  const SizedBox(height: 4),
                                  Text('36%', style: AppTextStyle.h2),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 56), // MVP 섹션과의 간격
                      Text('나만의 MVP TOP5', style: AppTextStyle.h3),
                      const SizedBox(height: 16), // 헤더와 첫 번째 순위 박스 사이 간격
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 5,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final List<Map<String, String>> mvpData = [
                            {"rank": "1위", "name": "임찬규", "count": "5회"},
                            {"rank": "2위", "name": "홍창기", "count": "4회"},
                            {"rank": "3위", "name": "문보경", "count": "3회"},
                            {"rank": "4위", "name": "손주영", "count": "2회"},
                            {"rank": "5위", "name": "고석", "count": "1회"},
                          ];

                          return Container(
                            padding: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              color: AppColors.gray2,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  mvpData[index]["rank"]!,
                                  style: AppTextStyle.body1SemiBold,
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  mvpData[index]["name"]!,
                                  style: AppTextStyle.body1SemiBold,
                                ),
                                const Spacer(),
                                Text(
                                  mvpData[index]["count"]!,
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
    );
  }
}
