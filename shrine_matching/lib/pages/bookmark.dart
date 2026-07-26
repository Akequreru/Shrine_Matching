import 'package:flutter/material.dart';
import 'package:shrine_matching/pages/shrineInfo.dart';

class BookmarkPage extends StatelessWidget {
  const BookmarkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BookmarkPageWidget();
  }
}

class BookmarkPageWidget extends StatelessWidget {
  const BookmarkPageWidget({super.key});

  static String routeName = 'BookmarkPage';
  static String routePath = '/bookmarkPage';

  @override
  Widget build(BuildContext context) {
    final items = <_BookmarkedShrine>[
      const _BookmarkedShrine(
        name: 'Fushimi Inari Shrine',
        subtitle: 'Kyoto, famous for thousands of torii gates.',
        imageUrl: 'https://picsum.photos/seed/fushimi/600',
      ),
      const _BookmarkedShrine(
        name: 'Meiji Shrine',
        subtitle: 'Tokyo, quiet forested grounds in the city center.',
        imageUrl: 'https://picsum.photos/seed/meiji/600',
      ),
      const _BookmarkedShrine(
        name: 'Itsukushima Shrine',
        subtitle: 'Miyajima, known for the floating torii gate.',
        imageUrl: 'https://picsum.photos/seed/itsukushima/600',
      ),
      const _BookmarkedShrine(
        name: 'Dazaifu Tenmangu',
        subtitle: 'Fukuoka, shrine dedicated to scholarship.',
        imageUrl: 'https://picsum.photos/seed/dazaifu/600',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 50),
        child: FloatingActionButton(
          onPressed: () => debugPrint('Add bookmark tapped'),
          backgroundColor: const Color(0xFFDB4713),
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final item = items[index];
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ShrineInfoPage(
                      shrineName: item.name,
                      description: item.subtitle,
                      imageUrl: item.imageUrl,
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
                        item.imageUrl,
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.subtitle,
                            style: const TextStyle(
                              color: Colors.black87,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap to open details',
                            style: TextStyle(
                              color: Color(0xFFDB4713),
                              fontWeight: FontWeight.w600,
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
    );
  }
}

class _BookmarkedShrine {
  const _BookmarkedShrine({
    required this.name,
    required this.subtitle,
    required this.imageUrl,
  });

  final String name;
  final String subtitle;
  final String imageUrl;
}
