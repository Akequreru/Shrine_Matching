import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shrine_matching/services/firestore_service.dart';
import 'package:shrine_matching/pages/userType.dart';
import 'package:shrine_matching/widgets/loading_ribbon_screen.dart';

// ==========================================
// 1. データ定義
// ==========================================
class DiagnosticQuestion {
  final String text; // 質問文
  final String choiceA; // 選択肢Aのテキスト（E/S/T/J）
  final String choiceB; // 選択肢Bのテキスト（I/N/F/P）
  final int axis; // どの軸か (0:E/I, 1:S/N, 2:T/F, 3:J/P)

  DiagnosticQuestion({
    required this.text,
    required this.choiceA,
    required this.choiceB,
    required this.axis,
  });
}

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({Key? key}) : super(key: key);

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  final PageController _pageController = PageController();
  final FirestoreService _firestoreService = FirestoreService();

  // 現在の質問インデックス
  int _currentIndex = 0;

  bool _isLoading = true;

  // Firestoreの Questions コレクションから取得した質問（各軸3問ずつになる想定）
  List<DiagnosticQuestion> questions = [];

  // 各質問への回答を保持するリスト（1: 選択肢A, -1: 選択肢B, 0: 未回答）
  // 戻って選び直したときに上書きできるように、スコアの足し算ではなく「回答の記録」に変更
  List<int> userAnswers = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final fetched = await _firestoreService.getQuestions();

    // 同じ軸の質問がまとまるよう value（軸）でソート
    fetched.sort((a, b) => a.value.compareTo(b.value));

    setState(() {
      questions = fetched
          .map(
            (q) => DiagnosticQuestion(
              text: q.question,
              choiceA: q.answer1,
              choiceB: q.answer2,
              axis: q.value,
            ),
          )
          .toList();
      userAnswers = List.filled(questions.length, 0);
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 回答ボタンを押した時の処理（選択状態のみ更新）
  void _handleAnswer(int score) {
    setState(() {
      userAnswers[_currentIndex] = score;
    });
  }

  // 前に戻る処理
  void _goBack() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // 「次へ / 診断結果」ボタンを押した時の処理
  void _goNext() {
    if (userAnswers[_currentIndex] == 0) {
      return;
    }

    if (_currentIndex < questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _calculateAndNavigate();
    }
  }

  // 多数決の計算と結果画面への遷移
  void _calculateAndNavigate() {
    // 軸(0:E/I, 1:S/N, 2:T/F, 3:J/P)ごとに回答を合計する
    final Map<int, int> axisScores = {0: 0, 1: 0, 2: 0, 3: 0};
    for (int i = 0; i < questions.length; i++) {
      final axis = questions[i].axis;
      axisScores[axis] = (axisScores[axis] ?? 0) + userAnswers[i];
    }

    String typeStr = "";
    typeStr += (axisScores[0]! > 0) ? "E" : "I";
    typeStr += (axisScores[1]! > 0) ? "S" : "N";
    typeStr += (axisScores[2]! > 0) ? "T" : "F";
    typeStr += (axisScores[3]! > 0) ? "J" : "P";

    int typeId = _convertToTypeId(typeStr);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      unawaited(_firestoreService.saveDiagnosticResult(uid, typeId));
    }

    // Navigator.pushReplacement を使うと、結果画面から「戻る」ボタンで質問に戻れなくなります（診断リセット）
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => UserTypePage(typeId: typeId, typeStr: typeStr),
      ),
    );
  }

  int _convertToTypeId(String typeStr) {
    const Map<String, int> typeMap = {
      "ESTJ": 1,
      "ENTJ": 2,
      "ESFJ": 3,
      "ENFJ": 4,
      "ESTP": 5,
      "ENTP": 6,
      "ESFP": 7,
      "ENFP": 8,
      "ISTJ": 9,
      "INTJ": 10,
      "ISFJ": 11,
      "INFJ": 12,
      "ISTP": 13,
      "INTP": 14,
      "ISFP": 15,
      "INFP": 16,
    };
    return typeMap[typeStr] ?? 1;
  }

  // 「〜ですか？それとも、〜ですか？」の文を「？」の直後で改行する
  String _formatQuestionText(String text) {
    final parts = text.split('？').where((s) => s.isNotEmpty).toList();
    return parts.map((s) => '$s？').join('\n');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingRibbonScreen();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEFEFE),
        surfaceTintColor: Colors.transparent,
      ),
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // スワイプ禁止
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          final answer = userAnswers[index];
          final hasSelection = answer != 0;
          final isLastQuestion = index == questions.length - 1;

          return Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Q${index + 1}.",
                    style: GoogleFonts.castoro(
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  height: 4 * 28.0, // 4行分を確保して長い質問文でも欠けないようにする
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      _formatQuestionText(question.text),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.zenOldMincho(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 選択肢A (+1)
                _buildChoiceButton(
                  context: context,
                  text: question.choiceA,
                  isSelected: answer == 1,
                  onPressed: () => _handleAnswer(1),
                ),
                const SizedBox(height: 16),

                // 選択肢B (-1)
                _buildChoiceButton(
                  context: context,
                  text: question.choiceB,
                  isSelected: answer == -1,
                  onPressed: () => _handleAnswer(-1),
                ),

                const Spacer(),

                Padding(
                  padding: EdgeInsets.only(
                    bottom: _actionRowBottomPadding(context),
                  ),
                  child: Row(
                    children: [
                      if (index > 0)
                        IconButton(
                          onPressed: _goBack,
                          icon: const Icon(Icons.arrow_back),
                          color: Colors.black,
                        ),
                      const Spacer(),
                      _buildNextButton(
                        context: context,
                        hasSelection: hasSelection,
                        isLastQuestion: isLastQuestion,
                        onPressed: _goNext,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _buttonBackgroundColor(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  double _actionRowBottomPadding(BuildContext context) {
    final safeAreaBottom = MediaQuery.of(context).viewPadding.bottom;
    return safeAreaBottom + kBottomNavigationBarHeight + 20;
  }

  ButtonStyle _buildPillButtonStyle({
    required Color backgroundColor,
    required Color foregroundColor,
    BorderSide side = const BorderSide(color: Colors.black),
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      vertical: 24,
      horizontal: 16,
    ),
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      padding: padding,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      minimumSize: Size.zero,
      side: side,
      shape: const StadiumBorder(), // 50% に近い丸みのピル形
    );
  }

  Widget _buildChoiceButton({
    required BuildContext context,
    required String text,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    final backgroundColor = isSelected
        ? Colors.black
        : _buttonBackgroundColor(context);
    final foregroundColor = isSelected ? Colors.white : Colors.black;

    return ElevatedButton(
      onPressed: onPressed,
      style: _buildPillButtonStyle(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.all(20),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Text(
          text,
          style: GoogleFonts.zenKakuGothicNew(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.left,
        ),
      ),
    );
  }

  Widget _buildNextButton({
    required BuildContext context,
    required bool hasSelection,
    required bool isLastQuestion,
    required VoidCallback onPressed,
  }) {
    final backgroundColor = !hasSelection
        ? _buttonBackgroundColor(context)
        : (isLastQuestion ? const Color(0xFFDB4713) : Colors.black);
    final foregroundColor = hasSelection ? Colors.white : Colors.black;
    final label = isLastQuestion ? "診断結果" : "次へ";

    return ElevatedButton(
      onPressed: onPressed,
      style: _buildPillButtonStyle(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        side: isLastQuestion
            ? BorderSide.none
            : const BorderSide(color: Colors.black),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward),
        ],
      ),
    );
  }
}
