import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/board_model.dart';
import '../../services/auth_service.dart';
import '../../services/board_service.dart';
import '../../theme/app_theme.dart';
import '../board/kanban_board_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _boardService = BoardService();

  Map<String, dynamic>? _userProfile;
  List<BoardModel> _boards = [];
  bool _isLoadingBoards = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadUserProfile(), _loadBoards()]);
  }

  Future<void> _loadUserProfile() async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _userProfile = data;
        });
      }
    } catch (e) {
      debugPrint('Profile error: $e');
    }
  }

  Future<void> _loadBoards() async {
    try {
      final boards = await _boardService.getUserBoards();
      if (mounted) {
        setState(() {
          _boards = boards;
          _isLoadingBoards = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBoards = false);
      }
    }
  }

  void _showCreateBoardDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: const Row(
                children: [
                  Text('📌 ', style: TextStyle(fontSize: 18)),
                  Text(
                    'Новый проект',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Название проекта *',
                        hintText: 'Например: Разработка мобилки',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите название проекта';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Описание (опционально)',
                        hintText: 'Краткая суть процесса...',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Отмена',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() => isSubmitting = true);

                          try {
                            await _boardService.createBoard(
                              title: titleController.text,
                              description: descriptionController.text,
                            );
                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Доска создана с базовыми колонками!',
                                  ),
                                  backgroundColor: AppTheme.textPrimary,
                                ),
                              );
                              _loadBoards();
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Ошибка: ${e.toString()}'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.textPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Создать'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteBoard(BoardModel board) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить проект?'),
        content: Text('Удалить "${board.title}" со всеми задачами?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Отмена',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _boardService.deleteBoard(board.id);
        _loadBoards();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка удаления: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final fullName = _userProfile?['full_name'] ?? 'Пользователь';
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Text('📖 ', style: TextStyle(fontSize: 18)),
            Text(
              'Kanly Workspace',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            tooltip: 'Выйти',
            onPressed: () async {
              await _authService.signOut();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateBoardDialog,
        backgroundColor: AppTheme.textPrimary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Новая доска',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.textPrimary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.sidebarBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.tagGrayBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Все Доски / Проекты (${_boards.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: _loadBoards,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_isLoadingBoards)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                )
              else if (_boards.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.dashboard_customize_outlined,
                          size: 56,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'У вас пока нет созданных досок',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _showCreateBoardDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Создать первую доску'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.textPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _boards.length,
                  itemBuilder: (context, index) {
                    final board = _boards[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        leading: const Text(
                          '📌',
                          style: TextStyle(fontSize: 20),
                        ),
                        title: Text(
                          board.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          board.description != null &&
                                  board.description!.isNotEmpty
                              ? board.description!
                              : 'Без описания',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 16,
                                color: AppTheme.textSecondary,
                              ),
                              onPressed: () => _deleteBoard(board),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppTheme.textSecondary,
                              size: 20,
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => KanbanBoardScreen(board: board),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
