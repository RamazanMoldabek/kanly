class BoardModel {
  final String id;
  final String title;
  final String? description;
  final String ownerId;
  final DateTime createdAt;

  BoardModel({
    required this.id,
    required this.title,
    this.description,
    required this.ownerId,
    required this.createdAt,
  });

  factory BoardModel.fromJson(Map<String, dynamic> json) {
    return BoardModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      ownerId: json['owner_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'owner_id': ownerId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
