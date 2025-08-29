import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:todo_list/models/todo_item.dart';

// Константы для нашего сервера
const String serverBaseUrl = "http://192.168.0.102:8000"; // или ваш IP адрес
const String sendMessageUrl = "$serverBaseUrl/ai/send_message";

class ApiService {
  static Future<List<String>> sendMessage(
      String userId,
      String message,
      List<String> activeTodos,
      List<String> completedTodos,
      ) async {
    try {
      final response = await http.post(
        Uri.parse(sendMessageUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "message": message,
          "active_todos": activeTodos,
          "completed_todos": completedTodos,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['parts']);
      } else {
        developer.log('Ошибка сервера: ${response.statusCode} - ${response.body}');
        return ['Ошибка: Сервер вернул статус ${response.statusCode}'];
      }
    } catch (e) {
      developer.log('Исключение при отправке сообщения: $e');
      return ['Ошибка: Не удалось подключиться к серверу'];
    }
  }
}

class AiAssistantPage extends StatefulWidget {
  final List<TodoItem> activeTodos;
  final List<TodoItem> completedTodos;
  final bool isDarkTheme;

  const AiAssistantPage({
    Key? key,
    required this.activeTodos,
    required this.completedTodos,
    required this.isDarkTheme,
  }) : super(key: key);

  @override
  _AiAssistantPageState createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];
  bool _isLoading = false;
  final String _userId = 'user1';
  String _thinkingDots = '';
  Timer? _thinkingTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _thinkingTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startThinkingAnimation() {
    _thinkingDots = '';
    _thinkingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _thinkingDots = _thinkingDots.length < 3 ? _thinkingDots + '.' : '';
      });
    });
  }

  void _stopThinkingAnimation() {
    _thinkingTimer?.cancel();
    setState(() {
      _thinkingDots = '';
    });
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    final message = _controller.text;
    setState(() {
      _messages.add('Вы: $message');
      _isLoading = true;
      _startThinkingAnimation();
    });
    _controller.clear();

    // Отправляем сообщение на сервер
    final responseParts = await ApiService.sendMessage(
      _userId,
      message,
      widget.activeTodos.map((t) => t.title).toList(),
      widget.completedTodos.map((t) => t.title).toList(),
    );

    setState(() {
      for (var part in responseParts) {
        _messages.add('ИИ: $part');
      }
      _isLoading = false;
      _stopThinkingAnimation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkTheme ? Colors.blueGrey[900] : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: widget.isDarkTheme ? Colors.blueGrey[800] : Colors.blueGrey[200],
        title: const Text(
          'ИИ Ассистент',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
        ),
        iconTheme: IconThemeData(color: widget.isDarkTheme ? Colors.white : Colors.black87),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isCode = message.contains('```');
                final isUser = message.startsWith('Вы:');

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: isUser
                        ? (widget.isDarkTheme ? Colors.blueAccent.withOpacity(0.3) : Colors.blue[100])
                        : (widget.isDarkTheme ? Colors.grey[700] : Colors.grey[200]),
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isCode
                      ? SelectableText(
                    message.replaceFirst(isUser ? 'Вы: ' : 'ИИ: ', ''),
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 14,
                      color: widget.isDarkTheme ? Colors.white : Colors.black87,
                    ),
                  )
                      : SelectableText(
                    message.replaceFirst(isUser ? 'Вы: ' : 'ИИ: ', ''),
                    style: TextStyle(
                      fontSize: 16,
                      color: widget.isDarkTheme ? Colors.white : Colors.black87,
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: widget.isDarkTheme ? Colors.grey[700] : Colors.blueGrey[200],
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Text(
                  'ИИ думает$_thinkingDots',
                  style: TextStyle(
                    fontSize: 16,
                    color: widget.isDarkTheme ? Colors.white : Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          if (_isLoading)
            LinearProgressIndicator(
              color: widget.isDarkTheme ? Colors.white : Colors.blueGrey[600],
              backgroundColor: widget.isDarkTheme ? Colors.white24 : Colors.grey[300],
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Задайте вопрос ИИ...',
                      hintStyle: TextStyle(color: widget.isDarkTheme ? Colors.white70 : Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      filled: true,
                      fillColor: widget.isDarkTheme ? Colors.white24 : Colors.grey[200],
                    ),
                    style: TextStyle(color: widget.isDarkTheme ? Colors.white : Colors.black87),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: widget.isDarkTheme ? Colors.white : Colors.blueGrey[800]),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}