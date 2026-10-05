import '../../features/friends/presentation/friends_screen.dart';
import 'package:flutter/material.dart';

import '../../features/auth/presentation/screens/auth_choice_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/guest_name_screen.dart';
import '../../features/auth/presentation/screens/guest_opponent_screen.dart';
import '../../features/game/presentation/screens/game_screen.dart';
import '../../features/tutorial/presentation/screens/game_tutorial_screen.dart';
import '../../features/legal/presentation/screens/privacy_policy_screen.dart';
import '../../features/legal/presentation/screens/terms_conditions_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/game_history_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/support/presentation/screens/support_screen.dart';
import '../../features/support/presentation/screens/contact_us_screen.dart';
import '../../features/support/presentation/screens/report_issue_screen.dart';
import '../../features/support/presentation/screens/faq_screen.dart';
import '../../features/menu/presentation/screens/menu_screen.dart';
import '../../features/menu/presentation/screens/leaderboard_screen.dart';
import '../../features/menu/presentation/screens/general_settings_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/baithak/presentation/screens/baithak_screen.dart';
import '../../features/baithak/presentation/screens/my_clan_screen.dart';
import '../../features/baithak/presentation/screens/global_players_screen.dart';
import '../../features/baithak/presentation/screens/chat_lobby_screen.dart';
import '../../features/baithak/presentation/screens/personal_chat_screen.dart';
import '../../features/dukan/presentation/screens/dukan_screen.dart';
import '../../features/quests/presentation/screens/side_quests_screen.dart';
import '../../features/tables/presentation/screens/table_room_screen.dart';
import '../../features/tables/presentation/screens/tables_screen.dart';
import '../../features/tables/domain/table_room.dart';
import '../../features/tables/domain/table_match_selection.dart';
import '../../features/game/presentation/screens/multiplayer_screen.dart';
import '../../features/game/presentation/screens/waiting_room_screen.dart';
import '../../features/game/presentation/screens/game_results_screen.dart';
import '../../features/access/presentation/waitlist_screen.dart';
import '../../features/auth/presentation/screens/account_link_screen.dart';
import 'app_routes.dart';
import 'fixed_background_page_route.dart';
import 'game_popup_route.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    Route<dynamic> page(Widget child) {
      final mainPage = {
            AppRoutes.splash,
            AppRoutes.waitlist,
            AppRoutes.accountLink,
            AppRoutes.welcome,
            AppRoutes.login,
            AppRoutes.signup,
            AppRoutes.home,
            AppRoutes.tables,
            AppRoutes.game,
            AppRoutes.terms,
            AppRoutes.privacy
          }.contains(settings.name) ||
          (settings.name == AppRoutes.gameTutorial &&
              (settings.arguments == null ||
                  settings.arguments == AppRoutes.welcome));
      return mainPage
          ? FixedBackgroundPageRoute<dynamic>(
              settings: settings, builder: (_) => child)
          : GamePopupRoute<dynamic>(
              settings: settings,
              child: child,
              videoBackground: settings.name == AppRoutes.guestOpponents);
    }

    switch (settings.name) {
      case AppRoutes.waitlist:
        return page(const WaitlistScreen());
      case AppRoutes.accountLink:
        return page(AccountLinkScreen(
            uri:
                settings.arguments is Uri ? settings.arguments as Uri : Uri()));
      case AppRoutes.splash:
        return page(const SplashScreen());
      case AppRoutes.terms:
        return page(const TermsConditionsScreen());
      case AppRoutes.privacy:
        return page(const PrivacyPolicyScreen());
      case AppRoutes.welcome:
        return page(const WelcomeScreen());
      case AppRoutes.authChoice:
        return page(const AuthChoiceScreen());
      case AppRoutes.guestName:
        return page(GuestNameScreen(
          returnToPrevious: settings.arguments == AppRoutes.multiplayer,
          tableSelection: settings.arguments is TableMatchSelection
              ? settings.arguments! as TableMatchSelection
              : null,
        ));
      case AppRoutes.guestOpponents:
        final tableMatch = settings.arguments is TableMatchArguments
            ? settings.arguments! as TableMatchArguments
            : null;
        final guestName = settings.arguments is String
            ? settings.arguments! as String
            : 'Guest';
        return page(GuestOpponentScreen(
          playerName: tableMatch?.playerName ?? guestName,
          tableSelection: tableMatch?.selection,
        ));
      case AppRoutes.login:
        return page(const LoginScreen());
      case AppRoutes.signup:
        return page(const SignupScreen());
      case AppRoutes.settings:
        return page(const SettingsScreen());
      case AppRoutes.profile:
        return page(const ProfileScreen());
      case AppRoutes.gameHistory:
        return page(const GameHistoryScreen());
      case AppRoutes.support:
        return page(const SupportScreen());
      case AppRoutes.menu:
        return page(const MenuScreen());
      case AppRoutes.leaderboard:
        return page(const LeaderboardScreen());
      case AppRoutes.generalSettings:
        return page(const GeneralSettingsScreen());
      case AppRoutes.contactUs:
        return page(const ContactUsScreen());
      case AppRoutes.reportIssue:
        return page(const ReportIssueScreen());
      case AppRoutes.faqs:
        return page(const FaqScreen());
      case AppRoutes.home:
        return page(const HomeScreen());
      case AppRoutes.game:
        return page(const GameScreen());
      case AppRoutes.gameTutorial:
        final arguments = settings.arguments;
        return page(GameTutorialScreen(
          returnRoute: arguments is String ? arguments : AppRoutes.welcome,
        ));
      case AppRoutes.friends:
        return page(const FriendsScreen());
      case AppRoutes.baithak:
        return page(const BaithakScreen());
      case AppRoutes.myClan:
        return page(const MyClanScreen());
      case AppRoutes.globalPlayers:
        return page(const GlobalPlayersScreen());
      case AppRoutes.chatLobby:
        return page(const ChatLobbyScreen());
      case AppRoutes.personalChat:
        return page(const PersonalChatScreen());
      case AppRoutes.dukan:
        return page(const DukanScreen());
      case AppRoutes.sideQuests:
        return page(const SideQuestsScreen());
      case AppRoutes.tables:
        return page(const TablesScreen());
      case AppRoutes.tableRoom:
        final room = settings.arguments is TableRoom
            ? settings.arguments! as TableRoom
            : TableRoom.oldLahore;
        return page(TableRoomScreen(room: room));
      case AppRoutes.multiplayer:
        final playerName =
            settings.arguments is String ? settings.arguments! as String : '';
        return page(MultiplayerScreen(initialPlayerName: playerName));
      case AppRoutes.waitingRoom:
        return page(const WaitingRoomScreen());
      case AppRoutes.results:
        return page(const GameResultsScreen());
      default:
        return page(const SplashScreen());
    }
  }
}
