import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz Master',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const CategorySelectionPage(),
    );
  }
}

class Question {
  final String question;
  final String correctAnswer;
  final List<String> allAnswers;

  Question({
    required this.question,
    required this.correctAnswer,
    required this.allAnswers,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    final incorrect = List<String>.from(map['incorrect_answers']);
    final correct = map['correct_answer'];
    final all = [...incorrect, correct]..shuffle();

    return Question(
      question: HtmlUnescape().convert(map['question']),
      correctAnswer: correct,
      allAnswers: all.map((a) => HtmlUnescape().convert(a)).toList(),
    );
  }
}

class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
    );
  }
}

class QuizService {
  static Future<List<Category>> fetchCategories() async {
    final url = Uri.parse('https://opentdb.com/api_category.php');
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['trivia_categories'] as List)
          .map((cat) => Category.fromMap(cat))
          .toList();
    } else {
      throw Exception('Failed to load categories\n Please try again later or check your internet.');
    }
  }

  static Future<List<Question>> fetchQuestions(
      int amount, int categoryId) async {
    final url = Uri.parse(
        'https://opentdb.com/api.php?amount=$amount&category=$categoryId&type=multiple');
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['results'] as List)
          .map((q) => Question.fromMap(q))
          .toList();
    } else {
      throw Exception('Failed to load questions');
    }
  }
}

class CategorySelectionPage extends StatefulWidget {
  const CategorySelectionPage({super.key});

  @override
  State<CategorySelectionPage> createState() => _CategorySelectionPageState();
}

class _CategorySelectionPageState extends State<CategorySelectionPage> {
  List<Category> _categories = [];
  bool _isLoading = true;
  int? _selectedCategoryId;
  int _questionCount = 5;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() async {
    try {
      final categories = await QuizService.fetchCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Failed to load categories.\n Please try again later or check your internet.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
    builder: (ctx) => AlertDialog(
            title: const Text('Error⚠️', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(color: Color(0xFF2E7D32))),
              ),
            ],
          ),
        );
  }

  void _startQuiz() {
    if (_selectedCategoryId == null) {
      _showErrorDialog('Please select a category');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => QuizPage(
          categoryId: _selectedCategoryId!,
          questionCount: _questionCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trivia Quiz Pro',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Select Category:',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32)),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _categories.length,
                        itemBuilder: (ctx, index) => Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            title: Text(_categories[index].name,
                                style: const TextStyle(fontWeight: FontWeight.w500)),
                            tileColor: _selectedCategoryId == _categories[index].id
                                ? const Color(0xFFC8E6C9)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            onTap: () => setState(
                                () => _selectedCategoryId = _categories[index].id),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Number of Questions:',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32)),
                    ),
                    Slider(
                      value: _questionCount.toDouble(),
                      min: 3,
                      max: 20,
                      divisions: 17,
                      label: _questionCount.toString(),
                      activeColor: const Color(0xFF2E7D32),
                      inactiveColor: const Color(0xFF81C784),
                      onChanged: (value) =>
                          setState(() => _questionCount = value.toInt()),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _startQuiz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Start Quiz',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class QuizPage extends StatefulWidget {
  final int categoryId;
  final int questionCount;

  const QuizPage({
    super.key,
    required this.categoryId,
    required this.questionCount,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late List<Question> _questions;
  int _currentIndex = 0;
  String? _selectedAnswer;
  bool _isLoading = true;
  int _score = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _loadQuestions() async {
    try {
      final questions = await QuizService.fetchQuestions(
          widget.questionCount, widget.categoryId);
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Failed to load questions. Please try again later.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Color(0xFF2E7D32))),
          ),
        ],
      ),
    );
  }

  Future<void> _playSound(String sound) async {
    try {
      await _audioPlayer.play(AssetSource('sounds/$sound.mp3'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  void _checkAnswer(String answer) async {
    setState(() => _selectedAnswer = answer);

    final isCorrect = answer == _questions[_currentIndex].correctAnswer;
    if (isCorrect) {
      await _playSound('correct');
      setState(() => _score++);
    } else {
      await _playSound('wrong');
    }

    await Future.delayed(const Duration(milliseconds: 1000));

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
      });
    } else {
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    final percentage = (_score / widget.questionCount) * 100;
    String message;
    String emoji;
    Color color;

    if (percentage >= 80) {
      message = 'Excellent! You really know your stuff!';
      emoji = '🎉';
      color = const Color(0xFF4CAF50);
    } else if (percentage >= 60) {
      message = 'Good job! Keep learning!';
      emoji = '👍';
      color = const Color(0xFF66BB6A);
    } else if (percentage >= 40) {
      message = 'Not bad! Try again to improve!';
      emoji = '😊';
      color = const Color(0xFF81C784);
    } else {
      message = 'Nice try! Keep practicing!';
      emoji = '💪';
      color = const Color(0xFFEF5350);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text('Quiz Completed $emoji',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You scored $_score out of ${widget.questionCount}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text(message,
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.popUntil(ctx, (route) => route.isFirst);
            },
            child: const Text('Back to Categories',
                style: TextStyle(color: Color(0xFF2E7D32))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _currentIndex = 0;
                _selectedAnswer = null;
                _score = 0;
              });
            },
            child: const Text('Try Again',
                style: TextStyle(color: Color(0xFF2E7D32))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Question ${_currentIndex + 1}/${widget.questionCount} | Score: $_score',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_currentIndex + 1) / widget.questionCount,
                        backgroundColor: Colors.grey[300],
                        color: const Color(0xFF2E7D32),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          _questions[_currentIndex].question,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Expanded(
                      child: ListView(
                        children: _questions[_currentIndex]
                            .allAnswers
                            .map((answer) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: AnswerButton(
                                    answer: answer,
                                    isSelected: _selectedAnswer == answer,
                                    isCorrect: answer ==
                                        _questions[_currentIndex].correctAnswer,
                                    showCorrect: _selectedAnswer != null,
                                    onPressed: _selectedAnswer == null
                                        ? () => _checkAnswer(answer)
                                        : null,
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class AnswerButton extends StatelessWidget {
  final String answer;
  final bool isSelected;
  final bool isCorrect;
  final bool showCorrect;
  final VoidCallback? onPressed;

  const AnswerButton({
    super.key,
    required this.answer,
    required this.isSelected,
    required this.isCorrect,
    required this.showCorrect,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey.shade300;
    IconData? icon;
    Color iconColor = Colors.transparent;

    if (showCorrect) {
      if (isSelected) {
        backgroundColor = isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFEF5350);
        borderColor = isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
        icon = isCorrect ? Icons.check_circle : Icons.cancel;
        iconColor = Colors.white;
      } else if (isCorrect) {
        backgroundColor = const Color(0xFFC8E6C9);
        borderColor = const Color(0xFF2E7D32);
        icon = Icons.check_circle;
        iconColor = const Color(0xFF2E7D32);
      }
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 2),
        color: backgroundColor,
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: ListTile(
        title: Text(
          answer,
          style: TextStyle(
            fontSize: 18,
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Icon(icon, color: iconColor, size: 28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        onTap: onPressed,
      ),
    );
  }
}