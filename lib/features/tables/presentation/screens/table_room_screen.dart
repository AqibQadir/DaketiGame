import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/guest_name_provider.dart';

import '../../domain/table_room.dart';
import '../../domain/table_match_selection.dart';
import '../widgets/table_card.dart';
import '../widgets/table_categories.dart';
import '../widgets/table_page_shell.dart';

class TableRoomScreen extends ConsumerWidget {
  const TableRoomScreen({super.key, required this.room});

  final TableRoom room;

  bool get purple => room == TableRoom.dubaiRise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const stakes = TableTier.values;
    return TablePageShell(
      title: room.title,
      categories: const TableCategories(),
      child: Row(
        children: [
          for (var index = 0; index < stakes.length; index++) ...[
            Expanded(
              child: TableCard(
                title: stakes[index].title,
                subtitle: stakes[index].subtitle,
                buyIn: stakes[index].buyIn,
                reward: stakes[index].reward,
                badge: stakes[index].badge,
                purple: purple,
                imageAsset: room.imageAsset,
                onTap: () {
                  final name = ref.read(authControllerProvider).user?.name ??
                      ref.read(guestNameProvider);
                  Navigator.pushNamed(
                      context,
                      name == null
                          ? AppRoutes.guestName
                          : AppRoutes.guestOpponents,
                      arguments: name == null
                          ? TableMatchSelection(room: room, tier: stakes[index])
                          : TableMatchArguments(
                              playerName: name,
                              selection: TableMatchSelection(
                                  room: room, tier: stakes[index]),
                            ));
                },
              ),
            ),
            if (index != stakes.length - 1) const SizedBox(width: 12),
          ],
          const SizedBox(width: 7),
          const Icon(
            Icons.arrow_forward_ios,
            size: 31,
            color: Color(0xFFC79150),
          ),
        ],
      ),
    );
  }
}
