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
    final quizzesMap = await _databaseHelper.getQuizzes();
    setState(() {
      _quizzes = quizzesMap.map((map) => Quiz.fromMap(map)).toList();
      
      // Extract unique categories from quizzes
      final uniqueCategories = _quizzes.map((q) => q.category).toSet().toList();
      uniqueCategories.sort(); // Sort alphabetically
      _categories = ['All Categories', ...uniqueCategories];
      
      _filterQuizzes();
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
            icon: const Icon(Icons.sort),
            tooltip: 'Sort quizzes',
            onPressed: _quizzes.isNotEmpty ? _showSortOptions : null,
          ),
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Filter by category',
            onPressed: _quizzes.isNotEmpty ? _showCategoryOptions : null,
          ),
          PopupMenuButton<FilterOption>(
            tooltip: 'Filter quizzes',
            icon: Icon(_getFilterIcon()),
            onSelected: _changeFilter,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: FilterOption.all,
                child: Row(
                  children: [
                    Icon(
                      Icons.list,
                      color: _currentFilter == FilterOption.all 
                          ? themeProvider.primaryColor
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('All Quizzes'),
                    if (_currentFilter == FilterOption.all)
                      Icon(Icons.check, color: themeProvider.primaryColor),
                  ],
                ),
              ),
              PopupMenuItem(
                value: FilterOption.favorites,
                child: Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      color: _currentFilter == FilterOption.favorites 
                          ? Colors.red
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Favorites'),
                    if (_currentFilter == FilterOption.favorites)
                      const Icon(Icons.check, color: Colors.red),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                enabled: false,
                child: Text('Difficulty'),
              ),
              PopupMenuItem(
                value: FilterOption.easy,
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: _currentFilter == FilterOption.easy 
                          ? Colors.green
                          : Colors.green.withOpacity(0.5),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text('Easy'),
                    if (_currentFilter == FilterOption.easy)
                      const Icon(Icons.check, color: Colors.green),
                  ],
                ),
              ),
              PopupMenuItem(
                value: FilterOption.medium,
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: _currentFilter == FilterOption.medium 
                          ? Colors.orange
                          : Colors.orange.withOpacity(0.5),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text('Medium'),
                    if (_currentFilter == FilterOption.medium)
                      const Icon(Icons.check, color: Colors.orange),
                  ],
                ),
              ),
              PopupMenuItem(
                value: FilterOption.hard,
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: _currentFilter == FilterOption.hard 
                          ? Colors.red
                          : Colors.red.withOpacity(0.5),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text('Hard'),
                    if (_currentFilter == FilterOption.hard)
                      const Icon(Icons.check, color: Colors.red),
                  ],
                ),
              ),
            ],
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
                              child: ListTile(
                                leading: quiz.isFavorite
                                    ? const Icon(Icons.favorite, color: Colors.red)
                                    : null,
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        quiz.title,
                                        style: const TextStyle(
                                            fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getDifficultyColor(quiz.difficulty),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        quiz.difficulty.name,
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(quiz.description),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getCategoryIcon(quiz.category),
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          quiz.category,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        quiz.isFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: quiz.isFavorite ? Colors.red : null,
                                      ),
                                      onPressed: () => _toggleFavorite(quiz),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.more_vert),
                                      onPressed: () => _showQuizOptions(quiz),
                                    ),
                                  ],
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
} 