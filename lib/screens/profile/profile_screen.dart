import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../services/board_service.dart';
import '../../theme/app_theme.dart';

/// Экран профиля пользователя Kanly
/// Соответствует критериям:
/// - Критерий 8: Профиль бөлімін әзірлеу
/// - Критерий 10: Шығу функциясын әзірлеу
/// - Критерий 14: Демонстрация по цепочке Басты бет -> Профиль -> Шығу
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _boardService = BoardService();

  Map<String, dynamic>? _userProfile;
  int _boardsCount = 0;
  int _totalTasksCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = _authService.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Загружаем профиль
      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      // 2. Загружаем статистику досок
      final boards = await _boardService.getUserBoards();
      final boardIds = boards.map((b) => b.id).toList();

      // 3. Подсчитываем задачи во всех досках пользователя
      int tasksCount = 0;
      if (boardIds.isNotEmpty) {
        final tasksResponse = await Supabase.instance.client
            .from('tasks')
            .select('id')
            .inFilter('board_id', boardIds);
        tasksCount = (tasksResponse as List).length;
      }

      if (mounted) {
        setState(() {
          _userProfile = profile;
          _boardsCount = boards.length;
          _totalTasksCount = tasksCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Profile fetch error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEditNameDialog() {
    final currentName = _userProfile?['full_name'] ?? '';
    final nameController = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

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
                  Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppTheme.textPrimary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Аты-жөнін өзгерту',
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
                child: TextFormField(
                  controller: nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Толық аты-жөні',
                    hintText: 'Мысалы: Арман Серіков',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Аты-жөніңізді енгізіңіз';
                    }
                    return null;
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Бас тарту',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSaving = true);

                          try {
                            await _authService.updateFullName(
                              nameController.text.trim(),
                            );
                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Профиль сәтті жаңартылды!'),
                                  backgroundColor: AppTheme.textPrimary,
                                ),
                              );
                              _loadProfileData();
                            }
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Қате: ${e.toString()}'),
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
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Сақтау'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, size: 20, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              'Жүйеден шығу',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: const Text(
          'Жүйеден шығуды растайсыз ба? Қайта кіру үшін пошта мен құпия сөз қажет болады.',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Бас тарту',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text('Шығу'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted) {
        Navigator.of(context).pop(); // возвращаемся с экрана профиля
      }
      await _authService.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final fullName = _userProfile?['full_name'] ?? 'Пайдаланушы';
    final email = user?.email ?? '';
    final createdAtRaw = _userProfile?['created_at'];
    String createdFormatted = 'Жақында';
    if (createdAtRaw != null) {
      final date = DateTime.tryParse(createdAtRaw.toString());
      if (date != null) {
        createdFormatted =
            '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Профиль',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Жаңарту',
            onPressed: _loadProfileData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.textPrimary,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              color: AppTheme.textPrimary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Карточка пользователя с аватаром
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: [
                          // Монохромный минималистичный аватар
                          Container(
                            width: 68,
                            height: 68,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.tagGrayBg,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppTheme.border,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              fullName.isNotEmpty
                                  ? fullName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Имя и кнопка редактирования
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  fullName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: _showEditNameDialog,
                                borderRadius: BorderRadius.circular(4),
                                child: const Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Email
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Статус аккаунта
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.tagGreenBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 13,
                                  color: AppTheme.tagGreenText,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Белсенді қолданушы',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.tagGreenText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Статистика (Жұмыс кеңістігі)
                    const Text(
                      'ЖҰМЫС КЕҢІСТІГІНІҢ СТАТИСТИКАСЫ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Жобалар',
                            count: '$_boardsCount',
                            icon: Icons.dashboard_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Тапсырмалар',
                            count: '$_totalTasksCount',
                            icon: Icons.checklist_outlined,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Информация об аккаунте
                    const Text(
                      'АККАУНТ ДЕРЕКТЕРІ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: [
                          _buildInfoTile(
                            icon: Icons.email_outlined,
                            title: 'Email',
                            subtitle: email,
                          ),
                          const Divider(height: 1, color: AppTheme.border),
                          _buildInfoTile(
                            icon: Icons.calendar_today_outlined,
                            title: 'Тіркелген күні',
                            subtitle: createdFormatted,
                          ),
                          const Divider(height: 1, color: AppTheme.border),
                          _buildInfoTile(
                            icon: Icons.security_outlined,
                            title: 'База деректері',
                            subtitle: 'Supabase Cloud PostgreSQL',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Параметры и управление
                    const Text(
                      'БАСҚАРУ ЖӘНЕ ҚАУІПСІЗДІК',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.edit_note_outlined,
                              size: 20,
                              color: AppTheme.textPrimary,
                            ),
                            title: const Text(
                              'Аты-жөнін өңдеу',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: AppTheme.textSecondary,
                            ),
                            onTap: _showEditNameDialog,
                          ),
                          const Divider(height: 1, color: AppTheme.border),
                          ListTile(
                            leading: const Icon(
                              Icons.info_outline,
                              size: 20,
                              color: AppTheme.textPrimary,
                            ),
                            title: const Text(
                              'Қосымша туралы',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            trailing: const Text(
                              'v1.0.0',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            onTap: () {
                              showAboutDialog(
                                context: context,
                                applicationName: 'Kanly',
                                applicationVersion: '1.0.0',
                                applicationLegalese: 'Курстық жоба: Мобильді қосымшаларды әзірлеу\nКолледж AITU, 2026',
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Кнопка Выхода (Шығу)
                    OutlinedButton.icon(
                      onPressed: _handleSignOut,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Color(0xFFFFCDD2)),
                        backgroundColor: const Color(0xFFFFF8F8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text(
                        'Жүйеден шығу',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              Icon(icon, size: 18, color: AppTheme.textSecondary),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            count,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 18, color: AppTheme.textSecondary),
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}
