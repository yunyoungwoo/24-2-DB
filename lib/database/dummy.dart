import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  late Database database;

  DatabaseHelper._internal();

  /// 데이터베이스 초기화
  Future<void> initializeDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'BaseballDiary.db');

    // 데이터베이스 존재 여부 확인
    final exists = await databaseExists(path);
    if (!exists) {
      // assets에서 데이터베이스 파일 복사
      ByteData data = await rootBundle.load('assets/BaseballDiary.db');
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes);
      print('Database copied to $path');
    }

    // 데이터베이스 열기
    database = await openDatabase(path);

    // 이 부분에서 메시지를 출력하지 않음
    if (!exists) {
      print('Database opened at: $path');
    }
  }

  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'BaseballDiary.db');

    // 데이터베이스 파일 삭제
    if (await databaseExists(path)) {
      await deleteDatabase(path);
      print('Database deleted at $path');
    } else {
      print('No database found to delete.');
    }

    // 데이터베이스 재생성
    await _copyDatabaseFromAssets(path);
    database = await openDatabase(path);
    print('Database reset and reinitialized at $path');
  }

  Future<void> _copyDatabaseFromAssets(String path) async {
    ByteData data = await rootBundle.load('assets/BaseballDiary.db');
    List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(path).writeAsBytes(bytes);
    print('Database copied from assets to $path');
  }

  /// 팀 정보 가져오기
  Future<List<Map<String, dynamic>>> fetchTeams() async {
    return await database.query('Teams');
  }

  /// 유저 팀 색상 가져오기
  Future<List<Map<String, dynamic>>> fetchUserTeamColor(int userId) async {
    const String query = '''
      SELECT Teams.teamName, Teams.color 
      FROM Users
      JOIN Teams ON Users.teamID = Teams.teamID
      WHERE Users.userID = ?
    ''';

    return await database.rawQuery(query, [userId]);
  }

  /// 유저 팀 ID 가져오기
  Future<List<Map<String, dynamic>>> fetchUserTeam(int userId) async {
    return await database.query(
      'Users',
      columns: ['teamID'],
      where: 'userID = ?',
      whereArgs: [userId],
    );
  }

  /// 게임 정보 가져오기
  Future<List<Map<String, dynamic>>> fetchGames() async {
    return await database.query('Games'); // Games 테이블의 모든 데이터 반환
  }

  /// 다이어리 정보 가져오기
  Future<List<Map<String, dynamic>>> fetchDiaries() async {
    return await database.query('Diary'); // Diary 테이블의 모든 데이터 반환
  }

  Future<List<Map<String, dynamic>>> fetchPhotos() async {
    return await database.query('Photos'); // Diary 테이블의 모든 데이터 반환
  }

  /// 게임 정보 삽입
  Future<int> insertGame(Map<String, dynamic> gameData) async {
    try {
      return await database.insert(
        'Games',
        gameData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error inserting game: $e');
      rethrow;
    }
  }

  /// 사진 정보 삽입
  Future<int> insertPhoto(Map<String, dynamic> photo) async {
    try {
      return await database.insert(
        'Photos',
        photo,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error inserting photo: $e');
      rethrow;
    }
  }

  /// 다이어리 정보 삽입
  Future<int> insertDiary(Map<String, dynamic> diaryData) async {
    try {
      return await database.insert(
        'Diary',
        diaryData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error inserting diary: $e');
      rethrow;
    }
  }

  /// 데이터 삭제 예제 (게임 삭제)
  Future<int> deleteGame(int gameId) async {
    try {
      return await database.delete(
        'Games',
        where: 'gameID = ?',
        whereArgs: [gameId],
      );
    } catch (e) {
      print('Error deleting game: $e');
      rethrow;
    }
  }
}
