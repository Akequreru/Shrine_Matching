import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:shrine_matching/pages/home.dart';
import 'package:shrine_matching/pages/profile.dart';
import 'package:shrine_matching/pages/type.dart';
import 'package:shrine_matching/pages/map.dart';
import 'package:shrine_matching/pages/bookmark.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const MyApp(),
    ),
  );
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

class RootTabsPage extends StatelessWidget {
  const RootTabsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.house_fill),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.square_grid_2x2_fill),
            label: 'Type',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.map_fill),
            label: 'Map'
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.bookmark_fill),
            label: 'Bookmark',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_fill),
            label: 'Profile',
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