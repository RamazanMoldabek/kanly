import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth/auth_gate.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KanlyApp());
}

class KanlyApp extends StatelessWidget {
  const KanlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kanly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeApp();
  }

  Future<void> _initializeApp() async {
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
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.view_kanban_outlined,
                    size: 52,
                    color: AppTheme.textPrimary,
                  ),
                  SizedBox(height: 16),
                  CircularProgressIndicator(
                    color: AppTheme.textPrimary,
                    strokeWidth: 2,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Kanly',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ошибка подключения к Supabase:',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _initFuture = _initializeApp();
                        });
                      },
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return const AuthGate();
      },
    );
  }
}
