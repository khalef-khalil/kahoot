import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'kahoot.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDb,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS quiz_results(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          quiz_id INTEGER,
          score INTEGER,
          total_questions INTEGER,
          percentage REAL,
          date_taken TEXT,
          FOREIGN KEY (quiz_id) REFERENCES quizzes(id)
        )
      ''');
    }
    
    if (oldVersion < 3) {
      // Add is_favorite column to quizzes table if it doesn't exist
      var columns = await db.rawQuery('PRAGMA table_info(quizzes)');
      bool columnExists = columns.any((column) => column['name'] == 'is_favorite');
      
      if (!columnExists) {
        await db.execute('ALTER TABLE quizzes ADD COLUMN is_favorite INTEGER DEFAULT 0');
      }
    }
  }

  Future<void> _createDb(Database db, int version) async {
    // Create quizzes table
    await db.execute('''
      CREATE TABLE quizzes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        description TEXT,
        is_favorite INTEGER DEFAULT 0
      )
    ''');

    // Create questions table
    await db.execute('''
      CREATE TABLE questions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quiz_id INTEGER,
        question TEXT,
        time_limit INTEGER,
        FOREIGN KEY (quiz_id) REFERENCES quizzes(id)
      )
    ''');

    // Create options table
    await db.execute('''
      CREATE TABLE options(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id INTEGER,
        option_text TEXT,
        is_correct INTEGER,
        FOREIGN KEY (question_id) REFERENCES questions(id)
      )
    ''');
    
    // Create quiz_results table
    await db.execute('''
      CREATE TABLE quiz_results(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quiz_id INTEGER,
        score INTEGER,
        total_questions INTEGER,
        percentage REAL,
        date_taken TEXT,
        FOREIGN KEY (quiz_id) REFERENCES quizzes(id)
      )
    ''');
  }

  // Quiz Operations
  Future<int> insertQuiz(Map<String, dynamic> quiz) async {
    Database db = await database;
    return await db.insert('quizzes', quiz);
  }

  Future<List<Map<String, dynamic>>> getQuizzes() async {
    Database db = await database;
    return await db.query('quizzes');
  }

  Future<Map<String, dynamic>?> getQuiz(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> result = 
        await db.query('quizzes', where: 'id = ?', whereArgs: [id], limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  // Delete a quiz and its associated questions and options
  Future<int> deleteQuiz(int quizId) async {
    Database db = await database;
    
    // Get all questions for this quiz
    List<Map<String, dynamic>> questions = await db.query(
      'questions',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
    );
    
    // Delete options for each question
    for (var question in questions) {
      int questionId = question['id'];
      await db.delete(
        'options',
        where: 'question_id = ?',
        whereArgs: [questionId],
      );
    }
    
    // Delete all questions for this quiz
    await db.delete(
      'questions',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
    );
    
    // Delete the quiz
    return await db.delete(
      'quizzes',
      where: 'id = ?',
      whereArgs: [quizId],
    );
  }

  // Update a quiz
  Future<int> updateQuiz(int id, Map<String, dynamic> quiz) async {
    Database db = await database;
    return await db.update(
      'quizzes',
      quiz,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Question Operations
  Future<int> insertQuestion(Map<String, dynamic> question) async {
    Database db = await database;
    return await db.insert('questions', question);
  }

  Future<List<Map<String, dynamic>>> getQuestionsByQuiz(int quizId) async {
    Database db = await database;
    return await db.query(
      'questions',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
    );
  }

  // Update a question
  Future<int> updateQuestion(int id, Map<String, dynamic> question) async {
    Database db = await database;
    return await db.update(
      'questions',
      question,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete a question and its options
  Future<int> deleteQuestion(int questionId) async {
    Database db = await database;
    
    // Delete options for this question
    await db.delete(
      'options',
      where: 'question_id = ?',
      whereArgs: [questionId],
    );
    
    // Delete the question
    return await db.delete(
      'questions',
      where: 'id = ?',
      whereArgs: [questionId],
    );
  }

  // Option Operations
  Future<int> insertOption(Map<String, dynamic> option) async {
    Database db = await database;
    return await db.insert('options', option);
  }

  Future<List<Map<String, dynamic>>> getOptionsByQuestion(int questionId) async {
    Database db = await database;
    return await db.query(
      'options',
      where: 'question_id = ?',
      whereArgs: [questionId],
    );
  }

  // Update an option
  Future<int> updateOption(int id, Map<String, dynamic> option) async {
    Database db = await database;
    return await db.update(
      'options',
      option,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Delete an option
  Future<int> deleteOption(int optionId) async {
    Database db = await database;
    return await db.delete(
      'options',
      where: 'id = ?',
      whereArgs: [optionId],
    );
  }

  // Duplicate a quiz with all its questions and options
  Future<int> duplicateQuiz(int quizId) async {
    Database db = await database;
    
    // Get the quiz to duplicate
    final quizMap = await getQuiz(quizId);
    if (quizMap == null) {
      throw Exception('Quiz not found');
    }
    
    // Create a new quiz with the same details but append "(Copy)" to the title
    final newQuizId = await insertQuiz({
      'title': '${quizMap['title']} (Copy)',
      'description': quizMap['description'],
    });
    
    // Get all questions for this quiz
    final questionsMap = await getQuestionsByQuiz(quizId);
    
    // Duplicate each question
    for (var questionMap in questionsMap) {
      final newQuestionId = await insertQuestion({
        'quiz_id': newQuizId,
        'question': questionMap['question'],
        'time_limit': questionMap['time_limit'],
      });
      
      // Get all options for this question
      final optionsMap = await getOptionsByQuestion(questionMap['id']);
      
      // Duplicate each option
      for (var optionMap in optionsMap) {
        await insertOption({
          'question_id': newQuestionId,
          'option_text': optionMap['option_text'],
          'is_correct': optionMap['is_correct'],
        });
      }
    }
    
    return newQuizId;
  }

  // Quiz Result Operations
  Future<void> ensureQuizResultsTableExists() async {
    Database db = await database;
    // Check if the table exists
    var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='quiz_results'");
    if (tables.isEmpty) {
      // Create the table if it doesn't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS quiz_results(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          quiz_id INTEGER,
          score INTEGER,
          total_questions INTEGER,
          percentage REAL,
          date_taken TEXT,
          FOREIGN KEY (quiz_id) REFERENCES quizzes(id)
        )
      ''');
    }
  }

  Future<int> saveQuizResult(Map<String, dynamic> result) async {
    await ensureQuizResultsTableExists();
    Database db = await database;
    return await db.insert('quiz_results', result);
  }

  Future<List<Map<String, dynamic>>> getQuizResults() async {
    await ensureQuizResultsTableExists();
    Database db = await database;
    return await db.query(
      'quiz_results',
      orderBy: 'date_taken DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getQuizResultsByQuiz(int quizId) async {
    await ensureQuizResultsTableExists();
    Database db = await database;
    return await db.query(
      'quiz_results',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
      orderBy: 'date_taken DESC',
    );
  }
  
  Future<Map<String, dynamic>> getQuizResultStats() async {
    await ensureQuizResultsTableExists();
    Database db = await database;
    
    // Get total number of quiz attempts
    final totalAttemptsResult = await db.rawQuery('SELECT COUNT(*) AS count FROM quiz_results');
    final totalAttempts = Sqflite.firstIntValue(totalAttemptsResult) ?? 0;
    
    // Default values in case there are no results
    double avgScore = 0.0;
    double bestScore = 0.0;
    int uniqueQuizzes = 0;
    
    if (totalAttempts > 0) {
      // Get average score percentage
      final avgScoreResult = await db.rawQuery('SELECT AVG(percentage) AS avg_score FROM quiz_results');
      avgScore = avgScoreResult.first['avg_score'] as double? ?? 0.0;
      
      // Get best score
      final bestScoreResult = await db.rawQuery('SELECT MAX(percentage) AS best_score FROM quiz_results');
      bestScore = bestScoreResult.first['best_score'] as double? ?? 0.0;
      
      // Get total quizzes taken
      final uniqueQuizzesResult = await db.rawQuery('SELECT COUNT(DISTINCT quiz_id) AS count FROM quiz_results');
      uniqueQuizzes = Sqflite.firstIntValue(uniqueQuizzesResult) ?? 0;
    }
    
    return {
      'total_attempts': totalAttempts,
      'avg_score': avgScore,
      'best_score': bestScore,
      'unique_quizzes': uniqueQuizzes,
    };
  }
  
  Future<int> deleteQuizResult(int resultId) async {
    await ensureQuizResultsTableExists();
    Database db = await database;
    return await db.delete(
      'quiz_results',
      where: 'id = ?',
      whereArgs: [resultId],
    );
  }
  
  Future<int> deleteAllQuizResults() async {
    await ensureQuizResultsTableExists();
    Database db = await database;
    return await db.delete('quiz_results');
  }

  // Insert sample data for testing
  Future<void> insertSampleData() async {
    // Insert a sample quiz
    int quizId = await insertQuiz({
      'title': 'Sample Quiz',
      'description': 'A sample quiz to test the app',
    });

    // Insert sample questions
    int q1 = await insertQuestion({
      'quiz_id': quizId,
      'question': 'What is Flutter?',
      'time_limit': 20,
    });

    int q2 = await insertQuestion({
      'quiz_id': quizId,
      'question': 'What is SQLite?',
      'time_limit': 20,
    });

    // Insert options for question 1
    await insertOption({
      'question_id': q1,
      'option_text': 'A mobile app development framework',
      'is_correct': 1,
    });
    await insertOption({
      'question_id': q1,
      'option_text': 'A database',
      'is_correct': 0,
    });
    await insertOption({
      'question_id': q1,
      'option_text': 'A programming language',
      'is_correct': 0,
    });
    await insertOption({
      'question_id': q1,
      'option_text': 'A web framework',
      'is_correct': 0,
    });

    // Insert options for question 2
    await insertOption({
      'question_id': q2,
      'option_text': 'A relational database management system',
      'is_correct': 1,
    });
    await insertOption({
      'question_id': q2,
      'option_text': 'A programming language',
      'is_correct': 0,
    });
    await insertOption({
      'question_id': q2,
      'option_text': 'A mobile app',
      'is_correct': 0,
    });
    await insertOption({
      'question_id': q2,
      'option_text': 'A cloud service',
      'is_correct': 0,
    });
  }

  // Toggle favorite status for a quiz
  Future<int> toggleQuizFavorite(int quizId, bool isFavorite) async {
    Database db = await database;
    return await db.update(
      'quizzes',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [quizId],
    );
  }

  // Get all favorite quizzes
  Future<List<Map<String, dynamic>>> getFavoriteQuizzes() async {
    Database db = await database;
    return await db.query(
      'quizzes',
      where: 'is_favorite = ?',
      whereArgs: [1],
    );
  }
} 