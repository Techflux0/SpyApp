import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class QuizResult {
  final int? id;
  final int categoryId;
  final String categoryName;
  final int score;
  final int totalQuestions;
  final DateTime date;
  final String details; // JSON string storing question-by-question results

  QuizResult({
    this.id,
    required this.categoryId,
    required this.categoryName,
    required this.score,
    required this.totalQuestions,
    required this.date,
    required this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'score': score,
      'totalQuestions': totalQuestions,
      'date': date.toIso8601String(),
      'details': details,
    };
  }

  factory QuizResult.fromMap(Map<String, dynamic> map) {
    return QuizResult(
      id: map['id'],
      categoryId: map['categoryId'],
      categoryName: map['categoryName'],
      score: map['score'],
      totalQuestions: map['totalQuestions'],
      date: DateTime.parse(map['date']),
      details: map['details'],
    );
  }
}

class DatabaseService {
  static const _databaseName = 'quiz_results.db';
  static const _databaseVersion = 1;

  static const table = 'quiz_results';

  static const columnId = 'id';
  static const columnCategoryId = 'categoryId';
  static const columnCategoryName = 'categoryName';
  static const columnScore = 'score';
  static const columnTotalQuestions = 'totalQuestions';
  static const columnDate = 'date';
  static const columnDetails = 'details';

  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnCategoryId INTEGER NOT NULL,
        $columnCategoryName TEXT NOT NULL,
        $columnScore INTEGER NOT NULL,
        $columnTotalQuestions INTEGER NOT NULL,
        $columnDate TEXT NOT NULL,
        $columnDetails TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertResult(QuizResult result) async {
    final db = await instance.database;
    return await db.insert(table, result.toMap());
  }

  Future<List<QuizResult>> getAllResults() async {
    final db = await instance.database;
    final results = await db.query(table, orderBy: '$columnDate DESC');
    return results.map((e) => QuizResult.fromMap(e)).toList();
  }

  Future<List<QuizResult>> getResultsByCategory(int categoryId) async {
    final db = await instance.database;
    final results = await db.query(
      table,
      where: '$columnCategoryId = ?',
      whereArgs: [categoryId],
      orderBy: '$columnDate DESC',
    );
    return results.map((e) => QuizResult.fromMap(e)).toList();
  }

  Future<int> deleteResult(int id) async {
    final db = await instance.database;
    return await db.delete(
      table,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
}