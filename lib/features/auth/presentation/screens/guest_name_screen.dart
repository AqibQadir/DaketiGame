import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/guest_name_provider.dart';
import '../../../tables/domain/table_match_selection.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_button.dart';

class GuestNameScreen extends ConsumerStatefulWidget {
  const GuestNameScreen(
      {super.key, this.tableSelection, this.returnToPrevious = false});

  final TableMatchSelection? tableSelection;
  final bool returnToPrevious;
  @override
  ConsumerState<GuestNameScreen> createState() => _GuestNameScreenState();
}

class _GuestNameScreenState extends ConsumerState<GuestNameScreen> {
  final form = GlobalKey<FormState>();
  final controller = TextEditingController();
  int? age;
  String? gender;
  @override
  void initState() {
    super.initState();
    controller.text = ref.read(guestNameProvider) ?? '';
    final savedAge = ref.read(guestAgeProvider);
    age =
        savedAge != null && savedAge >= 14 && savedAge <= 120 ? savedAge : null;
    gender = ref.read(guestGenderProvider);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void continueToRooms() {
    if (!form.currentState!.validate()) return;
    ref.read(guestNameProvider.notifier).state = controller.text.trim();
    ref.read(guestAgeProvider.notifier).state = age;
    ref.read(guestGenderProvider.notifier).state = gender;
    if (widget.returnToPrevious) {
      Navigator.pop(context, true);
      return;
    }
    final selection = widget.tableSelection;
    if (selection != null) {
      Navigator.pushReplacementNamed(context, AppRoutes.guestOpponents,
          arguments: TableMatchArguments(
              playerName: controller.text.trim(), selection: selection));
      return;
    }
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home,
        (route) => route.settings.name == AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: GameBackground(
            child: Center(
                child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
          child: SizedBox(
              width: 440,
              child: Form(
                  key: form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('PLAY AS GUEST',
                          style: TextStyle(
                              fontFamily: 'Dirty Brush',
                              fontSize: 28,
                              color: Colors.white)),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: controller,
                          maxLength: 24,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                              labelText: 'Name', counterText: ''),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Enter your name'
                                  : null),
                      const SizedBox(height: 12),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: DropdownButtonFormField<int>(
                                    initialValue: age,
                                    isExpanded: true,
                                    decoration:
                                        const InputDecoration(labelText: 'Age'),
                                    menuMaxHeight: 200,
                                    items: List.generate(
                                        107,
                                        (index) => DropdownMenuItem(
                                            value: index + 14,
                                            child: Text('${index + 14}'))),
                                    onChanged: (value) =>
                                        setState(() => age = value),
                                    validator: (value) =>
                                        value == null ? 'Select age' : null)),
                            const SizedBox(width: 18),
                            Expanded(
                                child: DropdownButtonFormField<String>(
                                    initialValue: gender,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                        labelText: 'Gender'),
                                    items: [
                                      'Male',
                                      'Female',
                                      'Other',
                                      'Prefer not to say'
                                    ]
                                        .map((value) => DropdownMenuItem(
                                            value: value,
                                            child: Text(value,
                                                style: const TextStyle(
                                                    fontSize: 13))))
                                        .toList(),
                                    onChanged: (value) =>
                                        setState(() => gender = value),
                                    validator: (value) => value == null
                                        ? 'Select gender'
                                        : null)),
                          ]),
                      const SizedBox(height: 22),
                      GameButton(
                          text: 'Continue', width: 170, onTap: continueToRooms),
                    ],
                  ))),
        ))),
      );
}
