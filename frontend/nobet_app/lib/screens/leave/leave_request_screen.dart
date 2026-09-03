import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/status_badge.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token!;
    await context.read<LeaveProvider>().fetchMy(token);
  }

  Future<void> _showCreateDialog() async {
    DateTime? startDate;
    DateTime? endDate;
    final reasonCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('Yeni İzin Talebi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: AppTheme.primaryLight, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'İzinler otomatik onaylanır ve nöbet listesi güncellenir.',
                          style: TextStyle(fontSize: 12, color: AppTheme.primaryLight),
                        ),
                      ),
                    ],
                  ),
                ),
                // Start date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.calendar_today, color: AppTheme.primary),
                  title: Text(
                    startDate == null
                        ? 'Başlangıç tarihi seç'
                        : AppDateUtils.formatDate(startDate!.toIso8601String()),
                  ),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setInner(() => startDate = d);
                  },
                ),
                // End date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.calendar_today, color: AppTheme.primaryLight),
                  title: Text(
                    endDate == null
                        ? 'Bitiş tarihi seç'
                        : AppDateUtils.formatDate(endDate!.toIso8601String()),
                  ),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: startDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setInner(() => endDate = d);
                  },
                ),
                const SizedBox(height: 8),
                // Reason — optional
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Gerekçe (isteğe bağlı)',
                    hintText: 'Boş bırakılabilir',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (startDate == null || endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen başlangıç ve bitiş tarihini seçin.')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await context.read<LeaveProvider>().create(
                        context.read<AuthProvider>().token!,
                        startDate!,
                        endDate!,
                        reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
                      );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('✅ İzin onaylandı, nöbet listesi güncellendi.'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
                    );
                  }
                }
              },
              child: const Text('İzin Al'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final provider = context.watch<LeaveProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('İzinlerim')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Yeni İzin'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : provider.leaves.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.beach_access_outlined, size: 64, color: AppTheme.textSecondary),
                        const SizedBox(height: 12),
                        Text('Henüz izin yok',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: provider.leaves.length,
                    itemBuilder: (ctx, i) {
                      final leave = provider.leaves[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.success.withValues(alpha: 0.2),
                            child: Icon(Icons.beach_access, color: AppTheme.success, size: 20),
                          ),
                          title: Text(
                            '${AppDateUtils.formatDate(leave.startDate)} – ${AppDateUtils.formatDate(leave.endDate)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: leave.reason.isNotEmpty
                              ? Text(leave.reason, maxLines: 2, overflow: TextOverflow.ellipsis)
                              : Text('Gerekçe belirtilmedi',
                                  style: TextStyle(fontStyle: FontStyle.italic,
                                      color: AppTheme.textSecondary)),
                          trailing: StatusBadge(leave.status),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
