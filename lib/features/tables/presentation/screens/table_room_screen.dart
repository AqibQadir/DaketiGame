import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/guest_name_provider.dart';

import '../../domain/table_room.dart';
import '../../domain/table_match_selection.dart';
import '../widgets/table_card.dart';
import '../widgets/focused_card_carousel.dart';
import '../widgets/table_page_shell.dart';

class TableRoomScreen extends ConsumerWidget {
  const TableRoomScreen({super.key, required this.room});

  final TableRoom room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const stakes = TableTier.values;
    return TablePageShell(
      title: room.cityName.toUpperCase(),
      titlePlateAsset: room == TableRoom.islamabad
          ? null
          : 'assets/images/cities/plates/${room.artwork}.png',
      backgroundAsset: room.backgroundAsset(
          portrait: MediaQuery.sizeOf(context).height >
              MediaQuery.sizeOf(context).width),
      child: FocusedCardCarousel(
        pageKey: const ValueKey('table-tier-pages'),
        label: 'Tables',
        itemCount: stakes.length,
        itemBuilder: (context, index) => TableCard(
          title: stakes[index].title,
          subtitle: stakes[index].subtitle,
          buyIn: stakes[index].buyIn,
          reward: stakes[index].reward,
          badge: stakes[index].badge,
          locked: stakes[index].locked,
          wholeCardClickable: true,
          imageAsset: stakes[index].imageAsset,
          onTap: () {
            if (stakes[index].locked) return;
            final name = ref.read(authControllerProvider).user?.name ??
                ref.read(guestNameProvider);
            Navigator.pushNamed(context,
                name == null ? AppRoutes.guestName : AppRoutes.guestOpponents,
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
    );
  }
}
