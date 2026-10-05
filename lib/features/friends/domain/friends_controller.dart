import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_assets.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

enum Friendship { none, friend, incoming, outgoing }

class FriendPlayer {
  const FriendPlayer(this.id, this.name, this.city, this.avatar, this.online,
      this.relationship);
  final String id, name, city, avatar;
  final bool online;
  final Friendship relationship;

  FriendPlayer withRelationship(Friendship value) =>
      FriendPlayer(id, name, city, avatar, online, value);
}

/// Demo state only: no request is sent to a real player. Keep this provider
/// boundary when replacing the demo directory with an authenticated repository.
final friendsProvider =
    StateNotifierProvider<FriendsController, List<FriendPlayer>>((ref) {
  ref.watch(authControllerProvider.select((auth) => auth.user?.id));
  return FriendsController();
});

class FriendsController extends StateNotifier<List<FriendPlayer>> {
  FriendsController()
      : super(const [
          FriendPlayer('DK1001', 'Hamza Malik', 'Karachi',
              AppAssets.playerHamza, true, Friendship.friend),
          FriendPlayer('DK1002', 'Ayesha Khan', 'Lahore',
              AppAssets.playerAyesha, false, Friendship.friend),
          FriendPlayer('DK1003', 'Bilal Ahmed', 'Rawalpindi',
              AppAssets.playerBilal, true, Friendship.incoming),
          FriendPlayer('DK1004', 'Mahnoor Fatima', 'Multan',
              AppAssets.playerMahnoor, false, Friendship.incoming),
          FriendPlayer('DK1005', 'Saad Qureshi', 'Islamabad',
              AppAssets.playerSaad, true, Friendship.none),
          FriendPlayer('DK1006', 'Zara Ali', 'Karachi', AppAssets.playerAvatar,
              false, Friendship.none),
          FriendPlayer('DK1007', 'Usman Raza', 'Lahore', AppAssets.playerAvatar,
              true, Friendship.none),
          FriendPlayer('DK1008', 'Hassan Shah', 'Peshawar',
              AppAssets.playerAvatar, false, Friendship.outgoing),
        ]);

  void _transition(String id, Friendship from, Friendship to) {
    state = [
      for (final player in state)
        if (player.id == id && player.relationship == from)
          player.withRelationship(to)
        else
          player,
    ];
  }

  void add(String id) => _transition(id, Friendship.none, Friendship.outgoing);
  void accept(String id) =>
      _transition(id, Friendship.incoming, Friendship.friend);
  void decline(String id) =>
      _transition(id, Friendship.incoming, Friendship.none);
  void cancel(String id) =>
      _transition(id, Friendship.outgoing, Friendship.none);
  void remove(String id) => _transition(id, Friendship.friend, Friendship.none);
}
