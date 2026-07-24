import 'package:flutter/material.dart';
import 'package:shrine_matching/pages/matching.dart';

class TypePage extends StatelessWidget {
  const TypePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TypePageWidget();
  }
}

class TypePageWidget extends StatefulWidget {
  const TypePageWidget({super.key});

  static String routeName = 'TypePage';
  static String routePath = '/typePage';

  @override
  State<TypePageWidget> createState() => _TypePageWidgetState();
}

class _TypePageWidgetState extends State<TypePageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

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
                      'https://picsum.photos/seed/48/601',
                      width: 300,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sample Type',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Short description for this type\nConcept copy can go here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(color: Colors.black87, fontSize: 16),
                        children: [
                          TextSpan(text: 'Rich text supports mixed formatting like '),
                          TextSpan(
                            text: 'bold',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: ', '),
                          TextSpan(
                            text: 'italics',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                          TextSpan(text: ', and '),
                          TextSpan(
                            text: 'underline',
                            style: TextStyle(decoration: TextDecoration.underline),
                          ),
                          TextSpan(text: ' inside one paragraph.'),
                        ],
                      ),
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
                        MaterialPageRoute(
                          builder: (_) => const MatchingPage(),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
