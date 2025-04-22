import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database_helper.dart';
import '../models.dart';
import '../theme_provider.dart';
import 'multiplayer_quiz_screen.dart';

class JoinQuizScreen extends StatefulWidget {
  const JoinQuizScreen({super.key});

  @override
  State<JoinQuizScreen> createState() => _JoinQuizScreenState();
}

class _JoinQuizScreenState extends State<JoinQuizScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  
  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _joinSession() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    final sessionCode = _codeController.text.trim().toUpperCase();
    final playerName = _nameController.text.trim();
    
    try {
      // Find the session by code
      final sessionMap = await _databaseHelper.getSessionByCode(sessionCode);
      
      if (sessionMap == null) {
        _showError('Session not found. Check the code and try again.');
        return;
      }
      
      final session = QuizSession.fromMap(sessionMap);
      
      if (session.status == 'completed') {
        _showError('This session has already ended.');
        return;
      }
      
      // Add the player to the session
      final playerId = await _databaseHelper.addPlayer({
        'session_id': session.id,
        'name': playerName,
        'score': 0,
        'joined_at': DateTime.now().toIso8601String(),
      });
      
      // Navigate to the multiplayer quiz screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MultiplayerQuizScreen(
              sessionId: session.id!,
              quizId: session.quizId,
              playerId: playerId,
              playerName: playerName,
              sessionCode: sessionCode,
              isHost: false,
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to join session: $e');
    }
  }
  
  void _showError(String message) {
    setState(() {
      _isLoading = false;
    });
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join a Quiz'),
        backgroundColor: themeProvider.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Icon(
                        Icons.login_rounded,
                        size: 80,
                        color: themeProvider.primaryColor,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Join a Quiz Session',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Enter the session code provided by the host',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        controller: _codeController,
                        decoration: InputDecoration(
                          labelText: 'Session Code',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.vpn_key),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 6,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the session code';
                          }
                          if (value.length != 6) {
                            return 'Session code must be 6 characters long';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          // Auto convert to uppercase
                          if (value != value.toUpperCase()) {
                            _codeController.value = _codeController.value.copyWith(
                              text: value.toUpperCase(),
                              selection: TextSelection.collapsed(offset: value.length),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Your Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          if (value.length < 2) {
                            return 'Name must be at least 2 characters long';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _joinSession,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeProvider.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Join Quiz',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
} 