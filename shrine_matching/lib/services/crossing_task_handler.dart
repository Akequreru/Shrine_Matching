import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geofencing_api/geofencing_api.dart';
import 'package:shrine_matching/firebase_options.dart';

// バックグラウンドサービスを開始するときに呼ばれるコールバック。
// 必ずトップレベル関数（クラスの外）にする必要がある。
@pragma('vm:entry-point')
void startCrossingCallback() {
  FlutterForegroundTask.setTaskHandler(CrossingTaskHandler());
}

// すれ違い検知の本体。ここはアプリ本体とは別のアイソレートで動くので、
// Firebaseなどアプリ側で初期化済みのものも、ここでは自前で初期化し直す必要がある。
class CrossingTaskHandler extends TaskHandler {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // ignore: avoid_print
    print('CrossingTaskHandler: onStart 開始');
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // ignore: avoid_print
      print('CrossingTaskHandler: Firebase初期化 完了');

      await _initNotifications();
      // ignore: avoid_print
      print('CrossingTaskHandler: 通知初期化 完了');

      final regions = await _buildRegionsFromShrines();
      // ignore: avoid_print
      print('CrossingTaskHandler: ジオフェンス${regions.length}件を構築');

      // onStartが複数回呼ばれても（サービス再起動やボタン連打など）リスナーが
      // 二重登録されないよう、まず既存のものを外してから登録し直す
      Geofencing.instance.removeGeofenceStatusChangedListener(_onGeofenceStatusChanged);
      Geofencing.instance.removeGeofenceErrorCallbackListener(_onGeofenceError);
      Geofencing.instance.addGeofenceStatusChangedListener(_onGeofenceStatusChanged);
      Geofencing.instance.addGeofenceErrorCallbackListener(_onGeofenceError);

      if (Geofencing.instance.isRunningService) {
        // 既に起動中だった場合は、リージョンの内容だけ最新に入れ替える
        Geofencing.instance.clearAllRegions();
        Geofencing.instance.addRegions(regions);
        // ignore: avoid_print
        print('CrossingTaskHandler: 既に起動中だったためリージョンのみ更新');
      } else {
        Geofencing.instance.setup(
          interval: 5000,
          accuracy: 100,
          statusChangeDelay: 10000,
          // エミュレータで手動セットした位置情報でも検知できるようにする。
          // 本番配布時はfalseにするのが望ましい（なりすまし位置情報を弾くため）。
          allowsMockLocation: true,
          printsDebugLog: true,
        );
        await Geofencing.instance.start(regions: regions);
        // ignore: avoid_print
        print('CrossingTaskHandler: Geofencing起動 完了');
      }
    } catch (e, stack) {
      // ignore: avoid_print
      print('CrossingTaskHandler: onStartでエラー発生 $e\n$stack');
    }
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);
  }

  // Shrinesコレクションから神社ごとのジオフェンス（円形・半径100m）を組み立てる。
  // Home画面のパネル表示で使う画像・タグ・住所もこの時点でdataに含めておき、
  // すれ違い記録に余計なFirestore読み込みなしでそのまま保存できるようにする。
  Future<Set<GeofenceRegion>> _buildRegionsFromShrines() async {
    final snapshot = await FirebaseFirestore.instance.collection('Shrines').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final images = List<String>.from(data['images'] ?? []);
      return GeofenceRegion.circular(
        id: doc.id,
        data: {
          'name': data['name'] ?? '',
          'image': images.isNotEmpty ? images.first : '',
          'tags': List<String>.from(data['tags'] ?? []),
          'address': data['address'] ?? '',
        },
        center: LatLng(
          (data['latitude'] ?? 0.0).toDouble(),
          (data['longitude'] ?? 0.0).toDouble(),
        ),
        radius: 100,
      );
    }).toSet();
  }

  Future<void> _onGeofenceStatusChanged(
    GeofenceRegion geofenceRegion,
    GeofenceStatus geofenceStatus,
    Location location,
  ) async {
    final shrineData = geofenceRegion.data as Map? ?? {};
    final shrineName = shrineData['name'] as String? ?? '神社';
    // ignore: avoid_print
    print('CrossingTaskHandler: $shrineName の状態が $geofenceStatus に変化');

    if (geofenceStatus == GeofenceStatus.enter) {
      await _showNotification(
        id: geofenceRegion.id.hashCode,
        title: '$shrineNameが近くにあります',
        body: 'すれ違うとホーム画面に記録されます',
      );

      // アプリが開いていれば、タブに関係なくその場で参拝パネルを出せるように
      // メイン側（UIアイソレート）へリアルタイムで知らせる
      FlutterForegroundTask.sendDataToMain({
        'type': 'nearbyShrineEnter',
        'shrineId': geofenceRegion.id,
        'shrineName': shrineName,
        'image': shrineData['image'] as String? ?? '',
        'tags': List<String>.from(shrineData['tags'] ?? []),
        'address': shrineData['address'] as String? ?? '',
      });
    } else if (geofenceStatus == GeofenceStatus.exit) {
      // 神社から離れた＝滞在は終わったので、参拝パネルの「出した記録」をクリアする
      FlutterForegroundTask.sendDataToMain({
        'type': 'nearbyShrineExit',
        'shrineId': geofenceRegion.id,
      });

      // 参拝済みなら、このEXITはすれ違いとして記録しない
      if (await _consumeVisitSuppression(geofenceRegion.id)) {
        // ignore: avoid_print
        print('CrossingTaskHandler: $shrineName は参拝済みのためすれ違い記録をスキップ');
        return;
      }

      await _showNotification(
        id: geofenceRegion.id.hashCode + 1,
        title: '$shrineNameとすれ違いました',
        body: 'ホーム画面で確認できます',
      );
      await _recordCrossing(
        shrineId: geofenceRegion.id,
        shrineName: shrineName,
        image: shrineData['image'] as String? ?? '',
        tags: List<String>.from(shrineData['tags'] ?? []),
        address: shrineData['address'] as String? ?? '',
      );
    }
  }

  // 参拝済みの印が付いていれば消費してtrueを返す（以後は通常通りすれ違い判定する）
  Future<bool> _consumeVisitSuppression(String shrineId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final ref = FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('PendingVisitSuppressions')
        .doc(shrineId);

    final doc = await ref.get();
    if (!doc.exists) return false;

    await ref.delete();
    return true;
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'crossing_alerts',
      'すれ違いお知らせ',
      channelDescription: '神社とのすれ違いを知らせる通知です。',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(id, title, body, details);
  }

  // Users/{uid}/Crossingsに記録する。Home画面はseen==falseのものを表示する想定
  Future<void> _recordCrossing({
    required String shrineId,
    required String shrineName,
    required String image,
    required List<String> tags,
    required String address,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return; // ログインしていなければ記録しない

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('Crossings')
        .add({
      'shrineId': shrineId,
      'shrineName': shrineName,
      'image': image,
      'tags': tags,
      'address': address,
      'crossedAt': FieldValue.serverTimestamp(),
      'seen': false,
    });
  }

  void _onGeofenceError(Object error, StackTrace stackTrace) {
    // ignore: avoid_print
    print('CrossingTaskHandler geofence error: $error\n$stackTrace');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    Geofencing.instance.removeGeofenceStatusChangedListener(_onGeofenceStatusChanged);
    Geofencing.instance.removeGeofenceErrorCallbackListener(_onGeofenceError);
    Geofencing.instance.clearAllListeners();
    await Geofencing.instance.stop();
  }

  @override
  void onReceiveData(Object data) {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationDismissed() {}
}
