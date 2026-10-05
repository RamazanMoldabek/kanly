import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/board_model.dart';

class BoardService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Получить все доски текущего авторизованного пользователя
  Future<List<BoardModel>> getUserBoards() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    // Бэкенд Supabase проверяет RLS политики (owner_id = uid OR is_board_member)
    final response = await _supabase
        .from('boards')
        .select()
        .order('created_at', ascending: false);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => BoardModel.fromJson(json)).toList();
  }

  /// Создать новую доску с базовыми колонками (To Do, In Progress, Done)
  Future<BoardModel> createBoard({
    required String title,
    String? description,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Пользователь не авторизован');
    }

    // 1. Создаем доску
    final boardData = await _supabase
        .from('boards')
        .insert({
          'title': title.trim(),
          'description': description?.trim(),
          'owner_id': userId,
        })
        .select()
        .single();

    final newBoard = BoardModel.fromJson(boardData);

    // 2. Создаем дефолтные колонки для новой доски (To Do, In Progress, Done)
    final defaultColumns = [
      {'board_id': newBoard.id, 'title': 'To Do 📋', 'order_index': 1000.0},
      {
        'board_id': newBoard.id,
        'title': 'In Progress ⏳',
        'order_index': 2000.0,
      },
      {'board_id': newBoard.id, 'title': 'Done ✅', 'order_index': 3000.0},
    ];

    await _supabase.from('columns').insert(defaultColumns);

    notifyListeners();
    return newBoard;
  }

  /// Удалить доску
  Future<void> deleteBoard(String boardId) async {
    await _supabase.from('boards').delete().eq('id', boardId);
    notifyListeners();
  }
}
