import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/game_background.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/widgets/game_viewport.dart';
import '../../../core/widgets/game_styled_dialog.dart';
import '../../../core/widgets/game_dialog_title.dart';
import '../domain/friends_controller.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../auth/presentation/widgets/account_required_screen.dart';

enum FriendsTab { friends, find, requests }

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen(
      {super.key, this.initialTab = FriendsTab.friends, this.embedded = false});
  final bool embedded;
  final FriendsTab initialTab;

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  late FriendsTab tab = widget.initialTab;
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void _select(FriendsTab value) => setState(() {
        tab = value;
        search.clear();
      });

  Future<void> _remove(FriendPlayer player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => GameStyledDialog(
        title: const GameDialogTitle('REMOVE FRIEND'),
        content: Text('Remove ${player.name} from your friend list?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (mounted && confirmed == true) {
      ref.read(friendsProvider.notifier).remove(player.id);
    }
  }

  void _profile(FriendPlayer player) {
    showDialog<void>(
      context: context,
      builder: (context) => GameStyledDialog(
        title: const GameDialogTitle('PLAYER PROFILE'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(radius: 36, backgroundImage: AssetImage(player.avatar)),
          const SizedBox(height: 12),
          Text(player.name,
              style: const TextStyle(fontSize: 20, color: Colors.white)),
          Text('${player.id} · ${player.city}'),
          const SizedBox(height: 8),
          Text(
              player.online ? 'Online · demo player' : 'Offline · demo player'),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    if (auth.isRestoring) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!auth.isAuthenticated) return const AccountRequiredScreen();
    final players = ref.watch(friendsProvider);
    final friends =
        players.where((p) => p.relationship == Friendship.friend).length;
    final incoming =
        players.where((p) => p.relationship == Friendship.incoming).length;
    final query =
        search.text.trim().toLowerCase().replaceFirst(RegExp(r'^#'), '');
    final visible = players.where((p) {
      final inTab = switch (tab) {
        FriendsTab.friends => p.relationship == Friendship.friend,
        FriendsTab.find => true,
        FriendsTab.requests => p.relationship == Friendship.incoming ||
            p.relationship == Friendship.outgoing,
      };
      return inTab &&
          (query.isEmpty ||
              p.name.toLowerCase().contains(query) ||
              p.id.toLowerCase().contains(query));
    }).toList();
    if (tab == FriendsTab.find) {
      const order = [
        Friendship.none,
        Friendship.incoming,
        Friendship.outgoing,
        Friendship.friend
      ];
      visible.sort((a, b) {
        final rank = order
            .indexOf(a.relationship)
            .compareTo(order.indexOf(b.relationship));
        return rank == 0 ? a.name.compareTo(b.name) : rank;
      });
    }
    final controller = ref.read(friendsProvider.notifier);
    final content = Padding(
      padding: widget.embedded
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(30, 16, 30, 16),
      child: Column(children: [
        Row(children: [
          if (!widget.embedded)
            IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.maybePop(context),
                icon:
                    const Icon(Icons.arrow_back_ios, color: Color(0xFFE4B574))),
          const Text('FRIENDS',
              style: TextStyle(
                  fontFamily: 'Dirty Brush',
                  fontSize: 27,
                  color: Color(0xFFFF8500))),
          const Spacer(),
          const Icon(Icons.people_outline,
              size: 17, color: Colors.orangeAccent),
          const SizedBox(width: 8),
          Text('$friends friends',
              style: const TextStyle(color: Colors.white70)),
        ]),
        const SizedBox(height: 2),
        Align(
            alignment: Alignment.centerLeft,
            child: Text(
                widget.embedded
                    ? 'Demo friends · Requests stay in this session.'
                    : 'Demo players · Changes last for this app session. No real requests are sent.',
                style:
                    const TextStyle(fontSize: 11, color: Color(0xFFD2B995)))),
        const SizedBox(height: 12),
        Wrap(spacing: 6, runSpacing: 4, children: [
          _tab('My friends ($friends)', FriendsTab.friends),
          _tab('Find friends', FriendsTab.find),
          _tab('Requests ($incoming)', FriendsTab.requests),
        ]),
        const SizedBox(height: 6),
        SizedBox(
            height: 34,
            child: TextField(
              controller: search,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Name or player ID',
                filled: true,
                fillColor: const Color(0xCC15120F),
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => setState(search.clear)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            )),
        const SizedBox(height: 12),
        Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.person_search,
                        size: 34, color: Colors.white38),
                    const SizedBox(height: 8),
                    Text(
                        query.isNotEmpty
                            ? 'No players found'
                            : tab == FriendsTab.friends
                                ? 'Your friend list is empty'
                                : 'No pending requests',
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white)),
                    const SizedBox(height: 5),
                    Text(
                        query.isNotEmpty
                            ? 'Try another name or player ID.'
                            : 'Find players and send a friend request.',
                        style: const TextStyle(color: Colors.white60)),
                    if (query.isEmpty)
                      TextButton(
                          onPressed: () => _select(FriendsTab.find),
                          child: const Text('Find friends')),
                  ]))
                : GridView.builder(
                    padding: const EdgeInsets.only(bottom: 4),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: widget.embedded ? 1 : 2,
                        mainAxisExtent: widget.embedded ? 92 : 112,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 10),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final player = visible[index];
                      return Container(
                        key: ValueKey(player.id),
                        padding: EdgeInsets.all(widget.embedded ? 8 : 12),
                        decoration: BoxDecoration(
                            color: const Color(0xDD191714),
                            border: Border.all(color: const Color(0xFF62503B)),
                            borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [
                          InkWell(
                              onTap: () => _profile(player),
                              child: CircleAvatar(
                                  radius: widget.embedded ? 20 : 28,
                                  backgroundImage: AssetImage(player.avatar))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              InkWell(
                                  onTap: () => _profile(player),
                                  child: Text(player.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.white))),
                              const SizedBox(height: 3),
                              Text('${player.id} · ${player.city}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.white54)),
                              const SizedBox(height: 4),
                              Row(children: [
                                Icon(Icons.circle,
                                    size: 6,
                                    color: player.online
                                        ? const Color(0xFF70C694)
                                        : Colors.white30),
                                const SizedBox(width: 4),
                                Text(player.online ? 'Online' : 'Offline',
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.white60)),
                              ]),
                            ],
                          )),
                          const SizedBox(width: 6),
                          SizedBox(
                              width: 92,
                              child: switch (player.relationship) {
                                Friendship.none => _button('Add friend',
                                    () => controller.add(player.id)),
                                Friendship.friend => Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('Friends',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF70C694))),
                                        _button('Remove', () => _remove(player),
                                            secondary: true),
                                      ]),
                                Friendship.incoming => Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!widget.embedded)
                                          const Text('Received',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white54)),
                                        _button('Accept',
                                            () => controller.accept(player.id)),
                                        _button('Decline',
                                            () => controller.decline(player.id),
                                            secondary: true),
                                      ]),
                                Friendship.outgoing => Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('Request sent',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.orangeAccent)),
                                        _button('Cancel',
                                            () => controller.cancel(player.id),
                                            secondary: true),
                                      ]),
                              }),
                        ]),
                      );
                    },
                  )),
      ]),
    );
    if (widget.embedded) return content;
    return Scaffold(
        body: GameBackground(
            overlayOpacity: .45, child: GameViewport(child: content)));
  }

  Widget _tab(String label, FriendsTab value) => Semantics(
        selected: tab == value,
        child: GameButton(
          text: label,
          width: widget.embedded ? 108 : 146,
          fontSize: 13,
          backgroundTint: tab == value ? null : const Color(0xFF72513C),
          onTap: () => _select(value),
        ),
      );

  Widget _button(String label, VoidCallback action, {bool secondary = false}) =>
      GameButton(
        text: label,
        width: 86,
        fontSize: 12,
        backgroundTint: secondary ? const Color(0xFF72513C) : null,
        onTap: action,
      );
}
