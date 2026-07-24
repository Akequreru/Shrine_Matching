import 'package:flutter/material.dart';

class TypeInfoPage extends StatefulWidget {
  const TypeInfoPage({super.key});

  static String routeName = 'TypeInfoPage';
  static String routePath = '/typeInfoPage';

  @override
  State<TypeInfoPage> createState() => _TypeInfoPageState();
}

class _TypeInfoPageState extends State<TypeInfoPage> {
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
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      'Rich text supports mixed formatting like ',
                                ),
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
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                TextSpan(text: ' inside one paragraph.'),
                              ],
                            ),
                          ),
                        ),
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
