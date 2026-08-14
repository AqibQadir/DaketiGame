import 'package:flutter/material.dart';

import '../../features/auth/presentation/screens/auth_choice_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/game/presentation/screens/game_screen.dart';
import '../../features/legal/presentation/screens/privacy_policy_screen.dart';
import '../../features/legal/presentation/screens/terms_conditions_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/support/presentation/screens/support_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/baithak/presentation/screens/baithak_screen.dart';
import '../../features/dukan/presentation/screens/dukan_screen.dart';
import '../../features/quests/presentation/screens/side_quests_screen.dart';
import '../../features/tables/presentation/screens/table_room_screen.dart';
import '../../features/tables/presentation/screens/tables_screen.dart';
import '../../features/tables/domain/table_room.dart';
import '../../features/game/presentation/screens/multiplayer_screen.dart';
import '../../features/game/presentation/screens/waiting_room_screen.dart';
import '../../features/game/presentation/screens/game_results_screen.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _page(const SplashScreen());
      case AppRoutes.terms:
        return _page(const TermsConditionsScreen());
      case AppRoutes.privacy:
        return _page(const PrivacyPolicyScreen());
      case AppRoutes.welcome:
        return _page(const WelcomeScreen());
      case AppRoutes.authChoice:
        return _page(const AuthChoiceScreen());
      case AppRoutes.login:
        return _page(const LoginScreen());
      case AppRoutes.signup:
        return _page(const SignupScreen());
      case AppRoutes.settings:
        return _page(const SettingsScreen());
      case AppRoutes.profile:
        return _page(const ProfileScreen());
      case AppRoutes.support:
        return _page(const SupportScreen());
      case AppRoutes.home:
        return _page(const HomeScreen());
      case AppRoutes.game:
        return _page(const GameScreen());
      case AppRoutes.baithak:
        return _page(const BaithakScreen());
      case AppRoutes.dukan:
        return _page(const DukanScreen());
      case AppRoutes.sideQuests:
        return _page(const SideQuestsScreen());
      case AppRoutes.tables:
        return _page(const TablesScreen());
      case AppRoutes.tableRoom:
        final room = settings.arguments is TableRoom
            ? settings.arguments! as TableRoom
            : TableRoom.oldLahore;
        return _page(TableRoomScreen(room: room));
      case AppRoutes.multiplayer:
        return _page(const MultiplayerScreen());
      case AppRoutes.waitingRoom:
        return _page(const WaitingRoomScreen());
      case AppRoutes.results:
        return _page(const GameResultsScreen());
      default:
        return _page(const SplashScreen());
    }
  }

  static MaterialPageRoute<dynamic> _page(Widget child) {
    return MaterialPageRoute<dynamic>(
      builder: (_) => child,
    );
  }
}
