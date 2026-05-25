import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'todo_model.dart';

class TodoDbHelper {
  static final TodoDbHelper instance = TodoDbHelper._init();
  static Database? _database;

  // Penyimpanan memori sementara (Mock DB) jika platform tidak mendukung SQLite
  final List<Map<String, dynamic>> _mockDb = [];
  int _mockIdCounter = 1;


  TodoDbHelper._init();

  // Memeriksa apakah SQLite didukung secara native pada platform saat ini
  bool get isSQLiteSupported {
    if (kIsWeb) return false; // Hanya Web yang tidak mendukung SQLite secara native tanpa FFI/WASM khusus
    return true;
  }

  Future<Database?> get database async {
    if (!isSQLiteSupported) return null;
    if (_database != null) return _database;
    try {
      _database = await _initDB('todo.db'); // Sesuai dengan slide: todo.db
      return _database;
    } catch (e) {
      print("Gagal menginisialisasi SQLite, beralih ke Mock DB: $e");
      return null;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Membuat tabel sesuai skema di slide (dengan kolom isDone)
    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        isDone INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<int> insert(Todo todo) async {
    if (!isSQLiteSupported) {
      print("[TodoDbHelper] Menyimpan ke Mock DB (Penyimpanan Memori): ${todo.title}");
      final newTodo = todo.copyWith(id: _mockIdCounter++);
      _mockDb.add(newTodo.toMap());
      return newTodo.id!;
    }

    try {
      final db = await database;
      if (db != null) {
        return await db.insert('todos', todo.toMap());
      }
    } catch (e) {
      print("[TodoDbHelper] Gagal menyimpan ke SQLite, beralih ke Mock DB: $e");
    }

    // Fallback jika terjadi error
    final newTodo = todo.copyWith(id: _mockIdCounter++);
    _mockDb.add(newTodo.toMap());
    return newTodo.id!;
  }

  Future<List<Todo>> readAllTodos() async {
    List<Map<String, dynamic>> maps = [];

    if (!isSQLiteSupported) {
      print("[TodoDbHelper] Membaca dari Mock DB (Penyimpanan Memori)");
      maps = List<Map<String, dynamic>>.from(_mockDb.reversed);
    } else {
      try {
        final db = await database;
        if (db != null) {
          maps = await db.query('todos', orderBy: 'id DESC');
        }
      } catch (e) {
        print("[TodoDbHelper] Gagal membaca dari SQLite, beralih ke Mock DB: $e");
        maps = List<Map<String, dynamic>>.from(_mockDb.reversed);
      }
    }

    return List.generate(maps.length, (i) {
      return Todo.fromMap(maps[i]);
    });
  }

  Future<int> update(Todo todo) async {
    if (!isSQLiteSupported) {
      print("[TodoDbHelper] Memperbarui di Mock DB (Penyimpanan Memori)");
      final index = _mockDb.indexWhere((element) => element['id'] == todo.id);
      if (index != -1) {
        _mockDb[index] = todo.toMap();
        return 1;
      }
      return 0;
    }

    try {
      final db = await database;
      if (db != null) {
        return await db.update(
          'todos',
          todo.toMap(),
          where: 'id = ?',
          whereArgs: [todo.id],
        );
      }
    } catch (e) {
      print("[TodoDbHelper] Gagal memperbarui SQLite: $e");
    }

    // Fallback jika terjadi error
    final index = _mockDb.indexWhere((element) => element['id'] == todo.id);
    if (index != -1) {
      _mockDb[index] = todo.toMap();
      return 1;
    }
    return 0;
  }

  Future<int> delete(int id) async {
    if (!isSQLiteSupported) {
      print("[TodoDbHelper] Menghapus dari Mock DB (Penyimpanan Memori): $id");
      _mockDb.removeWhere((element) => element['id'] == id);
      return 1;
    }

    try {
      final db = await database;
      if (db != null) {
        return await db.delete(
          'todos',
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } catch (e) {
      print("[TodoDbHelper] Gagal menghapus SQLite: $e");
    }

    _mockDb.removeWhere((element) => element['id'] == id);
    return 1;
  }
}


