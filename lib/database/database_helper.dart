import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static DatabaseHelper get instance => _instance;
  static Database? _database;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initializeDatabase();
    return _database!;
  }

  /// 데이터베이스 초기화
  Future<Database> _initializeDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'baseball.sqlite');

    // 데이터베이스 파일이 없으면 assets에서 복사
    if (!await File(path).exists()) {
      try {
        // assets에서 데이터베이스 파일 복사
        ByteData data =
            await rootBundle.load('assets/database/baseball.sqlite');
        List<int> bytes = data.buffer.asUint8List();
        await File(path).writeAsBytes(bytes);
        print('Database copied to $path');
      } catch (e) {
        print('Error copying database: $e');
      }
    }

    return openDatabase(path);
  }

  /// 데이터베이스 리셋 (삭제 없이 초기화만 수행)
  /*Future<void> resetDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'baseball.sqlite');

    // 데이터베이스가 이미 존재하면 그대로 유지
    if (await File(path).exists()) {
      print('Database already exists at $path. No reset performed.');
      return;
    }

    // 데이터베이스가 없을 경우 assets에서 복사
    await _copyDatabaseFromAssets(path);
    print('Database reset and copied to $path');
  }*/

  /// Users 테이블에 특정 teamID를 저장하는 메서드
  Future<void> saveTeamToUser(int teamID) async {
    final db = await database;
    try {
      await db.insert(
        'Users',
        {'teamID': teamID},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      print('Team ID $teamID saved successfully.');
    } catch (e) {
      print('Error saving team to user: $e');
    }
  }

  /// 팀 정보 가져오기
  Future<List<Map<String, dynamic>>> fetchTeams() async {
    final db = await database;
    return await db.query('Teams');
  }

  /// 사용자 팀 색상 가져오기
  Future<String?> getTeamColor(int teamID) async {
    final db = await database;
    final result = await db.query(
      'Teams',
      columns: ['color'],
      where: 'teamID = ?',
      whereArgs: [teamID],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['color'] as String?;
    }
    return null;
  }

  /// Flutter에서 사용할 수 있는 Color 변환
  Color parseColor(String colorCode) {
    final hexColor = colorCode.replaceFirst('#', ''); // # 제거
    return Color(int.parse('FF$hexColor', radix: 16)); // 16진수 변환
  }

  /// 사용자 팀 ID 가져오기
  Future<int?> getUserTeam() async {
    final db = await database;
    final result = await db.query('Users', columns: ['teamID'], limit: 1);
    if (result.isNotEmpty) {
      return result.first['teamID'] as int?;
    }
    return null;
  }

  /// 사용자 팀 색상과 팀명 가져오기
  Future<List<Map<String, dynamic>>> fetchUserTeamColor(int userId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT Teams.teamName, Teams.color
      FROM Users
      JOIN Teams ON Users.teamID = Teams.teamID
      WHERE Users.userID = ?
    ''', [userId]);
  }

  /// 게임 정보 가져오기
  Future<List<Map<String, dynamic>>> fetchGames() async {
    final db = await database;
    return await db.query('Games');
  }

  /// 다이어리 정보 가져오기
  Future<List<Map<String, dynamic>>> fetchDiaries() async {
    final db = await database;
    return await db.query('Diary');
  }

  /// 특정 다이어리 가져오기 (게임, 팀 정보 포함)
  Future<Map<String, dynamic>?> fetchDiaryById(int diaryId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT d.*,
            g.date AS gameDate,
            g.score,
            t1.teamName AS homeTeam,
            t2.teamName AS awayTeam
      FROM Diary d
      INNER JOIN Games g ON d.gameID = g.gameID
      INNER JOIN Teams t1 ON g.homeTeamID = t1.teamID
      INNER JOIN Teams t2 ON g.awayTeamID = t2.teamID
      WHERE d.diaryID = ?
      LIMIT 1
    ''', [diaryId]);
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchPhotos() async {
    final db = await database;
    return await db.query('Photos'); // Fetch all rows from Photos table
  }

  /// 특정 사진 경로 가져오기
  Future<String?> fetchPhotoPathById(int photoId) async {
    final db = await database;
    final result = await db.query(
      'Photos',
      columns: ['photoPath'],
      where: 'photoID = ?',
      whereArgs: [photoId],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['photoPath'] as String?;
    }
    return null;
  }

  /// 팀별 색상 정보 가져오기
  Future<Map<String, Color>> fetchTeamColors() async {
    final db = await database;
    final result = await db.query('Teams', columns: ['teamID', 'color']);
    return Map.fromEntries(
      result.map((row) {
        final teamID = row['teamID'].toString();
        final colorCode = row['color'] as String;
        return MapEntry(teamID, parseColor(colorCode));
      }),
    );
  }

  /// 다이어리 및 게임 정보 가져오기
  Future<List<Map<String, dynamic>>> fetchDiaryWithGameInfo() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT d.*, 
            g.date AS gameDate, 
            g.score, 
            t1.teamName AS homeTeam, 
            t2.teamName AS awayTeam
      FROM Diary d
      INNER JOIN Games g ON d.gameID = g.gameID
      INNER JOIN Teams t1 ON g.homeTeamID = t1.teamID
      INNER JOIN Teams t2 ON g.awayTeamID = t2.teamID
      ORDER BY d.createdAt DESC
    ''');
  }

  /// 게임 삽입
  Future<int> insertGame(Map<String, dynamic> gameData) async {
    final db = await database;
    return await db.insert(
      'Games',
      gameData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 다이어리 삽입
  Future<int> insertDiary(Map<String, dynamic> diaryData) async {
    final db = await database;
    return await db.insert(
      'Diary',
      diaryData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 사진 삽입
  Future<int> insertPhoto(Map<String, dynamic> photoData) async {
    final db = await database;
    return await db.insert(
      'Photos',
      photoData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 다이어리 삭제
  Future<void> deleteDiary(int diaryId) async {
    final db = await database;
    await db.delete('Diary', where: 'diaryID = ?', whereArgs: [diaryId]);
  }

  /// 게임 삭제
  Future<int> deleteGame(int gameId) async {
    final db = await database;
    return await db.delete('Games', where: 'gameID = ?', whereArgs: [gameId]);
  }

  /// 관람 방식별 승률 계산 (무승부 제외, 소수점 생략)
  Future<Map<String, int>> calculateWinRatesByViewType(int teamId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        d.watchingType,
        COUNT(*) as total_games,
        SUM(CASE WHEN d.result = '승리' THEN 1 ELSE 0 END) as wins,
        SUM(CASE WHEN d.result = '무승부' THEN 1 ELSE 0 END) as draws
      FROM Diary d
      JOIN Games g ON d.gameID = g.gameID
      WHERE (g.homeTeamID = ? OR g.awayTeamID = ?)
      GROUP BY d.watchingType
    ''', [teamId, teamId]);

    Map<String, int> winRates = {'직관': 0, '집관': 0};

    for (var row in result) {
      final watchingType = row['watchingType'] as String;
      final totalGames = row['total_games'] as int;
      final wins = row['wins'] as int;
      final draws = row['draws'] as int;
      final gamesExcludingDraws = totalGames - draws;

      if (gamesExcludingDraws > 0) {
        final winRate = (wins / gamesExcludingDraws * 100).round();
        winRates[watchingType] = winRate;
      }
    }

    return winRates;
  }

  /// 팀의 전체 경기 기록 조회
  Future<Map<String, int>> getTeamRecord(int teamId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_games,
        SUM(CASE WHEN d.result = '승리' THEN 1 ELSE 0 END) as wins,
        SUM(CASE WHEN d.result = '패배' THEN 1 ELSE 0 END) as losses,
        SUM(CASE WHEN d.result = '무승부' THEN 1 ELSE 0 END) as draws
      FROM Diary d
      JOIN Games g ON d.gameID = g.gameID
      WHERE (g.homeTeamID = ? OR g.awayTeamID = ?)
    ''', [teamId, teamId]);

    if (result.isNotEmpty) {
      return {
        'total': result.first['total_games'] as int? ?? 0,
        'wins': result.first['wins'] as int? ?? 0,
        'losses': result.first['losses'] as int? ?? 0,
        'draws': result.first['draws'] as int? ?? 0,
      };
    }
    return {'total': 0, 'wins': 0, 'losses': 0, 'draws': 0};
  }

  /// MVP 언급 횟수 TOP N 조회
  Future<List<Map<String, dynamic>>> getTopMVPs({int limit = 3}) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        MVP,
        COUNT(*) as mention_count
      FROM Diary
      WHERE MVP IS NOT NULL AND MVP != ''
      GROUP BY MVP
      ORDER BY mention_count DESC
      LIMIT ?
    ''', [limit]);

    return result.map((row) {
      return {
        'name': row['MVP'] as String,
        'count': row['mention_count'] as int,
      };
    }).toList();
  }
}
