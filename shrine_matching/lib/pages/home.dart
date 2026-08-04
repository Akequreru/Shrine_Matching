import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shrine_matching/models/shrine.dart';
import 'package:shrine_matching/pages/matching.dart';
import 'package:shrine_matching/pages/shrineInfo.dart';
import 'package:shrine_matching/services/firestore_service.dart';
import 'package:shrine_matching/services/app_globals.dart';
import 'package:shrine_matching/models/crossing.dart';
import 'package:shrine_matching/widgets/root_tab_selection.dart';

// Home画面の「最近すれちがった神社」欄に表示する件数の上限
const int _recentCrossingsLimit = 5;

// すれ違い日時を「8/4 16:00」のような表記にする
String _formatCrossingDateTime(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dt.month}/${dt.day} ${two(dt.hour)}:${two(dt.minute)}';
}

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  State<HomePageWidget> createState() => HomePageWidgetState();
}

class HomePageWidgetState extends State<HomePageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final FirestoreService _firestoreService = FirestoreService();
  List<_ShrineCardData> _matchedShrines = const <_ShrineCardData>[];
  List<_ShrineCardData> _recentShrines = const <_ShrineCardData>[];
  List<_ShrineCardData> _sameTypeShrines = const <_ShrineCardData>[];
  String _sameTypeTitle = '同じ○○タイプの神社';

  @override
  void initState() {
    super.initState();
    RootTabSelection.request.addListener(_handleRootTabSelectionRequested);
    refreshCrossings();
    _loadMatchedShrines();
    _loadRecentCrossings();
    _loadSameTypeShrines();
  }

  @override
  void dispose() {
    RootTabSelection.request.removeListener(_handleRootTabSelectionRequested);
    super.dispose();
  }

  void _handleRootTabSelectionRequested() {
    final request = RootTabSelection.request.value;
    if (request == null || request.index != RootTabSelection.home) {
      return;
    }
    refreshCrossings();
    _loadMatchedShrines();
    _loadRecentCrossings();
    _loadSameTypeShrines();
  }

  // Homeタブに切り替えられるたびに、外部（RootTabsPage）から呼び出せるようにpublicにしてある
  Future<void> refreshCrossings() async {
    // 参拝パネルの処理が進行中なら、それが片付くまで待ってから出す（参拝パネルを優先する）
    await visitPromptService.waitUntilIdle();
    if (!mounted) return;

    try {
      await _loadCrossings();
    } catch (e, stack) {
      debugPrint('すれ違いパネルの表示に失敗しました: $e\n$stack');
    }
  }

  Future<void> _loadCrossings() async {
    final crossings = await _firestoreService.getUnseenCrossings();
    if (!mounted || crossings.isEmpty) return;

    // 表示したら既読にする（次回Home表示時には出てこないようにする）
    await _firestoreService.markCrossingsAsSeen(
      crossings.map((c) => c.id).toList(),
    );

    if (!mounted) return;
    await _showCrossingsPanel(crossings);
  }

  Future<void> _showCrossingsPanel(List<Crossing> crossings) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            height: 420,
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.88),
              itemCount: crossings.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _CrossingCard(
                    crossing: crossings[index],
                    allShrineIds: crossings.map((c) => c.shrineId).toList(),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadMatchedShrines() async {
    try {
      final shrines = await _firestoreService.getMatchedShrinesForCurrentUser();
      if (!mounted) return;

      setState(() {
        _matchedShrines = shrines
            .map(
              (shrine) => _ShrineCardData(
                imageUrl: shrine.images.isNotEmpty
                    ? shrine.images.first
                    : 'https://picsum.photos/seed/${shrine.id}/700/900',
                name: shrine.name,
                location: shrine.address.isNotEmpty ? shrine.address : '住所情報なし',
                shrineId: shrine.id,
                initialShrine: shrine,
              ),
            )
            .toList();
      });
    } catch (e, stack) {
      debugPrint('縁を結んだ神社の読み込みに失敗しました: $e\n$stack');
    }
  }

  Future<void> _loadRecentCrossings() async {
    try {
      final crossings = await _firestoreService.getRecentCrossings(
        limit: _recentCrossingsLimit,
      );
      if (!mounted) return;

      setState(() {
        _recentShrines = crossings
            .map(
              (crossing) => _ShrineCardData(
                imageUrl: crossing.image.isNotEmpty
                    ? crossing.image
                    : 'https://picsum.photos/seed/${crossing.shrineId}/500/500',
                name: crossing.shrineName,
                location: crossing.address.isNotEmpty
                    ? crossing.address
                    : '住所情報なし',
                dateLabel: _formatCrossingDateTime(crossing.crossedAt),
                shrineId: crossing.shrineId,
                initialShrine: _placeholderShrine(
                  id: crossing.shrineId,
                  name: crossing.shrineName,
                  imageUrl: crossing.image,
                  address: crossing.address,
                ),
              ),
            )
            .toList();
      });
    } catch (e, stack) {
      debugPrint('最近すれ違った神社の読み込みに失敗しました: $e\n$stack');
    }
  }

  Future<void> _loadSameTypeShrines() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final user = await _firestoreService.getUserWithHistory(uid);
      if (!mounted) return;

      if (user == null || user.lastType <= 0) {
        setState(() {
          _sameTypeTitle = '同じ○○タイプの神社';
          _sameTypeShrines = const <_ShrineCardData>[];
        });
        return;
      }

      final typeInfo = await _firestoreService.getType(user.lastType);
      final typeName = (typeInfo != null && typeInfo.name.isNotEmpty)
          ? typeInfo.name
          : 'タイプ${user.lastType}';

      final shrines = await _firestoreService.getShrinesWithSameKamiType(
        user.lastType,
      );
      if (!mounted) return;

      setState(() {
        _sameTypeTitle = '同じ$typeNameタイプの神社';
        _sameTypeShrines = shrines
            .map(
              (shrine) => _ShrineCardData(
                imageUrl: shrine.images.isNotEmpty
                    ? shrine.images.first
                    : 'https://picsum.photos/seed/${shrine.id}/700/900',
                name: shrine.name,
                location: shrine.address.isNotEmpty
                    ? shrine.address
                    : '住所情報なし',
                shrineId: shrine.id,
                initialShrine: shrine,
              ),
            )
            .toList();
      });
    } catch (e, stack) {
      debugPrint('同じタイプの神社の読み込みに失敗しました: $e\n$stack');
    }
  }

  static Shrine _placeholderShrine({
    required String id,
    required String name,
    required String imageUrl,
    required String address,
  }) {
    return Shrine(
      id: id,
      name: name,
      images: <String>[imageUrl],
      concept: 'この神社の詳細情報は準備中です。',
      description: 'この神社の説明は準備中です。',
      tags: const <String>[],
      latitude: 0,
      longitude: 0,
      address: address,
      favoriteCount: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFFFEFEFE),
        body: ListView(
          primary: true,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 50, 0, 110),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'ホーム',
                textAlign: TextAlign.center,
                style: GoogleFonts.zenKakuGothicNew(
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _ShrineSection(
              title: 'あなたへが縁を結んだ神社',
              cards: _matchedShrines,
              imageWidth: 220,
              imageHeight: 289,
            ),
            const SizedBox(height: 20),
            _ShrineSection(
              title: '最近すれちがった神社',
              cards: _recentShrines,
              imageWidth: 160,
              imageHeight: 160,
            ),
            const SizedBox(height: 20),
            _ShrineSection(
              title: _sameTypeTitle,
              cards: _sameTypeShrines,
              imageWidth: 160,
              imageHeight: 160,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShrineSection extends StatelessWidget {
  const _ShrineSection({
    required this.title,
    required this.cards,
    required this.imageWidth,
    required this.imageHeight,
  });

  final String title;
  final List<_ShrineCardData> cards;
  final double imageWidth;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.zenOldMincho(
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(cards.length, (index) {
              final card = cards[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == cards.length - 1 ? 20 : 10,
                ),
                child: _ShrineCard(
                  data: card,
                  imageWidth: imageWidth,
                  imageHeight: imageHeight,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _ShrineCard extends StatelessWidget {
  const _ShrineCard({
    required this.data,
    required this.imageWidth,
    required this.imageHeight,
  });

  final _ShrineCardData data;
  final double imageWidth;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ShrineInfoPage(
              shrineId: data.shrineId,
              initialShrine: data.initialShrine,
            ),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              data.imageUrl,
              width: imageWidth,
              height: imageHeight,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: imageWidth,
            child: Text(
              data.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.zenOldMincho(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6D666B),
              ),
            ),
          ),
          SizedBox(
            width: imageWidth,
            child: Text(
              data.location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.zenOldMincho(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFA9A2A7),
              ),
            ),
          ),
          if (data.dateLabel != null)
            SizedBox(
              width: imageWidth,
              child: Text(
                data.dateLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.zenOldMincho(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFA9A2A7),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShrineCardData {
  const _ShrineCardData({
    required this.imageUrl,
    required this.name,
    required this.location,
    required this.shrineId,
    this.dateLabel,
    this.initialShrine,
  });

  final String imageUrl;
  final String name;
  final String location;
  final String shrineId;
  // すれ違った日付など、住所の下にもう1行表示したいときだけ指定する
  final String? dateLabel;
  final Shrine? initialShrine;
}

class _CrossingCard extends StatelessWidget {
  const _CrossingCard({required this.crossing, required this.allShrineIds});

  final Crossing crossing;
  final List<String> allShrineIds;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: crossing.image.isNotEmpty
                ? Image.network(crossing.image, fit: BoxFit.cover)
                : Container(color: Colors.black12),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            crossing.shrineName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (crossing.tags.isNotEmpty)
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: crossing.tags
                                  .map(
                                    (tag) => Chip(
                                      label: Text(
                                        tag,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                      backgroundColor: const Color(0xFFFFF3EC),
                                    ),
                                  )
                                  .toList(),
                            ),
                          const SizedBox(height: 8),
                          if (crossing.address.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.place, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    crossing.address,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_formatCrossingDateTime(crossing.crossedAt)} にすれ違いました',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                        Navigator.of(context).pop(); // パネルを閉じる
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                MatchingPage(shrineIds: allShrineIds),
                          ),
                        );
                      },
                      child: const Text('マッチング画面へ'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
