import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/game_button.dart';
import '../widgets/support_page_shell.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void submit() {
    final text = controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the issue first.')),
      );
      return;
    }
    controller.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your report has been recorded.')),
    );
  }

  @override
  Widget build(BuildContext context) => SupportPageShell(
        title: 'Report An Issue',
        width: 440,
        height: 260,
        child: Column(children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLength: 200,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'What problem did you face...',
                hintStyle: const TextStyle(
                  color: Colors.white38,
                  fontStyle: FontStyle.italic,
                ),
                filled: true,
                fillColor: const Color(0xA80E0D0C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.panelBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.panelBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.orange),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          GameButton(text: 'Submit', width: 105, onTap: submit),
        ]),
      );
}
