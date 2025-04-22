import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database_helper.dart';
import '../models.dart';
import '../theme_provider.dart';

class MultiplayerQuizScreen extends StatefulWidget {
  final int sessionId;
  final int quizId;
  final String sessionCode;
  final bool isHost;
  final int? playerId;
  final String? playerName;

  const MultiplayerQuizScreen({
    super.key,
    required this.sessionId,
    required this.quizId,
    required this.sessionCode,
    required this.isHost,
    this.playerId,
    this.playerName,
  });

  @override
  State<MultiplayerQuizScreen> createState() => _MultiplayerQuizScreenState();
}

class _MultiplayerQuizScreenState extends State<MultiplayerQuizScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  Quiz? _quiz;
  List<Question> _questions = [];
  List<Player> _players = [];
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  bool _quizStarted = false;
  bool _quizFinished = false;
  bool _isAnswered = false;
  int _selectedOptionIndex = -1;
  Timer? _timer;
  int _timeLeft = 0;
  Timer? _refreshTimer;
  bool _showingLeaderboard = false;
  
  @override
  void initState() {
    super.initState();
    _loadQuizData();
    
    // Set up a timer to refresh player list every few seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && !_quizFinished) {
        _refreshPlayers();
      }
    });
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadQuizData() async {
    try {
      // Load the quiz
      final quizMap = await _databaseHelper.getQuiz(widget.quizId);
      if (quizMap != null) {
        _quiz = Quiz.fromMap(quizMap);
      }
      
      // Load the questions and options
      final questionsMap = await _databaseHelper.getQuestionsByQuiz(widget.quizId);
      _questions = await Future.wait(questionsMap.map((qMap) async {
        final question = Question.fromMap(qMap);
        
        final optionsMap = await _databaseHelper.getOptionsByQuestion(question.id!);
        question.options = optionsMap.map((oMap) => Option.fromMap(oMap)).toList();
        
        return question;
      }));
      
      // Load the players
      await _refreshPlayers();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading quiz: $e')),
        );
      }
    }
  }
  
  Future<void> _refreshPlayers() async {
    try {
      final playersMap = await _databaseHelper.getPlayersBySession(widget.sessionId);
      final players = playersMap.map((map) => Player.fromMap(map)).toList();
      
      if (mounted) {
        setState(() {
          _players = players;
        });
      }
    } catch (e) {
      print('Error refreshing players: $e');
    }
  }
  
  void _startQuiz() async {
    if (_players.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wait for players to join before starting')),
      );
      return;
    }
    
    try {
      await _databaseHelper.updateSessionStatus(widget.sessionId, 'active');
      
      setState(() {
        _quizStarted = true;
        _showingLeaderboard = false;
      });
      
      _startTimer();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start quiz: $e')),
      );
    }
  }
  
  void _startTimer() {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) return;
    
    _timeLeft = _questions[_currentQuestionIndex].timeLimit;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeLeft > 0) {
            _timeLeft--;
          } else {
            _timer?.cancel();
            
            if (widget.isHost) {
              // If host, show leaderboard after time is up
              _showLeaderboard();
            } else if (!_isAnswered) {
              // Player didn't answer in time
              _isAnswered = true;
            }
          }
        });
      }
    });
  }
  
  void _selectAnswer(int optionIndex) async {
    if (_isAnswered || !_quizStarted || _showingLeaderboard) return;
    
    final selectedOption = _questions[_currentQuestionIndex].options![optionIndex];
    final isCorrect = selectedOption.isCorrect;
    
    setState(() {
      _selectedOptionIndex = optionIndex;
      _isAnswered = true;
    });
    
    if (!widget.isHost && widget.playerId != null) {
      try {
        // Calculate points based on time left and correctness
        int pointsEarned = 0;
        if (isCorrect) {
          // More points for faster answers
          pointsEarned = 1000 + (_timeLeft * 10);
        }
        
        // Get current player
        final playerIndex = _players.indexWhere((p) => p.id == widget.playerId);
        if (playerIndex != -1) {
          final currentPlayer = _players[playerIndex];
          final newScore = (currentPlayer.score ?? 0) + pointsEarned;
          
          // Update score in database
          await _databaseHelper.updatePlayerScore(widget.playerId!, newScore);
          
          // Update local player object
          setState(() {
            _players[playerIndex] = currentPlayer.copyWith(score: newScore);
          });
        }
      } catch (e) {
        print('Error updating score: $e');
      }
    }
  }
  
  void _showLeaderboard() {
    setState(() {
      _showingLeaderboard = true;
    });
    
    // Wait a few seconds then move to next question
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _quizStarted && !_quizFinished) {
        _nextQuestion();
      }
    });
  }
  
  void _nextQuestion() {
    _timer?.cancel();
    
    if (_currentQuestionIndex >= _questions.length - 1) {
      // End of quiz
      _endQuiz();
      return;
    }
    
    setState(() {
      _currentQuestionIndex++;
      _isAnswered = false;
      _selectedOptionIndex = -1;
      _showingLeaderboard = false;
    });
    
    _startTimer();
  }
  
  Future<void> _endQuiz() async {
    try {
      await _databaseHelper.endQuizSession(widget.sessionId);
      
      setState(() {
        _quizFinished = true;
        _showingLeaderboard = true;
      });
    } catch (e) {
      print('Error ending quiz: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading Quiz...'),
          backgroundColor: themeProvider.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_quiz?.title ?? 'Multiplayer Quiz'),
        backgroundColor: themeProvider.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Session code display
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Chip(
              label: Text(
                'Code: ${widget.sessionCode}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
      body: _quizStarted ? _buildQuizContent() : _buildWaitingRoom(),
    );
  }
  
  Widget _buildWaitingRoom() {
    return Column(
      children: [
        // Header for waiting room
        Container(
          width: double.infinity,
          color: Colors.purple.shade50,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Waiting for players to join',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share code: ${widget.sessionCode}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Quiz: ${_quiz?.title ?? ''}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Questions: ${_questions.length}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
        
        // Player list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _players.length,
            itemBuilder: (context, index) {
              final player = _players[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.primaries[index % Colors.primaries.length],
                  child: Text(
                    player.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  player.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Joined ${_formatTime(player.joinedAt)}'),
              );
            },
          ),
        ),
        
        // Start quiz button (only for host)
        if (widget.isHost)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _players.isNotEmpty ? _startQuiz : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Start Quiz',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
          
        if (!widget.isHost)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Waiting for host to start the quiz...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }
  
  Widget _buildQuizContent() {
    if (_questions.isEmpty) {
      return const Center(child: Text('No questions available'));
    }
    
    if (_quizFinished) {
      return _buildFinalResults();
    }
    
    if (_showingLeaderboard) {
      return _buildLeaderboard();
    }
    
    final currentQuestion = _questions[_currentQuestionIndex];
    
    return Column(
      children: [
        // Timer and progress
        LinearProgressIndicator(
          value: _timeLeft / currentQuestion.timeLimit,
          backgroundColor: Colors.grey.shade200,
          color: _getTimerColor(_timeLeft, currentQuestion.timeLimit),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Icon(Icons.timer, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '$_timeLeft s',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getTimerColor(_timeLeft, currentQuestion.timeLimit),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Question
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            currentQuestion.question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        // Options grid
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: List.generate(
              currentQuestion.options!.length,
              (index) => _buildOptionButton(index, currentQuestion),
            ),
          ),
        ),
        
        // Player info (if player)
        if (!widget.isHost)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Playing as: ${widget.playerName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      'Score: ${_getPlayerScore()}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildOptionButton(int index, Question question) {
    final option = question.options![index];
    final colors = _getOptionColors(index);
    
    return ElevatedButton(
      onPressed: _isAnswered ? null : () => _selectAnswer(index),
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.background,
        foregroundColor: Colors.white,
        disabledBackgroundColor: colors.background,
        disabledForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                option.optionText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (_isAnswered && option.isCorrect)
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(Icons.check_circle, color: Colors.white),
            ),
        ],
      ),
    );
  }
  
  Widget _buildLeaderboard() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.purple.shade50,
          child: Column(
            children: [
              const Text(
                'Leaderboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!_quizFinished) ...[
                const SizedBox(height: 8),
                Text(
                  'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Next question coming up...',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ] else ...[
                const SizedBox(height: 8),
                const Text(
                  'Final Results',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _players.length,
            itemBuilder: (context, index) {
              final player = _players[index];
              final isCurrentPlayer = widget.playerId == player.id;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: isCurrentPlayer ? Colors.blue.shade50 : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.primaries[index % Colors.primaries.length],
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    player.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Text(
                    '${player.score ?? 0} pts',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        if (_quizFinished && widget.isHost)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Exit Quiz',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
          
        if (_quizFinished && !widget.isHost)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Back to Menu',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildFinalResults() {
    return _buildLeaderboard();
  }
  
  int _getPlayerScore() {
    if (widget.playerId == null) return 0;
    
    final playerIndex = _players.indexWhere((p) => p.id == widget.playerId);
    if (playerIndex == -1) return 0;
    
    return _players[playerIndex].score ?? 0;
  }
  
  Color _getTimerColor(int timeLeft, int totalTime) {
    final percentage = timeLeft / totalTime;
    
    if (percentage > 0.66) return Colors.green;
    if (percentage > 0.33) return Colors.orange;
    return Colors.red;
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ${difference.inMinutes % 60}m ago';
    }
  }
  
  _OptionColors _getOptionColors(int index) {
    final colors = [
      _OptionColors(Colors.red, Colors.red.shade800),
      _OptionColors(Colors.blue, Colors.blue.shade800),
      _OptionColors(Colors.orange, Colors.orange.shade800),
      _OptionColors(Colors.green, Colors.green.shade800),
    ];
    
    return colors[index % colors.length];
  }
}

class _OptionColors {
  final Color background;
  final Color border;
  
  _OptionColors(this.background, this.border);
} 