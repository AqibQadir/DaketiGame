import 'package:flutter/material.dart';
import '../../../tables/domain/table_room.dart';

class RoomCityPicker extends StatelessWidget {
  const RoomCityPicker(
      {super.key,
      required this.selected,
      required this.onChanged,
      this.enabled = true});
  final TableRoom? selected;
  final ValueChanged<TableRoom> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 82,
        child: ListView.separated(
          key: const ValueKey('room-city-picker'),
          scrollDirection: Axis.horizontal,
          itemCount: TableRoom.values.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final city = TableRoom.values[index];
            final active = selected == city;
            return Semantics(
              button: true,
              selected: active,
              label: 'Room city ${city.cityName}',
              child: GestureDetector(
                  onTap: enabled ? () => onChanged(city) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 108,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: active ? const Color(0xFFFF9800) : Colors.white24,
                    ),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(fit: StackFit.expand, children: [
                          Image.asset(city.backgroundAsset(portrait: true),
                              fit: BoxFit.cover),
                          const DecoratedBox(
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                Colors.transparent,
                                Color(0xDD000000)
                              ]))),
                          if (active)
                            const Positioned(
                                right: 5,
                                top: 5,
                                child: Icon(Icons.check_circle,
                                    color: Color(0xFFFFB454), size: 18)),
                          Positioned(
                              left: 4,
                              right: 4,
                              bottom: 8,
                              child: Text(city.title,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontFamily: 'Dirty Brush',
                                      fontSize: 14,
                                      color: Colors.white))),
                        ])),
                  )),
            );
          },
        ),
      );
}
