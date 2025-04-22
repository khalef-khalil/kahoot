// Define difficulty levels
enum QuizDifficulty {
  easy,
  medium,
  hard
}

// Helper extension to convert from/to string
extension QuizDifficultyExtension on QuizDifficulty {
  String get name {
    switch (this) {
      case QuizDifficulty.easy: return 'Easy';
      case QuizDifficulty.medium: return 'Medium';
      case QuizDifficulty.hard: return 'Hard';
    }
  }
  
  static QuizDifficulty fromString(String? value) {
    if (value == 'Easy') return QuizDifficulty.easy;
    if (value == 'Medium') return QuizDifficulty.medium;
    if (value == 'Hard') return QuizDifficulty.hard;
    return QuizDifficulty.medium; // Default
  }
}

class Quiz {
  final int? id;
  final String title;
  final String description;
  final bool isFavorite;
  final QuizDifficulty difficulty;
  final String category;

  Quiz({
    this.id,
    required this.title,
    required this.description,
    this.isFavorite = false,
    this.difficulty = QuizDifficulty.medium,
    this.category = 'General',
  });

  factory Quiz.fromMap(Map<String, dynamic> map) {
    return Quiz(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      isFavorite: map['is_favorite'] == 1,
      difficulty: map['difficulty'] != null 
          ? QuizDifficultyExtension.fromString(map['difficulty'])
          : QuizDifficulty.medium,
      category: map['category'] ?? 'General',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_favorite': isFavorite ? 1 : 0,
      'difficulty': difficulty.name,
      'category': category,
    };
  }

  // Create a copy of this quiz with changes
  Quiz copyWith({
    int? id,
    String? title,
    String? description,
    bool? isFavorite,
    QuizDifficulty? difficulty,
    String? category,
  }) {
    return Quiz(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
    );
  }
}

class Question {
  final int? id;
  int quizId;
  final String question;
  final int timeLimit;
  List<Option>? options;

  Question({
    this.id,
    required this.quizId,
    required this.question,
    required this.timeLimit,
    this.options,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'],
      quizId: map['quiz_id'],
      question: map['question'],
      timeLimit: map['time_limit'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quiz_id': quizId,
      'question': question,
      'time_limit': timeLimit,
    };
  }
}

class Option {
  final int? id;
  int questionId;
  String optionText;
  bool isCorrect;

  Option({
    this.id,
    required this.questionId,
    required this.optionText,
    required this.isCorrect,
  });

  factory Option.fromMap(Map<String, dynamic> map) {
    return Option(
      id: map['id'],
      questionId: map['question_id'],
      optionText: map['option_text'],
      isCorrect: map['is_correct'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question_id': questionId,
      'option_text': optionText,
      'is_correct': isCorrect ? 1 : 0,
    };
  }
}

class QuizResult {
  final int? id;
  final int quizId;
  final int score;
  final int totalQuestions;
  final double percentage;
  final String dateTaken;
  final int? totalTime; // Total time in seconds
  String? quizTitle; // For display purposes, not stored in database directly

  QuizResult({
    this.id,
    required this.quizId,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.dateTaken,
    this.totalTime,
    this.quizTitle,
  });

  factory QuizResult.fromMap(Map<String, dynamic> map) {
    return QuizResult(
      id: map['id'],
      quizId: map['quiz_id'],
      score: map['score'],
      totalQuestions: map['total_questions'],
      percentage: map['percentage'] is int 
          ? (map['percentage'] as int).toDouble() 
          : map['percentage'],
      dateTaken: map['date_taken'],
      totalTime: map['total_time'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quiz_id': quizId,
      'score': score,
      'total_questions': totalQuestions,
      'percentage': percentage,
      'date_taken': dateTaken,
      'total_time': totalTime,
    };
  }
  
  // Format the percentage for display
  String getFormattedPercentage() {
    return '${(percentage * 100).toStringAsFixed(1)}%';
  }
  
  // Get a performance grade based on percentage
  String getGrade() {
    if (percentage >= 0.9) return 'A';
    if (percentage >= 0.8) return 'B';
    if (percentage >= 0.7) return 'C';
    if (percentage >= 0.6) return 'D';
    return 'F';
  }
  
  // Format the total time for display
  String getFormattedTime() {
    if (totalTime == null) return 'N/A';
    
    final minutes = totalTime! ~/ 60;
    final seconds = totalTime! % 60;
    
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
} 