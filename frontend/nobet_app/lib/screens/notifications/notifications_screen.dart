import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/app_drawer.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetch(
        context.read<AuthProvider>().token!,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final token = context.read<AuthProvider>().token!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () => provider.markAllAsRead(token),
              child: const Text(
                'Tümünü oku',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () => provider.fetch(token),
        child: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : provider.notifications.isEmpty
            ? const Center(child: Text('Bildirim bulunamadı.'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: provider.notifications.length,
                itemBuilder: (ctx, i) {
                  final n = provider.notifications[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: n.isRead
                        ? null
                        : AppTheme.primary.withValues(alpha: 0.06),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: n.isRead
                            ? Colors.grey.shade200
                            : AppTheme.primary,
                        child: Icon(
                          Icons.notifications,
                          color: n.isRead ? Colors.grey : Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        n.title,
                        style: TextStyle(
                          fontWeight: n.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.message),
                          Text(
                            AppDateUtils.formatDateTime(n.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      trailing: !n.isRead
                          ? IconButton(
                              icon: const Icon(
                                Icons.mark_email_read,
                                color: AppTheme.primary,
                                size: 20,
                              ),
                              onPressed: () => provider.markAsRead(token, n.id),
                            )
                          : const Icon(
                              Icons.done,
                              color: Colors.grey,
                              size: 18,
                            ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
