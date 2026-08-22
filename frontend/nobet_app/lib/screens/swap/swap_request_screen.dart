import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/duty_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/swap_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/status_badge.dart';

class SwapRequestScreen extends StatefulWidget {
  const SwapRequestScreen({super.key});

  @override
  State<SwapRequestScreen> createState() => _SwapRequestScreenState();
}

class _SwapRequestScreenState extends State<SwapRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token!;
    final userId = context.read<AuthProvider>().user!.id;
    final groupId = context.read<GroupProvider>().currentGroup?.id;
    await Future.wait([
      context.read<SwapProvider>().fetchMy(token),
      context.read<SwapProvider>().fetchIncoming(token),
      context.read<DutyProvider>().fetchByUser(token, userId),
      if (groupId != null) context.read<GroupProvider>().fetchMembers(token, groupId),
    ]);
  }

  Future<void> _respond(String id, bool approve) async {
    try {
      await context.read<SwapProvider>().review(context.read<AuthProvider>().token!, id, approve);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? 'Değişim onaylandı' : 'Değişim reddedildi'),
          backgroundColor: approve ? AppTheme.success : AppTheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _showCreateDialog() async {
    String? selectedTargetUserId;
    String? selectedMyDutyId;
    final reasonCtrl = TextEditingController();
    final duties = context.read<DutyProvider>().duties;
    final members = context.read<GroupProvider>().members;
    final currentUserId = context.read<AuthProvider>().user!.id;
    final otherUsers =
        members.where((m) => m.userId != currentUserId && m.isActive).toList();
    final upcomingDuties =
        duties.where((d) => DateTime.parse(d.date).isAfter(DateTime.now())).toList();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('Nöbet Değişim Talebi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DropdownField(
                  label: 'Değişim İstenen Kişi',
                  child: DropdownButton<String>(
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    hint: const Text('Kişi seçin'),
                    value: selectedTargetUserId,
                    items: otherUsers
                        .map((u) => DropdownMenuItem(value: u.userId, child: Text(u.userName)))
                        .toList(),
                    onChanged: (v) => setInner(() => selectedTargetUserId = v),
                  ),
                ),
                const SizedBox(height: 12),
                _DropdownField(
                  label: 'Benim Nöbetim',
                  child: DropdownButton<String>(
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    hint: const Text('Nöbet seçin'),
                    value: selectedMyDutyId,
                    items: upcomingDuties
                        .map((d) => DropdownMenuItem(
                              value: d.id,
                              child: Text(AppDateUtils.formatDate(d.date)),
                            ))
                        .toList(),
                    onChanged: (v) => setInner(() => selectedMyDutyId = v),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Gerekçe', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                if (selectedTargetUserId == null || selectedMyDutyId == null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Kişi ve nöbet seçin')));
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await context.read<SwapProvider>().create(
                        context.read<AuthProvider>().token!,
                        selectedTargetUserId!,
                        selectedMyDutyId!,
                        null,
                        reasonCtrl.text.trim(),
                      );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Değişim talebi gönderildi'),
                          backgroundColor: AppTheme.success),
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
              child: const Text('Gönder'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sentList(SwapProvider provider) {
    if (provider.swaps.isEmpty) {
      return const Center(child: Text('Gönderdiğiniz değişim talebi yok.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: provider.swaps.length,
      itemBuilder: (ctx, i) {
        final swap = provider.swaps[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppTheme.warning,
              child: Icon(Icons.swap_horiz, color: Colors.white, size: 20),
            ),
            title: Text(
              '${AppDateUtils.formatDate(swap.requesterDutyDate)} → ${swap.targetUserName}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              swap.reason.isNotEmpty ? swap.reason : 'Gerekçe belirtilmemiş',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusBadge(swap.status),
                if (swap.status == 'Pending') ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: AppTheme.error, size: 20),
                    onPressed: () async {
                      await context.read<SwapProvider>().cancel(
                            context.read<AuthProvider>().token!,
                            swap.id,
                          );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _incomingList(SwapProvider provider) {
    if (provider.incoming.isEmpty) {
      return const Center(child: Text('Size gelen değişim talebi yok.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: provider.incoming.length,
      itemBuilder: (ctx, i) {
        final swap = provider.incoming[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppTheme.warning,
                      child: Icon(Icons.swap_horiz, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${swap.requesterName} • ${AppDateUtils.formatDate(swap.requesterDutyDate)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    StatusBadge(swap.status),
                  ],
                ),
                if (swap.reason.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(swap.reason, style: const TextStyle(color: AppTheme.textSecondary)),
                ],
                if (swap.status == 'Pending') ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _respond(swap.id, false),
                        icon: const Icon(Icons.close, color: AppTheme.error),
                        label: const Text('Reddet', style: TextStyle(color: AppTheme.error)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _respond(swap.id, true),
                        icon: const Icon(Icons.check),
                        label: const Text('Onayla'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SwapProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nöbet Değişim Talepleri'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Gönderdiklerim'),
            Tab(text: 'Gelen Talepler'),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Talep'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabCtrl,
                children: [
                  _sentList(provider),
                  _incomingList(provider),
                ],
              ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final Widget child;
  const _DropdownField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: child,
    );
  }
}
