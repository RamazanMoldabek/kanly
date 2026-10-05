class ColumnModel {
  final String id;
  final String boardId;
  final String title;
  final double orderIndex;
  final DateTime createdAt;

  ColumnModel({
    required this.id,
    required this.boardId,
    required this.title,
    required this.orderIndex,
    required this.createdAt,
  });

  factory ColumnModel.fromJson(Map<String, dynamic> json) {
    return ColumnModel(
      id: json['id'] as String,
      boardId: json['board_id'] as String,
      title: json['title'] as String,
      orderIndex: (json['order_index'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'board_id': boardId,
      'title': title,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
