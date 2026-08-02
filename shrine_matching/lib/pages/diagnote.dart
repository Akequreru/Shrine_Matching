import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shrine_matching/survices/firestore_service.dart';
import 'package:shrine_matching/pages/userType.dart';

// ==========================================
// 1. データ定義
// ==========================================
class DiagnosticQuestion {
  final String text;      // 質問文
  final String choiceA;   // 選択肢Aのテキスト（E/S/T/J）
  final String choiceB;   // 選択肢Bのテキスト（I/N/F/P）
  final int axis;         // どの軸か (0:E/I, 1:S/N, 2:T/F, 3:J/P)

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
          .map((q) => DiagnosticQuestion(
                text: q.question,
                choiceA: q.answer1,
                choiceB: q.answer2,
                axis: q.value,
              ))
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

  // 回答ボタンを押した時の処理
  void _handleAnswer(int score) {
    // 回答を記録
    userAnswers[_currentIndex] = score;

    if (_currentIndex < questions.length - 1) {
      // 次のページへ
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // 全問終わったら結果を計算して画面遷移
      _calculateAndNavigate();
    }
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
      "ESTJ": 1, "ENTJ": 2, "ESFJ": 3, "ENFJ": 4,
      "ESTP": 5, "ENTP": 6, "ESFP": 7, "ENFP": 8,
      "ISTJ": 9, "INTJ": 10, "ISFJ": 11, "INFJ": 12,
      "ISTP": 13, "INTP": 14, "ISFP": 15, "INFP": 16,
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
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(),
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

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Q${index + 1}",
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  height: 3 * 28.0, // 2〜3行分を確保して質問ごとの高さのブレを無くす
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      _formatQuestionText(question.text),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.4),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 選択肢A (+1)
                _buildChoiceButton(
                  text: question.choiceA,
                  onPressed: () => _handleAnswer(1),
                ),
                const SizedBox(height: 16),

                // 選択肢B (-1)
                _buildChoiceButton(
                  text: question.choiceB,
                  onPressed: () => _handleAnswer(-1),
                ),

                const SizedBox(height: 32),

                // 1問目以外は「前に戻る」ボタンを表示
                if (index > 0)
                  TextButton.icon(
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("1つ前の質問に戻る"),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                    ),
                  )
                else
                  const SizedBox(height: 48), // ボタンがない時の高さ合わせ
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChoiceButton({required String text, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }
}