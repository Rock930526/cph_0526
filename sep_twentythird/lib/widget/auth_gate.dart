import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../app_shell_page.dart';
import '../page/login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 還在檢查登入狀態
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ❌ 尚未登入 → 強制登入頁
        if (!snapshot.hasData) {
          return const LoginPage();
        }

        // ✅ 已登入 → 主功能
        return const AppShellPage();
      },
    );
  }
}
