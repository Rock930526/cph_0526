import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    signInOption: SignInOption.standard,
    scopes: ['email'],
  );

  /// ✅ 快速登入（使用目前帳號）
  Future<void> _signInWithGoogle() async {
    try {
      final user = await _googleSignIn.signIn();
      if (user == null) return;

      final auth = await user.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Google 登入失敗：$e');
    }
  }

  /// 🔁 切換帳號（強制選帳號）
  Future<void> _switchGoogleAccount() async {
    try {
      await _googleSignIn.signOut();
      await _signInWithGoogle();
    } catch (e) {
      debugPrint('切換帳號失敗：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 60),

              const Icon(
                Icons.health_and_safety,
                size: 72,
                color: Colors.cyanAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                'AI Skin Scanner',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '皮膚輔助辨識與健康追蹤',
                style: TextStyle(color: Colors.white54),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      '使用前請先登入',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '我們將安全地儲存您的個人健康設定，\n並提供更準確的分析結果。',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
                    ),
                    const SizedBox(height: 24),

                    /// 🔐 快速登入
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: const Icon(Icons.login),
                        label: const Text('使用 Google 登入'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// 🔁 切換帳號
                    TextButton.icon(
                      onPressed: _switchGoogleAccount,
                      icon: const Icon(Icons.switch_account, color: Colors.white70),
                      label: const Text(
                        '切換 Google 帳號',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              const Text(
                '© 2026 AI Skin Scanner',
                style: TextStyle(color: Colors.white38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
