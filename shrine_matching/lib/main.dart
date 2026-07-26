import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:shrine_matching/pages/home.dart';
<<<<<<< HEAD
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const MyApp(), // Wrap your app
    ),
  );
=======
import 'package:shrine_matching/pages/profile.dart';
import 'package:shrine_matching/pages/type.dart';
import 'package:shrine_matching/pages/map.dart';
import 'package:shrine_matching/pages/bookmark.dart';

void main() {
  runApp(DevicePreview(enabled: true, builder: (context) => const MyApp()));
>>>>>>> origin
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RootTabsPage(),
    );
  }
}
<<<<<<< HEAD
=======

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
>>>>>>> origin
