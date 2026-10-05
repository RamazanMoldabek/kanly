class BoardMemberModel {
  final String boardId;
  final String userId;
  final String role; // 'admin' | 'member'
  final DateTime? createdAt;

  BoardMemberModel({
    required this.boardId,
    required this.userId,
    required this.role,
    this.createdAt,
  });

  factory BoardMemberModel.fromJson(Map<String, dynamic> json) {
    return BoardMemberModel(
      boardId: json['board_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'member',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'board_id': boardId,
      'user_id': userId,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
