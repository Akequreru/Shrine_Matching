import 'package:flutter/material.dart';
import 'package:shrine_matching/pages/diagnote.dart';
import 'package:shrine_matching/pages/matching.dart';
import 'package:shrine_matching/survices/firestore_service.dart';
import 'package:shrine_matching/survices/app_globals.dart';
import 'package:shrine_matching/models/crossing.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Shrine Matching',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      'https://picsum.photos/seed/306/600',
                      width: 300,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Simple app description\nYour concept copy can go here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDB4713),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DiagnosticScreen()),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text('Find my shrine type'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CrossingCard extends StatelessWidget {
  const _CrossingCard({required this.crossing, required this.allShrineIds});

  final Crossing crossing;
  final List<String> allShrineIds;

  String _formatDateTime(DateTime dt) {
    final two = (int n) => n.toString().padLeft(2, '0');
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
