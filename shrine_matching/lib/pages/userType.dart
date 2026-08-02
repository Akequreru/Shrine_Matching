import 'package:flutter/material.dart';
import 'package:shrine_matching/pages/matching.dart';
import 'package:shrine_matching/survices/firestore_service.dart';
import 'package:shrine_matching/models/type_info.dart';

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
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
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
                  const SizedBox(height: 16),
                  Text(
                    _typeInfo != null
                        ? '${_typeInfo!.name}\n(${_typeInfo!.mbti})'
                        : (widget.typeStr != null
                            ? 'タイプ${widget.typeId}\n(${widget.typeStr})'
                            : 'Sample Type'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _typeInfo?.paraphrase ??
                        (_isLoadingType
                            ? ''
                            : (widget.typeStr != null
                                ? '※ここに詳細な説明文やイラストを配置します。'
                                : 'Short description for this type\nConcept copy can go here.')),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  if (_typeInfo != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _typeInfo!.concept,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _typeInfo!.description,
                            style: const TextStyle(color: Colors.black87, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '旅のスタイル：${_typeInfo!.attitude}',
                            style: const TextStyle(color: Colors.black87, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '好きなもの：${_typeInfo!.favorite}',
                            style: const TextStyle(color: Colors.black87, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDB4713),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => MatchingPage(typeId: widget.typeId)),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text('Start Matching'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
