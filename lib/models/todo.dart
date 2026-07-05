class Todo {
  static const personal = 'personal';
  static const project = 'project';

  final int? id;
  final String title;
  final bool isDone;
  final String scope;
  final int? projectId;
  final String createdAt;

  Todo({
    this.id,
    required this.title,
    this.isDone = false,
    this.scope = personal,
    this.projectId,
    this.createdAt = '',
  });

  Todo copyWith({int? id, String? title, bool? isDone, String? scope, int? projectId}) => Todo(
        id: id ?? this.id,
        title: title ?? this.title,
        isDone: isDone ?? this.isDone,
        scope: scope ?? this.scope,
        projectId: projectId ?? this.projectId,
        createdAt: createdAt,
      );

  Todo withId(int? newId) => Todo(
        id: newId,
        title: title,
        isDone: isDone,
        scope: scope,
        projectId: projectId,
        createdAt: createdAt,
      );

  factory Todo.fromMap(Map<String, dynamic> m) => Todo(
        id: m['id'],
        title: m['title'] ?? '',
        isDone: m['is_done'] ?? false,
        scope: m['scope'] ?? personal,
        projectId: m['project'],
        createdAt: m['created_at'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'is_done': isDone,
        'scope': scope,
        'project': projectId,
      };
}
