enum TodoSubtaskKind { item, heading }

/// A checklist entry inside a task. Headings only label the entries below
/// them and are never "done".
class TodoSubtask {
  const TodoSubtask({
    required this.id,
    required this.title,
    this.isDone = false,
    this.level = 0,
    this.kind = TodoSubtaskKind.item,
  }) : assert(level == 0 || level == 1);

  factory TodoSubtask.fromJson(Map<String, dynamic> json) {
    final kind = TodoSubtaskKind.values.firstWhere(
      (candidate) => candidate.name == json['kind'],
      orElse: () => TodoSubtaskKind.item,
    );
    final level = json['level'];
    return TodoSubtask(
      id: json['id'] as String,
      title: json['title'] as String,
      isDone:
          kind == TodoSubtaskKind.item && (json['isDone'] as bool? ?? false),
      level: level == 1 ? 1 : 0,
      kind: kind,
    );
  }

  final String id;
  final String title;
  final bool isDone;

  /// 0 = top level, 1 = indented under the entry above.
  final int level;
  final TodoSubtaskKind kind;

  bool get isHeading => kind == TodoSubtaskKind.heading;

  TodoSubtask copyWith({String? title, bool? isDone, int? level}) =>
      TodoSubtask(
        id: id,
        title: title ?? this.title,
        isDone: isHeading ? false : (isDone ?? this.isDone),
        level: level ?? this.level,
        kind: kind,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isDone': isDone,
    'level': level,
    'kind': kind.name,
  };
}
