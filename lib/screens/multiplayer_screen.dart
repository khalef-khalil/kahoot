import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database_helper.dart';
import '../models.dart';
import '../theme_provider.dart';
import 'host_quiz_screen.dart';
import 'join_quiz_screen.dart';

class MultiplayerScreen extends StatelessWidget {
  const MultiplayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiplayer Quiz'),
        backgroundColor: themeProvider.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // Illustration/Icon
            Icon(
              Icons.people_alt_rounded,
              size: 100,
              color: themeProvider.primaryColor,
            ),
            const SizedBox(height: 20),
            const Text(
              'Play together with friends!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Host a quiz or join an existing game using a code',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            // Host button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HostQuizScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Host a Quiz',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            // Join button
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const JoinQuizScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: themeProvider.primaryColor,
                side: BorderSide(color: themeProvider.primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Join a Quiz',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const Spacer(),
            // Info text
            const Text(
              'The multiplayer feature allows you to play quizzes with friends in real-time. One person hosts the quiz while others join using a unique code.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
} 