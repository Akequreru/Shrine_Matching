import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shrine_matching/pages/home.dart';
import 'package:shrine_matching/pages/diagnote.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:shrine_matching/pages/profile.dart';
import 'package:shrine_matching/pages/type.dart';
import 'package:shrine_matching/pages/map.dart';
import 'package:shrine_matching/pages/bookmark.dart';
import 'package:shrine_matching/pages/login.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firestoreへの初回接続（WebChannelのハンドシェイク）はここで先に済ませておく。
  // 待たずに投げっぱなしにすることで、Home画面を見ている間に裏側で接続確立が進み、
  // 実際に質問を読み込む診断画面に着く頃には通信が速くなっている想定。
  unawaited(FirebaseFirestore.instance.collection('Questions').limit(1).get());

  runApp(DevicePreview(enabled: true, builder: (context) => const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
    );
  }
}

// ログイン状態を見て、ログイン済みならメイン画面、未ログインならログイン画面を出す。
// Firebase Authはログイン状態を端末側に永続化するので、アプリを再起動しても
// ここで自動的にログイン済み判定される（再ログイン不要）。
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const RootTabsPage();
        }
        return const LoginPage();
      },
    );
  }
}

class RootTabsPage extends StatelessWidget {
  const RootTabsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        activeColor: Color(0xFFDB4713),
        items: [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Icon(CupertinoIcons.house_fill),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Icon(CupertinoIcons.square_grid_2x2_fill),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Icon(CupertinoIcons.map_fill),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Icon(CupertinoIcons.bookmark_fill),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Icon(CupertinoIcons.person_fill),
            ),
            label: '',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return CupertinoTabView(builder: (_) => const HomePageWidget());
          case 1:
            return CupertinoTabView(builder: (_) => const TypePage());
          case 2:
            return CupertinoTabView(builder: (_) => const MapPage());
          case 3:
            return CupertinoTabView(builder: (_) => const BookmarkPage());
          case 4:
            return CupertinoTabView(builder: (_) => const ProfilePage());
          default:
            return CupertinoTabView(builder: (_) => const HomePageWidget());
        }
      },
    );
  }
}
