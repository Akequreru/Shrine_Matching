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
      bool isSubmitting = false;
      String? errorMessage;

      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: const Text('アカウントを削除'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('この操作は取り消せません。本当に削除しますか？'),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setState(() {
                          isSubmitting = true;
                          errorMessage = null;
                        });
                        try {
                          await authService.deleteAccount();
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        } on FirebaseAuthException catch (e) {
                          if (e.code == 'requires-recent-login') {
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            if (context.mounted) {
                              _showDeleteAccountPasswordDialog(
                                context,
                                authService,
                              );
                            }
                            return;
                          }
                          setState(() {
                            isSubmitting = false;
                            errorMessage = authService.messageForError(e);
                          });
                        } catch (e) {
                          setState(() {
                            isSubmitting = false;
                            errorMessage = authService.messageForError(e);
                          });
                        }
                      },
                child: Text(
                  '削除する',
                  style: TextStyle(
                    color: isSubmitting ? Colors.grey : Colors.red,
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

void _showDeleteAccountPasswordDialog(
  BuildContext context,
  AuthService authService,
) {
  final passwordController = TextEditingController();

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      bool isSubmitting = false;
      String? errorMessage;

      return StatefulBuilder(
        builder: (dialogContext, setState) {
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
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setState(() {
                          isSubmitting = true;
                          errorMessage = null;
                        });
                        try {
                          await authService.deleteAccount(
                            password: passwordController.text,
                          );
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        } catch (e) {
                          setState(() {
                            isSubmitting = false;
                            errorMessage = authService.messageForError(e);
                          });
                        }
                      },
                child: Text(
                  '削除する',
                  style: TextStyle(
                    color: isSubmitting ? Colors.grey : Colors.red,
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  ).then((_) {
    passwordController.dispose();
  });
}
