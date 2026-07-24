import 'package:flutter/material.dart';

class ShrineInfoPage extends StatelessWidget {
  const ShrineInfoPage({
    super.key,
    this.shrineName = 'Sample Shrine',
    this.description = 'Short shrine description.',
    this.imageUrl = 'https://picsum.photos/seed/shrineinfo/900/700',
    this.details =
        'This is placeholder shrine detail text. You can replace this with actual content from your data source.',
  });

  final String shrineName;
  final String description;
  final String imageUrl;
  final String details;

  @override
  Widget build(BuildContext context) {
    return ShrineInfoWidget(
      shrineName: shrineName,
      description: description,
      imageUrl: imageUrl,
      details: details,
    );
  }
}

class ShrineInfoWidget extends StatelessWidget {
  const ShrineInfoWidget({
    super.key,
    required this.shrineName,
    required this.description,
    required this.imageUrl,
    required this.details,
  });

  static String routeName = 'ShrineInfo';
  static String routePath = '/shrineInfo';

  final String shrineName;
  final String description;
  final String imageUrl;
  final String details;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: const Color(0xFFDB4713),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Shrine Info',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 320,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  shrineName,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Text(
                  description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  details,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
