import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shrine_matching/models/shrine.dart';

class ShrineInfoPage extends StatelessWidget {
  const ShrineInfoPage({super.key, required this.shrineId, this.initialShrine});

  final String shrineId;
  final Shrine? initialShrine;

  @override
  Widget build(BuildContext context) {
    return ShrineInfoWidget(shrineId: shrineId, initialShrine: initialShrine);
  }
}

class ShrineInfoWidget extends StatefulWidget {
  const ShrineInfoWidget({
    super.key,
    required this.shrineId,
    this.initialShrine,
  });

  static String routeName = 'ShrineInfo';
  static String routePath = '/shrineInfo';

  final String shrineId;
  final Shrine? initialShrine;

  @override
  State<ShrineInfoWidget> createState() => _ShrineInfoWidgetState();
}

class _ShrineInfoWidgetState extends State<ShrineInfoWidget> {
  static const List<String> _placeholderImages = <String>[
    'https://picsum.photos/seed/199/900/700',
    'https://picsum.photos/seed/134/900/700',
    'https://picsum.photos/seed/43/900/700',
  ];
  static const List<String> _placeholderTags = <String>['#tag', '#tag'];
  static const String _placeholderName = '○○神社';
  static const String _placeholderSaijin = '祭神';
  static const String _placeholderAddress = '京都市上京区京都市上京区染殿町680';
  static const String _placeholderConcept =
      '常に前進を楽しむ「○○タイプ」のあなたには、勝負の神様を祀るこの神社の力強い気がぴったりです。新たな挑戦の背中を押し、道を切り開くご利益をもたらしてくれます。';
  static const String _placeholderDescription =
      '梨木神社は、明治18年（1885）に三條實萬公を御祭神として創建され、別格官幣社に列した。大正4年（1915）、大正天皇即位式に際して三條實萬公の子である三條實美公を第二座御祭神として合祀した。社名は旧地名の梨木町に由来する。';
  static const String _placeholderShrineType = '師範';
  static const String _placeholderBenefit = '開運';
  static const String _placeholderOfficialSite = 'https://www.nashinoki.jp/';

  static const Color _yellowTypeColor = Color(0xFFF1BC1F);
  static const Color _greenTypeColor = Color(0xFF5D8634);
  static const Color _blueTypeColor = Color(0xFF5095BF);
  static const Color _purpleTypeColor = Color(0xFF906BAC);

