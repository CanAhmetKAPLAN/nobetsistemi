import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/group_routing.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/duty_provider.dart';
import 'providers/group_provider.dart';
import 'providers/leave_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/swap_provider.dart';
import 'screens/admin/admin_panel_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/duty/duty_list_screen.dart';
import 'screens/duty/monthly_calendar_screen.dart';
import 'screens/group/create_group_screen.dart';
import 'screens/group/group_select_screen.dart';
import 'screens/group/join_group_screen.dart';
import 'screens/leaderboard/leaderboard_screen.dart';
import 'screens/leaderboard/score_history_screen.dart';
import 'screens/leave/leave_request_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/swap/swap_request_screen.dart';
import 'services/fcm_service.dart';
import 'services/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocalNotificationService.init();
  await LocalNotificationService.requestPermission();

  runApp(const NobetApp());
}

class NobetApp extends StatelessWidget {
  const NobetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => DutyProvider()),
        ChangeNotifierProvider(create: (_) => LeaveProvider()),
        ChangeNotifierProvider(create: (_) => SwapProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
      ],
      child: MaterialApp(
        title: 'Nöbet Sistemi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        initialRoute: '/',
        routes: {
          '/': (ctx) => const _SplashRouter(),
          '/login': (ctx) => const LoginScreen(),
          '/register': (ctx) => const RegisterScreen(),
          '/dashboard': (ctx) => const DashboardScreen(),
          '/duties': (ctx) => const DutyListScreen(),
          '/monthly-calendar': (ctx) => const MonthlyCalendarScreen(),
          '/leaderboard': (ctx) => const LeaderboardScreen(),
          '/score-history': (ctx) => const ScoreHistoryScreen(),
          '/leaves': (ctx) => const LeaveRequestScreen(),
          '/swaps': (ctx) => const SwapRequestScreen(),
          '/notifications': (ctx) => const NotificationsScreen(),
          '/admin': (ctx) => const _AdminGuard(),
          '/group-select': (ctx) => const GroupSelectScreen(),
          '/create-group': (ctx) => const CreateGroupScreen(),
          '/join-group': (ctx) => const JoinGroupScreen(),
        },
      ),
    );
  }
}

class _SplashRouter extends StatefulWidget {
  const _SplashRouter();

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final auth = context.read<AuthProvider>();
    while (auth.loading) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    if (!mounted) return;

    if (auth.isLoggedIn) {
      // FCM'i başlat ve token'ı backend'e kaydet
      await FcmService.init(authToken: auth.token);
      if (!mounted) return;
      await resolveGroupAndRoute(context);
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_hospital, size: 80, color: Colors.white),
            SizedBox(height: 16),
            Text('Nöbet Sistemi',
                style: TextStyle(
                    color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 32),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _AdminGuard extends StatelessWidget {
  const _AdminGuard();

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<GroupProvider>().currentGroup?.isAdmin ?? false;
    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Yetkisiz')),
        body: const Center(child: Text('Bu sayfaya erişim yetkiniz yok.')),
      );
    }
    return const AdminPanelScreen();
  }
}
