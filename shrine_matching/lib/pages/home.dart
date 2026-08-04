import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shrine_matching/pages/matching.dart';
import 'package:shrine_matching/services/firestore_service.dart';
import 'package:shrine_matching/services/app_globals.dart';
import 'package:shrine_matching/models/crossing.dart';

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

  @override
  void initState() {
    super.initState();
    refreshCrossings();
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

  final List<_ShrineCardData> _matchedShrines = const [
    _ShrineCardData(
      imageUrl: 'https://picsum.photos/seed/matched_1/700/900',
      name: '〇〇神社',
      location: '京都市〇〇区',
    ),
    _ShrineCardData(
      imageUrl: 'https://picsum.photos/seed/matched_2/700/900',
      name: '〇〇神社',
      location: '京都市〇〇区',
    ),
  ];

  final List<_ShrineCardData> _recentShrines = const [
    _ShrineCardData(
      imageUrl: 'https://picsum.photos/seed/recent_1/500/500',
      name: '〇〇神社',
      location: '京都市〇〇区',
    ),
    _ShrineCardData(
      imageUrl: 'https://picsum.photos/seed/recent_2/500/500',
      name: '〇〇神社',
      location: '京都市〇〇区',
    ),
    _ShrineCardData(
      imageUrl: 'https://picsum.photos/seed/recent_3/500/500',
      name: '〇〇神社',
      location: '京都市〇〇区',
    ),
  ];

  final List<_ShrineCardData> _sameTypeShrines = const [
    _ShrineCardData(
      imageUrl: 'https://picsum.photos/seed/type_1/500/500',
      name: '〇〇神社',
      location: '京都市〇〇区',
    ),
    _ShrineCardData(
      imageUrl: 'https://picsum.photos/seed/type_2/500/500',
      name: '〇〇神社',
      location: '京都市〇〇区',
    ),
    _ShrineCardData(
      imageUrl: 'https://picsum.photos/seed/type_3/500/500',
      name: '〇〇神社',
      location: '京都市〇〇区',
    ),
  ];

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
              title: '同じ○○タイプの神社',
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
    return Column(
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
      ],
    );
  }
}

class _ShrineCardData {
  const _ShrineCardData({
    required this.imageUrl,
    required this.name,
    required this.location,
  });

  final String imageUrl;
  final String name;
  final String location;
}

class _CrossingCard extends StatelessWidget {
  const _CrossingCard({required this.crossing, required this.allShrineIds});

  final Crossing crossing;
  final List<String> allShrineIds;

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.month}/${dt.day} ${two(dt.hour)}:${two(dt.minute)}';
  }

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
                  Text(
                    crossing.shrineName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (crossing.tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: crossing.tags
                          .map((tag) => Chip(
                                label: Text(tag, style: const TextStyle(fontSize: 12)),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                backgroundColor: const Color(0xFFFFF3EC),
                              ))
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
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatDateTime(crossing.crossedAt)} にすれ違いました',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Spacer(),
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
                            builder: (_) => MatchingPage(shrineIds: allShrineIds),
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
