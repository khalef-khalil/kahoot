class Quiz {
  final int? id;
  final String title;
  final String description;

  Quiz({
    this.id,
    required this.title,
    required this.description,
  });

  factory Quiz.fromMap(Map<String, dynamic> map) {
    return Quiz(
      id: map['id'],
      title: map['title'],
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
    };
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