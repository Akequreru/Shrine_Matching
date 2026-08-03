import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// ユーザー名の後ろにこのドメインを付けた「疑似メールアドレス」でFirebase Authを利用する。
// ユーザーには一切見せない内部的な値。
const String _fakeEmailDomain = 'shrine-matching.local';

class UsernameValidationException implements Exception {
  UsernameValidationException(this.message);
  final String message;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String _emailForUsername(String username) {
    return '${username.trim().toLowerCase()}@$_fakeEmailDomain';
  }

  void _validateUsername(String username) {
    final trimmed = username.trim();
    if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(trimmed)) {
      throw UsernameValidationException(
        'ユーザー名は半角英数字と_のみ、3〜20文字で入力してください',
      );
    }
  }

  // 新規登録。ユーザー名が既に使われていれば FirebaseAuthException(email-already-in-use) が投げられる
  Future<void> signUp({required String username, required String password}) async {
    _validateUsername(username);
    final trimmedUsername = username.trim();

    final credential = await _auth.createUserWithEmailAndPassword(
      email: _emailForUsername(trimmedUsername),
      password: password,
    );

    final uid = credential.user!.uid;
    await credential.user!.updateDisplayName(trimmedUsername);

    await _db.collection('Users').doc(uid).set({
      'userName': trimmedUsername,
      'lastType': 0,
      'favoriteShrineIds': <String>[],
    });
  }

  Future<void> signIn({required String username, required String password}) async {
    _validateUsername(username);

    await _auth.signInWithEmailAndPassword(
      email: _emailForUsername(username),
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> _deleteUserData(String uid) async {
    // FirestoreはドキュメントごとサブコレクションのHistoryを自動削除してくれないので、先に消しておく
    final userRef = _db.collection('Users').doc(uid);
    final historySnapshot = await userRef.collection('History').get();

    final batch = _db.batch();
    for (final doc in historySnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(userRef);
    await batch.commit();
  }

  // アカウントを完全に削除する。
  // まずパスワードなしでの削除を試み、Firebaseが「ログインから時間が経っているので
  // 再認証が必要」と言ってきた場合のみ、渡されたpasswordで再認証してから削除し直す。
  // パスワードを渡さずにこの例外が発生した場合は、呼び出し側でパスワード入力を促す。
  Future<void> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _deleteUserData(user.uid);
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login' || password == null) {
        rethrow;
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      await _deleteUserData(user.uid);
      await user.delete();
    }
  }

  // FirebaseAuthExceptionのエラーコードを日本語の文言に変換する
  String messageForError(Object error) {
    // 想定外のエラーコードでも原因を追えるよう、実際のエラーを必ずコンソールに出力する
    debugPrint('Auth error: $error');

    if (error is UsernameValidationException) {
      return error.message;
    }
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'このユーザー名は既に使われています';
        case 'weak-password':
          return 'パスワードは6文字以上で入力してください';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'ユーザー名またはパスワードが違います';
        case 'requires-recent-login':
          return 'セキュリティのため、もう一度ログインしてからお試しください';
        default:
          return '通信に失敗しました。もう一度お試しください';
      }
    }
    return '通信に失敗しました。もう一度お試しください';
  }
}
