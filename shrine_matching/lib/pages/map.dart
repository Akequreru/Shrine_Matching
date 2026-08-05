import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shrine_matching/services/crossing_task_handler.dart';
import 'package:shrine_matching/services/firestore_service.dart';
import 'package:shrine_matching/models/shrine.dart';
import 'package:shrine_matching/pages/shrineInfo.dart';
import 'package:shrine_matching/widgets/root_tab_selection.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const LatLng _kyotoCenter = LatLng(35.0116, 135.7681);
  static final LatLngBounds _kyotoBounds = LatLngBounds(
    const LatLng(34.90, 135.60), // 南西
    const LatLng(35.15, 135.85), // 北東
  );

  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionSubscription;
  bool _isCrossingServiceRunning = false;
  bool _isTogglingCrossingService = false;

  final FirestoreService _firestoreService = FirestoreService();
  List<Shrine> _shrines = [];
  Set<String> _favoriteShrineIds = {};
  bool _showOnlyFavorites = false;

  @override
  void initState() {
    super.initState();
    RootTabSelection.request.addListener(_handleRootTabSelectionRequested);
    _determinePosition();
    _loadShrines();
    _loadFavorites();
  }

  void _handleRootTabSelectionRequested() {
    final request = RootTabSelection.request.value;
    if (request == null) return;

    // マップタブが選択されるたびに再取得することで、直前に診断・マッチングで
    // 増えたお気に入り（＝ピンの色）をアプリ再起動なしで反映する
    if (request.index == RootTabSelection.map) {
      _loadFavorites();
    }
  }

  Future<void> _loadShrines() async {
    final shrines = await _firestoreService.getShrines();
    if (!mounted) return;
    setState(() {
      _shrines = shrines;
    });
  }

  Future<void> _loadFavorites() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ids = await _firestoreService.getFavoriteShrineIds(uid);
    if (!mounted) return;
    setState(() {
      _favoriteShrineIds = ids.toSet();
    });
  }

  void _showShrineSheet(Shrine shrine) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shrine.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                if (shrine.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: shrine.tags
                        .map((tag) => Chip(
                              label: Text(tag, style: const TextStyle(fontSize: 12)),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              backgroundColor: const Color(0xFFFFF3EC),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDB4713),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ShrineInfoPage(
                            shrineId: shrine.id,
                            initialShrine: shrine,
                          ),
                        ),
                      );
                    },
                    child: const Text('詳細を見る'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _requestForegroundTaskPermissions() async {
    if (kIsWeb) return;

    final notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
    }
  }

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'crossing_service',
        channelName: 'すれ違い検知',
        channelDescription: '神社とのすれ違いをバックグラウンドで検知するために表示されます。',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<void> _toggleCrossingService() async {
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('すれ違い検知はAndroid/iOSのみ対応です')),
      );
      return;
    }

    // 連打などで重複してstart/stopが走らないようにする
    if (_isTogglingCrossingService) return;
    _isTogglingCrossingService = true;

    try {
      if (_isCrossingServiceRunning) {
        await FlutterForegroundTask.stopService();
        setState(() {
          _isCrossingServiceRunning = false;
        });
        return;
      }

      await _requestForegroundTaskPermissions();
      _initForegroundTask();

      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.restartService();
      } else {
        await FlutterForegroundTask.startService(
          serviceId: 1,
          notificationTitle: 'すれ違い検知中',
          notificationText: '神社とのすれ違いを検知しています',
          callback: startCrossingCallback,
        );
      }
      setState(() {
        _isCrossingServiceRunning = true;
      });
    } finally {
      _isTogglingCrossingService = false;
    }
  }

  @override
  void dispose() {
    RootTabSelection.request.removeListener(_handleRootTabSelectionRequested);
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    // ボタンで再試行されたときのために、既存の購読があれば一旦止めてからやり直す
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    // 端末側の位置情報サービス自体がオフなら諦める
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    // アプリへの許可状態を確認し、必要なら許可ダイアログを出す
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return; // 拒否された場合は現在地なしで地図だけ表示する
    }

    // 1回だけでなく、位置が変わるたびに丸の位置を更新し続ける
    _positionSubscription = Geolocator.getPositionStream().listen((position) {
      debugPrint('現在地を取得: ${position.latitude}, ${position.longitude}');
      if (!mounted) return;
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _kyotoCenter,
          initialZoom: 12,
          minZoom: 9,
          maxZoom: 18,
          cameraConstraint: CameraConstraint.contain(bounds: _kyotoBounds),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.shrine_matching',
          ),
          MarkerLayer(
            markers: _shrines
                .where((shrine) =>
                    !_showOnlyFavorites || _favoriteShrineIds.contains(shrine.id))
                .map((shrine) {
              final isFavorite = _favoriteShrineIds.contains(shrine.id);
              return Marker(
                point: LatLng(shrine.latitude, shrine.longitude),
                width: 36,
                height: 36,
                child: GestureDetector(
                  onTap: () => _showShrineSheet(shrine),
                  child: Icon(
                    Icons.location_on,
                    color: isFavorite ? const Color(0xFFDB4713) : Colors.blue,
                    size: 36,
                  ),
                ),
              );
            }).toList(),
          ),
          if (_currentLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentLocation!,
                  width: 24,
                  height: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 50),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'crossingToggle',
              backgroundColor: _isCrossingServiceRunning
                  ? const Color(0xFFDB4713)
                  : null,
              onPressed: _toggleCrossingService,
              tooltip: _isCrossingServiceRunning ? 'すれ違い検知を停止' : 'すれ違い検知を開始',
              child: Icon(
                _isCrossingServiceRunning
                    ? Icons.notifications_active
                    : Icons.notifications_off_outlined,
              ),
            ),
            const SizedBox(height: 12),
            FloatingActionButton(
              heroTag: 'myLocation',
              onPressed: _determinePosition,
              child: const Icon(Icons.my_location),
            ),
          ],
        ),
      ),
    );
  }
}
