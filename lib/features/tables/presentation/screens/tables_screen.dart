import 'package:flutter/material.dart';

import '../widgets/city_table_cards.dart';
import '../widgets/table_categories.dart';
import '../widgets/table_page_shell.dart';

class TablesScreen extends StatelessWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TablePageShell(
      title: 'TABLES',
      categories: TableCategories(),
      child: CityTableCards(),
    );
  }
}
