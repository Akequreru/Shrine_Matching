import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:shrine_matching/pages/home.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:shrine_matching/pages/profile.dart';
import 'package:shrine_matching/pages/map.dart';
import 'package:shrine_matching/pages/bookmark.dart';
import 'package:shrine_matching/pages/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shrine_matching/widgets/bottom_bar_visibility.dart';
import 'package:shrine_matching/widgets/loading_ribbon_screen.dart';
import 'package:shrine_matching/widgets/root_tab_selection.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shrine_matching/services/app_globals.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    FlutterForegroundTask.initCommunicationPort();

    // 独自のフローティングタブバーを使っているので、Android標準のナビゲーションバー
    // （ホームボタン等）は隠す。ステータスバー（時計・電池など）は残す。
    // 画面端からスワイプすれば一時的に再表示される。
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Firestoreへの初回接続（WebChannelのハンドシェイク）はここで先に済ませておく。
  // 待たずに投げっぱなしにすることで、Home画面を見ている間に裏側で接続確立が進み、
  // 実際に質問を読み込む診断画面に着く頃には通信が速くなっている想定。
  unawaited(FirebaseFirestore.instance.collection('Questions').limit(1).get());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: const Color(0xFFFEFEFE)),
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
          return const LoadingRibbonScreen();
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

