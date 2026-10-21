import 'package:flutter/material.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/widgets/account_required_screen.dart';
import '../../../auth/presentation/controllers/guest_name_provider.dart';
import '../widgets/room_code_input.dart';
import '../widgets/room_city_picker.dart';
import '../controllers/custom_room_details.dart';
import '../../../tables/domain/table_room.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_alert.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/game_close_button.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/game_viewport.dart';
import '../../../friends/presentation/friends_screen.dart';
import '../controllers/game_controller.dart';
import '../../domain/models/daketi_game.dart';

class MultiplayerScreen extends ConsumerStatefulWidget {
  const MultiplayerScreen({
    super.key,
    this.initialPlayerName = '',
  });

  final String initialPlayerName;

  @override
  ConsumerState<MultiplayerScreen> createState() => _MultiplayerScreenState();
}

class _MultiplayerScreenState extends ConsumerState<MultiplayerScreen> {
  final codeController = TextEditingController();
  final roomNameController = TextEditingController();
  final roomForm = GlobalKey<FormState>();
  TableRoom? roomCity;
  int maxPlayers = 4;

  String get playerName => (ref.read(authControllerProvider).user?.name ??
          (widget.initialPlayerName.trim().isNotEmpty
              ? widget.initialPlayerName
              : null) ??
          ref.read(guestNameProvider) ??
          '')
      .trim();

  bool _identityPending = false;

  Future<bool> ensureIdentity() async {
    if (playerName.isNotEmpty) return true;
    if (_identityPending) return false;
    _identityPending = true;
    try {
      await Navigator.pushNamed(context, AppRoutes.guestName,
          arguments: AppRoutes.multiplayer);
      return mounted && playerName.isNotEmpty;
    } finally {
      _identityPending = false;
    }
  }

  @override
  void dispose() {
    codeController.dispose();
    roomNameController.dispose();
    super.dispose();
  }

  Future<void> createRoom() async {
    if (ref.read(gameControllerProvider).isLoading) return;
    if (!(roomForm.currentState?.validate() ?? false)) return;
    if (roomCity == null) {
      _message('Please select a city for your room.');
      return;
    }
    if (!await ensureIdentity() || !mounted) return;
    final name = playerName;
    final success = await ref
        .read(gameControllerProvider.notifier)
        .createMultiplayerRoom(playerName: name, maxPlayers: maxPlayers);
    if (mounted && success) {
      final gameId = ref.read(gameControllerProvider).gameId;
      if (gameId != null) {
        ref.read(customRoomDetailsProvider.notifier).state = CustomRoomDetails(
            gameId: gameId,
            name: roomNameController.text.trim(),
            city: roomCity!);
      }
    }
    if (mounted) _finish(success);
  }

  Future<void> joinRoom() async {
    if (ref.read(gameControllerProvider).isLoading) return;
    if (!await ensureIdentity() || !mounted) return;
    final name = playerName;
    final code = codeController.text.trim();
    if (name.isEmpty || !RegExp(r'^\d{4}$').hasMatch(code)) {
      _message('Enter a four-digit room code.');
      return;
    }
    final success = await ref
        .read(gameControllerProvider.notifier)
        .joinExistingGame(gameId: code, playerName: name);
    if (mounted) _finish(success);
  }

  void _finish(bool success) {
    if (success) {
      final status = ref.read(gameControllerProvider).game?.status;
      Navigator.pushReplacementNamed(
          context,
          status == DaketiGameStatus.playing
              ? AppRoutes.game
              : status == DaketiGameStatus.finished
                  ? AppRoutes.results
                  : AppRoutes.waitingRoom);
    } else {
      _message(
        ref.read(gameControllerProvider).error ?? 'Unable to join the room.',
      );
    }
  }

