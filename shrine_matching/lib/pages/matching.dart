import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shrine_matching/models/shrine.dart';
import 'package:shrine_matching/pages/matching_complete.dart';
import 'package:shrine_matching/pages/shrineInfo.dart';
import 'package:shrine_matching/services/firestore_service.dart';
import 'package:shrine_matching/widgets/bottom_bar_visibility.dart';
import 'package:shrine_matching/widgets/loading_ribbon_screen.dart';

class MatchingPage extends StatelessWidget {
  const MatchingPage({super.key, this.typeId, this.shrineIds});

  // 診断結果のタイプID（未診断で開かれた場合はnull＝全件表示）
  final int? typeId;

  // すれ違いパネルから開かれたときだけ指定される。指定時はこの神社たちを順番に表示する
  final List<String>? shrineIds;

  @override
  Widget build(BuildContext context) {
    return MatchingPageWidget(typeId: typeId, shrineIds: shrineIds);
  }
}

class MatchingPageWidget extends StatefulWidget {
  const MatchingPageWidget({super.key, this.typeId, this.shrineIds});

  final int? typeId;
  final List<String>? shrineIds;

  static String routeName = 'MatchingPage';
  static String routePath = '/matchingPage';

  @override
  State<MatchingPageWidget> createState() => _MatchingPageWidgetState();
}

enum _CardSwipeIntent { none, yes, no }

class _MatchingPageWidgetState extends State<MatchingPageWidget> {
  static const List<String> _placeholderImages = <String>[
    'https://picsum.photos/seed/199/900/700',
    'https://picsum.photos/seed/134/900/700',
    'https://picsum.photos/seed/43/900/700',
  ];
  static const List<String> _placeholderTags = <String>['#開運'];
  static const String _placeholderName = '○○神社';
  static const String _placeholderSaijin = '祭神';
  static const String _placeholderAddress = '京都市上京区京都市上京区染殿町680';
  static const String _placeholderConcept =
      '常に前進を楽しむ「○○タイプ」のあなたには、勝負の神様を祀るこの神社の力強い気がぴったりです。';

  static const Color _yellowTypeColor = Color(0xFFF1BC1F);
  static const Color _greenTypeColor = Color(0xFF5D8634);
  static const Color _blueTypeColor = Color(0xFF5095BF);
  static const Color _purpleTypeColor = Color(0xFF906BAC);

  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = true;
  bool _hadAnyMatches = false;
  List<_MatchingCardData> _cards = <_MatchingCardData>[];

  @override
  void initState() {
    super.initState();
    RootBottomBarVisibility.hide();
    _loadMatches();
  }

  @override
  void dispose() {
    RootBottomBarVisibility.show();
    super.dispose();
  }

