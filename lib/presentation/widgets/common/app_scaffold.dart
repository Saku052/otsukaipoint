import 'package:flutter/material.dart';

/// アプリ共通のScaffold
class AppScaffold extends StatelessWidget {
  /// タイトル
  final String? title;
  
  /// ボディ
  final Widget body;
  
  /// フローティングアクションボタン
  final Widget? floatingActionButton;
  
  /// アプリバーアクション
  final List<Widget>? actions;
  
  /// 戻るボタンを表示するか
  final bool automaticallyImplyLeading;
  
  /// アプリバーを表示するか
  final bool showAppBar;
  
  /// 背景色
  final Color? backgroundColor;
  
  /// 下部ナビゲーションバー
  final Widget? bottomNavigationBar;
  
  /// 引き出しメニュー
  final Widget? drawer;
  
  /// 右引き出しメニュー
  final Widget? endDrawer;
  
  /// セーフエリアを適用するか
  final bool resizeToAvoidBottomInset;

  const AppScaffold({
    super.key,
    this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.showAppBar = true,
    this.backgroundColor,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: title != null ? Text(title!) : null,
              actions: actions,
              automaticallyImplyLeading: automaticallyImplyLeading,
              backgroundColor: backgroundColor,
              elevation: 0,
              surfaceTintColor: Theme.of(context).colorScheme.surface,
            )
          : null,
      body: body,
      floatingActionButton: floatingActionButton,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surface,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}