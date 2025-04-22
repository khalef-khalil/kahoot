import 'dart:async';
import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';
import '../auth_service.dart';

class QuizScreen extends StatefulWidget {
  final int quizId;

  const QuizScreen({super.key, required this.quizId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final AuthService _authService = AuthService();
  Quiz? _quiz;
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  bool _isAnswered = false;
  int _selectedOptionIndex = -1;
  int _score = 0;
  Timer? _timer;
  int _timeLeft = 0;
  bool _quizFinished = false;
  
  // Total quiz time tracking
  int _totalQuizTime = 0;
  Timer? _quizTimeTimer;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    // Load quiz
    final quizMap = await _databaseHelper.getQuiz(widget.quizId);
    if (quizMap != null) {
      _quiz = Quiz.fromMap(quizMap);
      
      // Load questions
      final questionsMap = await _databaseHelper.getQuestionsByQuiz(widget.quizId);
      _questions = await Future.wait(questionsMap.map((qMap) async {
        final question = Question.fromMap(qMap);
        
        // Load options for each question
        final optionsMap = await _databaseHelper.getOptionsByQuestion(question.id!);
        question.options = optionsMap.map((oMap) => Option.fromMap(oMap)).toList();
        
        return question;
      }));
      
      if (_questions.isNotEmpty) {
        _startTimer();
        _startQuizTimeTracking();
      }
      
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startQuizTimeTracking() {
    // Start a timer to track the total quiz time
    _quizTimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _totalQuizTime++;
    });
  }

  void _stopQuizTimeTracking() {
    _quizTimeTimer?.cancel();
  }

  void _startTimer() {
    _timeLeft = _questions[_currentQuestionIndex].timeLimit;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer?.cancel();
          if (!_isAnswered) {
            // Time's up without answering
            _isAnswered = true;
            Future.delayed(const Duration(seconds: 2), () {
              _nextQuestion();
            });
          }
        }
      });
    });
  }

  void _nextQuestion() {
    _timer?.cancel();
    setState(() {
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
        _isAnswered = false;
        _selectedOptionIndex = -1;
        _startTimer();
      } else {
        // Quiz is finished
        _quizFinished = true;
        _stopQuizTimeTracking();
        _saveQuizResult();
      }
    });
  }

  void _checkAnswer(int optionIndex) {
    if (_isAnswered) return;
    
    final currentQuestion = _questions[_currentQuestionIndex];
    final selectedOption = currentQuestion.options![optionIndex];
    
    setState(() {
      _selectedOptionIndex = optionIndex;
      _isAnswered = true;
      if (selectedOption.isCorrect) {
        _score++;
      }
    });
    
    _timer?.cancel();
    Future.delayed(const Duration(seconds: 2), () {
      _nextQuestion();
    });
  }

  Future<void> _saveQuizResult() async {
    final percentage = _score / _questions.length;
    
    try {
      // Make sure the quiz_results table exists
      await _databaseHelper.ensureQuizResultsTableExists();
      
      // Get current user ID
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('You must be logged in to save quiz results');
      }
      
      await _databaseHelper.saveQuizResult({
        'quiz_id': widget.quizId,
        'user_id': userId,
        'score': _score,
        'total_questions': _questions.length,
        'percentage': percentage,
        'date_taken': DateTime.now().toIso8601String(),
        'total_time': _totalQuizTime, // Save the total time
      });
    } catch (e) {
      print('Failed to save quiz result: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to save quiz result. Your score was $_score/${_questions.length}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _quizTimeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading Quiz...'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_quizFinished) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_quiz!.title),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Quiz Completed!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                'Score: $_score / ${_questions.length}',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 10),
              Text(
                'Time: ${_formatTime(_totalQuizTime)}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Return to Home'),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final options = currentQuestion.options!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_quiz!.title),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Progress and Timer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                  style: const TextStyle(fontSize: 18),
                ),
                Row(
                  children: [
                    const Icon(Icons.timer),
                    const SizedBox(width: 5),
                    Text(
                      '$_timeLeft s',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
            // Question
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                currentQuestion.question,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Options
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  Color buttonColor = Colors.blue;
                  
                  if (_isAnswered) {
                    if (option.isCorrect) {
                      buttonColor = Colors.green;
                    } else if (index == _selectedOptionIndex) {
                      buttonColor = Colors.red;
                    }
                  } else {
                    switch (index) {
                      case 0:
                        buttonColor = Colors.red;
                        break;
                      case 1:
                        buttonColor = Colors.blue;
                        break;
                      case 2:
                        buttonColor = Colors.yellow;
                        break;
                      case 3:
                        buttonColor = Colors.green;
                        break;
                    }
                  }
                  
                  return InkWell(
                    onTap: _isAnswered ? null : () => _checkAnswer(index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: buttonColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            option.optionText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
} 