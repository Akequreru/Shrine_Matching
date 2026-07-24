import 'package:flutter/material.dart';

class MatchingPage extends StatelessWidget {
  const MatchingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MatchingPageWidget();
  }
}

class MatchingPageWidget extends StatelessWidget {
  const MatchingPageWidget({super.key});

  static String routeName = 'MatchingPage';
  static String routePath = '/matchingPage';

  @override
  Widget build(BuildContext context) {
    final cards = <_MatchingCardData>[
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Matching'),
        backgroundColor: const Color(0xFFDB4713),
        foregroundColor: Colors.white,
      ),
      body: PageView.builder(
        itemCount: cards.length,
        padEnds: true,
        itemBuilder: (context, index) {
          final card = cards[index];
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 260,
                      child: PageView.builder(
                        itemCount: card.images.length,
                        itemBuilder: (context, imageIndex) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              card.images[imageIndex],
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      card.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      card.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const Spacer(),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(Icons.arrow_back),
                        Icon(Icons.stars_rounded),
                        Icon(Icons.arrow_forward),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