  Future<void> _loadMatches() async {
    final shrines = await _firestoreService.getShrinesWithKami();
    List<_MatchingCardData> cards;
    if (widget.shrineIds != null) {
      // すれ違い経由のときは、受け取った順番のまま表示する
      final shrineById = {for (final shrine in shrines) shrine.id: shrine};
      cards = widget.shrineIds!
          .map((id) => shrineById[id])
          .whereType<Shrine>()
          .map(_toCardData)
          .toList();
    } else {
      final matched = shrines.where((shrine) {
        if (widget.typeId == null) return true;
        return shrine.kami.any((k) => k.matchTypes.contains(widget.typeId));
      });
      cards = matched.map(_toCardData).toList();
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _cards = cards;
      _hadAnyMatches = _cards.isNotEmpty;
      _isLoading = false;
    });
  }

  _MatchingCardData _toCardData(Shrine shrine) {
    final deityNames = shrine.kami
        .map((kami) => kami.name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    final imageUrls = shrine.images
        .map((image) => image.trim())
        .where((image) => image.isNotEmpty)
        .toList();
    final normalizedTags = shrine.tags
        .map(_normalizeTag)
        .where((tag) => tag.isNotEmpty)
        .toList();

    return _MatchingCardData(
      shrine: shrine,
      id: shrine.id,
      name: _hasText(shrine.name) ? shrine.name : _placeholderName,
      saijin: deityNames.isNotEmpty ? deityNames.join('・') : _placeholderSaijin,
      address: _hasText(shrine.address) ? shrine.address : _placeholderAddress,
      concept: _hasText(shrine.concept) ? shrine.concept : _placeholderConcept,
      images: imageUrls.isNotEmpty ? imageUrls : _placeholderImages,
      tags: normalizedTags.isNotEmpty ? normalizedTags : _placeholderTags,
      accentColor: _resolveAccentColorForShrine(shrine),
    );
  }

  final Set<String> _favoriteShrineIds = <String>{};
  int _swipeCycle = 0;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  bool _isAnimatingOut = false;
  bool _isNavigatingResult = false;
  String? _lastShrineImageUrl;

  void _removeFrontCard() {
    if (_cards.isEmpty) {
      return;
    }

    if (_cards.first.images.isNotEmpty) {
      _lastShrineImageUrl = _cards.first.images.first;
    }
    _cards.removeAt(0);
    _swipeCycle++;
  }

  void _favoriteFrontCard() {
    if (_cards.isEmpty) {
      return;
    }
    _favoriteShrineIds.add(_cards.first.id);
  }

  Future<void> _saveFavoritesIfNeeded() async {
    if (_favoriteShrineIds.isEmpty) {
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }
    await _firestoreService.addFavoriteShrines(
      uid,
      _favoriteShrineIds.toList(),
    );
  }

  Future<void> _showResultAfterLastSwipe() async {
    if (_isNavigatingResult) {
      return;
    }

    _isNavigatingResult = true;
    await _saveFavoritesIfNeeded();

    if (!mounted) {
      return;
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MatchCompletePage(shrineImageUrl: _lastShrineImageUrl),
      ),
    );
  }

  void _animateSwipeOut({required bool toRight, required double cardWidth}) {
    if (_isAnimatingOut) {
      return;
    }

    if (toRight) {
      _favoriteFrontCard();
    }

    final double targetX = toRight ? cardWidth * 1.5 : -cardWidth * 1.5;
    setState(() {
      _isDragging = false;
      _isAnimatingOut = true;
      _dragOffset = Offset(targetX, _dragOffset.dy * 0.2);
    });

    Future<void>.delayed(const Duration(milliseconds: 220), () async {
      if (!mounted) {
        return;
      }
      setState(() {
        _removeFrontCard();
        _isDragging = false;
        _dragOffset = Offset.zero;
        _isAnimatingOut = false;
      });
      if (_cards.isEmpty) {
        if (widget.shrineIds != null) {
          await _saveFavoritesIfNeeded();
          _returnToHomeWhenFinished();
        } else {
          await _showResultAfterLastSwipe();
        }
      }
    });
  }

  // 最後まで見終わったら、少し間を置いてHome画面（タブのルート）まで戻る
  void _returnToHomeWhenFinished() {
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  void _onCardPanEnd(DragEndDetails details, double cardWidth) {
    final double velocityX = details.velocity.pixelsPerSecond.dx;
    final bool shouldDismiss =
        _dragOffset.dx.abs() > cardWidth * 0.23 || velocityX.abs() > 700;

    if (shouldDismiss) {
      final bool toRight = (_dragOffset.dx + (velocityX * 0.18)) >= 0;
      _animateSwipeOut(toRight: toRight, cardWidth: cardWidth);
      return;
    }

    setState(() {
      _isDragging = false;
      _dragOffset = Offset.zero;
    });
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  String _normalizeTag(String tag) {
    final trimmed = tag.trim();
    if (!_hasText(trimmed)) {
      return '';
    }
    return trimmed.startsWith('#') ? trimmed : '#$trimmed';
  }

  Color _colorByTypeId(int? typeId) {
    if (typeId == null || typeId <= 0) {
      return _greenTypeColor;
    }

    if (<int>{13, 15, 5, 7}.contains(typeId)) {
      return _yellowTypeColor;
    }
    if (<int>{10, 14, 2, 6}.contains(typeId)) {
      return _greenTypeColor;
    }
    if (<int>{12, 16, 4, 8}.contains(typeId)) {
      return _blueTypeColor;
    }
    if (<int>{9, 11, 1, 3}.contains(typeId)) {
      return _purpleTypeColor;
    }
    return _greenTypeColor;
  }

  Color _resolveAccentColorForShrine(Shrine shrine) {
    int? matchedDeityTypeId;

    if (widget.typeId != null && widget.typeId! > 0) {
      for (final kami in shrine.kami) {
        if (kami.matchTypes.contains(widget.typeId) && kami.type > 0) {
          matchedDeityTypeId = kami.type;
          break;
        }
      }
    }

    if (matchedDeityTypeId == null) {
      for (final kami in shrine.kami) {
        if (kami.type > 0) {
          matchedDeityTypeId = kami.type;
          break;
        }
      }
    }

    return _colorByTypeId(matchedDeityTypeId);
  }

  void _openShrineInfo(_MatchingCardData card) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ShrineInfoPage(shrineId: card.id, initialShrine: card.shrine),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingRibbonScreen();
    }

    if (_cards.isEmpty) {
      if (_hadAnyMatches && _isNavigatingResult) {
        return const LoadingRibbonScreen();
      }

      return Scaffold(
        backgroundColor: const Color(0xFFFEFEFE),
        body: Center(
          child: Text(_hadAnyMatches ? 'すべての神社を見終わりました' : '相性の良い神社が見つかりませんでした'),
        ),
      );
    }

    final _MatchingCardData frontCard = _cards.first;
    final _MatchingCardData? backCard = _cards.length > 1 ? _cards[1] : null;

    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFE),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      RootBottomBarVisibility.show();
                      Navigator.of(context).maybePop();
                    },
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.black,
                  ),
                  Expanded(
                    child: Text(
                      'おすすめ',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.zenKakuGothicNew(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double cardWidth = constraints.maxWidth * 0.94;
                    final double cardHeight = constraints.maxHeight * 0.90;
                    final double dragProgress =
                        (_dragOffset.dx.abs() / cardWidth).clamp(0.0, 1.0);
                    final double rotation = (_dragOffset.dx / cardWidth) * 0.22;
                    final _CardSwipeIntent swipeIntent = _dragOffset.dx > 0
                        ? _CardSwipeIntent.yes
                        : _dragOffset.dx < 0
                        ? _CardSwipeIntent.no
                        : _CardSwipeIntent.none;
                    final double overlayProgress =
                        (_dragOffset.dx.abs() / (cardWidth * 0.26)).clamp(
                          0.0,
                          1.0,
                        );

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        if (backCard != null)
                          Transform.translate(
                            offset: Offset(0, 16 - (10 * dragProgress)),
                            child: Transform.scale(
                              scale: 0.94 + (0.04 * dragProgress),
                              child: Opacity(
                                opacity: 0.62 + (0.23 * dragProgress),
                                child: SizedBox(
                                  width: cardWidth,
                                  height: cardHeight,
                                  child: _MatchingCard(
                                    card: backCard,
                                    onOpenBasicInfo: () =>
                                        _openShrineInfo(backCard),
                                    swipeIntent: _CardSwipeIntent.none,
                                    overlayProgress: 0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        GestureDetector(
                          onPanStart: (_) {
                            if (_isAnimatingOut) {
                              return;
                            }
                            setState(() {
                              _isDragging = true;
                            });
                          },
                          onPanUpdate: (details) {
                            if (_isAnimatingOut) {
                              return;
                            }
                            setState(() {
                              _dragOffset = Offset(
                                _dragOffset.dx + details.delta.dx,
                                (_dragOffset.dy + details.delta.dy)
                                    .clamp(-120.0, 120.0)
                                    .toDouble(),
                              );
                            });
                          },
                          onPanEnd: (details) =>
                              _onCardPanEnd(details, cardWidth),
                          child: AnimatedContainer(
                            key: ValueKey('front_transform_$_swipeCycle'),
                            duration: Duration(
                              milliseconds: _isDragging ? 0 : 220,
                            ),
                            curve: Curves.easeOutCubic,
                            transform: Matrix4.identity()
                              ..translateByDouble(
                                _dragOffset.dx,
                                _dragOffset.dy,
                                0,
                                1,
                              )
                              ..rotateZ(rotation),
                            transformAlignment: Alignment.topCenter,
                            child: SizedBox(
                              width: cardWidth,
                              height: cardHeight,
                              child: _MatchingCard(
                                key: ValueKey('${frontCard.name}_$_swipeCycle'),
                                card: frontCard,
                                onOpenBasicInfo: () =>
                                    _openShrineInfo(frontCard),
                                swipeIntent: swipeIntent,
                                overlayProgress: overlayProgress,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchingCard extends StatelessWidget {
  const _MatchingCard({
    super.key,
    required this.card,
    required this.onOpenBasicInfo,
    this.swipeIntent = _CardSwipeIntent.none,
    this.overlayProgress = 0,
  });

  static const String _yesRibbonAssetPath = 'lib/assets/loading_ribbon.png';

  final _MatchingCardData card;
  final VoidCallback onOpenBasicInfo;
  final _CardSwipeIntent swipeIntent;
  final double overlayProgress;

  @override
  Widget build(BuildContext context) {
    final visibleTags = card.tags.take(6).toList();
    final double clampedOverlayProgress = overlayProgress.clamp(0.0, 1.0);

    return Card(
      elevation: 0.5,
      clipBehavior: Clip.antiAlias,
      color: const Color(0xFFFEFEFE),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE6E3DE)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.zenOldMincho(
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    color: card.accentColor,
                    height: 1.06,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '祭神 ${card.saijin}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.zenOldMincho(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: card.accentColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      card.images.first,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFE9E9E9),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.black45,
                            size: 38,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        card.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.zenKakuGothicNew(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black54,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFF7A767B),
                      size: 30,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  card.concept,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.zenOldMincho(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: visibleTags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: card.accentColor.withValues(alpha: 0.45),
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.zenKakuGothicNew(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: card.accentColor,
                          height: 1.2,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.center,
                  child: OutlinedButton(
                    onPressed: onOpenBasicInfo,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7A767B),
                      side: BorderSide(
                        color: card.accentColor.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      textStyle: GoogleFonts.zenKakuGothicNew(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('基本情報を見る'),
                        SizedBox(width: 2),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (swipeIntent != _CardSwipeIntent.none)
            Positioned.fill(
              child: IgnorePointer(
                child: swipeIntent == _CardSwipeIntent.yes
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            color: Colors.white.withValues(
                              alpha: 0.14 + (0.24 * clampedOverlayProgress),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Opacity(
                              opacity: 0.3 + (0.7 * clampedOverlayProgress),
                              child: Image.asset(
                                _yesRibbonAssetPath,
                                fit: BoxFit.fitWidth,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        color: const Color(0xFF5E5E5E).withValues(
                          alpha: 0.18 + (0.52 * clampedOverlayProgress),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MatchingCardData {
  const _MatchingCardData({
    required this.shrine,
    required this.id,
    required this.name,
    required this.saijin,
    required this.address,
    required this.concept,
    required this.images,
    required this.tags,
    required this.accentColor,
  });

  final Shrine shrine;
  final String id;
  final String name;
  final String saijin;
  final String address;
  final String concept;
  final List<String> images;
  final List<String> tags;
  final Color accentColor;
}
