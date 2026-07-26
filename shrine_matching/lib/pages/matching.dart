import 'package:flutter/material.dart';

class MatchingPage extends StatelessWidget {
  const MatchingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MatchingPageWidget();
  }
}

class MatchingPageWidget extends StatefulWidget {
  const MatchingPageWidget({super.key});

  static String routeName = 'MatchingPage';
  static String routePath = '/matchingPage';

  @override
  State<MatchingPageWidget> createState() => _MatchingPageWidgetState();
}

class _MatchingPageWidgetState extends State<MatchingPageWidget> {
  final List<_MatchingCardData> _cards = <_MatchingCardData>[
    const _MatchingCardData(
      name: 'Kitsune Shrine',
      description: 'Energetic and curious. A match for adventurous days.',
      images: [
        'https://picsum.photos/seed/match1a/900/600',
        'https://picsum.photos/seed/match1b/900/600',
        'https://picsum.photos/seed/match1c/900/600',
      ],
    ),
    const _MatchingCardData(
      name: 'Forest Shrine',
      description: 'Calm and grounded. Best for reflective moments.',
      images: [
        'https://picsum.photos/seed/match2a/900/600',
        'https://picsum.photos/seed/match2b/900/600',
        'https://picsum.photos/seed/match2c/900/600',
      ],
    ),
    const _MatchingCardData(
      name: 'Ocean Shrine',
      description: 'Open and intuitive. A great fit for fresh starts.',
      images: [
        'https://picsum.photos/seed/match3a/900/600',
        'https://picsum.photos/seed/match3b/900/600',
        'https://picsum.photos/seed/match3c/900/600',
      ],
    ),
  ];

  final Map<String, int> _imageIndexByCard = <String, int>{};
  int _swipeCycle = 0;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  bool _isAnimatingOut = false;

  void _moveFrontCardToBack() {
    if (_cards.isEmpty) {
      return;
    }

    final _MatchingCardData moved = _cards.removeAt(0);
    _cards.add(moved);
    _swipeCycle++;
  }

  void _animateSwipeOut({required bool toRight, required double cardWidth}) {
    if (_isAnimatingOut) {
      return;
    }

    final double targetX = toRight ? cardWidth * 1.5 : -cardWidth * 1.5;
    setState(() {
      _isDragging = false;
      _isAnimatingOut = true;
      _dragOffset = Offset(targetX, _dragOffset.dy * 0.2);
    });

    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _moveFrontCardToBack();
        _isDragging = false;
        _dragOffset = Offset.zero;
        _isAnimatingOut = false;
      });
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

  void _showNextImage(_MatchingCardData card) {
    final int current = _imageIndexByCard[card.name] ?? 0;
    final int next = (current + 1) % card.images.length;
    setState(() {
      _imageIndexByCard[card.name] = next;
    });
  }

  void _showPreviousImage(_MatchingCardData card) {
    final int current = _imageIndexByCard[card.name] ?? 0;
    final int previous =
        (current - 1 + card.images.length) % card.images.length;
    setState(() {
      _imageIndexByCard[card.name] = previous;
    });
  }

  @override
  Widget build(BuildContext context) {
    final _MatchingCardData frontCard = _cards.first;
    final _MatchingCardData? backCard = _cards.length > 1 ? _cards[1] : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: const Color(0xFFDB4713),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Matching',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double dragProgress =
                        (_dragOffset.dx.abs() / constraints.maxWidth).clamp(
                          0.0,
                          1.0,
                        );
                    final double rotation =
                        (_dragOffset.dx / constraints.maxWidth) * 0.22;

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
                                  height: constraints.maxHeight,
                                  child: _MatchingCard(
                                    card: backCard,
                                    imageIndex:
                                        _imageIndexByCard[backCard.name] ?? 0,
                                    onNextImage: () => _showNextImage(backCard),
                                    onPreviousImage: () =>
                                        _showPreviousImage(backCard),
                                    canChangeImage: false,
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
                              _onCardPanEnd(details, constraints.maxWidth),
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
                              height: constraints.maxHeight,
                              child: _MatchingCard(
                                key: ValueKey('${frontCard.name}_$_swipeCycle'),
                                card: frontCard,
                                imageIndex:
                                    _imageIndexByCard[frontCard.name] ?? 0,
                                onNextImage: () => _showNextImage(frontCard),
                                onPreviousImage: () =>
                                    _showPreviousImage(frontCard),
                                canChangeImage: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () => _animateSwipeOut(
                        toRight: false,
                        cardWidth: MediaQuery.sizeOf(context).width,
                      ),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    IconButton(
                      onPressed: () => _animateSwipeOut(
                        toRight: true,
                        cardWidth: MediaQuery.sizeOf(context).width,
                      ),
                      icon: const Icon(Icons.stars_rounded),
                      color: Colors.amber,
                    ),
                    IconButton(
                      onPressed: () => _animateSwipeOut(
                        toRight: true,
                        cardWidth: MediaQuery.sizeOf(context).width,
                      ),
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ],
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
    required this.imageIndex,
    required this.onNextImage,
    required this.onPreviousImage,
    required this.canChangeImage,
  });

  final _MatchingCardData card;
  final int imageIndex;
  final VoidCallback onNextImage;
  final VoidCallback onPreviousImage;
  final bool canChangeImage;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      card.images[imageIndex],
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (canChangeImage)
                    Positioned.fill(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _ImageNavButton(
                            icon: Icons.chevron_left_rounded,
                            onPressed: onPreviousImage,
                          ),
                          _ImageNavButton(
                            icon: Icons.chevron_right_rounded,
                            onPressed: onNextImage,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              card.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              card.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(card.images.length, (index) {
                final bool isActive = index == imageIndex;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 18 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFDB4713) : Colors.black26,
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageNavButton extends StatelessWidget {
  const _ImageNavButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(999),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          color: Colors.white,
          splashRadius: 20,
        ),
      ),
    );
  }
}

class _MatchingCardData {
  const _MatchingCardData({
    required this.name,
    required this.description,
    required this.images,
  });

  final String name;
  final String description;
  final List<String> images;
}
