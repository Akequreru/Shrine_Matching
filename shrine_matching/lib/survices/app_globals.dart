import 'package:flutter/material.dart';
import 'package:shrine_matching/survices/visit_prompt_service.dart';

// アプリ全体でどの画面からでも参拝パネルを表示できるよう、ルートのNavigatorKeyを共有する
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final VisitPromptService visitPromptService = VisitPromptService(rootNavigatorKey);
