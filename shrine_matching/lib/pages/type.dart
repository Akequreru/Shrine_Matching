import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shrine_matching/models/type_info.dart';
import 'package:shrine_matching/pages/typeInfo.dart';
import 'package:shrine_matching/survices/firestore_service.dart';

class TypePage extends StatefulWidget {
  const TypePage({super.key});

  static String routeName = 'Type';
  static String routePath = '/type';

  @override
  State<TypePage> createState() => _TypePageState();
}

class _TypePageState extends State<TypePage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = true;
  List<TypeInfo> _types = <TypeInfo>[];
  int? _myTypeId;

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    final types = await _firestoreService.getAllTypes();

    int? myTypeId;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final user = await _firestoreService.getUserWithHistory(uid);
      if (user != null && user.lastType != 0) {
        myTypeId = user.lastType;
      }
    }

    if (!mounted) return;
    setState(() {
      _types = types;
      _myTypeId = myTypeId;
      _isLoading = false;
    });
  }

  void _openTypeInfoPage(TypeInfo type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TypeInfoPage(
          typeId: type.id,
          isOwnType: type.id == _myTypeId,
        ),
      ),
    );
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
          top: true,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 10, 0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _types.isEmpty
                    ? const Center(
                        child: Text(
                          'タイプ情報がまだ登録されていません',
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1,
                        ),
                        itemCount: _types.length,
                        itemBuilder: (context, index) {
                          final type = _types[index];
                          return _TypeCard(
                            type: type,
                            isOwnType: type.id == _myTypeId,
                            onTap: () => _openTypeInfoPage(type),
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.type,
    required this.isOwnType,
    required this.onTap,
  });

  final TypeInfo type;
  final bool isOwnType;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Card(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        color: isOwnType ? const Color(0xFFFFE6D4) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isOwnType
              ? const BorderSide(color: Color(0xFFDB4713), width: 1.5)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    type.image,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${type.name}\n(${type.mbti})',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 0,
                  fontWeight: isOwnType ? FontWeight.w700 : FontWeight.normal,
                  color: isOwnType ? const Color(0xFFDB4713) : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
