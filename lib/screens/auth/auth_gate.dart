import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_screen.dart';
import '../home/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Получаем текущую сессию сразу, без ожидания первого ивента стрима
    final currentSession = Supabase.instance.client.auth.currentSession;

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? currentSession;

        if (session != null) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
