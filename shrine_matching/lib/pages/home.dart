import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

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
