import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../domain/table_room.dart';
import '../widgets/table_card.dart';
import '../widgets/table_categories.dart';
import '../widgets/table_page_shell.dart';

class TablesScreen extends StatelessWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TablePageShell(
      title: 'TABLES',
      categories: const TableCategories(),
      child: Row(
        children: [
          for (final room in TableRoom.values) ...[
            Expanded(
              child: TableCard(
                title: room.title,
                subtitle: room.subtitle,
                buyIn: switch (room) {
                  TableRoom.oldLahore => '100',
                  TableRoom.karachiClan => '500',
                  TableRoom.dubaiRise => '2000',
                  TableRoom.thaiBliss => '10K',
                },
                reward: switch (room) {
                  TableRoom.oldLahore => '100',
                  TableRoom.karachiClan => '700',
                  TableRoom.dubaiRise => '2500',
                  TableRoom.thaiBliss => '10K',
                },
                badge: switch (room) {
                  TableRoom.oldLahore => 'STARTER',
                  TableRoom.karachiClan => 'POPULAR',
                  TableRoom.dubaiRise => 'PREMIUM',
                  TableRoom.thaiBliss => 'EXCLUSIVE',
                },
                imageAsset: room.imageAsset,
                locked: room.locked,
                purple: room == TableRoom.dubaiRise,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.tableRoom,
                  arguments: room,
                ),
              ),
            ),
            if (room != TableRoom.thaiBliss) const SizedBox(width: 12),
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
