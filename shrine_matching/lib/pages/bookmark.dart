import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shrine_matching/models/shrine.dart';
import 'package:shrine_matching/pages/shrineInfo.dart';
import 'package:shrine_matching/services/firestore_service.dart';
import 'package:shrine_matching/widgets/root_tab_selection.dart';
import 'package:shrine_matching/widgets/loading_ribbon_screen.dart';

class BookmarkPage extends StatelessWidget {
  const BookmarkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BookmarkPageWidget();
  }
}

class BookmarkPageWidget extends StatefulWidget {
  const BookmarkPageWidget({super.key});

  static String routeName = 'BookmarkPage';
  static String routePath = '/bookmarkPage';

  @override
  State<BookmarkPageWidget> createState() => _BookmarkPageWidgetState();
}

class _BookmarkPageWidgetState extends State<BookmarkPageWidget> {
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = true;
  List<Shrine> _shrines = <Shrine>[];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    RootTabSelection.request.addListener(_handleRootTabSelectionRequested);
    _loadMatchedShrines();
  }

  @override
  void dispose() {
    RootTabSelection.request.removeListener(_handleRootTabSelectionRequested);
    super.dispose();
  }

  void _handleRootTabSelectionRequested() {
    final request = RootTabSelection.request.value;
    if (request == null || request.index != RootTabSelection.bookmark) {
      return;
    }
    _loadMatchedShrines();
  }

  Future<void> _loadMatchedShrines() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final shrines = await _firestoreService.getMatchedShrinesForCurrentUser();

      if (!mounted) return;
      setState(() {
        _shrines = shrines;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _shrines = <Shrine>[];
        _isLoading = false;
        _errorMessage = '縁を結んだ神社の読み込みに失敗しました';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingRibbonScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFE),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Text(
                '縁を結んだ神社',
                textAlign: TextAlign.center,
                style: GoogleFonts.zenKakuGothicNew(
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.zenOldMincho(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadMatchedShrines,
                              child: Text(
                                '再読み込み',
                                style: GoogleFonts.zenOldMincho(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _shrines.isEmpty
                  ? Center(
                      child: Text(
                        'まだ縁を結んだ神社がありません',
                        style: GoogleFonts.zenOldMincho(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: _shrines.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final shrine = _shrines[index];
                        final imageUrl = shrine.images.isNotEmpty
                            ? shrine.images.first
                            : 'https://picsum.photos/seed/${shrine.id}/600';
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ShrineInfoPage(
                                  shrineId: shrine.id,
                                  initialShrine: shrine,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F7F7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrl,
                                    width: 110,
                                    height: 110,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        shrine.name,
                                        style: GoogleFonts.zenOldMincho(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF2D2D2D),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        shrine.concept,
                                        style: GoogleFonts.zenOldMincho(
                                          fontSize: 14,
                                          color: const Color(0xFF6D666B),
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
