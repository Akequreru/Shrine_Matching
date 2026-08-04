import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shrine_matching/models/shrine.dart';
import 'package:shrine_matching/pages/shrineInfo.dart';
import 'package:shrine_matching/survices/auth_service.dart';
import 'package:shrine_matching/survices/firestore_service.dart';

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

class _ProfilePageWidgetState extends State<ProfilePageWidget> {
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoadingFavorites = true;
  List<Shrine> _favoriteShrines = <Shrine>[];

  String _avatarUrl = '';
  String _coverUrl = '';
  bool _isUploadingAvatar = false;
  bool _isUploadingCover = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteShrines();
  }

  Future<void> _loadFavoriteShrines() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoadingFavorites = false);
      return;
    }

    final user = await _firestoreService.getUserWithHistory(uid);
    final shrines = user == null
        ? <Shrine>[]
        : await _firestoreService.getFavoriteShrines(user.favoriteShrineIds);

    if (!mounted) return;
    setState(() {
      _favoriteShrines = shrines;
      _avatarUrl = user?.avatarUrl ?? '';
      _coverUrl = user?.coverUrl ?? '';
      _isLoadingFavorites = false;
    });
  }

  Future<void> _pickAndUploadImage({required bool isAvatar}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() {
      if (isAvatar) {
        _isUploadingAvatar = true;
      } else {
        _isUploadingCover = true;
      }
    });

    try {
      final fileName = isAvatar ? 'avatar.jpg' : 'cover.jpg';
      final ref = FirebaseStorage.instance.ref('Users/$uid/$fileName');
      await ref.putData(await picked.readAsBytes());
      final url = await ref.getDownloadURL();

      if (isAvatar) {
        await _firestoreService.updateAvatarUrl(uid, url);
      } else {
        await _firestoreService.updateCoverUrl(uid, url);
      }

      if (!mounted) return;
      setState(() {
        if (isAvatar) {
          _avatarUrl = url;
        } else {
          _coverUrl = url;
        }
      });
    } catch (e) {
      debugPrint('画像のアップロードに失敗しました: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('画像のアップロードに失敗しました')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (isAvatar) {
            _isUploadingAvatar = false;
          } else {
            _isUploadingCover = false;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    const coverImageHeight = 150.0;
    const avatarSize = 100.0;
    final headerHeight = topInset + coverImageHeight;
    final avatarTop = headerHeight - (avatarSize / 1.7);

    final visitedShrines = List.generate(
      4,
      (index) => 'https://picsum.photos/seed/visited$index/300',
    );

    final crossedShrines = List.generate(
      4,
      (index) => 'https://picsum.photos/seed/crossed$index/300',
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        primary: true,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.only(bottom: bottomInset + 72),
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: _isUploadingCover
                    ? null
                    : () => _pickAndUploadImage(isAvatar: false),
                child: Stack(
                  children: [
                    Image.network(
                      _coverUrl.isNotEmpty
                          ? _coverUrl
                          : 'https://picsum.photos/seed/836/900/320',
                      width: double.infinity,
                      height: headerHeight,
                      fit: BoxFit.cover,
                    ),
                    if (_isUploadingCover)
                      Container(
                        width: double.infinity,
                        height: headerHeight,
                        color: Colors.black26,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      )
                    else
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Material(
                          color: const Color(0x818D8D8D),
                          shape: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 20,
                top: avatarTop,
                child: GestureDetector(
                  onTap: _isUploadingAvatar
                      ? null
                      : () => _pickAndUploadImage(isAvatar: true),
                  child: Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Image.network(
                          _avatarUrl.isNotEmpty
                              ? _avatarUrl
                              : 'https://picsum.photos/seed/796/300',
                          width: avatarSize,
                          height: avatarSize,
                          fit: BoxFit.cover,
                        ),
                        if (_isUploadingAvatar)
                          Container(
                            width: avatarSize,
                            height: avatarSize,
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
                                radius: 12,
                                backgroundColor: Color(0x818D8D8D),
                                child: Icon(Icons.camera_alt, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: topInset + 8,
                child: Row(
                  children: [
                    Material(
                      color: const Color(0x818D8D8D),
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: () => AuthService().signOut(),
                        icon: const Icon(Icons.logout, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: const Color(0x818D8D8D),
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: () => _showDeleteAccountDialog(context),
                        icon: const Icon(Icons.delete_forever, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: const Color(0x818D8D8D),
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: () => debugPrint('Settings pressed'),
                        icon: const Icon(Icons.settings, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 56),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Text(
              'Name',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Text(
              'Status',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Text(
              'My Shrine Types',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(
            height: 88,
            child: _isLoadingFavorites
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _favoriteShrines.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'まだお気に入りの神社がありません',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                        scrollDirection: Axis.horizontal,
                        itemCount: _favoriteShrines.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final shrine = _favoriteShrines[index];
                          final imageUrl = shrine.images.isNotEmpty
                              ? shrine.images.first
                              : 'https://picsum.photos/seed/${shrine.id}/200';
                          return GestureDetector(
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
                            child: ClipOval(
                              child: Image.network(
                                imageUrl,
                                width: 75,
                                height: 75,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'Visited Shrines',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(
            height: 116,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              scrollDirection: Axis.horizontal,
              itemCount: visitedShrines.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    visitedShrines[index],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'Shrines Crossed Paths',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(
            height: 116,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              scrollDirection: Axis.horizontal,
              itemCount: crossedShrines.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    crossedShrines[index],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDB4713),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              onPressed: () => debugPrint('Retake test pressed'),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text('Retake the Test'),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

void _showDeleteAccountDialog(BuildContext context) {
  final authService = AuthService();

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      bool isSubmitting = false;
      String? errorMessage;

      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: const Text('アカウントを削除'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('この操作は取り消せません。本当に削除しますか？'),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setState(() {
                          isSubmitting = true;
                          errorMessage = null;
                        });
                        try {
                          // まずはパスワード無しで削除を試みる
                          await authService.deleteAccount();
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        } on FirebaseAuthException catch (e) {
                          if (e.code == 'requires-recent-login') {
                            // 最近ログインしていない場合だけパスワード入力を求める
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            if (context.mounted) {
                              _showDeleteAccountPasswordDialog(context, authService);
                            }
                            return;
                          }
                          setState(() {
                            isSubmitting = false;
                            errorMessage = authService.messageForError(e);
                          });
                        } catch (e) {
                          setState(() {
                            isSubmitting = false;
                            errorMessage = authService.messageForError(e);
                          });
                        }
                      },
                child: Text(
                  '削除する',
                  style: TextStyle(color: isSubmitting ? Colors.grey : Colors.red),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

void _showDeleteAccountPasswordDialog(BuildContext context, AuthService authService) {
  final passwordController = TextEditingController();

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      bool isSubmitting = false;
      String? errorMessage;

      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: const Text('アカウントを削除'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('セキュリティのため、確認のためパスワードを入力してください。'),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'パスワード'),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setState(() {
                          isSubmitting = true;
                          errorMessage = null;
                        });
                        try {
                          await authService.deleteAccount(password: passwordController.text);
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        } catch (e) {
                          setState(() {
                            isSubmitting = false;
                            errorMessage = authService.messageForError(e);
                          });
                        }
                      },
                child: Text(
                  '削除する',
                  style: TextStyle(color: isSubmitting ? Colors.grey : Colors.red),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
