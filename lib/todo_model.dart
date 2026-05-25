class Todo {
  final int? id;
  final String title;
  final bool isDone;

  Todo({
    this.id,
    required this.title,
    this.isDone = false,
  });

  // Konversi objek -> Map (untuk simpan ke DB)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isDone': isDone ? 1 : 0, // SQLite pakai int (1 atau 0)
    };
  }

  // Konversi Map -> objek (dari hasil query)
  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      title: map['title'],
      isDone: map['isDone'] == 1,
    );
  }

  // Helper untuk menduplikasi objek dengan beberapa perubahan data
  Todo copyWith({
    int? id,
    String? title,
    bool? isDone,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }
}
