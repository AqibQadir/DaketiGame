import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tables/domain/table_room.dart';

/// Host-side presentation details until the server supports shared room metadata.
class CustomRoomDetails {
  const CustomRoomDetails(
      {required this.gameId, required this.name, required this.city});
  final String gameId;
  final String name;
  final TableRoom city;
}

final customRoomDetailsProvider =
    StateProvider<CustomRoomDetails?>((ref) => null);
