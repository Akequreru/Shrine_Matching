import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shrine_matching/services/auth_service.dart';

class ProfileSettingsPage extends StatelessWidget {
  const ProfileSettingsPage({super.key});

  static String routeName = 'ProfileSettingsPage';
  static String routePath = '/profileSettingsPage';

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEFEFE),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '設定',
          style: TextStyle(
            color: Color(0xFF2D2D2D),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2D2D2D)),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDB4713),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  await AuthService().signOut();
                },
                child: const Text('ログアウト'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCE6C6C)),
                  foregroundColor: const Color(0xFFB24343),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _showDeleteAccountDialog(context),
                child: const Text('アカウントを削除'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showDeleteAccountDialog(BuildContext context) {
  final authService = AuthService();

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('アカウントを削除'),
        content: const Text('この操作は取り消せません。本当に削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              // 削除に成功するとFirebase Authのログイン状態が変わり、ルート画面が
              // ログイン画面へ丸ごと入れ替わる。そのタイミングとこのダイアログを閉じる
              // 操作が同じフレームで重なると、Flutterのウィジェットツリーの後始末が
              // 崩れて赤画面のクラッシュになるため、削除処理を始める前に必ず
              // ダイアログを閉じておく。
              Navigator.of(dialogContext).pop();
              _performDeleteAccount(context, authService);
            },
            child: const Text('削除する', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
}

Future<void> _performDeleteAccount(
  BuildContext context,
  AuthService authService, {
  String? password,
}) async {
  try {
    await authService.deleteAccount(password: password);
    // 成功時はauthStateChangesの変化を受けてAuthGateが自動でログイン画面に切り替える
  } on FirebaseAuthException catch (e) {
    if (e.code == 'requires-recent-login' && password == null) {
      if (context.mounted) {
        _showDeleteAccountPasswordDialog(context, authService);
      }
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authService.messageForError(e))));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authService.messageForError(e))));
    }
  }
}

void _showDeleteAccountPasswordDialog(
  BuildContext context,
  AuthService authService,
) {
  final passwordController = TextEditingController();

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('アカウントを削除'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('セキュリティのため、確認のためパスワードを入力してください。'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'パスワード'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              // 上の確認ダイアログと同じ理由で、削除処理を始める前に必ず
              // ダイアログを閉じておく（成功時のauthStateChanges変化と
              // ダイアログを閉じる操作が重なるとクラッシュするため）。
              Navigator.of(dialogContext).pop();
              _performDeleteAccount(
                context,
                authService,
                password: passwordController.text,
              );
            },
            child: const Text('削除する', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  ).then((_) {
    passwordController.dispose();
  });
}
