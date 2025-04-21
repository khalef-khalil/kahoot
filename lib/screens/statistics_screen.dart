import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database_helper.dart';
import '../models.dart';
import '../theme_provider.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _isLoading = true;
  List<QuizResult> _results = [];
  Map<String, dynamic> _stats = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Try to ensure the table exists
      try {
        // Check if the database is ready
        await _databaseHelper.database;
      } catch (e) {
        print("Database initialization error: $e");
      }

      // Try to load quiz results
      List<Map<String, dynamic>> resultsMap = [];
      try {
        resultsMap = await _databaseHelper.getQuizResults();
      } catch (e) {
        print("Error getting quiz results: $e");
        // If we can't get results, just use an empty list
        resultsMap = [];
      }
      
      final List<QuizResult> results = [];
      
      for (var resultMap in resultsMap) {
        final result = QuizResult.fromMap(resultMap);
        
        // Get quiz title
        try {
          final quizMap = await _databaseHelper.getQuiz(result.quizId);
          if (quizMap != null) {
            result.quizTitle = quizMap['title'];
          } else {
            result.quizTitle = 'Unknown Quiz';
          }
        } catch (e) {
          print("Error getting quiz data: $e");
          result.quizTitle = 'Unknown Quiz';
        }
        
        results.add(result);
      }
      
      // Load stats
      Map<String, dynamic> stats = {};
      try {
        stats = await _databaseHelper.getQuizResultStats();
      } catch (e) {
        print("Error getting quiz stats: $e");
        // Default stats if we couldn't load them
        stats = {
          'total_attempts': 0,
          'avg_score': 0.0,
          'best_score': 0.0,
          'unique_quizzes': 0,
        };
      }
      
      setState(() {
        _results = results;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No quiz results available yet. Try completing a quiz first.')),
        );
        setState(() {
          _isLoading = false;
          _results = [];
          _stats = {
            'total_attempts': 0,
            'avg_score': 0.0,
            'best_score': 0.0,
            'unique_quizzes': 0,
          };
        });
      }
    }
  }
  
  Future<void> _clearHistory() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all quiz history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              setState(() {
                _isLoading = true;
              });
              
              try {
                await _databaseHelper.deleteAllQuizResults();
                _loadData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to clear history: $e')),
                  );
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: themeProvider.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Summary', icon: Icon(Icons.bar_chart)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _results.isNotEmpty ? _clearHistory : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildHistoryTab(),
              ],
            ),
    );
  }
  
  Widget _buildSummaryTab() {
    final totalAttempts = _stats['total_attempts'] ?? 0;
    final avgScore = _stats['avg_score'] ?? 0.0;
    final bestScore = _stats['best_score'] ?? 0.0;
    final uniqueQuizzes = _stats['unique_quizzes'] ?? 0;
    
    // Calculate grade distribution
    Map<String, int> gradeDistribution = {
      'A': 0,
      'B': 0,
      'C': 0,
      'D': 0,
      'F': 0,
    };
    
    for (var result in _results) {
      gradeDistribution[result.getGrade()] = (gradeDistribution[result.getGrade()] ?? 0) + 1;
    }
    
    return totalAttempts == 0
        ? const Center(
            child: Text(
              'No quiz results yet. Try taking a quiz first!',
              style: TextStyle(fontSize: 16),
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Performance Summary',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  'Total Quizzes Taken',
                  totalAttempts.toString(),
                  Icons.quiz,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Unique Quizzes Completed',
                  uniqueQuizzes.toString(),
                  Icons.category,
                  Colors.green,
                ),
                _buildStatCard(
                  'Average Score',
                  '${(avgScore * 100).toStringAsFixed(1)}%',
                  Icons.score,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Best Score',
                  '${(bestScore * 100).toStringAsFixed(1)}%',
                  Icons.emoji_events,
                  Colors.purple,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Grade Distribution',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildGradeItem('A', gradeDistribution['A'] ?? 0, totalAttempts, Colors.green),
                          _buildGradeItem('B', gradeDistribution['B'] ?? 0, totalAttempts, Colors.lightGreen),
                          _buildGradeItem('C', gradeDistribution['C'] ?? 0, totalAttempts, Colors.yellow),
                          _buildGradeItem('D', gradeDistribution['D'] ?? 0, totalAttempts, Colors.orange),
                          _buildGradeItem('F', gradeDistribution['F'] ?? 0, totalAttempts, Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }
  
  Widget _buildGradeItem(String grade, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Text(
            grade,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('$percentage%'),
      ],
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHistoryTab() {
    return _results.isEmpty
        ? const Center(
            child: Text(
              'No quiz history yet. Try taking a quiz first!',
              style: TextStyle(fontSize: 16),
            ),
          )
        : ListView.builder(
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final result = _results[index];
              final date = DateTime.parse(result.dateTaken);
              final formattedDate = DateFormat('MMM d, yyyy - h:mm a').format(date);
              
              return Dismissible(
                key: Key(result.id.toString()),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Result'),
                      content: const Text('Are you sure you want to delete this result?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) async {
                  try {
                    await _databaseHelper.deleteQuizResult(result.id!);
                    _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Result deleted')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to delete result: $e')),
                      );
                    }
                  }
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(
                      result.quizTitle ?? 'Unknown Quiz',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formattedDate),
                        Text('Score: ${result.score}/${result.totalQuestions} (${result.getFormattedPercentage()})'),
                      ],
                    ),
                    trailing: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: result.percentage >= 0.6 ? Colors.green : Colors.red,
                      ),
                      child: Text(
                        result.getGrade(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
  }
} 