import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shrine_matching/pages/matching.dart';
import 'package:shrine_matching/services/firestore_service.dart';
import 'package:shrine_matching/models/type_info.dart';
import 'package:shrine_matching/widgets/bottom_bar_visibility.dart';

class UserTypePage extends StatefulWidget {
  const UserTypePage({super.key, this.typeId, this.typeStr});

  // 診断結果から遷移してきたときだけ値が入る（直接開いた場合はnull）
  final int? typeId;
  final String? typeStr;

  static String routeName = 'UserTypePage';
  static String routePath = '/userTypePage';

  @override
  State<UserTypePage> createState() => _UserTypePageState();
}

class _UserTypePageState extends State<UserTypePage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoadingType = false;
  TypeInfo? _typeInfo;

  Color _typeAccentColor(String? typeName) {
    const yellow = Color(0xFFF1BC1F);
    const green = Color(0xFF5D8634);
    const blue = Color(0xFF5095BF);
    const purple = Color(0xFF906BAC);

    switch (typeName) {
      case '工芸職人':
      case '流浪人':
      case '旗手':
      case '神楽師':
        return yellow;
      case '軍師':
      case '仙人':
      case '将軍':
      case '発明家':
        return green;
      case '伝道師':
      case '祈祷者':
      case '師範':
      case '吟遊詩人':
        return blue;
      case '防人':
      case '庇護者':
      case '船頭':
      case '宿主':
        return purple;
      default:
        return const Color(0xFFDB4713);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.typeId != null) {
      _isLoadingType = true;
      _loadTypeInfo(widget.typeId!);
    }
  }

  Future<void> _loadTypeInfo(int typeId) async {
    final typeInfo = await _firestoreService.getType(typeId);
    if (!mounted) return;
    setState(() {
      _typeInfo = typeInfo;
      _isLoadingType = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _typeAccentColor(_typeInfo?.name);
    final bottomScrollPadding = MediaQuery.of(context).padding.bottom + 120;
    const contentHorizontalPadding = EdgeInsets.symmetric(horizontal: 12);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFFFEFEFE),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 20, 20, bottomScrollPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _typeInfo?.image ??
                          (widget.typeStr != null
                              ? 'https://firebasestorage.googleapis.com/v0/b/shrine-matching-f1a77.firebasestorage.app/o/kari_gazou_A.jpg?alt=media&token=f1c501c1-1afa-4f95-9e06-9996e1319cef'
                              : 'https://picsum.photos/seed/48/601'),
                      width: 300,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: contentHorizontalPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _typeInfo?.name ??
                            (widget.typeStr != null
                                ? 'タイプ${widget.typeId}'
                                : 'Sample Type'),
                        textAlign: TextAlign.left,
                        style: GoogleFonts.zenOldMincho(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _typeInfo?.paraphrase ??
                            (_isLoadingType
                                ? ''
                                : (widget.typeStr != null
                                      ? '※ここに詳細な説明文やイラストを配置します。'
                                      : 'Short description for this type\nConcept copy can go here.')),
                        textAlign: TextAlign.left,
                        style: GoogleFonts.zenOldMincho(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_typeInfo != null)
                  Padding(
                    padding: contentHorizontalPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'このタイプについて',
                          textAlign: TextAlign.left,
                          style: GoogleFonts.zenOldMincho(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _typeInfo!.description,
                          textAlign: TextAlign.left,
                          style: GoogleFonts.zenKakuGothicNew(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '大切にするもの',
                          textAlign: TextAlign.left,
                          style: GoogleFonts.zenOldMincho(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _typeInfo!.attitude,
                          textAlign: TextAlign.left,
                          style: GoogleFonts.zenKakuGothicNew(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'キーワード',
                          textAlign: TextAlign.left,
                          style: GoogleFonts.zenOldMincho(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _typeInfo!.favorite,
                          textAlign: TextAlign.left,
                          style: GoogleFonts.zenKakuGothicNew(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    onPressed: () {
                      RootBottomBarVisibility.hide();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MatchingPage(typeId: widget.typeId),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('神社を見る', textAlign: TextAlign.center),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
