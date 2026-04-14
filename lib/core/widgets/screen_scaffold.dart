import 'package:flutter/material.dart';

import '../app_colors.dart';

class ScreenScaffold extends StatelessWidget {
  const ScreenScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.useScroll = true,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final bool useScroll;

  @override
  Widget build(BuildContext context) {
    final content = useScroll
        ? SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: body,
          )
        : Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: body,
          );

    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      body: Column(
        children: [
          Container(
            color: AppColors.teal,
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: MediaQuery.paddingOf(context).top + 20,
              bottom: 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ...actions,
              ],
            ),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}
