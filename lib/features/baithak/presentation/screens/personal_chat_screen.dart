import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../widgets/baithak_page_shell.dart';

class PersonalChatScreen extends StatefulWidget {
  const PersonalChatScreen({super.key});

  @override
  State<PersonalChatScreen> createState() => _PersonalChatScreenState();
}

class _PersonalChatScreenState extends State<PersonalChatScreen> {
  final controller = TextEditingController();
  final messages = <String>[];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void send() {
    final message = controller.text.trim();
    if (message.isEmpty) return;
    setState(() => messages.add(message));
    controller.clear();
  }

  @override
  Widget build(BuildContext context) => BaithakPageShell(
        title: 'A Person Chat',
        showTopBar: false,
        child: Center(
          child: Container(
            width: 450,
            height: 230,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xD913100E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.panelBorder),
              boxShadow: const [
                BoxShadow(color: Colors.black87, blurRadius: 18),
              ],
            ),
            child: Column(children: [
              const Row(children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: Color(0xFFD6D3CF),
                  child: Icon(Icons.face, color: Color(0xFF4B382B)),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THE FULL NAME',
                      style: TextStyle(
                        color: AppColors.orange,
                        fontFamily: 'Dirty Brush',
                        fontSize: 13,
                      ),
                    ),
                    Text('The Dakait Group', style: TextStyle(fontSize: 8)),
                  ],
                ),
              ]),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (_, index) => Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xA34A3322),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(messages[index],
                          style: const TextStyle(fontSize: 9)),
                    ),
                  ),
                ),
              ),
              Container(
                height: 38,
                padding: const EdgeInsets.only(left: 12, right: 4),
                decoration: BoxDecoration(
                  color: const Color(0xB2080808),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.panelBorder),
                ),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onSubmitted: (_) => send(),
                      style: const TextStyle(fontSize: 10),
                      decoration: const InputDecoration(
                        hintText: 'Write a Message...',
                        hintStyle: TextStyle(fontSize: 9),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: send,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Send', style: TextStyle(fontSize: 9)),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      );
}
