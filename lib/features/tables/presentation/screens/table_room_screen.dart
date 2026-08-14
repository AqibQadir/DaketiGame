import 'package:flutter/material.dart';

import '../../domain/table_room.dart';
import '../widgets/table_card.dart';
import '../widgets/table_categories.dart';
import '../widgets/table_page_shell.dart';

class TableRoomScreen extends StatelessWidget {
  const TableRoomScreen({super.key, required this.room});

  final TableRoom room;

  bool get purple => room == TableRoom.dubaiRise;

  @override
  Widget build(BuildContext context) {
    const stakes = [
      ('SILVER', 'LOW STAKES', '100', '100', 'STARTER'),
      ('GOLD', 'MID STAKES', '500', '700', 'POPULAR'),
      ('PLATINUM', 'HIGHEST STAKES', '2000', '2500', 'PREMIUM'),
      ('DIAMOND', 'EXCLUSIVE STAKES', '10K', '10K', 'EXCLUSIVE'),
    ];
    return TablePageShell(
      title: room.title,
      categories: const TableCategories(),
      child: Row(
        children: [
          for (var index = 0; index < stakes.length; index++) ...[
            Expanded(
              child: TableCard(
                title: stakes[index].$1,
                subtitle: stakes[index].$2,
                buyIn: stakes[index].$3,
                reward: stakes[index].$4,
                badge: stakes[index].$5,
                locked: index == stakes.length - 1,
                purple: purple,
                imageAsset:
                    'assets/images/tables/rooms/${room.name}_${stakes[index].$1.toLowerCase()}.png',
                onTap: () {},
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
