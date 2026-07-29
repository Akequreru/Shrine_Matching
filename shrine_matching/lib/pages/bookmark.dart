import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shrine_matching/models/shrine.dart';
import 'package:shrine_matching/pages/shrineInfo.dart';
import 'package:shrine_matching/survices/firestore_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadFavoriteShrines();
  }

  Future<void> _loadFavoriteShrines() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    final user = await _firestoreService.getUserWithHistory(uid);
    final shrines = user == null
        ? <Shrine>[]
        : await _firestoreService.getFavoriteShrines(user.favoriteShrineIds);

    if (!mounted) return;
    setState(() {
      _shrines = shrines;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _shrines.isEmpty
                ? const Center(
                    child: Text(
                      'まだお気に入りの神社がありません',
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
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
                                shrineName: shrine.name,
                                description: shrine.concept,
                                imageUrl: imageUrl,
                                details: shrine.description,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shrine.name,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      shrine.concept,
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
