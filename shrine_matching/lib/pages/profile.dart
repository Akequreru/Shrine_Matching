import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfilePageWidget();
  }
}

class ProfilePageWidget extends StatelessWidget {
  const ProfilePageWidget({super.key});

  static String routeName = 'ProfilePage';
  static String routePath = '/profilePage';

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    const coverImageHeight = 150.0;
    const avatarSize = 100.0;
    final headerHeight = topInset + coverImageHeight;
    final avatarTop = headerHeight - (avatarSize / 1.7);

    final typeIcons = List.generate(
      5,
      (index) => 'https://picsum.photos/seed/type$index/200',
    );

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
              Image.network(
                'https://picsum.photos/seed/836/900/320',
                width: double.infinity,
                height: headerHeight,
                fit: BoxFit.cover,
              ),
              Positioned(
                left: 20,
                top: avatarTop,
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    'https://picsum.photos/seed/796/300',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: topInset + 8,
                child: Material(
                  color: const Color(0x818D8D8D),
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: () => debugPrint('Settings pressed'),
                    icon: const Icon(Icons.settings, color: Colors.white),
                  ),
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
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              scrollDirection: Axis.horizontal,
              itemCount: typeIcons.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return ClipOval(
                  child: Image.network(
                    typeIcons[index],
                    width: 75,
                    height: 75,
                    fit: BoxFit.cover,
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
