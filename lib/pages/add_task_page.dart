import 'package:flutter/material.dart';
import 'package:todo_list/models/todo_item.dart';

class AddTaskPage extends StatefulWidget {
  final TodoItem? initialTask;
  final bool isDarkTheme;

  const AddTaskPage({super.key, this.initialTask, required this.isDarkTheme});

  @override
  _AddTaskPageState createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  late TextEditingController _controller;
  TimeOfDay? _selectedTime;
  String _timeString = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialTask != null) {
      _controller = TextEditingController(text: widget.initialTask!.title);
      _timeString = widget.initialTask!.time;
      final parts = _timeString.split(':');
      if (parts.length == 2) {
        _selectedTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } else {
      _controller = TextEditingController();
      _selectedTime = TimeOfDay.now();
      _updateTimeString();
    }
  }

  void _updateTimeString() {
    if (_selectedTime != null) {
      final hour = _selectedTime!.hour;
      final minute = _selectedTime!.minute.toString().padLeft(2, '0');
      setState(() {
        _timeString = '$hour:$minute';
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
        _updateTimeString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: widget.isDarkTheme ? Colors.blueGrey[900] : Colors.grey[100],
      appBar: AppBar(
        iconTheme: IconThemeData(color: widget.isDarkTheme ? Colors.white : Colors.black87),
        automaticallyImplyLeading: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.isDarkTheme
                  ? [Colors.blueGrey[800]!, Colors.blueGrey[600]!]
                  : [Colors.blueGrey[300]!, Colors.blueGrey[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          widget.initialTask == null ? 'Добавить задачу' : 'Редактировать задачу',
          style: TextStyle(
            fontSize: 24,
            color: widget.isDarkTheme ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Объединенный виджет для ввода задачи и времени
            Card(
              color: widget.isDarkTheme ? Colors.blueGrey[800] : Colors.blueGrey[100],
              elevation: 6.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Ввод текста задачи
                    TextField(
                      style: TextStyle(
                          color: widget.isDarkTheme ? Colors.white : Colors.black87,
                          fontFamily: 'Roboto'
                      ),
                      controller: _controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Введите задачу',
                        hintStyle: TextStyle(
                            color: widget.isDarkTheme ? Colors.white70 : Colors.grey[600],
                            fontFamily: 'Roboto'
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                      ),
                      maxLines: 3,
                    ),
                    Divider(
                      color: widget.isDarkTheme ? Colors.white24 : Colors.grey[400],
                      thickness: 1.0,
                      height: 24,
                    ),
                    // Выбор времени
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.access_time,
                              color: widget.isDarkTheme ? Colors.white : Colors.black87),
                          onPressed: () => _selectTime(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timeString.isNotEmpty ? _timeString : 'Выберите время',
                          style: TextStyle(
                            color: widget.isDarkTheme ? Colors.white : Colors.black87,
                            fontSize: screenWidth * 0.045,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Добавить или Изменить
            Card(
              color: widget.isDarkTheme ? Colors.blueGrey[800] : Colors.blueGrey[100],
              elevation: 6.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isDarkTheme ? Colors.white : Colors.blueGrey[600],
                    foregroundColor: widget.isDarkTheme ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    final newTask = TodoItem(
                      id: widget.initialTask?.id ?? 0,
                      title: _controller.text,
                      time: _timeString,
                      isCompleted: widget.initialTask?.isCompleted ?? false,
                    );
                    Navigator.pop(context, newTask);
                  },
                  child: Text(
                    widget.initialTask == null ? 'Добавить' : 'Сохранить',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}