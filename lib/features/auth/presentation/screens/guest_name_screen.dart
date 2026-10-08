import '../../data/guest_session_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/guest_name_provider.dart';
import '../../../tables/domain/table_match_selection.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/game_close_button.dart';
import '../../../../core/widgets/daketi_logo.dart';

class GuestNameScreen extends ConsumerStatefulWidget {
  const GuestNameScreen(
      {super.key, this.tableSelection, this.returnToPrevious = false});

  final TableMatchSelection? tableSelection;
  final bool returnToPrevious;
  @override
  ConsumerState<GuestNameScreen> createState() => _GuestNameScreenState();
}

class _GuestNameScreenState extends ConsumerState<GuestNameScreen> {
  bool saving = false;
  final form = GlobalKey<FormState>();
  final controller = TextEditingController();
  @override
  void initState() {
    super.initState();
    controller.text = ref.read(guestNameProvider) ?? '';
    if (!widget.returnToPrevious) restoreGuest();
  }

  Future<void> restoreGuest() async {
    try {
      final name = await GuestSessionStorage().read();
      if (!mounted ||
          name == null ||
          (controller.text.isNotEmpty && controller.text != name) ||
          saving) {
        return;
      }
      controller.text = name;
      ref.read(guestNameProvider.notifier).state = name;
      navigateToRooms();
    } catch (_) {/* Allow manual guest entry if storage is unavailable. */}
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> continueToRooms() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await GuestSessionStorage().save(controller.text.trim());
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not save your guest session. Please retry.')));
      }
      return;
    }
    if (!mounted) return;
    ref.read(guestNameProvider.notifier).state = controller.text.trim();
    FocusScope.of(context).unfocus();
    navigateToRooms();
  }

  void navigateToRooms() {
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
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GameBackground(
        child: Center(
            child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
              width: 844,
              height: 390,
              child: Stack(children: [
                Positioned(
                    right: 18,
                    top: 18,
                    child: GameCloseButton(onTap: () {
                      final navigator = Navigator.of(context);
                      if (navigator.canPop()) {
                        navigator.pop();
                      } else {
                        navigator.pushReplacementNamed(AppRoutes.welcome);
                      }
                    })),
                Positioned(
                    top: 46,
                    left: 0,
                    right: 0,
                    child: Column(children: [
                      const DaketiLogo(width: 320, height: 120),
                      const SizedBox(height: 18),
                      AnimatedSlide(
                        offset: Offset(0, keyboardOpen ? -.65 : 0),
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: SizedBox(
                            width: 280,
                            child: Form(
                                key: form,
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextFormField(
                                        controller: controller,
                                        maxLength: 24,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        textInputAction: TextInputAction.done,
                                        onFieldSubmitted: (_) =>
                                            continueToRooms(),
                                        style: const TextStyle(fontSize: 14),
                                        decoration: InputDecoration(
                                          hintText: 'Your name',
                                          counterText: '',
                                          hintStyle: const TextStyle(
                                              color: Colors.white38),
                                          filled: true,
                                          fillColor: const Color(0x773C3A36),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 20, vertical: 10),
                                          enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              borderSide: const BorderSide(
                                                  color: Colors.white30)),
                                          focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              borderSide: const BorderSide(
                                                  color: Color(0xFFFF8500))),
                                        ),
                                        validator: (value) => value == null ||
                                                value.trim().isEmpty
                                            ? 'Enter your name'
                                            : null,
                                      ),
                                      const SizedBox(height: 16),
                                      GameButton(
                                          text: 'Play as Guest',
                                          isLoading: saving,
                                          width: 200,
                                          onTap:
                                              saving ? null : continueToRooms),
                                    ]))),
                      ),
                    ])),
              ])),
        )),
      ),
    );
  }
}
