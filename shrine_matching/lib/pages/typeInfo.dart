import 'package:flutter/material.dart';
import 'package:shrine_matching/models/type_info.dart';
import 'package:shrine_matching/pages/matching.dart';
import 'package:shrine_matching/services/firestore_service.dart';
import 'package:shrine_matching/widgets/bottom_bar_visibility.dart';
import 'package:shrine_matching/widgets/loading_ribbon_screen.dart';

class TypeInfoPage extends StatefulWidget {
  const TypeInfoPage({super.key, required this.typeId, this.isOwnType = false});

  final int typeId;

  // 自分の診断結果タイプかどうか。falseの場合はマッチング開始ボタンを表示しない
  final bool isOwnType;

  static String routeName = 'TypeInfoPage';
  static String routePath = '/typeInfoPage';

  @override
  State<TypeInfoPage> createState() => _TypeInfoPageState();
}

class _TypeInfoPageState extends State<TypeInfoPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = true;
  TypeInfo? _typeInfo;

  @override
  void initState() {
    super.initState();
    _loadTypeInfo();
  }

  Future<void> _loadTypeInfo() async {
    final typeInfo = await _firestoreService.getType(widget.typeId);
    if (!mounted) return;
    setState(() {
      _typeInfo = typeInfo;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingRibbonScreen();
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFFFEFEFE),
        body: SafeArea(
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
                      'Type Info',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _typeInfo == null
                    ? const Center(
                        child: Text(
                          'タイプ情報が見つかりませんでした',
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _typeInfo!.image,
                                  width: 300,
                                  height: 300,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${_typeInfo!.name}\n(${_typeInfo!.mbti})',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _typeInfo!.paraphrase,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 20),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
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
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '旅のスタイル：${_typeInfo!.attitude}',
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '好きなもの：${_typeInfo!.favorite}',
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.isOwnType) ...[
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
                                    RootBottomBarVisibility.hide();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            MatchingPage(typeId: widget.typeId),
                                      ),
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
                            ],
                          ),
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
