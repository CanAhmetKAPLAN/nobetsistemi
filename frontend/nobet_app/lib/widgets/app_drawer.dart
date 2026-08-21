import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/notification_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notif = context.watch<NotificationProvider>();
    final groupProvider = context.watch<GroupProvider>();
    final isAdmin = groupProvider.currentGroup?.isAdmin ?? false;
    final user = auth.user;

    return Drawer(
      backgroundColor: AppTheme.panel,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: AppTheme.panelLight,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            accountName: Text(user?.name ?? '',
              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
            accountEmail: Text(user?.email ?? '',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppTheme.primary,
              child: Text(
                (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.groups),
                  title: Text(groupProvider.currentGroup?.name ?? '...'),
                  subtitle: const Text('Grup Değiştir'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/group-select');
                  },
                ),
                const Divider(),
                _tile(context, Icons.dashboard, 'Dashboard', '/dashboard'),
                _tile(context, Icons.calendar_today, 'Nöbet Listesi', '/duties'),
                _tile(context, Icons.calendar_month, 'Aylık Takvim', '/monthly-calendar'),
                _tile(context, Icons.leaderboard, 'Puan Tablosu', '/leaderboard'),
                _tile(context, Icons.history, 'Geçmiş Puanlar', '/score-history'),
                _tile(context, Icons.beach_access, 'İzin Talepleri', '/leaves'),
                _tile(context, Icons.swap_horiz, 'Nöbet Değişim', '/swaps'),
                ListTile(
                  leading: Badge(
                    isLabelVisible: notif.unreadCount > 0,
                    label: Text('${notif.unreadCount}'),
                    child: const Icon(Icons.notifications),
                  ),
                  title: const Text('Bildirimler'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/notifications');
                  },
                ),
                if (isAdmin) ...[
                  const Divider(),
                  _tile(context, Icons.admin_panel_settings, 'Admin Panel', '/admin'),
                ],
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.error),
            title: const Text('Çıkış Yap', style: TextStyle(color: AppTheme.error)),
            onTap: () async {
              await auth.logout();
              if (context.mounted) context.read<GroupProvider>().clearGroup();
              if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label, String route) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }
}
