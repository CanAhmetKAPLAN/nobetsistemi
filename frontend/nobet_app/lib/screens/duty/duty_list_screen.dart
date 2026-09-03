import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/duty_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/app_drawer.dart';

class DutyListScreen extends StatefulWidget {
  const DutyListScreen({super.key});

  @override
  State<DutyListScreen> createState() => _DutyListScreenState();
}

class _DutyListScreenState extends State<DutyListScreen> {
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token!;
    final isAdmin = context.read<GroupProvider>().currentGroup?.isAdmin ?? false;
    if (_showAll || isAdmin) {
      await context.read<DutyProvider>().fetchAll(token);
    } else {
      await context.read<DutyProvider>().fetchByUser(token, auth.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final provider = context.watch<DutyProvider>();
    final isAdmin = context.watch<GroupProvider>().currentGroup?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nöbet Listesi'),
        actions: [
          if (isAdmin)
            Switch(
              value: _showAll,
              onChanged: (v) {
                setState(() => _showAll = v);
                _load();
              },
              activeThumbColor: Colors.white,
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _load,
        child: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : provider.duties.isEmpty
            ? const Center(child: Text('Nöbet bulunamadı.'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: provider.duties.length,
                itemBuilder: (ctx, i) {
                  final duty = provider.duties[i];
                  final date = DateTime.tryParse(duty.date) ?? DateTime.now();
                  final isToday =
                      date.year == DateTime.now().year &&
                      date.month == DateTime.now().month &&
                      date.day == DateTime.now().day;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isToday
                        ? AppTheme.primary.withValues(alpha: 0.08)
                        : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isToday
                            ? AppTheme.accent
                            : AppTheme.primary,
                        child: Text(
                          '${date.day}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            AppDateUtils.formatDate(duty.date),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Bugün',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(duty.userName),
                          if (duty.notes != null && duty.notes!.isNotEmpty)
                            Text(
                              duty.notes!,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: duty.isAutoAssigned
                                  ? AppTheme.secondary.withValues(alpha: 0.2)
                                  : AppTheme.success.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              duty.isAutoAssigned ? 'Otomatik' : 'Manuel',
                              style: TextStyle(
                                fontSize: 11,
                                color: duty.isAutoAssigned
                                    ? AppTheme.secondary
                                    : AppTheme.success,
                              ),
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: AppTheme.error,
                                size: 20,
                              ),
                              onPressed: () => _confirmDelete(duty.id),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _confirmDelete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nöbet Sil'),
        content: const Text('Bu nöbeti silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sil', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<DutyProvider>().delete(
        context.read<AuthProvider>().token!,
        id,
      );
    }
  }
}
