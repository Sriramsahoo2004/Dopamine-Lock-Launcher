import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'dopaminelock.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE questions (
            id INTEGER PRIMARY KEY,
            question_text TEXT NOT NULL,
            correct_answer TEXT NOT NULL,
            options TEXT NOT NULL,
            category TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE user_stats (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            package_name TEXT NOT NULL UNIQUE,
            app_opened TEXT NOT NULL,
            unlock_time TEXT NOT NULL,
            unlock_count INTEGER NOT NULL DEFAULT 0,
            questions_answered INTEGER NOT NULL DEFAULT 0,
            questions_failed INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await _seedQuestions(db);
      },
    );
  }

  Future<void> insertQuestions(List<Map<String, dynamic>> questions) async {
    final db = await database;
    final batch = db.batch();

    for (final question in questions) {
      batch.insert(
        'questions',
        _normalizeQuestion(question),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<Map<String, dynamic>?> getRandomQuestion() async {
    final db = await database;
    final rows = await db.query('questions', orderBy: 'RANDOM()', limit: 1);
    if (rows.isEmpty) {
      return null;
    }
    return rows.first;
  }

  Future<void> recordAppAttempt({
    required String packageName,
    required String appName,
    required bool unlocked,
  }) async {
    final db = await database;
    await db.rawInsert(
      '''
      INSERT INTO user_stats (
        package_name,
        app_opened,
        unlock_time,
        unlock_count,
        questions_answered,
        questions_failed
      )
      VALUES (?, ?, ?, ?, 1, ?)
      ON CONFLICT(package_name) DO UPDATE SET
        app_opened = excluded.app_opened,
        unlock_time = excluded.unlock_time,
        unlock_count = user_stats.unlock_count + excluded.unlock_count,
        questions_answered = user_stats.questions_answered + 1,
        questions_failed = user_stats.questions_failed + excluded.questions_failed
      ''',
      [
        packageName,
        appName,
        DateTime.now().toUtc().toIso8601String(),
        unlocked ? 1 : 0,
        unlocked ? 0 : 1,
      ],
    );
  }

  Future<List<Map<String, dynamic>>> getPendingStats() async {
    final db = await database;
    return db.query('user_stats');
  }

  Map<String, Object?> _normalizeQuestion(Map<String, dynamic> question) {
    final rawOptions = question['options'];
    final options = rawOptions is String ? rawOptions : jsonEncode(rawOptions);

    return {
      'id': question['id'],
      'question_text': question['question_text'],
      'correct_answer': question['correct_answer'],
      'options': options,
      'category': question['category'],
    };
  }

  Future<void> _seedQuestions(Database db) async {
    final seedQuestions = [
      {
        'id': 1,
        'question_text': 'What is the average time complexity of QuickSort?',
        'correct_answer': 'O(n log n)',
        'options': jsonEncode(['O(n^2)', 'O(n log n)', 'O(n)', 'O(log n)']),
        'category': 'Algorithms',
      },
      {
        'id': 2,
        'question_text':
            'Which structure is commonly paired with a hash map for an LRU cache?',
        'correct_answer': 'Doubly linked list',
        'options': jsonEncode(['Stack', 'Queue', 'Doubly linked list', 'Heap']),
        'category': 'Data Structures',
      },
    ];

    for (final question in seedQuestions) {
      await db.insert('questions', question);
    }
  }
}
