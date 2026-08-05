import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shrine_matching/widgets/bottom_bar_visibility.dart';
import 'package:shrine_matching/widgets/root_tab_selection.dart';

class MatchCompletePage extends StatefulWidget {
  const MatchCompletePage({super.key, this.userImageUrl, this.shrineImageUrl});

  final String? userImageUrl;
  final String? shrineImageUrl;

  @override
  State<MatchCompletePage> createState() => _MatchCompletePageState();
}

class _MatchCompletePageState extends State<MatchCompletePage> {
  static const Color _accentColor = Color(0xFFDB4713);
  static const String _ribbonAssetPath = 'lib/assets/loading_ribbon.png';
  static const String _fallbackShrineImage =
      'https://picsum.photos/seed/matched_shrine/300/300';

  @override
  void initState() {
    super.initState();
    RootBottomBarVisibility.hide();
  }

  @override
  void dispose() {
    RootBottomBarVisibility.show();
    super.dispose();
  }

  void _goToRootTabWithRefresh(int tabIndex) {
    RootBottomBarVisibility.show();
    RootTabSelection.select(tabIndex);
    Navigator.of(context).popUntil((route) => route.isFirst);

    // Re-request after the route pop animation so visibility recovery does not
    // depend on scroll events from the destination page.
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      RootBottomBarVisibility.show();
      RootTabSelection.select(tabIndex);
    });
  }

  void _openBookmarkPage() {
    _goToRootTabWithRefresh(RootTabSelection.bookmark);
  }

  void _closeToHomePage() {
    _goToRootTabWithRefresh(RootTabSelection.home);
  }

  @override
  Widget build(BuildContext context) {
    final String shrineImageUrl =
        widget.shrineImageUrl?.trim().isNotEmpty == true
        ? widget.shrineImageUrl!.trim()
        : _fallbackShrineImage;

    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFE),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            const _DoubleAccentLine(accentColor: _accentColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    Text(
                      '縁が結ばれました！',
                      style: GoogleFonts.zenOldMincho(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF28262B),
                      ),
                    ),
                    const SizedBox(height: 48),
                    _ConnectionVisual(
                      ribbonAssetPath: _ribbonAssetPath,
                      userImageUrl: widget.userImageUrl,
                      shrineImageUrl: shrineImageUrl,
                    ),
                    const SizedBox(height: 44),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                            textStyle: GoogleFonts.zenKakuGothicNew(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onPressed: _openBookmarkPage,
                          child: const Text('神社を見る'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 160,
                      height: 40,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB4AEB3),
                          side: const BorderSide(color: Color(0xFFC6C2C7)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          textStyle: GoogleFonts.zenKakuGothicNew(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onPressed: _closeToHomePage,
                        child: const Text('閉じる'),
                      ),
                    ),
                    const Spacer(flex: 4),
                  ],
                ),
              ),
            ),
            const _DoubleAccentLine(accentColor: _accentColor),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _ConnectionVisual extends StatelessWidget {
  const _ConnectionVisual({
    required this.ribbonAssetPath,
    required this.userImageUrl,
    required this.shrineImageUrl,
  });

  final String ribbonAssetPath;
  final String? userImageUrl;
  final String shrineImageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ProfileCircle(imageUrl: userImageUrl),
              const SizedBox(height: 8),
              Text(
                'あなた',
                style: GoogleFonts.zenOldMincho(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7E7780),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Image.asset(
                ribbonAssetPath,
                fit: BoxFit.fitWidth,
                height: 30,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ShrineCircle(imageUrl: shrineImageUrl),
              const SizedBox(height: 6),
              Text(
                '神社',
                style: GoogleFonts.zenOldMincho(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7E7780),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileCircle extends StatelessWidget {
  const _ProfileCircle({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final String? trimmed = imageUrl?.trim();

    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFC9C5CA)),
        color: Colors.white,
      ),
      clipBehavior: Clip.antiAlias,
      child: trimmed == null || trimmed.isEmpty
          ? const Icon(Icons.person_outline_rounded, color: Color(0xFFC9C5CA))
          : Image.network(
              trimmed,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFFC9C5CA),
                );
              },
            ),
    );
  }
}

class _ShrineCircle extends StatelessWidget {
  const _ShrineCircle({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFC9C5CA)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(0xFFE8E8E8),
            alignment: Alignment.center,
            child: const Icon(
              Icons.broken_image_outlined,
              color: Colors.black45,
            ),
          );
        },
      ),
    );
  }
}

class _DoubleAccentLine extends StatelessWidget {
  const _DoubleAccentLine({required this.accentColor});

  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(height: 1, width: double.infinity, color: accentColor),
        const SizedBox(height: 12),
        Container(height: 1, width: double.infinity, color: accentColor),
      ],
    );
  }
}
