import 'package:flutter/material.dart';

import '../core/routes/app_router.dart';
import '../core/routes/app_routes.dart';
import '../core/theme/app_theme.dart';

class DaketiApp extends StatelessWidget {
  const DaketiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Daketi',
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
