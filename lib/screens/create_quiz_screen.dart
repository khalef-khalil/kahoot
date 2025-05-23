import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';
import '../auth_service.dart';

class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController(text: 'General');
  
  final List<Question> _questions = [];
  bool _isLoading = false;
  QuizDifficulty _selectedDifficulty = QuizDifficulty.medium;
  
  // Predefined categories for dropdown
  final List<String> _categories = [
    'General',
    'Technology',
    'Science',
    'Mathematics',
    'History',
    'Geography',
    'Sports',
    'Entertainment',
    'Arts',
    'Literature',
    'Music',
    'Movies',
    'Television',
    'Food',
    'Language',
    'Other'
  ];
  String _selectedCategory = 'General';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<bool> _saveQuiz() async {
    if (_formKey.currentState!.validate() && _questions.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Get the current user ID
        final userId = _authService.currentUser?.id;
        if (userId == null) {
          throw Exception('You must be logged in to create a quiz');
        }
        
        // Create the quiz with user_id
        final quizId = await _databaseHelper.insertQuiz({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'user_id': userId,
          'difficulty': _selectedDifficulty.name,
          'category': _selectedCategory,
        });
        
        // Save questions
        for (var question in _questions) {
          question.quizId = quizId;
          final questionId = await _databaseHelper.insertQuestion(question.toMap());
          
          // Save options for this question
          if (question.options != null) {
            for (var option in question.options!) {
              option.questionId = questionId;
              await _databaseHelper.insertOption(option.toMap());
            }
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quiz saved successfully')),
          );
        }
        
        setState(() {
          _isLoading = false;
        });
        
        return true;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save quiz: $e')),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return false;
      }
    } else if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one question')),
      );
      return false;
    } else {
      return false;
    }
  }

  void _addQuestion() {
    showDialog(
      context: context,
      builder: (context) {
        final questionController = TextEditingController();
        final timeLimitController = TextEditingController(text: '20');
        final List<Option> options = [
          Option(questionId: 0, optionText: '', isCorrect: false),
          Option(questionId: 0, optionText: '', isCorrect: false),
          Option(questionId: 0, optionText: '', isCorrect: false),
          Option(questionId: 0, optionText: '', isCorrect: false),
        ];
        int correctOptionIndex = 0;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Question'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: questionController,
                      decoration: const InputDecoration(
                        labelText: 'Question',
                        hintText: 'Enter the question',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: timeLimitController,
                      decoration: const InputDecoration(
                        labelText: 'Time Limit (seconds)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Options (select the correct one):',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(options.length, (index) {
                      return Row(
                        children: [
                          Radio<int>(
                            value: index,
                            groupValue: correctOptionIndex,
                            onChanged: (value) {
                              setState(() {
                                correctOptionIndex = value!;
                                for (int i = 0; i < options.length; i++) {
                                  options[i].isCorrect = (i == value);
                                }
                              });
                            },
                          ),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: 'Option ${index + 1}',
                                hintText: 'Enter option text',
                              ),
                              onChanged: (value) {
                                options[index].optionText = value;
                              },
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Validate fields
                    if (questionController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please enter a question')),
                      );
                      return;
                    }

                    final timeLimit = int.tryParse(timeLimitController.text);
                    if (timeLimit == null || timeLimit <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please enter a valid time limit')),
                      );
                      return;
                    }

                    bool validOptions = true;
                    for (var option in options) {
                      if (option.optionText.isEmpty) {
                        validOptions = false;
                        break;
                      }
                    }

                    if (!validOptions) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please fill in all options')),
                      );
                      return;
                    }

                    // Create question
                    final question = Question(
                      quizId: 0, // Will be set later when quiz is created
                      question: questionController.text,
                      timeLimit: timeLimit,
                      options: options,
                    );

                    this.setState(() {
                      _questions.add(question);
                    });

                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Quiz'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveQuiz,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  DropdownButtonFormField<QuizDifficulty>(
                    decoration: const InputDecoration(
                      labelText: 'Difficulty',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedDifficulty,
                    items: QuizDifficulty.values.map((difficulty) {
                      return DropdownMenuItem<QuizDifficulty>(
                        value: difficulty,
                        child: Row(
                          children: [
                            Icon(
                              Icons.circle,
                              color: _getDifficultyColor(difficulty),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(difficulty.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDifficulty = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedCategory,
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Row(
                          children: [
                            Icon(
                              _getCategoryIcon(category),
                              color: Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(category),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 24.0),
                  Row(
                    children: [
                      const Text(
                        'Questions',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _addQuestion,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  _questions.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No questions added yet. Tap "Add" to create a question.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _questions.length,
                          itemBuilder: (context, index) {
                            final question = _questions[index];
                            return _buildQuestionItem(question, index);
                          },
                        ),
                ],
              ),
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

  IconData _getCategoryIcon(String category) {
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

  Widget _buildQuestionItem(Question question, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          question.question,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Time: ${question.timeLimit}s | Options: ${question.options!.length}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            setState(() {
              _questions.removeAt(index);
            });
          },
        ),
        onTap: () {
          // Show question details
          _showQuestionDetails(question);
        },
      ),
    );
  }

  void _showQuestionDetails(Question question) {
    showDialog(
      context: context,
      builder: (context) {
        // Find correct option
        final correctOptionIndex = question.options!.indexWhere((o) => o.isCorrect);
        
        return AlertDialog(
          title: const Text('Question Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.question,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Time limit: ${question.timeLimit} seconds'),
                const SizedBox(height: 16),
                const Text(
                  'Options:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...List.generate(question.options!.length, (index) {
                  final option = question.options![index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          option.isCorrect
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: option.isCorrect ? Colors.green : Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(option.optionText),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
} 