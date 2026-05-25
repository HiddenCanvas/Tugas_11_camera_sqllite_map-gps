import 'package:flutter/material.dart';
import 'todo_db_helper.dart';
import 'todo_model.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  List<Todo> _todos = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshTodos();
  }

  Future<void> _refreshTodos() async {
    final data = await TodoDbHelper.instance.readAllTodos();
    setState(() {
      _todos = data;
    });
  }

  Future<void> _addTodo() async {
    if (_controller.text.isNotEmpty) {
      final newTodo = Todo(title: _controller.text);
      await TodoDbHelper.instance.insert(newTodo);
      _controller.clear();
      _refreshTodos();
    }
  }

  Future<void> _toggleTodo(Todo todo) async {
    final updatedTodo = todo.copyWith(isDone: !todo.isDone);
    await TodoDbHelper.instance.update(updatedTodo);
    _refreshTodos();
  }

  Future<void> _deleteTodo(int id) async {
    await TodoDbHelper.instance.delete(id);
    _refreshTodos();
  }

  @override
  Widget build(BuildContext context) {
    final isMock = !TodoDbHelper.instance.isSQLiteSupported;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SQLite To-Do'),
      ),
      body: Column(
        children: [
          if (isMock)
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Menjalankan di Web Browser (Chrome/Edge). SQLite dialihkan ke penyimpanan memori sementara (Mock DB). Untuk penyimpanan permanen, jalankan di Windows Desktop (Opsi 1) atau HP/Emulator Android.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Tambah Tugas Baru',
                    ),
                    onSubmitted: (_) => _addTodo(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTodo,
                ),
              ],
            ),
          ),
          Expanded(
            child: _todos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.checklist, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada tugas. Silakan tambah baru!',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _todos.length,
                    itemBuilder: (context, index) {
                      final todo = _todos[index];
                      return ListTile(
                        leading: Checkbox(
                          value: todo.isDone,
                          onChanged: (_) => _toggleTodo(todo),
                          activeColor: Colors.blue,
                        ),
                        title: Text(
                          todo.title,
                          style: TextStyle(
                            decoration: todo.isDone ? TextDecoration.lineThrough : null,
                            color: todo.isDone ? Colors.grey : Colors.black87,
                            fontWeight: todo.isDone ? FontWeight.normal : FontWeight.w500,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () {
                            if (todo.id != null) {
                              _deleteTodo(todo.id!);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