  int _userTypeId = 0;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserType();
  }

  Future<void> _loadCurrentUserType() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .get();
    final data = userDoc.data();
    if (!mounted || data == null) {
      return;
    }

    setState(() {
      _userTypeId = _toInt(data['lastType']) ?? 0;
    });
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  String _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && _hasText(value)) {
        return value.trim();
      }
      if (value is num) {
        return value.toString();
      }
    }
    return '';
  }

  String _firstNonEmpty(List<String> values, String fallback) {
    for (final value in values) {
      if (_hasText(value)) {
        return value.trim();
      }
    }
    return fallback;
  }

  String _normalizeTag(String tag) {
    final trimmed = tag.trim();
    if (!_hasText(trimmed)) {
      return '';
    }
    return trimmed.startsWith('#') ? trimmed : '#$trimmed';
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  List<int> _toIntList(dynamic value) {
    if (value is! List) {
      return <int>[];
    }
    return value.map(_toInt).whereType<int>().toList();
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

  Color _resolveAccentColor(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> deities,
  ) {
    int? matchedDeityTypeId;

    if (_userTypeId > 0) {
      for (final deityDoc in deities) {
        final data = deityDoc.data();
        final matchTypes = _toIntList(data['matchTypes']);
        if (matchTypes.contains(_userTypeId)) {
          final deityTypeId = _toInt(data['mbti']);
          if (deityTypeId != null && deityTypeId > 0) {
            matchedDeityTypeId = deityTypeId;
            break;
          }
        }
      }
    }

    if (matchedDeityTypeId == null) {
      for (final deityDoc in deities) {
        final deityTypeId = _toInt(deityDoc.data()['mbti']);
        if (deityTypeId != null && deityTypeId > 0) {
          matchedDeityTypeId = deityTypeId;
          break;
        }
      }
    }

    return _colorByTypeId(matchedDeityTypeId);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 112;

    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFE),
      body: SafeArea(
        top: true,
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('Shrines')
              .doc(widget.shrineId)
              .snapshots(),
          builder: (context, snapshot) {
            Shrine? shrine = widget.initialShrine;
            Map<String, dynamic> rawShrineData = const <String, dynamic>{};

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data();
              if (data != null) {
                rawShrineData = data;
                shrine = Shrine.fromFirestore(data, snapshot.data!.id);
              }
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                shrine == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (shrine == null) {
              return const Center(
                child: Text(
                  '神社データが見つかりませんでした。',
                  style: TextStyle(color: Colors.black54),
                ),
              );
            }

            final currentShrine = shrine;

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('Shrines')
                  .doc(widget.shrineId)
                  .collection('Deities')
                  .snapshots(),
              builder: (context, deitiesSnapshot) {
                final deities =
                    deitiesSnapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                final deityNames = deities
                    .map((doc) => (doc.data()['name'] ?? '').toString())
                    .where(_hasText)
                    .toList();
                final accentColor = _resolveAccentColor(deities);

                final shrineName = _firstNonEmpty(<String>[
                  currentShrine.name,
                ], _placeholderName);
                final addressText = _firstNonEmpty(<String>[
                  currentShrine.address,
                ], _placeholderAddress);
                final conceptText = _firstNonEmpty(<String>[
                  currentShrine.concept,
                ], _placeholderConcept);
                final descriptionText = _firstNonEmpty(<String>[
                  currentShrine.description,
                ], _placeholderDescription);

                final shrineTypeText = _firstNonEmpty(<String>[
                  _readString(rawShrineData, <String>[
                    'shrineType',
                    'typeLabel',
                    '神社タイプ',
                  ]),
                  rawShrineData['type'] is String
                      ? rawShrineData['type'] as String
                      : '',
                ], _placeholderShrineType);

                final benefitText = _firstNonEmpty(<String>[
                  _readString(rawShrineData, <String>[
                    'benefit',
                    'gorieki',
                    'luck',
                    'ご利益',
                  ]),
                ], _placeholderBenefit);

                final officialSiteText = _firstNonEmpty(<String>[
                  _readString(rawShrineData, <String>[
                    'officialSite',
                    'website',
                    'url',
                    '公式サイト',
                  ]),
                ], _placeholderOfficialSite);

                final saijinFromField = _readString(rawShrineData, <String>[
                  'saijin',
                  'enshrinedDeity',
                  'enshrinedDeities',
                  '祭神',
                ]);
                final saijinText = _firstNonEmpty(<String>[
                  saijinFromField,
                  deityNames.join('・'),
                ], _placeholderSaijin);

                final imageUrls = currentShrine.images
                    .map((image) => image.trim())
                    .where(_hasText)
                    .toList();
                final images = imageUrls.isEmpty
                    ? _placeholderImages
                    : imageUrls;

                final normalizedTags = currentShrine.tags
                    .map(_normalizeTag)
                    .where(_hasText)
                    .toList();
                final tags = normalizedTags.isEmpty
                    ? _placeholderTags
                    : normalizedTags;

                final currentIndex = _currentImageIndex >= images.length
                    ? images.length - 1
                    : _currentImageIndex;

                if (currentIndex != _currentImageIndex) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      _currentImageIndex = currentIndex;
                    });
                  });
                }

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(25, 0, 25, bottomPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back),
                          color: Colors.black,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shrineName,
                            style: GoogleFonts.zenOldMincho(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '祭神 $saijinText',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.zenOldMincho(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      CarouselSlider.builder(
                        itemCount: images.length,
                        itemBuilder: (context, index, realIndex) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              images[index],
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
                          );
                        },
                        options: CarouselOptions(
                          height: 420,
                          viewportFraction: 1,
                          enableInfiniteScroll: images.length > 1,
                          autoPlay: false,
                          enlargeCenterPage: false,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(images.length, (index) {
                            final isActive = currentIndex == index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: isActive ? 18 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? accentColor
                                    : const Color(0xFFD2D2D2),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              addressText,
                              style: GoogleFonts.zenKakuGothicNew(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.black54,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFF7A767B),
                            size: 32,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        conceptText,
                        style: GoogleFonts.zenOldMincho(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.45),
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.zenKakuGothicNew(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: accentColor,
                                height: 1.2,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'この神社について',
                        style: GoogleFonts.zenOldMincho(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        descriptionText,
                        style: GoogleFonts.zenKakuGothicNew(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _InfoBlock(
                        title: '神社タイプ',
                        value: shrineTypeText,
                        accentColor: accentColor,
                      ),
                      const SizedBox(height: 18),
                      _InfoBlock(
                        title: 'ご利益',
                        value: benefitText,
                        accentColor: accentColor,
                      ),
                      const SizedBox(height: 18),
                      _InfoBlock(
                        title: '公式サイト',
                        value: officialSiteText,
                        accentColor: accentColor,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.value,
    required this.accentColor,
  });

  final String title;
  final String value;
  final Color accentColor;

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
            color: accentColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.zenKakuGothicNew(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
