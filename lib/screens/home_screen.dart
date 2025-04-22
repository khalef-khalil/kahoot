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
import '../file_utils.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'multiplayer_screen.dart';
import '../auth_service.dart';
import 'auth/login_screen.dart';

enum QuizSortOption {
  titleAsc,
  titleDesc,
  newest,
  oldest,
}

enum FilterOption {
  all,
  favorites,
  easy,
  medium,
  hard,
  category,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final AuthService _authService = AuthService();
  List<Quiz> _quizzes = [];
  List<Quiz> _filteredQuizzes = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  QuizSortOption _currentSortOption = QuizSortOption.titleAsc;
  FilterOption _currentFilter = FilterOption.all;
  String _selectedCategory = 'All Categories';
  
  List<String> _categories = ['All Categories'];

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
    setState(() {
      // First filter by text query
      final query = _searchController.text.toLowerCase();
      var result = _quizzes;
      
      if (query.isNotEmpty) {
        result = result
            .where((quiz) =>
                quiz.title.toLowerCase().contains(query) ||
                quiz.description.toLowerCase().contains(query))
            .toList();
      }
      
      // Apply filters based on selection
      switch (_currentFilter) {
        case FilterOption.favorites:
          result = result.where((quiz) => quiz.isFavorite).toList();
          break;
        case FilterOption.easy:
          result = result.where((quiz) => quiz.difficulty == QuizDifficulty.easy).toList();
          break;
        case FilterOption.medium:
          result = result.where((quiz) => quiz.difficulty == QuizDifficulty.medium).toList();
          break;
        case FilterOption.hard:
          result = result.where((quiz) => quiz.difficulty == QuizDifficulty.hard).toList();
          break;
        case FilterOption.category:
          // Only filter if not "All Categories"
          if (_selectedCategory != 'All Categories') {
            result = result.where((quiz) => quiz.category == _selectedCategory).toList();
          }
          break;
        case FilterOption.all:
          // No additional filtering needed
          break;
      }
      
      _filteredQuizzes = result;
      _sortQuizzes();
    });
  }

  void _toggleFavorite(Quiz quiz) async {
    final newFavoriteStatus = !quiz.isFavorite;
    
    try {
      await _databaseHelper.toggleQuizFavorite(quiz.id!, newFavoriteStatus);
      
      // Update local state
      setState(() {
        final index = _quizzes.indexWhere((q) => q.id == quiz.id);
        if (index != -1) {
          _quizzes[index] = quiz.copyWith(isFavorite: newFavoriteStatus);
          _filterQuizzes(); // Reapply filters
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newFavoriteStatus ? 'Added to favorites' : 'Removed from favorites'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update favorite status: $e')),
      );
    }
  }

  void _changeFilter(FilterOption filter) {
    setState(() {
      _currentFilter = filter;
      _filterQuizzes();
    });
  }

  void _sortQuizzes() {
    switch (_currentSortOption) {
      case QuizSortOption.titleAsc:
        _filteredQuizzes.sort((a, b) => a.title.compareTo(b.title));
        break;
      case QuizSortOption.titleDesc:
        _filteredQuizzes.sort((a, b) => b.title.compareTo(a.title));
        break;
      case QuizSortOption.newest:
        // For this to work properly, we would need to add a 'dateCreated' field to the Quiz model
        // For now, we'll use the id as a proxy for recency (higher id = more recent)
        _filteredQuizzes.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
        break;
      case QuizSortOption.oldest:
        // Using id as proxy for creation date (lower id = older)
        _filteredQuizzes.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
        break;
    }
  }

  void _changeSort(QuizSortOption option) {
    setState(() {
      _currentSortOption = option;
      _sortQuizzes();
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.sort_by_alpha),
            title: const Text('Title (A-Z)'),
            trailing: _currentSortOption == QuizSortOption.titleAsc
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              Navigator.pop(context);
              _changeSort(QuizSortOption.titleAsc);
            },
          ),
          ListTile(
            leading: const Icon(Icons.sort_by_alpha),
            title: const Text('Title (Z-A)'),
            trailing: _currentSortOption == QuizSortOption.titleDesc
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              Navigator.pop(context);
              _changeSort(QuizSortOption.titleDesc);
            },
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Newest First'),
            trailing: _currentSortOption == QuizSortOption.newest
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              Navigator.pop(context);
              _changeSort(QuizSortOption.newest);
            },
          ),
          ListTile(
            leading: const Icon(Icons.access_time_filled),
            title: const Text('Oldest First'),
            trailing: _currentSortOption == QuizSortOption.oldest
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              Navigator.pop(context);
              _changeSort(QuizSortOption.oldest);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _loadQuizzes() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Only load quizzes for the current user
      final userId = _authService.currentUser?.id;
      
      if (userId == null) {
        // Handle the case where there's no logged-in user
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }
      
      final quizzesMap = await _databaseHelper.getQuizzesByUser(userId);
      _quizzes = quizzesMap.map((map) => Quiz.fromMap(map)).toList();
      
      // Extract all unique categories
      _categories = ['All Categories'];
      final uniqueCategories = <String>{};
      for (var quiz in _quizzes) {
        if (quiz.category.isNotEmpty) {
          uniqueCategories.add(quiz.category);
        }
      }
      _categories.addAll(uniqueCategories);
      
      _filterQuizzes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading quizzes: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
    try {
      final newId = await _databaseHelper.duplicateQuiz(quizId);
      _loadQuizzes();
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
    }
  }

  Future<void> _exportQuiz(int quizId, String quizTitle) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final quizData = await _databaseHelper.exportQuizToJson(quizId);
      await FileUtils.shareQuizAsJson(quizData, quizTitle);
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz exported successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export quiz: $e')),
        );
      }
    }
  }
  
  Future<void> _importQuiz() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Open file picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        
        // Parse the JSON file
        final quizData = await FileUtils.parseQuizJsonFile(file);
        
        if (quizData != null) {
          // Import the quiz
          final newQuizId = await _databaseHelper.importQuizFromJson(quizData);
          
          // Reload quizzes
          _loadQuizzes();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Quiz imported successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid quiz file format')),
            );
          }
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import quiz: $e')),
        );
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
            leading: Icon(
              quiz.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: quiz.isFavorite ? Colors.red : null,
            ),
            title: Text(quiz.isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
            onTap: () {
              Navigator.pop(context);
              _toggleFavorite(quiz);
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
            leading: const Icon(Icons.share),
            title: const Text('Export Quiz'),
            onTap: () {
              Navigator.pop(context);
              _exportQuiz(quiz.id!, quiz.title);
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

  void _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentUser = _authService.currentUser;
    
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: themeProvider.primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentUser?.username ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    currentUser?.email ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Statistics'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StatisticsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Multiplayer'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MultiplayerScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Import Quiz'),
              onTap: () {
                Navigator.pop(context);
                _importQuiz();
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        elevation: 0,
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
            : Text('${currentUser?.username}\'s Quizzes'),
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
          if (_quizzes.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.sort),
              tooltip: 'Sort quizzes',
              onPressed: _showSortOptions,
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filter quizzes',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Text(
                            'Filter Quizzes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: Icon(
                            Icons.list,
                            color: _currentFilter == FilterOption.all ? themeProvider.primaryColor : null,
                          ),
                          title: const Text('All Quizzes'),
                          trailing: _currentFilter == FilterOption.all ? Icon(Icons.check, color: themeProvider.primaryColor) : null,
                          onTap: () {
                            _changeFilter(FilterOption.all);
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.favorite,
                            color: _currentFilter == FilterOption.favorites ? Colors.red : null,
                          ),
                          title: const Text('Favorites'),
                          trailing: _currentFilter == FilterOption.favorites ? const Icon(Icons.check, color: Colors.red) : null,
                          onTap: () {
                            _changeFilter(FilterOption.favorites);
                            Navigator.pop(context);
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Text(
                            'Difficulty',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.circle,
                            color: _currentFilter == FilterOption.easy ? Colors.green : Colors.green.withOpacity(0.5),
                            size: 16,
                          ),
                          title: const Text('Easy'),
                          trailing: _currentFilter == FilterOption.easy ? const Icon(Icons.check, color: Colors.green) : null,
                          onTap: () {
                            _changeFilter(FilterOption.easy);
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.circle,
                            color: _currentFilter == FilterOption.medium ? Colors.orange : Colors.orange.withOpacity(0.5),
                            size: 16,
                          ),
                          title: const Text('Medium'),
                          trailing: _currentFilter == FilterOption.medium ? const Icon(Icons.check, color: Colors.orange) : null,
                          onTap: () {
                            _changeFilter(FilterOption.medium);
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.circle,
                            color: _currentFilter == FilterOption.hard ? Colors.red : Colors.red.withOpacity(0.5),
                            size: 16,
                          ),
                          title: const Text('Hard'),
                          trailing: _currentFilter == FilterOption.hard ? const Icon(Icons.check, color: Colors.red) : null,
                          onTap: () {
                            _changeFilter(FilterOption.hard);
                            Navigator.pop(context);
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Text(
                            'Categories',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 48,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final isSelected = _selectedCategory == category && _currentFilter == FilterOption.category;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: FilterChip(
                                  avatar: Icon(
                                    _getCategoryIcon(category),
                                    size: 18,
                                    color: isSelected ? Colors.white : null,
                                  ),
                                  label: Text(category),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    Navigator.pop(context);
                                    _filterByCategory(selected ? category : 'All Categories');
                                  },
                                  backgroundColor: Colors.grey.shade200,
                                  selectedColor: themeProvider.primaryColor,
                                  checkmarkColor: Colors.white,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quizzes.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    if (_filteredQuizzes.isEmpty && _quizzes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _currentFilter == FilterOption.favorites
                          ? 'No favorite quizzes yet'
                          : 'No quizzes match your search',
                          style: const TextStyle(fontSize: 16),
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
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 6,
                                      color: _getDifficultyColor(quiz.difficulty),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  quiz.title,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  quiz.isFavorite
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  color: quiz.isFavorite ? Colors.red : Colors.grey,
                                                ),
                                                onPressed: () => _toggleFavorite(quiz),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.more_vert),
                                                onPressed: () => _showQuizOptions(quiz),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            quiz.description,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: _getDifficultyColor(quiz.difficulty).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: _getDifficultyColor(quiz.difficulty).withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.circle,
                                                      size: 8,
                                                      color: _getDifficultyColor(quiz.difficulty),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      quiz.difficulty.name,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: _getDifficultyColor(quiz.difficulty),
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.grey.shade300,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      _getCategoryIcon(quiz.category),
                                                      size: 12,
                                                      color: Colors.grey.shade700,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      quiz.category,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey.shade700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Spacer(),
                                              ElevatedButton.icon(
                                                icon: const Icon(Icons.play_arrow, size: 16),
                                                label: const Text('Play'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: themeProvider.primaryColor,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  minimumSize: const Size(80, 30),
                                                  textStyle: const TextStyle(fontSize: 12),
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => QuizScreen(quizId: quiz.id!),
                                                    ),
                                                  ).then((_) => _loadQuizzes());
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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

  IconData _getFilterIcon() {
    switch (_currentFilter) {
      case FilterOption.favorites:
        return Icons.favorite;
      case FilterOption.easy:
        return Icons.circle;
      case FilterOption.medium:
        return Icons.circle;
      case FilterOption.hard:
        return Icons.circle;
      case FilterOption.all:
      default:
        return Icons.filter_list;
    }
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _currentFilter = category == 'All Categories' ? FilterOption.all : FilterOption.category;
      _filterQuizzes();
    });
  }

  void _showCategoryOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            ListTile(
              title: const Text('Filter by Category', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  return ListTile(
                    leading: Icon(
                      _getCategoryIcon(category),
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                    ),
                    title: Text(
                      category,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Theme.of(context).primaryColor : null,
                      ),
                    ),
                    trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
                    onTap: () {
                      Navigator.pop(context);
                      _filterByCategory(category);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getCategoryIcon(String category) {
    if (category == 'All Categories') {
      return Icons.category;
    }
    
    switch (category) {
      case 'Technology':
        return Icons.computer;
      case 'Science':
        return Icons.science;
      case 'Mathematics':
        return Icons.calculate;
      case 'History':
        return Icons.history_edu;
      case 'Geography':
        return Icons.public;
      case 'Sports':
        return Icons.sports;
      case 'Entertainment':
        return Icons.theater_comedy;
      case 'Arts':
        return Icons.palette;
      case 'Literature':
        return Icons.book;
      case 'Music':
        return Icons.music_note;
      case 'Movies':
        return Icons.movie;
      case 'Television':
        return Icons.tv;
      case 'Food':
        return Icons.restaurant;
      case 'Language':
        return Icons.translate;
      case 'Other':
        return Icons.category;
      case 'General':
      default:
        return Icons.quiz;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.quiz, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Welcome, ${_authService.currentUser?.username ?? "User"}!',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No quizzes yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first quiz by tapping the + button below',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
} 