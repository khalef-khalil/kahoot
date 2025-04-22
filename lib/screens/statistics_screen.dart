import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database_helper.dart';
import '../models.dart';
import '../theme_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';

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
            icon: const Icon(Icons.file_download),
            tooltip: 'Export Results',
            onPressed: _results.isNotEmpty ? _exportQuizResults : null,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: _stats.isEmpty || (_stats['total_attempts'] ?? 0) == 0
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.quiz,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Quiz Data Yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Complete some quizzes to see your statistics here.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back to Quizzes'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Performance Summary',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildStatCard(
                  'Total Quizzes Taken',
                  '${_stats['total_attempts']}',
                  Icons.assignment_turned_in,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Unique Quizzes Completed',
                  '${_stats['unique_quizzes']}',
                  Icons.playlist_add_check,
                  Colors.green,
                ),
                _buildStatCard(
                  'Average Score',
                  '${(_stats['avg_score'] * 100).toStringAsFixed(1)}%',
                  Icons.score,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Best Score',
                  '${(_stats['best_score'] * 100).toStringAsFixed(1)}%',
                  Icons.emoji_events,
                  Colors.purple,
                ),
                _buildStatCard(
                  'Average Quiz Time',
                  _formatTime(_stats['avg_time'] ?? 0),
                  Icons.timer,
                  Colors.red,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Grade Distribution',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildGradeDistribution(),
              ],
            ),
    );
  }
  
  String _formatTime(dynamic timeValue) {
    double seconds = 0.0;
    
    if (timeValue is int) {
      seconds = timeValue.toDouble();
    } else if (timeValue is double) {
      seconds = timeValue;
    }
    
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  Widget _buildGradeDistribution() {
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
    
    return Container(
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
              _buildGradeItem('A', gradeDistribution['A'] ?? 0, _stats['total_attempts'] ?? 0, Colors.green),
              _buildGradeItem('B', gradeDistribution['B'] ?? 0, _stats['total_attempts'] ?? 0, Colors.lightGreen),
              _buildGradeItem('C', gradeDistribution['C'] ?? 0, _stats['total_attempts'] ?? 0, Colors.yellow),
              _buildGradeItem('D', gradeDistribution['D'] ?? 0, _stats['total_attempts'] ?? 0, Colors.orange),
              _buildGradeItem('F', gradeDistribution['F'] ?? 0, _stats['total_attempts'] ?? 0, Colors.red),
            ],
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
              return _buildHistoryItem(result);
            },
          );
  }

  Widget _buildHistoryItem(QuizResult result) {
    final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(DateTime.parse(result.dateTaken));
    final gradeColor = _getGradeColor(result.getGrade());
    
    return Dismissible(
      key: Key(result.id.toString()),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Result'),
            content: const Text('Are you sure you want to delete this quiz result?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        try {
          await _databaseHelper.deleteQuizResult(result.id!);
          _loadData();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete result: $e')),
            );
          }
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        elevation: 2.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      result.quizTitle ?? 'Unknown Quiz',
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: gradeColor,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      result.getGrade(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14.0, color: Colors.grey),
                  const SizedBox(width: 4.0),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.question_answer, size: 14.0, color: Colors.grey),
                        const SizedBox(width: 4.0),
                        Text(
                          '${result.score}/${result.totalQuestions} correct',
                          style: const TextStyle(fontSize: 14.0),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.score, size: 14.0, color: Colors.grey),
                        const SizedBox(width: 4.0),
                        Text(
                          result.getFormattedPercentage(),
                          style: const TextStyle(fontSize: 14.0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  const Icon(Icons.timer, size: 14.0, color: Colors.grey),
                  const SizedBox(width: 4.0),
                  Text(
                    'Time: ${result.getFormattedTime()}',
                    style: const TextStyle(fontSize: 14.0),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.lightGreen;
      case 'C':
        return Colors.yellow;
      case 'D':
        return Colors.orange;
      case 'F':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _exportQuizResults() async {
    try {
      // Show export options dialog
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Quiz Results'),
          content: const Text('Choose an export format:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'csv'),
              child: const Text('CSV'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      
      if (choice == 'csv') {
        await _exportAsCSV();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
  
  Future<void> _exportAsCSV() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Prepare CSV data
      List<List<dynamic>> csvData = [
        // CSV Header
        ['Quiz Title', 'Date', 'Score', 'Total Questions', 'Percentage', 'Grade', 'Time (m:ss)']
      ];
      
      // Add quiz results
      for (var result in _results) {
        csvData.add([
          result.quizTitle ?? 'Unknown Quiz',
          DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(result.dateTaken)),
          result.score,
          result.totalQuestions,
          result.getFormattedPercentage(),
          result.getGrade(),
          result.getFormattedTime(),
        ]);
      }
      
      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);
      
      // Get temp directory (doesn't require storage permission)
      final directory = await getTemporaryDirectory();
      final fileName = 'kahoot_results_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final path = '${directory.path}/$fileName';
      
      // Write the file
      final File file = File(path);
      await file.writeAsString(csv);
      
      // Share the file using share_plus (doesn't require storage permission)
      await Share.shareXFiles(
        [XFile(path)], 
        subject: 'Kahoot Quiz Results',
        text: 'Here are my Kahoot quiz results!'
      );
      
      setState(() {
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
} 