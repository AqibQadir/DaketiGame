import 'package:flutter/material.dart';
import '../../../../core/routes/app_routes.dart';
import '../../domain/table_room.dart';
import 'focused_card_carousel.dart';
import 'table_card.dart';

class CityTableCards extends StatelessWidget {
  const CityTableCards({super.key});

  @override
  Widget build(BuildContext context) => FocusedCardCarousel(
        pageKey: const ValueKey('city-pages'),
        label: 'Cities',
        itemCount: TableRoom.values.length,
        itemBuilder: (context, index) {
          final city = TableRoom.values[index];
          return TableCard(
              title: city.title,
              subtitle: city.subtitle,
              buyIn: '100',
              reward: '100',
              badge: '',
              wholeCardClickable: true,
              imageAsset: city.backgroundAsset(portrait: true),
              onTap: () => Navigator.pushNamed(context, AppRoutes.tableRoom,
                  arguments: city));
        },
      );
}
