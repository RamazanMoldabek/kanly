import 'package:flutter/material.dart';

import '../../models/board_model.dart';
import '../../models/column_model.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import '../../theme/app_theme.dart';

class KanbanBoardScreen extends StatefulWidget {
  final BoardModel board;

  const KanbanBoardScreen({super.key, required this.board});

  @override
  State<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
}

class _KanbanBoardScreenState extends State<KanbanBoardScreen> {
  final TaskService _taskService = TaskService();

  List<ColumnModel> _columns = [];
  List<TaskModel> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBoardData();
  }

  Future<void> _loadBoardData() async {
    try {
      final cols = await _taskService.getBoardColumns(widget.board.id);
      final tsks = await _taskService.getBoardTasks(widget.board.id);

      if (mounted) {
        setState(() {
          _columns = cols;
          _tasks = tsks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки данных: $e')));
      }
    }
  }

  void _showAddTaskDialog(String columnId) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String priority = 'medium';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: const Text(
                'Новая карточка',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Заголовок карточки...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Описание (опционально)...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Приоритет: ',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: priority,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'low', child: Text('Низкий')),
                          DropdownMenuItem(
                            value: 'medium',
                            child: Text('Средний'),
                          ),
                          DropdownMenuItem(
                            value: 'high',
                            child: Text('Высокий'),
                          ),
                          DropdownMenuItem(
                            value: 'critical',
                            child: Text('Критический'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => priority = val);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Отмена',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.textPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;
                    Navigator.of(context).pop();

                    await _taskService.createTask(
                      boardId: widget.board.id,
                      columnId: columnId,
                      title: titleController.text,
                      description: descriptionController.text,
                      priority: priority,
                    );
                    _loadBoardData();
                  },
                  child: const Text('Создать'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddColumnDialog() {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: const Text(
            'Новая колонка',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: TextField(
            controller: titleController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Название колонки (например: Review)...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Отмена',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.textPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                Navigator.of(context).pop();

                await _taskService.createColumn(
                  boardId: widget.board.id,
                  title: titleController.text,
                );
                _loadBoardData();
              },
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color bg;
    Color text;
    String label;

    switch (priority) {
      case 'low':
        bg = AppTheme.tagGreenBg;
        text = AppTheme.tagGreenText;
        label = 'Низкий';
        break;
      case 'high':
        bg = AppTheme.tagOrangeBg;
        text = AppTheme.tagOrangeText;
        label = 'Высокий';
        break;
      case 'critical':
        bg = AppTheme.tagRedBg;
        text = AppTheme.tagRedText;
        label = 'Срочно';
        break;
      case 'medium':
      default:
        bg = AppTheme.tagYellowBg;
        text = AppTheme.tagYellowText;
        label = 'Средний';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const Text('📌 ', style: TextStyle(fontSize: 18)),
            Text(
              widget.board.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Обновить',
            onPressed: _loadBoardData,
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            tooltip: 'Новая колонка',
            onPressed: _showAddColumnDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.textPrimary,
              ),
            )
          : Container(
              color: AppTheme.background,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                itemCount: _columns.length + 1,
                itemBuilder: (context, index) {
                  if (index == _columns.length) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: InkWell(
                        onTap: _showAddColumnDialog,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 260,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppTheme.sidebarBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Добавить колонку',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final column = _columns[index];
                  final columnTasks = _tasks
                      .where((t) => t.columnId == column.id)
                      .toList();

                  return DragTarget<TaskModel>(
                    onAcceptWithDetails: (details) async {
                      final draggedTask = details.data;
                      if (draggedTask.columnId != column.id) {
                        final colTasks = _tasks
                            .where((t) => t.columnId == column.id)
                            .toList();
                        double newOrder = 1000.0;
                        if (colTasks.isNotEmpty) {
                          newOrder = colTasks.last.orderIndex + 1000.0;
                        }

                        setState(() {
                          _tasks = _tasks.map((t) {
                            if (t.id == draggedTask.id) {
                              return TaskModel(
                                id: t.id,
                                title: t.title,
                                description: t.description,
                                priority: t.priority,
                                dueDate: t.dueDate,
                                assigneeId: t.assigneeId,
                                columnId: column.id,
                                boardId: t.boardId,
                                orderIndex: newOrder,
                                createdAt: t.createdAt,
                              );
                            }
                            return t;
                          }).toList();
                        });

                        await _taskService.moveTask(
                          taskId: draggedTask.id,
                          newColumnId: column.id,
                          newOrderIndex: newOrder,
                        );
                      }
                    },
                    builder: (context, candidateData, rejectedData) {
                      final isHovered = candidateData.isNotEmpty;

                      return Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isHovered
                              ? AppTheme.tagBlueBg
                              : AppTheme.sidebarBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isHovered
                                ? AppTheme.primaryAccent
                                : AppTheme.border,
                            width: isHovered ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.tagGrayBg,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        column.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${columnTasks.length}',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add,
                                    size: 18,
                                    color: AppTheme.textSecondary,
                                  ),
                                  onPressed: () =>
                                      _showAddTaskDialog(column.id),
                                  tooltip: 'Добавить задачу',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: columnTasks.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Нет задач',
                                        style: TextStyle(
                                          color: AppTheme.textSecondary
                                              .withValues(alpha: 0.6),
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: columnTasks.length,
                                      itemBuilder: (context, tIndex) {
                                        final task = columnTasks[tIndex];

                                        return LongPressDraggable<TaskModel>(
                                          data: task,
                                          feedback: Material(
                                            elevation: 6,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: SizedBox(
                                              width: 260,
                                              child: _buildTaskCard(task),
                                            ),
                                          ),
                                          childWhenDragging: Opacity(
                                            opacity: 0.3,
                                            child: _buildTaskCard(task),
                                          ),
                                          child: _buildTaskCard(task),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPriorityBadge(task.priority),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.close,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () async {
                    await _taskService.deleteTask(task.id);
                    _loadBoardData();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
