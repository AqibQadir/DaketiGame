import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_assets.dart';
import 'game_button.dart';
import 'game_dialog_title.dart';

/// Shared glass-and-brush treatment for notices, confirmations and form dialogs.
class GameStyledDialog extends StatelessWidget {
  const GameStyledDialog(
      {super.key,
      this.title,
      this.content,
      this.actions = const [],
      Color? backgroundColor,
      ShapeBorder? shape,
      bool scrollable = false,
      MainAxisAlignment? actionsAlignment});
  final Widget? title;
  final Widget? content;
  final List<Widget> actions;

  Widget _action(Widget action) {
    if (action is! ButtonStyleButton || action.child is! Text) return action;
    final text = (action.child! as Text).data ?? '';
    final destructive = [
      'YES',
      'LEAVE MATCH',
      'SKIP',
      'DISCARD',
      'DELETE',
      'LOGOUT'
    ].contains(text.toUpperCase());
    return GameButton(
        text: text,
        onTap: action.onPressed,
        width: text.length > 15 ? 155 : 120,
        fontSize: 16,
        backgroundAsset: AppAssets.actionButtonBrush,
        backgroundTint: destructive ? const Color(0xFFBC201B) : null);
  }

  @override
  Widget build(BuildContext context) {
    final heading = title is GameDialogTitle
        ? Text((title! as GameDialogTitle).title)
        : title;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 350),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF77746A), width: .8),
                gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xB32B2923),
                      Color(0xD9100B05),
                      Color(0xDE140803)
                    ]),
              ),
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 26, vertical: 34),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (heading != null)
                    DefaultTextStyle(
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontFamily: 'Dirty Brush',
                            fontSize: 23,
                            color: Color(0xFFFF8500)),
                        child: heading),
                  if (content != null) ...[
                    if (heading != null) const SizedBox(height: 16),
                    DefaultTextStyle(
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                        child: content!),
                  ],
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 18,
                        runSpacing: 12,
                        children: actions.map(_action).toList()),
                  ],
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