  void _message(String value) {
    showGameAlert(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    if (auth.isRestoring) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!auth.isAuthenticated) return const AccountRequiredScreen();
    final loading = ref.watch(gameControllerProvider).isLoading;
    return Scaffold(
      body: GameBackground(
        child: GameViewport(
          child: Stack(children: [
            Positioned(
                left: 12,
                top: 10,
                child: GameCloseButton(onTap: Navigator.of(context).pop)),
            const Positioned(
                left: 62,
                top: 18,
                child: Text('FRIENDS & CUSTOM ROOM',
                    style: TextStyle(
                        fontFamily: 'Dirty Brush',
                        fontSize: 24,
                        color: Colors.white))),
            Positioned(
              left: 10,
              right: 10,
              top: 54,
              bottom: 10,
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                        child: GlassPanel(
                      padding: const EdgeInsets.all(12),
                      child: SingleChildScrollView(
                          child: Form(
                              key: roomForm,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(children: [
                                    const Expanded(
                                        child: Text('CUSTOM ROOM',
                                            style: TextStyle(
                                                fontFamily: 'Dirty Brush',
                                                fontSize: 24,
                                                color: Color(0xFFFFA340)))),
                                    GameButton(
                                        text: 'Create room',
                                        isLoading: loading,
                                        width: 126,
                                        fontSize: 14,
                                        onTap: loading ? null : createRoom),
                                  ]),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: roomNameController,
                                    enabled: !loading,
                                    maxLength: 40,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    style: const TextStyle(fontSize: 13),
                                    decoration: InputDecoration(
                                      labelText: 'Room name',
                                      hintText:
                                          'e.g. Friday night with friends',
                                      counterText: '',
                                      prefixIcon: const Icon(
                                          Icons.edit_outlined,
                                          size: 18),
                                      filled: true,
                                      fillColor: Colors.black26,
                                      isDense: true,
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                            ? 'Enter a room name.'
                                            : null,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 16, color: Color(0xFFFFA340)),
                                    const SizedBox(width: 5),
                                    Expanded(
                                        child: Text(
                                            roomCity == null
                                                ? 'Select room location'
                                                : roomCity!.cityName,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white))),
                                    const Icon(Icons.swipe,
                                        size: 15, color: Colors.white54),
                                  ]),
                                  const SizedBox(height: 8),
                                  RoomCityPicker(
                                      selected: roomCity,
                                      enabled: !loading,
                                      onChanged: (city) =>
                                          setState(() => roomCity = city)),
                                  const SizedBox(height: 12),
                                  const Text('PLAYERS',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.white60)),
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    for (final count in [2, 3, 4]) ...[
                                      if (count > 2) const SizedBox(width: 8),
                                      Expanded(
                                          child: Semantics(
                                        label: '$count players',
                                        button: true,
                                        selected: maxPlayers == count,
                                        child: InkWell(
                                          onTap: loading
                                              ? null
                                              : () => setState(
                                                  () => maxPlayers = count),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Container(
                                            height: 56,
                                            decoration: BoxDecoration(
                                                color: maxPlayers == count
                                                    ? const Color(0x332D1905)
                                                    : Colors.black26,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                    color: maxPlayers == count
                                                        ? const Color(
                                                            0xFFFF8500)
                                                        : Colors.white24,
                                                    width: maxPlayers == count
                                                        ? 2
                                                        : 1)),
                                            child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: List.generate(
                                                          count,
                                                          (_) => Icon(
                                                              Icons.person,
                                                              size: 16,
                                                              color: maxPlayers ==
                                                                      count
                                                                  ? const Color(
                                                                      0xFFFFAC50)
                                                                  : Colors
                                                                      .white60))),
                                                  const SizedBox(height: 6),
                                                  Text('$count PLAYERS',
                                                      style: const TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.white)),
                                                ]),
                                          ),
                                        ),
                                      )),
                                    ],
                                  ]),
                                  const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 10),
                                      child: Divider(
                                          height: 1, color: Colors.white24)),
                                  const Text('JOIN A ROOM',
                                      style: TextStyle(
                                          fontFamily: 'Dirty Brush',
                                          fontSize: 20)),
                                  const SizedBox(height: 6),
                                  const Text(
                                      'Enter your friend’s four-digit code.',
                                      style: TextStyle(
                                          color: Colors.white60, fontSize: 11)),
                                  const SizedBox(height: 10),
                                  Row(children: [
                                    Expanded(
                                        child: RoomCodeInput(
                                            controller: codeController,
                                            enabled: !loading,
                                            onSubmitted: (_) => joinRoom())),
                                    const SizedBox(width: 10),
                                    GameButton(
                                        text: 'Join room',
                                        isLoading: loading,
                                        width: 112,
                                        fontSize: 14,
                                        onTap: loading ? null : joinRoom),
                                  ]),
                                ],
                              ))),
                    )),
                    const SizedBox(width: 12),
                    const Expanded(
                        child: GlassPanel(
                            padding: EdgeInsets.all(12),
                            child: FriendsScreen(embedded: true))),
                  ]),
            ),
          ]),
        ),
      ),
    );
  }
}
