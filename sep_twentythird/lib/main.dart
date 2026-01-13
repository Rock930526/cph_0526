import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'widget/auth_gate.dart';
import 'theme/app_theme.dart';
import 'widget/debug_db_check.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // 🔍 SQLite 驗證（只要跑一次就好）
  await DebugDbCheck.checkAndCreateDb();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Skin Scanner',
      theme: appTheme,
      home: const AuthGate(),
    );
  }
}
