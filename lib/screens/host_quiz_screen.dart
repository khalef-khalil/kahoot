import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database_helper.dart';
import '../models.dart';
import '../theme_provider.dart';
import 'multiplayer_quiz_screen.dart';

class HostQuizScreen extends StatefulWidget {
  const HostQuizScreen({super.key});

  @override
  State<HostQuizScreen> createState() => _HostQuizScreenState();
}

class _HostQuizScreenState extends State<HostQuizScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Quiz> _quizzes = [];
  bool _isLoading = true;
  Quiz? _selectedQuiz;
  
  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }
  
  Future<void> _loadQuizzes() async {
    final quizzesMap = await _databaseHelper.getQuizzes();
    final quizzes = quizzesMap.map((map) => Quiz.fromMap(map)).toList();
    
    setState(() {
      _quizzes = quizzes;
      _isLoading = false;
    });
  }
  
  Future<void> _createSession(Quiz quiz) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Generate unique session code
      final sessionCode = await _databaseHelper.generateUniqueSessionCode();
      
      // Create the session in the database
      final sessionId = await _databaseHelper.createQuizSession({
        'quiz_id': quiz.id,
        'session_code': sessionCode,
        'status': 'waiting',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Navigate to the multiplayer quiz screen as host
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MultiplayerQuizScreen(
              sessionId: sessionId,
              quizId: quiz.id!,
              sessionCode: sessionCode,
              isHost: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create session: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Host a Quiz'),
        backgroundColor: themeProvider.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quizzes.isEmpty
              ? _buildEmptyState()
              : _buildQuizList(),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.quiz, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'No Quizzes Available',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Create some quizzes first to host a multiplayer game',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Go back to create quizzes
            },
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuizList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _quizzes.length,
      itemBuilder: (context, index) {
        final quiz = _quizzes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              quiz.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(quiz.description),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildChip(
                      quiz.difficulty.name,
                      _getDifficultyColor(quiz.difficulty),
                    ),
                    const SizedBox(width: 8),
                    _buildChip(quiz.category, Colors.blue),
                  ],
                ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () => _createSession(quiz),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Host'),
            ),
            onTap: () {
              setState(() {
                _selectedQuiz = quiz;
              });
              _showQuizDetails(quiz);
            },
          ),
        );
      },
    );
  }
  
  Widget _buildChip(String label, Color color) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
  
  Color _getDifficultyColor(QuizDifficulty difficulty) {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return Colors.green;
      case QuizDifficulty.medium:
        return Colors.orange;
      case QuizDifficulty.hard:
        return Colors.red;
    }
  }
  
  void _showQuizDetails(Quiz quiz) async {
    final questionsMap = await _databaseHelper.getQuestionsByQuiz(quiz.id!);
    final questionCount = questionsMap.length;
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                quiz.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(quiz.description),
              const SizedBox(height: 16),
              Text('Number of questions: $questionCount'),
              const SizedBox(height: 8),
              Text('Difficulty: ${quiz.difficulty.name}'),
              const SizedBox(height: 8),
              Text('Category: ${quiz.category}'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _createSession(quiz);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Host This Quiz',
                    style: TextStyle(fontSize: 16),
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