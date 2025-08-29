import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:todo_list/models/todo_item.dart';
import 'package:todo_list/pages/add_task_page.dart';
import 'package:todo_list/ai_assistant.dart';
import 'package:fl_chart/fl_chart.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<TodoItem> activeTodos = [];
  List<TodoItem> completedTodos = [];
  bool _isDarkTheme = true;
  bool _notificationsEnabled = true;
  int _selectedIndex = 0;
  Color textColor = Colors.white;
  final String apiUrl = 'http://192.168.0.102:8000';

  @override
  void initState() {
    super.initState();
    _updateTextColor();
    fetchTodos();
  }

  void _updateTextColor() {
    setState(() {
      textColor = _isDarkTheme ? Colors.white : Colors.black87;
    });
  }

  Future<void> fetchTodos() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/todos/'));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          activeTodos = data
              .where((json) => !json['completed'])
              .map((json) => TodoItem.fromJson(json))
              .toList();
          completedTodos = data
              .where((json) => json['completed'])
              .map((json) => TodoItem.fromJson(json))
              .toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось загрузить задачи')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'января';
      case 2: return 'февраля';
      case 3: return 'марта';
      case 4: return 'апреля';
      case 5: return 'мая';
      case 6: return 'июня';
      case 7: return 'июля';
      case 8: return 'августа';
      case 9: return 'сентября';
      case 10: return 'октября';
      case 11: return 'ноября';
      case 12: return 'декабря';
      default: return '';
    }
  }

  double _calculateProductivity() {
    final totalTasks = activeTodos.length + completedTodos.length;
    if (totalTasks == 0) return 0.0;
    return (completedTodos.length / totalTasks) * 100;
  }

  // Основные функции
  void _addNewTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskPage(isDarkTheme: _isDarkTheme),
      ),
    );
    if (result != null && result is TodoItem) {
      try {
        final response = await http.post(
          Uri.parse('$apiUrl/todos/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': result.title,
            'time': result.time,
            'completed': false,
          }),
        );
        if (response.statusCode == 200) {
          fetchTodos();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Не удалось добавить задачу: ${response.statusCode}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  void _editTask(int index, {bool isArchivedTask = false}) async {
    if ((isArchivedTask && completedTodos.isEmpty) || (!isArchivedTask && activeTodos.isEmpty)) {
      return;
    }
    final taskToEdit = isArchivedTask ? completedTodos[index] : activeTodos[index];
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskPage(
          initialTask: taskToEdit,
          isDarkTheme: _isDarkTheme,
        ),
      ),
    );
    if (result != null && result is TodoItem) {
      try {
        final response = await http.put(
          Uri.parse('$apiUrl/todos/${result.id}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': result.title,
            'time': result.time,
            'completed': result.isCompleted,
          }),
        );
        if (response.statusCode == 200) {
          fetchTodos();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Не удалось обновить задачу: ${response.statusCode}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  void _deleteTask(int index, bool isArchived) async {
    if ((isArchived && completedTodos.isEmpty) || (!isArchived && activeTodos.isEmpty)) {
      return;
    }
    final task = isArchived ? completedTodos[index] : activeTodos[index];
    try {
      final response = await http.delete(Uri.parse('$apiUrl/todos/${task.id}'));
      if (response.statusCode == 200) {
        setState(() {
          if (isArchived) {
            completedTodos.removeAt(index);
          } else {
            activeTodos.removeAt(index);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Задача "${task.title}" удалена', style: TextStyle(color: textColor)),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось удалить задачу')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  void _toggleTaskStatus(int index) async {
    if (activeTodos.isEmpty) return;
    final task = activeTodos[index];
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/todos/${task.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': task.title,
          'time': task.time,
          'completed': true,
        }),
      );
      if (response.statusCode == 200) {
        fetchTodos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось обновить задачу: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  void _restoreTask(int index) async {
    if (completedTodos.isEmpty) return;
    final task = completedTodos[index];
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/todos/${task.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': task.title,
          'time': task.time,
          'completed': false,
        }),
      );
      if (response.statusCode == 200) {
        fetchTodos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось восстановить задачу')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  void _resetTasks() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/todos'));
      if (response.statusCode == 200) {
        List<dynamic> todos = jsonDecode(response.body);
        for (var todo in todos) {
          await http.delete(Uri.parse('$apiUrl/todos/${todo['id']}'));
        }
        setState(() {
          activeTodos.clear();
          completedTodos.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Все задачи удалены', style: TextStyle(color: textColor)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  //Навигация
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 2) {
      _addNewTask();
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AiAssistantPage(
            activeTodos: activeTodos,
            completedTodos: completedTodos,
            isDarkTheme: _isDarkTheme,
          ),
        ),
      );
    }
  }


  // Настройки
  void _toggleTheme(bool value) {
    setState(() {
      _isDarkTheme = value;
      _updateTextColor();
    });
  }

  void _toggleNotifications(bool value) {
    setState(() {
      _notificationsEnabled = value;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_notificationsEnabled ? 'Уведомления включены' : 'Уведомления выключены',
            style: TextStyle(color: textColor)),
        backgroundColor: Colors.blueGrey[600],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final productivity = _calculateProductivity();
    final screenWidth = MediaQuery.of(context).size.width;

    return MaterialApp(
      theme: _isDarkTheme
          ? ThemeData.dark().copyWith(
        primaryColor: Colors.blueGrey[800],
        scaffoldBackgroundColor: Colors.blueGrey[900],
        appBarTheme: const AppBarTheme(
          color: Colors.transparent,
          elevation: 0,
        ),
      )
          : ThemeData.light().copyWith(
        primaryColor: Colors.blueGrey[200],
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          color: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: Builder(
        builder: (innerContext) => Scaffold(
          key: _scaffoldKey,
          backgroundColor: _isDarkTheme ? Colors.blueGrey[900] : Colors.grey[100],
          appBar: AppBar(
            iconTheme: IconThemeData(color: textColor),
            automaticallyImplyLeading: true,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isDarkTheme
                      ? [Colors.blueGrey[800]!, Colors.blueGrey[600]!]
                      : [Colors.blueGrey[300]!, Colors.blueGrey[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            title: Text(
              'Список задач',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
                color: textColor,
              ),
            ),
            centerTitle: true,
            elevation: 0,
          ),
          drawer: MyDrawer(
            activeTodos: activeTodos,
            completedTodos: completedTodos,
            isDarkTheme: _isDarkTheme,
            notificationsEnabled: _notificationsEnabled,
            onThemeChanged: _toggleTheme,
            onNotificationsChanged: _toggleNotifications,
            onResetTasks: _resetTasks,
          ),
          body: _buildBody(innerContext),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: _isDarkTheme ? Colors.blueGrey[800] : Colors.blueGrey[200],
            selectedItemColor: textColor,
            unselectedItemColor: _isDarkTheme ? Colors.white70 : Colors.grey[600],
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.checklist_rtl_outlined),
                label: 'Активные',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.archive_outlined),
                label: 'Архив',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.add),
                label: 'Добавить',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.trending_up),
                label: 'Продуктивность',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.assistant),
                label: 'ИИ Ассистент',
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildBodyContent(screenWidth, context),
    );
  }

  Widget _buildBodyContent(double screenWidth, BuildContext context) {
    switch (_selectedIndex) {
      case 0:
        return _buildActiveTasksView(screenWidth, context);
      case 1:
        return _buildCompletedTasksView(screenWidth, context);
      case 3:
        return _buildProductivityView(screenWidth);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActiveTasksView(double screenWidth, BuildContext context) {
    return Column(
      key: ValueKey('activeTasks_${activeTodos.length}'),
      children: [
        Card(
          color: _isDarkTheme ? Colors.blueGrey[800] : Colors.blueGrey[100],
          elevation: 6.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.0)),
          ),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Сегодня, ${DateTime.now().day} ${_getMonthName(DateTime.now().month)}',
                          style: TextStyle(
                            color: _isDarkTheme ? Colors.grey[300] : Colors.grey[700],
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.trending_up, color: Colors.green, size: screenWidth * 0.04),
                            const SizedBox(width: 8),
                            Text(
                              'Продуктивность: ${_calculateProductivity().toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: textColor,
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(
                      width: screenWidth * 0.3,
                      height: screenWidth * 0.3,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              color: Colors.green,
                              value: completedTodos.length.toDouble(),
                              title: '',
                              radius: screenWidth * 0.1,
                              borderSide: BorderSide(color: _isDarkTheme ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2)),
                            ),
                            PieChartSectionData(
                              color: Colors.orange,
                              value: activeTodos.length.toDouble(),
                              title: '',
                              radius: screenWidth * 0.1,
                              borderSide: BorderSide(color: _isDarkTheme ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2)),
                            ),
                          ],
                          sectionsSpace: 2,
                          centerSpaceRadius: screenWidth * 0.06,
                          centerSpaceColor: _isDarkTheme ? Colors.blueGrey[900] : Colors.grey[300],
                        ),
                        swapAnimationDuration: const Duration(milliseconds: 150),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: _isDarkTheme ? Colors.grey[700] : Colors.grey[400], thickness: 1.0),
                const SizedBox(height: 12),
                Text(
                  'Активные задачи',
                  style: TextStyle(
                    color: textColor,
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: activeTodos.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Нет активных задач.\nНажмите "+", чтобы добавить новую.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 18, fontFamily: 'Roboto'),
              ),
            ),
          )
              : ListView.builder(
            key: ValueKey('activeList_${activeTodos.length}'),
            padding: const EdgeInsets.only(bottom: 80.0, left: 12.0, right: 12.0, top: 8.0),
            itemCount: activeTodos.length,
            itemBuilder: (context, index) {
              return _buildTaskItem(activeTodos[index], index, false, context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedTasksView(double screenWidth, BuildContext context) {
    return Column(
      key: ValueKey('completedTasks_${completedTodos.length}'),
      children: [
        Card(
          color: _isDarkTheme ? Colors.blueGrey[800] : Colors.blueGrey[100],
          elevation: 6.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.0)),
          ),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Выполненные задачи',
                  style: TextStyle(
                    color: textColor,
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: completedTodos.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Архив задач пуст.',
                style: TextStyle(color: Colors.white70, fontSize: 18, fontFamily: 'Roboto'),
              ),
            ),
          )
              : ListView.builder(
            key: ValueKey('completedList_${completedTodos.length}'),
            padding: const EdgeInsets.only(bottom: 80.0, left: 12.0, right: 12.0, top: 8.0),
            itemCount: completedTodos.length,
            itemBuilder: (context, index) {
              return _buildTaskItem(completedTodos[index], index, true, context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductivityView(double screenWidth) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Продуктивность',
            style: TextStyle(
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.bold,
              color: textColor,
              fontFamily: 'Roboto',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: screenWidth * 0.7,
            height: screenWidth * 0.7,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    color: Colors.green,
                    value: completedTodos.length > 0 ? completedTodos.length.toDouble() : 0.1,
                    title: 'Завершено\n${_calculateProductivity().toStringAsFixed(0)}%',
                    titleStyle: TextStyle(color: textColor, fontSize: 12),
                    radius: 80,
                  ),
                  PieChartSectionData(
                    color: Colors.orange,
                    value: activeTodos.length > 0 ? activeTodos.length.toDouble() : 0.1,
                    title: 'Активно\n${((100 - _calculateProductivity()).toStringAsFixed(0))}%',
                    titleStyle: TextStyle(color: textColor, fontSize: 12),
                    radius: 80,
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                centerSpaceColor: _isDarkTheme ? Colors.blueGrey[900] : Colors.grey[300],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(TodoItem task, int index, bool isArchived, BuildContext context) {
    return Card(
      color: isArchived ? (_isDarkTheme ? Colors.grey[700] : Colors.grey[300]) : (_isDarkTheme ? Colors.white30 : Colors.grey[200]),
      elevation: 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        key: ValueKey('${task.id}_$index'),
        leading: isArchived
            ? IconButton(
          icon: const Icon(Icons.restore, color: Colors.green, size: 28),
          tooltip: 'Восстановить',
          onPressed: () => _restoreTask(index),
        )
            : Checkbox(
          value: task.isCompleted,
          onChanged: (value) => _toggleTaskStatus(index),
          activeColor: Colors.blueAccent,
          checkColor: Colors.white,
          side: BorderSide(color: _isDarkTheme ? Colors.white70 : Colors.black54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            decorationColor: _isDarkTheme ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
            decorationThickness: 1.5,
            fontFamily: 'Roboto',
          ),
        ),
        subtitle: (task.time.isNotEmpty && task.time != 'Выберите время')
            ? Text(
          task.time,
          style: TextStyle(color: _isDarkTheme ? Colors.grey[400] : Colors.grey[600], fontSize: 14, fontFamily: 'Roboto'),
        )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_note_outlined, color: _isDarkTheme ? Colors.white.withOpacity(0.85) : Colors.black87),
              tooltip: 'Редактировать',
              onPressed: () => _editTask(index, isArchivedTask: isArchived),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              tooltip: 'Удалить',
              onPressed: () => _deleteTask(index, isArchived),
            ),
          ],
        ),
        onTap: () {
          if (!isArchived) {
            _editTask(index, isArchivedTask: false);
          }
        },
      ),
    );
  }
}

class MyDrawer extends StatelessWidget {
  final List<TodoItem> activeTodos;
  final List<TodoItem> completedTodos;
  final bool isDarkTheme;
  final bool notificationsEnabled;
  final Function(bool) onThemeChanged;
  final Function(bool) onNotificationsChanged;
  final VoidCallback onResetTasks;

  const MyDrawer({
    super.key,
    required this.activeTodos,
    required this.completedTodos,
    required this.isDarkTheme,
    required this.notificationsEnabled,
    required this.onThemeChanged,
    required this.onNotificationsChanged,
    required this.onResetTasks,
  });

  @override
  Widget build(BuildContext context) {
    const TextStyle drawerTextStyle = TextStyle(fontSize: 16, fontFamily: 'Roboto');
    const Color drawerIconColor = Colors.white70;

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkTheme
                ? [Colors.blueGrey[800]!, Colors.blueGrey[600]!]
                : [Colors.blueGrey[200]!, Colors.blueGrey[100]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkTheme
                      ? [Colors.blueGrey[900]!, Colors.blueGrey[700]!]
                      : [Colors.blueGrey[300]!, Colors.blueGrey[100]!],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Список задач',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkTheme ? Colors.white : Colors.black87,
                      fontSize: 24,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Управляйте своими задачами',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.white70 : Colors.grey[700],
                      fontSize: 14,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            ListTile(
              leading: Icon(Icons.settings_outlined, color: isDarkTheme ? drawerIconColor : Colors.black54, size: 24),
              title: Text('Настройки', style: drawerTextStyle.copyWith(color: isDarkTheme ? Colors.white : Colors.black87)),
              onTap: () {
                Navigator.pop(context);
                _showSettingsDialog(context);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            ListTile(
              leading: Icon(Icons.info_outline, color: isDarkTheme ? drawerIconColor : Colors.black54, size: 24),
              title: Text('О программе', style: drawerTextStyle.copyWith(color: isDarkTheme ? Colors.white : Colors.black87)),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'Список задач',
                  applicationVersion: '1.0.1',
                  applicationIcon: const Icon(Icons.done_all, size: 48, color: Color.fromRGBO(0, 0, 0, 0.1)),
                  applicationLegalese: '© ${DateTime.now().year} Galim',
                  children: const <Widget>[
                    Padding(
                      padding: EdgeInsets.only(top: 15),
                      child: Text('Простое приложение для управления задачами.'),
                    )
                  ],
                );
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Настройки', style: TextStyle(fontFamily: 'Roboto', fontSize: 20, fontWeight: FontWeight.bold, color: isDarkTheme ? Colors.white : Colors.black87)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_6, color: Colors.blueGrey),
                title: Text('Темная тема', style: TextStyle(fontFamily: 'Roboto', color: isDarkTheme ? Colors.white : Colors.black87)),
                trailing: Switch(
                  value: isDarkTheme,
                  onChanged: onThemeChanged,
                  activeColor: Colors.blueGrey[600],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.notifications, color: Colors.blueGrey),
                title: Text('Уведомления', style: TextStyle(fontFamily: 'Roboto', color: isDarkTheme ? Colors.white : Colors.black87)),
                trailing: Switch(
                  value: notificationsEnabled,
                  onChanged: onNotificationsChanged,
                  activeColor: Colors.blueGrey[600],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                title: Text('Сбросить все задачи', style: TextStyle(fontFamily: 'Roboto', color: isDarkTheme ? Colors.white : Colors.black87)),
                trailing: ElevatedButton(
                  onPressed: onResetTasks,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  child: Text('Сброс', style: TextStyle(color: Colors.white, fontFamily: 'Roboto')),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Закрыть', style: TextStyle(fontFamily: 'Roboto', color: isDarkTheme ? Colors.white : Colors.black87)),
          ),
        ],
        backgroundColor: isDarkTheme ? Colors.blueGrey[800] : Colors.white,
      ),
    );
  }
}