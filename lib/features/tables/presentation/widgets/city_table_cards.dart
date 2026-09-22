import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../domain/table_room.dart';
import 'table_card.dart';

class CityTableCards extends StatelessWidget {
  const CityTableCards({super.key});

  @override
  Widget build(BuildContext context) => Row(
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
        ],
      );
}