class _RootTabsPageState extends State<RootTabsPage>
    with WidgetsBindingObserver {
  static const Color _selectedColor = Color(0xFFDB4713);
  static const double _tabItemWidth = 50;
  static const double _tabItemGap = 6;
  static const double _barHorizontalPadding = 12;
  static const double _barVerticalPadding = 9;
  final BottomBarController _bottomBarController = BottomBarController();

  static const List<String?> _tabAssetIcons = [
    'lib/assets/torii.png',
    'lib/assets/maps.png',
    'lib/assets/ribbon.png',
    null,
  ];

  static const List<IconData> _tabIcons = [
    CupertinoIcons.house_fill,
    CupertinoIcons.map_fill,
    CupertinoIcons.bookmark_fill,
    CupertinoIcons.person_fill,
  ];

  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    _tabIcons.length,
    (_) => GlobalKey<NavigatorState>(),
  );

  Timer? _scrollIdleTimer;
  int _currentIndex = 0;
  int _barShowRequestId = 0;

  void _ensureBottomBarVisibleAfterTabChange({bool forceVisible = false}) {
    if (!mounted) {
      return;
    }

    if (forceVisible) {
      RootBottomBarVisibility.show();
    }

    final int requestId = ++_barShowRequestId;

    void showIfStillRelevant() {
      if (!mounted || requestId != _barShowRequestId) {
        return;
      }
      if (!RootBottomBarVisibility.isVisible.value) {
        return;
      }
      _bottomBarController.show();
    }

    showIfStillRelevant();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showIfStillRelevant();
    });

    // Route pops and tab/body swaps can emit late scroll updates that briefly
    // re-hide the bar. Retry a few times across the transition window.
    for (final int delayMs in <int>[120, 260, 420, 680, 960]) {
      Future<void>.delayed(Duration(milliseconds: delayMs), () {
        showIfStillRelevant();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    RootBottomBarVisibility.isVisible.addListener(
      _handleBottomBarVisibilityChanged,
    );
    RootTabSelection.request.addListener(_handleRootTabSelectionRequested);

    if (!kIsWeb) {
      FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
    }

    _handleBottomBarVisibilityChanged();
    visitPromptService.checkNearbyShrineForVisit();
  }

  void _handleBottomBarVisibilityChanged() {
    if (!mounted) {
      return;
    }
    if (RootBottomBarVisibility.isVisible.value) {
      _ensureBottomBarVisibleAfterTabChange(forceVisible: false);
    } else {
      _bottomBarController.hide();
    }
  }

  void _handleRootTabSelectionRequested() {
    if (!mounted) {
      return;
    }

    final request = RootTabSelection.request.value;
    if (request == null) {
      return;
    }

    final int requestedIndex = request.index;
    if (requestedIndex < 0 || requestedIndex >= _tabIcons.length) {
      return;
    }

    _navigatorKeys[requestedIndex].currentState?.popUntil(
      (route) => route.isFirst,
    );

    if (requestedIndex != _currentIndex) {
      setState(() {
        _currentIndex = requestedIndex;
      });
    }

    _ensureBottomBarVisibleAfterTabChange(forceVisible: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
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

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification ||
        notification is ScrollUpdateNotification ||
        notification is OverscrollNotification) {
      _scrollIdleTimer?.cancel();
    }

    if (notification is ScrollEndNotification) {
      _scrollIdleTimer?.cancel();

      // Bring the floating bar back once scrolling settles.
      _scrollIdleTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted && RootBottomBarVisibility.isVisible.value) {
          _bottomBarController.show();
        }
      });
    }

    return false;
  }

  void _onTabPressed(int index) {
    RootTabSelection.select(index);
  }

  Widget _buildTabIcon(int index, bool isSelected) {
    final assetPath = _tabAssetIcons[index];
    final double size = isSelected ? 24 : 22;

    if (assetPath != null) {
      return Opacity(
        opacity: isSelected ? 1 : 0.62,
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      );
    }

    return Opacity(
      opacity: isSelected ? 1 : 0.62,
      child: Icon(_tabIcons[index], size: size, color: _selectedColor),
    );
  }

  Widget _tabRootPage(int index) {
    switch (index) {
      case 0:
        return const HomePageWidget();
      case 1:
        return const MapPage();
      case 2:
        return const BookmarkPage();
      case 3:
        return const ProfilePage();
      default:
        return const HomePageWidget();
    }
  }

  Widget _buildTabNavigator(int index) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => _tabRootPage(index),
          settings: settings,
        );
      },
    );
  }

  Widget _buildTabBody() {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: IndexedStack(
        index: _currentIndex,
        children: List.generate(_tabIcons.length, _buildTabNavigator),
      ),
    );
  }

  @override
  void dispose() {
    _scrollIdleTimer?.cancel();
    RootBottomBarVisibility.isVisible.removeListener(
      _handleBottomBarVisibilityChanged,
    );
    RootTabSelection.request.removeListener(_handleRootTabSelectionRequested);
    WidgetsBinding.instance.removeObserver(this);

    if (!kIsWeb) {
      FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    }

    RootBottomBarVisibility.show();
    _bottomBarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double floatingBarWidth =
        (_tabIcons.length * _tabItemWidth) +
        ((_tabIcons.length - 1) * _tabItemGap) +
        (_barHorizontalPadding * 2);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        final NavigatorState? currentNavigator =
            _navigatorKeys[_currentIndex].currentState;
        if (currentNavigator != null && currentNavigator.canPop()) {
          currentNavigator.pop();
          return;
        }

        Navigator.of(context).maybePop();
      },
      child: BottomBar(
        controller: _bottomBarController,
        showIcon: false,
        layout: BottomBarLayout(
          width: floatingBarWidth,
          offset: 1,
          borderRadius: BorderRadius.circular(9999),
        ),
        motion: const BottomBarMotion.cupertino(
          preset: BottomBarCupertinoMotion.smooth,
          duration: Duration(milliseconds: 360),
          slideStart: Offset(0, 2.2),
        ),
        scrollBehavior: const BottomBarScrollBehavior(
          hideOnScroll: true,
          reverse: true,
          deltaThreshold: 14,
        ),
        theme: BottomBarThemeData(
          barDecoration: BoxDecoration(
            color: const Color(0xFFFEFBF8),
            borderRadius: BorderRadius.circular(9999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        ),
        body: _buildTabBody(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _barHorizontalPadding,
            vertical: _barVerticalPadding,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_tabIcons.length, (index) {
              final bool isSelected = index == _currentIndex;
              final bool isLast = index == _tabIcons.length - 1;
              return Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : _tabItemGap),
                child: SizedBox(
                  width: _tabItemWidth,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _onTabPressed(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _selectedColor.withValues(alpha: 0.14)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _buildTabIcon(index, isSelected),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
