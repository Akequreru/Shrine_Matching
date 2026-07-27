import 'package:flutter/material.dart';

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
  
  // 現在の質問インデックス
  int _currentIndex = 0;

  // 12問分の回答を保持するリスト（1: 選択肢A, -1: 選択肢B, 0: 未回答）
  // 戻って選び直したときに上書きできるように、スコアの足し算ではなく「回答の記録」に変更
  List<int> userAnswers = List.filled(12, 0);

  // いただいた12問のデータ（各軸3問ずつ）
// いただいた12問のデータ（各軸3問ずつ）
  final List<DiagnosticQuestion> questions = [
    // --- 軸0: E or I (旅行スタイル・対人) ---
    DiagnosticQuestion(axis: 0, text: "にぎやかな旅が好きですか？それとも、静かで落ち着いた旅が好きですか？", choiceA: "にぎやかな旅", choiceB: "静かで落ち着いた旅"),
    DiagnosticQuestion(axis: 0, text: "大人数での旅行が好きですか？それとも、一人旅が好きですか？", choiceA: "大人数での旅行", choiceB: "一人旅"),
    DiagnosticQuestion(axis: 0, text: "旅先で新しい友達を作りますか？それとも、人見知りしますか？", choiceA: "新しい友達", choiceB: "人見知り"),
    
    // --- 軸1: S or N (判断基準) ---
    DiagnosticQuestion(axis: 1, text: "事実や具体的な情報に基づいて判断しますか？それとも、未来の可能性や直感に頼りますか？", choiceA: "事実や具体的な情報", choiceB: "未来の可能性や直感"),
    DiagnosticQuestion(axis: 1, text: "現実的で実用的なことに焦点を当てますか？それとも、理想や抽象的なアイデアに興味を持ちますか？", choiceA: "現実的で実用的なこと", choiceB: "理想や抽象的なアイデア"),
    DiagnosticQuestion(axis: 1, text: "今起こっていることに集中しますか？それとも、先のことを考えることが多いですか？", choiceA: "今起こっていること", choiceB: "先のこと"),
    
    // --- 軸2: T or F (意思決定) ---
    DiagnosticQuestion(axis: 2, text: "論理的で客観的な判断を好みますか？それとも、人間関係や感情を考慮して判断しますか？", choiceA: "論理的で客観的", choiceB: "人間関係や感情"),
    DiagnosticQuestion(axis: 2, text: "決定を下す際に、公平さや原則を重視しますか？それとも、調和や共感を重視しますか？", choiceA: "公平さや原則", choiceB: "調和や共感"),
    DiagnosticQuestion(axis: 2, text: "自分の意見をはっきりと伝えることが得意ですか？それとも、他人の感情に配慮して言葉を選びますか？", choiceA: "意見をはっきりと伝える", choiceB: "他人の感情に配慮する"),
    
    // --- 軸3: J or P (旅行の計画性) ---
    DiagnosticQuestion(axis: 3, text: "旅行は計画を立ててから出かけることが好きですか？それとも、気ままに出かけることを好みますか？", choiceA: "計画を立ててから出かける", choiceB: "気ままに出かける"),
    DiagnosticQuestion(axis: 3, text: "旅行は予定通りに進めたいですか？それとも、思いがけない出来事がある方が良いですか？", choiceA: "予定通りに進めたい", choiceB: "思いがけない出来事がある方が良い"),
    DiagnosticQuestion(axis: 3, text: "お土産はあらかじめ何を買うか決めますか？それとも、お土産屋さんで決めますか？", choiceA: "あらかじめ決めておく", choiceB: "お土産屋さんで決める"),
  ];

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
    // 3問ずつの合計値を計算（必ずプラスかマイナスになる）
    int eScore = userAnswers[0] + userAnswers[1] + userAnswers[2];
    int sScore = userAnswers[3] + userAnswers[4] + userAnswers[5];
    int tScore = userAnswers[6] + userAnswers[7] + userAnswers[8];
    int jScore = userAnswers[9] + userAnswers[10] + userAnswers[11];

    String typeStr = "";
    typeStr += (eScore > 0) ? "E" : "I";
    typeStr += (sScore > 0) ? "S" : "N";
    typeStr += (tScore > 0) ? "T" : "F";
    typeStr += (jScore > 0) ? "J" : "P";

    int typeId = _convertToTypeId(typeStr);

    // Navigator.pushReplacement を使うと、結果画面から「戻る」ボタンで質問に戻れなくなります（診断リセット）
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(typeId: typeId, typeStr: typeStr),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('相性診断'),
        // AppBar左上の標準の戻るボタンをカスタマイズ（途中離脱を防ぐための確認などを入れることも可能）
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
          
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Q${index + 1} / ${questions.length}",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                Text(
                  question.text,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

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

// ==========================================
// 2. 結果画面（チームメンバーが後で作り込む用）
// ==========================================
class ResultScreen extends StatelessWidget {
  final int typeId;
  final String typeStr;

  const ResultScreen({
    Key? key,
    required this.typeId,
    required this.typeStr,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('診断結果'),
        automaticallyImplyLeading: false, // 戻る矢印を隠す（診断をやり直させるため）
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "あなたのタイプは...",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Text(
                "タイプ$typeId\n($typeStr)",
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text(
                "※ここに詳細な説明文やイラストを配置します。",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              
              // このボタンを押して、あなたに合う神社を表示する処理などを追加予定
              ElevatedButton(
                onPressed: () {
                  // TODO: おすすめの神社一覧画面へ遷移する
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("あなたに合う神社を見る"),
              ),
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: () {
                  // 診断画面に戻ってやり直す
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const DiagnosticScreen()),
                  );
                },
                child: const Text("もう一度診断する"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}