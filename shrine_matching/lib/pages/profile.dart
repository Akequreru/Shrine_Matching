import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shrine_matching/pages/diagnote.dart';
import 'package:shrine_matching/models/visit.dart';
import 'package:shrine_matching/pages/profile_settings.dart';
import 'package:shrine_matching/pages/shrineInfo.dart';
import 'package:shrine_matching/services/firestore_service.dart';
import 'package:shrine_matching/widgets/root_tab_selection.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfilePageWidget();
  }
}

class ProfilePageWidget extends StatefulWidget {
  const ProfilePageWidget({super.key});

  static String routeName = 'ProfilePage';
  static String routePath = '/profilePage';

  @override
  State<ProfilePageWidget> createState() => _ProfilePageWidgetState();
}

class _ProfilePageWidgetState extends State<ProfilePageWidget>
    with WidgetsBindingObserver {
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoadingPage = true;
  bool _isLoadingProfileData = false;
  List<Visit> _historyVisits = <Visit>[];

  String _displayName = 'ユーザーネーム';
  String _typeLabel = '○○タイプ';
  String _avatarUrl = '';
  int _matchedShrineCount = 0;
  int _crossedShrineCount = 0;
  int _visitedShrineCount = 0;

  bool _isUploadingAvatar = false;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    RootTabSelection.request.addListener(_handleRootTabSelectionRequested);
    _loadProfileData(showLoading: true);
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    RootTabSelection.request.removeListener(_handleRootTabSelectionRequested);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadProfileData();
    }
  }

  void _handleRootTabSelectionRequested() {
    final request = RootTabSelection.request.value;
    if (request == null) {
      return;
    }

    if (request.index == RootTabSelection.profile) {
      _loadProfileData();
      _startAutoRefresh();
    } else {
      _stopAutoRefresh();
    }
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _loadProfileData();
    });
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  Future<void> _loadProfileData({bool showLoading = false}) async {
    if (_isLoadingProfileData) {
      return;
    }

    _isLoadingProfileData = true;
    if (showLoading && mounted) {
      setState(() => _isLoadingPage = true);
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _isLoadingProfileData = false;
      if (mounted) {
        setState(() => _isLoadingPage = false);
      }
      return;
    }

    try {
      final userFuture = _firestoreService.getUserWithHistory(uid);
      final visitsFuture = _firestoreService.getVisits();
      final visitCountFuture = _firestoreService.getVisitsCount(uid);
      final crossingCountFuture = _firestoreService.getCrossingsCount(uid);

      final user = await userFuture;
      var typeLabel = '○○タイプ';
      if (user != null && user.lastType > 0) {
        final typeInfo = await _firestoreService.getType(user.lastType);
        if (typeInfo != null && typeInfo.name.isNotEmpty) {
          typeLabel = '${typeInfo.name}タイプ';
        } else {
          typeLabel = 'タイプ${user.lastType}';
        }
      }

      final visits = await visitsFuture;
      final visitCount = await visitCountFuture;
      final crossingCount = await crossingCountFuture;

      if (!mounted) return;
      setState(() {
        _displayName = user != null && user.userName.isNotEmpty
            ? user.userName
            : (FirebaseAuth.instance.currentUser?.displayName ?? 'ユーザーネーム');
        _typeLabel = typeLabel;
        _avatarUrl = user?.avatarUrl ?? '';
        _matchedShrineCount = user?.favoriteShrineIds.length ?? 0;
        _crossedShrineCount = crossingCount;
        _visitedShrineCount = visitCount;
        _historyVisits = visits;
        _isLoadingPage = false;
      });
    } catch (e) {
      debugPrint('プロフィール情報の読み込みに失敗しました: $e');
      if (!mounted) return;
      if (showLoading) {
        setState(() {
          _isLoadingPage = false;
        });
      }
    } finally {
      _isLoadingProfileData = false;
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploadingAvatar = true);

    try {
      const fileName = 'avatar.jpg';
      final ref = FirebaseStorage.instance.ref('Users/$uid/$fileName');
      await ref.putData(await picked.readAsBytes());
      final url = await ref.getDownloadURL();

      await _firestoreService.updateAvatarUrl(uid, url);

      if (!mounted) return;
      setState(() {
        _avatarUrl = url;
      });
    } catch (e) {
      debugPrint('画像のアップロードに失敗しました: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('画像のアップロードに失敗しました')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}/$month/$day';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFE),
      body: SafeArea(
        bottom: false,
        child: ListView(
          primary: true,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 88),
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: Color(0xFFC4C4C4)),
                  ),
                  color: Colors.white,
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileSettingsPage(),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.settings,
                        color: Color(0xFF707070),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE0E0E0),
                        width: 1.2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Image.network(
                          _avatarUrl.isNotEmpty
                              ? _avatarUrl
                              : 'https://picsum.photos/seed/avatar-profile/300',
                          width: 92,
                          height: 92,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFF1F1F1),
                              child: const Icon(
                                Icons.person,
                                size: 50,
                                color: Color(0xFF626B75),
                              ),
                            );
                          },
                        ),
                        if (_isUploadingAvatar)
                          Container(
                            width: 92,
                            height: 92,
                            color: Colors.black26,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        else
                          const Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: EdgeInsets.all(4),
                              child: CircleAvatar(
                                radius: 11,
                                backgroundColor: Color(0x818D8D8D),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 13,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.zenKakuGothicNew(
                          fontSize: 33,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _typeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.zenOldMincho(
                          fontSize: 16,
                          color: Color(0xFF5C5C5C),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBE643A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileSettingsPage(),
                    ),
                  );

                  if (!mounted) {
                    return;
                  }
                  _loadProfileData();
                },
                child: Text(
                  'プロフィールを編集',
                  style: GoogleFonts.zenOldMincho(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFBE643A),
                  side: const BorderSide(color: Color(0xFFBE643A), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DiagnosticScreen()),
                  );

                  if (!mounted) {
                    return;
                  }
                  _loadProfileData();
                },
                child: Text(
                  'もう一度診断する',
                  style: GoogleFonts.zenOldMincho(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'ステータス',
              style: GoogleFonts.zenOldMincho(
                fontSize: 25,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _StatusBadge(
                    count: _matchedShrineCount,
                    label: '縁を結んだ神社',
                  ),
                ),
                Expanded(
                  child: _StatusBadge(
                    count: _crossedShrineCount,
                    label: 'すれちがった神社',
                  ),
                ),
                Expanded(
                  child: _StatusBadge(
                    count: _visitedShrineCount,
                    label: '参拝した神社',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '履歴',
              style: GoogleFonts.zenOldMincho(
                fontSize: 25,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoadingPage)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (_historyVisits.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'まだ参拝した神社がありません',
                  style: GoogleFonts.zenOldMincho(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
              )
            else
              ...List.generate(_historyVisits.length, (index) {
                final visit = _historyVisits[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == _historyVisits.length - 1 ? 0 : 12,
                  ),
                  child: _HistoryCard(
                    visit: visit,
                    visitedDate: _formatDate(visit.visitedAt),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ShrineInfoPage(shrineId: visit.shrineId),
                        ),
                      );
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.count, required this.label});

  static const String _ribbonAssetPath = 'lib/assets/loading_ribbon.png';
  static const Color _accentColor = Color(0xFFB86A43);

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 98,
          height: 98,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _accentColor, width: 2),
                ),
              ),
              Positioned(
                top: 24,
                child: Text(
                  '$count',
                  style: GoogleFonts.zenOldMincho(
                    fontSize: 26,
                    height: 1,
                    color: _accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Positioned(
                bottom: 22,
                left: -8,
                right: -8,
                child: Image.asset(
                  _ribbonAssetPath,
                  fit: BoxFit.contain,
                  height: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.zenOldMincho(
            fontSize: 11,
            color: Color(0xFF6B6B6B),
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.visit,
    required this.visitedDate,
    required this.onTap,
  });

  final Visit visit;
  final String visitedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = visit.image.isNotEmpty
        ? visit.image
        : 'https://picsum.photos/seed/${visit.shrineId}/220';

    return Material(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 68,
                      height: 68,
                      color: const Color(0xFFF0F0F0),
                      child: const Icon(Icons.image_not_supported_outlined),
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visit.shrineName.isNotEmpty
                          ? visit.shrineName
                          : '名称未設定の神社',
                      style: GoogleFonts.zenOldMincho(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      visitedDate,
                      style: GoogleFonts.zenOldMincho(
                        fontSize: 14,
                        color: Color(0xFF7A7A7A),
                      ),
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
