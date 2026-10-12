import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import '../auth/auth_gate.dart';

/// Splash экран приложения Kanly
/// Соответствует критериям дисциплины «Мобильді қосымшаларды әзірлеу»:
/// - Логотип и название приложения
/// - Единый дизайн-код (Notion / Минимализм)
/// - Плавная анимация и переход на следующий этап (AuthGate)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  String? _errorMessage;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _startInitialization();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startInitialization() async {
    setState(() {
      _errorMessage = null;
      _isRetrying = false;
    });

    try {
      // Засекаем минимум 2.2 секунды для демонстрации Splash экрана
      final minSplashDuration = Future.delayed(
        const Duration(milliseconds: 2200),
      );

      // Инициализируем окружение и Supabase
      final initTask = _initializeServices();

      // Ожидаем завершения обеих задач параллельно
      await Future.wait([minSplashDuration, initTask]);

      if (!mounted) return;

      // Плавный переход на AuthGate (Авторизация / Главный экран)
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AuthGate(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _initializeServices() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('Dotenv warning: $e');
    }

    final url =
        dotenv.env['SUPABASE_URL'] ??
        'https://sgmmkrbewegwfiubijty.supabase.co';
    final anonKey =
        dotenv.env['SUPABASE_ANON_KEY'] ??
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNnbW1rcmJld2Vnd2ZpdWJpanR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA3NjMxMzIsImV4cCI6MjEwNjMzOTEzMn0.O6--3x9SYt-BFbEak-HQH6KAJAIJdJ90BmytbNHQSF8';

    try {
      Supabase.instance;
    } catch (_) {
      await Supabase.initialize(url: url, anonKey: anonKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Центрированный блок с логотипом и названием
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Стильный минималистичный логотип
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: AppTheme.border,
                            width: 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0D000000),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppTheme.tagGrayBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.view_kanban_outlined,
                              size: 34,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Название приложения
                      const Text(
                        'Kanly',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Подзаголовок / Слоган проекта
                      const Text(
                        'Фокус на главном',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.2,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Состояние загрузки или ошибка
                      if (_errorMessage == null)
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppTheme.textPrimary,
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Column(
                            children: [
                              Text(
                                'Қосылу қатесі:\n$_errorMessage',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _isRetrying
                                    ? null
                                    : () {
                                        setState(() => _isRetrying = true);
                                        _startInitialization();
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.textPrimary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Қайта көру'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
