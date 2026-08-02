import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shrine_matching/models/shrine.dart';
import 'package:shrine_matching/survices/firestore_service.dart';

// 参拝ボタンを出す判定に使う「近く」の半径（すれ違い検知と同じ100mに揃えている）
const double _visitRadiusMeters = 100;

// 「今回の滞在中に参拝パネルを出した神社のID」を端末に保存しておくキー。
// 半径外に出たらこれをクリアするので、次にどこかの神社に近づいたときはまた表示される。
const String _lastPromptedShrineIdKey = 'lastPromptedShrineId';

// アプリのどの画面が表示中でも参拝パネルを出せるよう、タブ切り替えやアプリ復帰の
// タイミングで呼び出す共通サービス。表示にはアプリ全体のNavigatorKeyを使う。
class VisitPromptService {
  VisitPromptService(this.navigatorKey);

  final GlobalKey<NavigatorState> navigatorKey;
  final FirestoreService _firestoreService = FirestoreService();

  // ENTER通知によるリアルタイム表示と、タブ切り替え時のポーリングが同時に走って
  // 二重に判定・表示してしまわないよう、実行を1本のキューに直列化する
  Future<void> _queue = Future<void>.value();

  Future<void> _enqueue(Future<void> Function() action) {
    final result = _queue.then((_) => action());
    // 個々の失敗で以後のキューが詰まらないようにしておく
    _queue = result.catchError((_) {});
    return result;
  }

  // 他の処理（Home画面のすれ違いパネルなど）から、参拝パネル関連の処理が
  // 一段落するまで待ちたいときに使う
  Future<void> waitUntilIdle() => _queue;

  Future<void> checkNearbyShrineForVisit() {
    return _enqueue(_checkNearbyShrineForVisit);
  }

  Future<void> _checkNearbyShrineForVisit() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    final shrines = await _firestoreService.getShrines();

    Shrine? nearestShrine;
    double nearestDistance = double.infinity;
    for (final shrine in shrines) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        shrine.latitude,
        shrine.longitude,
      );
      if (distance <= _visitRadiusMeters && distance < nearestDistance) {
        nearestDistance = distance;
        nearestShrine = shrine;
      }
    }

    if (nearestShrine == null) return;

    final prefs = await SharedPreferences.getInstance();
    await _showIfNotAlreadyPrompted(nearestShrine, prefs);
  }

  // バックグラウンドのすれ違い検知（ENTER）からのリアルタイム通知を受けて、
  // 今いる画面（タブ）に関係なくその場でパネルを出す。GPSの再取得は行わない。
  Future<void> showPromptForShrineData({
    required String shrineId,
    required String shrineName,
    required String image,
    required List<String> tags,
    required String address,
  }) {
    return _enqueue(() async {
      final shrine = Shrine(
        id: shrineId,
        name: shrineName,
        images: image.isNotEmpty ? [image] : [],
        concept: '',
        description: '',
        tags: tags,
        latitude: 0,
        longitude: 0,
        address: address,
        favoriteCount: 0,
      );

      final prefs = await SharedPreferences.getInstance();
      await _showIfNotAlreadyPrompted(shrine, prefs);
    });
  }

  // バックグラウンドのすれ違い検知がその神社から離れた（EXIT）ことを検知したら、
  // 「今回の滞在中」の記録を確実にクリアする。こちらを正とし、フォアグラウンド側の
  // GPS測位だけで判定してクリアすることはしない（GPSのブレで意図せず滞在が
  // リセットされ、パネルが再表示されてしまうことがあるため）。
  Future<void> clearPromptedShrine(String shrineId) {
    return _enqueue(() async {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_lastPromptedShrineIdKey) == shrineId) {
        await prefs.remove(_lastPromptedShrineIdKey);
      }
    });
  }

  Future<void> _showIfNotAlreadyPrompted(
    Shrine shrine,
    SharedPreferences prefs,
  ) async {
    // 同じ神社について、今回の滞在中に一度パネルを出していれば
    // （参拝する／参拝しないのどちらを選んでいても）もう出さない
    if (prefs.getString(_lastPromptedShrineIdKey) == shrine.id) {
      return;
    }
    await prefs.setString(_lastPromptedShrineIdKey, shrine.id);

    final context = navigatorKey.currentState?.overlay?.context;
    if (context == null) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => VisitPromptDialog(
        shrine: shrine,
        firestoreService: _firestoreService,
      ),
    );
  }
}

class VisitPromptDialog extends StatefulWidget {
  const VisitPromptDialog({
    super.key,
    required this.shrine,
    required this.firestoreService,
  });

  final Shrine shrine;
  final FirestoreService firestoreService;

  @override
  State<VisitPromptDialog> createState() => _VisitPromptDialogState();
}

class _VisitPromptDialogState extends State<VisitPromptDialog> {
  bool _isSubmitting = false;
  bool _isDone = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.shrine.images.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.network(widget.shrine.images.first, fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.shrine.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('近くにいるようです。参拝しましたか？', textAlign: TextAlign.center),
                const SizedBox(height: 20),
                if (_isDone)
                  const Text('参拝を記録しました', style: TextStyle(color: Colors.green))
                else ...[
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
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              setState(() => _isSubmitting = true);
                              await widget.firestoreService.recordVisit(widget.shrine);
                              if (!mounted) return;
                              setState(() {
                                _isSubmitting = false;
                                _isDone = true;
                              });
                            },
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('参拝する'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('参拝しない'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
