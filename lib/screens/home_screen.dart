import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database_helper.dart';
import '../models.dart';
import '../theme_provider.dart';
import 'quiz_screen.dart';
import 'create_quiz_screen.dart';
import 'edit_quiz_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Quiz> _quizzes = [];
  List<Quiz> _filteredQuizzes = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
    _searchController.addListener(_filterQuizzes);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterQuizzes);
    _searchController.dispose();
    super.dispose();
  }

  void _filterQuizzes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredQuizzes = List.from(_quizzes);
      } else {
        _filteredQuizzes = _quizzes
            .where((quiz) =>
                quiz.title.toLowerCase().contains(query) ||
                quiz.description.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _loadQuizzes() async {
    final quizzesMap = await _databaseHelper.getQuizzes();
    setState(() {
      _quizzes = quizzesMap.map((map) => Quiz.fromMap(map)).toList();
      _filteredQuizzes = List.from(_quizzes);
      _isLoading = false;
    });
  }

  Future<void> _deleteQuiz(int quizId) async {
    try {
      await _databaseHelper.deleteQuiz(quizId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz deleted successfully')),
      );
      _loadQuizzes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete quiz: $e')),
      );
    }
  }
  
  Future<void> _duplicateQuiz(int quizId) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _databaseHelper.duplicateQuiz(quizId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz duplicated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to duplicate quiz: $e')),
        );
      }
    } finally {
      if (mounted) {
        _loadQuizzes();
      }
    }
  }

  void _confirmDelete(Quiz quiz) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text('Are you sure you want to delete "${quiz.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteQuiz(quiz.id!);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _editQuiz(Quiz quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditQuizScreen(quizId: quiz.id!),
      ),
    ).then((_) => _loadQuizzes());
  }
  
  void _showQuizOptions(Quiz quiz) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('Play Quiz'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizScreen(quizId: quiz.id!),
                ),
              ).then((_) => _loadQuizzes());
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Quiz'),
            onTap: () {
              Navigator.pop(context);
              _editQuiz(quiz);
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Duplicate Quiz'),
            onTap: () {
              Navigator.pop(context);
              _duplicateQuiz(quiz.id!);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Quiz', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(quiz);
            },
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
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search quizzes...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                autofocus: true,
              )
            : const Text('Kahoot Clone'),
        backgroundColor: themeProvider.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? 'Cancel search' : 'Search quizzes',
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StatisticsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quizzes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No quizzes available',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          await _databaseHelper.insertSampleData();
                          _loadQuizzes();
                        },
                        child: const Text('Add Sample Quiz'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (_filteredQuizzes.isEmpty && !_quizzes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No quizzes match your search',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _filteredQuizzes.length,
                        itemBuilder: (context, index) {
                          final quiz = _filteredQuizzes[index];
                          return Dismissible(
                            key: Key(quiz.id.toString()),
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
                              _confirmDelete(quiz);
                              return false; // Prevent automatic dismissal
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: ListTile(
                                title: Text(
                                  quiz.title,
                                  style: const TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(quiz.description),
                                trailing: IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () => _showQuizOptions(quiz),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => QuizScreen(quizId: quiz.id!),
                                    ),
                                  ).then((_) => _loadQuizzes());
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateQuizScreen(),
            ),
          ).then((_) => _loadQuizzes());
        },
        backgroundColor: themeProvider.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
} 