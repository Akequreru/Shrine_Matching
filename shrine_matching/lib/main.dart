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
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shrine_matching/survices/app_globals.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TaskHandler（バックグラウンドサービス）とアプリ本体が通信するためのポートを用意する
  FlutterForegroundTask.initCommunicationPort();

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
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
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

class RootTabsPage extends StatefulWidget {
  const RootTabsPage({super.key});

  @override
  State<RootTabsPage> createState() => _RootTabsPageState();
}

class _RootTabsPageState extends State<RootTabsPage> with WidgetsBindingObserver {
  final GlobalKey<HomePageWidgetState> _homeKey = GlobalKey<HomePageWidgetState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // バックグラウンドのすれ違い検知（ENTER）をリアルタイムで受け取り、
    // タブに関係なくその場で参拝パネルを出せるようにする
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
    // アプリ起動直後にも一度チェックしておく
    visitPromptService.checkNearbyShrineForVisit();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // アプリをバックグラウンドから復帰させたときにも参拝パネルをチェックする
    if (state == AppLifecycleState.resumed) {
      visitPromptService.checkNearbyShrineForVisit();
    }
  }

  void _onReceiveTaskData(Object data) {
    if (data is! Map) return;

    if (data['type'] == 'nearbyShrineEnter') {
      visitPromptService.showPromptForShrineData(
        shrineId: data['shrineId'] as String? ?? '',
        shrineName: data['shrineName'] as String? ?? '',
        image: data['image'] as String? ?? '',
        tags: List<String>.from(data['tags'] ?? []),
        address: data['address'] as String? ?? '',
      );
    } else if (data['type'] == 'nearbyShrineExit') {
      visitPromptService.clearPromptedShrine(data['shrineId'] as String? ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        activeColor: Color(0xFFDB4713),
        onTap: (index) {
          // どのタブに切り替えても参拝パネルの対象になり得るのでチェックする
          visitPromptService.checkNearbyShrineForVisit();
          // Homeタブに来たときは、すれ違いパネルも再チェックする。
          // 参拝パネルの処理待ち（優先表示）はrefreshCrossings側で行っている
          if (index == 0) {
            _homeKey.currentState?.refreshCrossings();
          }
        },
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
            return CupertinoTabView(builder: (_) => HomePageWidget(key: _homeKey));
          case 1:
            return CupertinoTabView(builder: (_) => const TypePage());
          case 2:
            return CupertinoTabView(builder: (_) => const MapPage());
          case 3:
            return CupertinoTabView(builder: (_) => const BookmarkPage());
          case 4:
            return CupertinoTabView(builder: (_) => const ProfilePage());
          default:
            return CupertinoTabView(builder: (_) => HomePageWidget(key: _homeKey));
        }
      },
    );
  }
}
