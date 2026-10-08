import 'package:flutter/material.dart';
import '../../../../core/routes/app_routes.dart';
import '../../domain/table_room.dart';
import 'table_card.dart';

class CityTableCards extends StatefulWidget {
  const CityTableCards({super.key});
  @override
  State<CityTableCards> createState() => _CityTableCardsState();
}

class _CityTableCardsState extends State<CityTableCards> {
  final controller = PageController();
  int page = 0;
  static const perPage = 4;
  int get pageCount => (TableRoom.values.length / perPage).ceil();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget pageArrow(bool next) => IconButton(
        tooltip: next ? 'Next cities' : 'Previous cities',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 36, height: 24),
        iconSize: 24,
        color: const Color(0xFFFFC571),
        onPressed: (next ? page < pageCount - 1 : page > 0)
            ? () => controller.animateToPage(page + (next ? 1 : -1),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut)
            : null,
        icon: Icon(next ? Icons.chevron_right : Icons.chevron_left),
      );

  @override
  Widget build(BuildContext context) => Column(children: [
        Expanded(
            child: PageView.builder(
          key: const ValueKey('city-pages'),
          controller: controller,
          itemCount: pageCount,
          onPageChanged: (value) => setState(() => page = value),
          itemBuilder: (context, index) {
            final cities =
                TableRoom.values.skip(index * perPage).take(perPage).toList();
            return Row(children: [
              for (var i = 0; i < cities.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                    child: TableCard(
                  title: cities[i].title,
                  subtitle: cities[i].subtitle,
                  buyIn: '100',
                  reward: '100',
                  badge: '',
                  buttonText: 'Select City',
                  imageAsset: cities[i].imageAsset,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.tableRoom,
                      arguments: cities[i]),
                )),
              ],
            ]);
          },
        )),
        SizedBox(
            height: 24,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              pageArrow(false),
              const Text('CITIES',
                  style: TextStyle(fontSize: 9, color: Color(0xFFE9D1A0))),
              const SizedBox(width: 8),
              for (var i = 0; i < pageCount; i++)
                Semantics(
                    button: true,
                    selected: page == i,
                    label: 'City page ${i + 1}',
                    child: InkWell(
                        onTap: () => controller.animateToPage(i,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut),
                        child: SizedBox(
                            width: 28,
                            height: 24,
                            child: Center(
                                child: Container(
                              width: page == i ? 17 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                  color: page == i
                                      ? const Color(0xFFFF9800)
                                      : Colors.white54,
                                  borderRadius: BorderRadius.circular(5)),
                            ))))),
              const SizedBox(width: 8),
              Text('${page + 1} / $pageCount',
                  style:
                      const TextStyle(fontSize: 9, color: Color(0xFFE9D1A0))),
              pageArrow(true),
            ])),
      ]);
}
