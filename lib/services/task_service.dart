import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/column_model.dart';
import '../models/task_model.dart';

class TaskService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Получить колонки доски по порядку
  Future<List<ColumnModel>> getBoardColumns(String boardId) async {
    final response = await _supabase
        .from('columns')
        .select()
        .eq('board_id', boardId)
        .order('order_index', ascending: true);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => ColumnModel.fromJson(json)).toList();
  }

  /// Получить задачи доски по порядку
  Future<List<TaskModel>> getBoardTasks(String boardId) async {
    final response = await _supabase
        .from('tasks')
        .select()
        .eq('board_id', boardId)
        .order('order_index', ascending: true);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => TaskModel.fromJson(json)).toList();
  }

  /// Создать новую задачу в колонке
  Future<TaskModel> createTask({
    required String boardId,
    required String columnId,
    required String title,
    String? description,
    String priority = 'medium',
    DateTime? dueDate,
  }) async {
    final existingTasks = await _supabase
        .from('tasks')
        .select('order_index')
        .eq('column_id', columnId)
        .order('order_index', ascending: false)
        .limit(1);

    double maxOrder = 0.0;
    if (existingTasks.isNotEmpty) {
      maxOrder = (existingTasks.first['order_index'] as num).toDouble();
    }
    final newOrderIndex = maxOrder + 1000.0;

    final response = await _supabase
        .from('tasks')
        .insert({
          'board_id': boardId,
          'column_id': columnId,
          'title': title.trim(),
          'description': description?.trim(),
          'priority': priority,
          'due_date': dueDate?.toIso8601String(),
          'order_index': newOrderIndex,
        })
        .select()
        .single();

    notifyListeners();
    return TaskModel.fromJson(response);
  }

  /// Переместить задачу (в другую колонку или изменить порядок)
  Future<void> moveTask({
    required String taskId,
    required String newColumnId,
    required double newOrderIndex,
  }) async {
    await _supabase
        .from('tasks')
        .update({
          'column_id': newColumnId,
          'order_index': newOrderIndex,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', taskId);

    notifyListeners();
  }

  /// Удалить задачу
  Future<void> deleteTask(String taskId) async {
    await _supabase.from('tasks').delete().eq('id', taskId);
    notifyListeners();
  }

  /// Создать новую колонку
  Future<ColumnModel> createColumn({
    required String boardId,
    required String title,
  }) async {
    final existing = await _supabase
        .from('columns')
        .select('order_index')
        .eq('board_id', boardId)
        .order('order_index', ascending: false)
        .limit(1);

    double maxOrder = 0.0;
    if (existing.isNotEmpty) {
      maxOrder = (existing.first['order_index'] as num).toDouble();
    }

    final response = await _supabase
        .from('columns')
        .insert({
          'board_id': boardId,
          'title': title.trim(),
          'order_index': maxOrder + 1000.0,
        })
        .select()
        .single();

    notifyListeners();
    return ColumnModel.fromJson(response);
  }
}
