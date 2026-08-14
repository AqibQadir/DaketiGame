import 'package:flutter/material.dart';

class TableCategories extends StatelessWidget {
  const TableCategories({super.key, this.selected = 'LOW STAKES'});

  final String selected;

  @override
  Widget build(BuildContext context) {
    const labels = [
      'ALL ROOMS',
      'LOW STAKES',
      'MID STAKES',
      'HIGH STAKES',
      'EXCLUSIVES',
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: labels.map((label) {
        final active = label == selected;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: Colors.white24)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.white70,
              fontSize: 10,
              fontWeight: active ? FontWeight.w900 : FontWeight.w400,
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}
