class TaskModel {
  final String id;
  final String title;
  final String? description;
  final String priority; // 'low', 'medium', 'high', 'critical'
  final DateTime? dueDate;
  final String? assigneeId;
  final String columnId;
  final String boardId;
  final double orderIndex;
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.priority = 'medium',
    this.dueDate,
    this.assigneeId,
    required this.columnId,
    required this.boardId,
    required this.orderIndex,
    required this.createdAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: json['priority'] as String? ?? 'medium',
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String)
          : null,
      assigneeId: json['assignee_id'] as String?,
      columnId: json['column_id'] as String,
      boardId: json['board_id'] as String,
      orderIndex: (json['order_index'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'due_date': dueDate?.toIso8601String(),
      'assignee_id': assigneeId,
      'column_id': columnId,
      'board_id': boardId,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
