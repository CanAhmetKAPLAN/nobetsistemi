import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/duty_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/leave_provider.dart';
import '../../providers/swap_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/status_badge.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token!;
    final groupId = context.read<GroupProvider>().currentGroup?.id;
    await Future.wait([
      context.read<DutyProvider>().fetchAll(token),
      context.read<LeaveProvider>().fetchPending(token),
      context.read<SwapProvider>().fetchPending(token),
      if (groupId != null) context.read<GroupProvider>().fetchMembers(token, groupId),
      if (groupId != null) context.read<GroupProvider>().fetchActiveVote(token, groupId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'Nöbet'),
            Tab(icon: Icon(Icons.beach_access), text: 'İzin'),
            Tab(icon: Icon(Icons.swap_horiz), text: 'Değişim'),
            Tab(icon: Icon(Icons.people), text: 'Kullanıcı'),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _DutyTab(),
          _LeaveTab(),
          _SwapTab(),
          _UserTab(),
        ],
      ),
    );
  }
}

class _DutyTab extends StatelessWidget {
  Future<void> _autoAssign(BuildContext context) async {
    DateTime? date;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Otomatik Nöbet Ata'),
          content: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today, color: AppTheme.primary),
            title: Text(date == null
                ? 'Tarih seç'
                : AppDateUtils.formatDate(date!.toIso8601String())),
            onTap: () async {
              final d = await showDatePicker(
                context: ctx,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (d != null) set(() => date = d);
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                if (date == null) return;
                Navigator.pop(ctx);
                final token = context.read<AuthProvider>().token!;
                try {
                  await context.read<DutyProvider>().autoAssign(token, date!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Nöbet otomatik atandı'),
                        backgroundColor: AppTheme.success),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
                  );
                }
              },
              child: const Text('Ata'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rebalance(BuildContext context) async {
    DateTime? fromDate = DateTime.now();
    DateTime? toDate = DateTime.now().add(const Duration(days: 30));

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Nöbeti Güncelle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Seçilen aralıktaki otomatik atanmış nöbetler, güncel üye '
                'listesiyle yeniden dağıtılır (yeni katılanlar dahil edilir). '
                'Manuel atamalar ve geçmiş tarihler değişmez.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, color: AppTheme.primary),
                title: Text(fromDate == null
                    ? 'Başlangıç tarihi'
                    : AppDateUtils.formatDate(fromDate!.toIso8601String())),
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: fromDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (d != null) set(() => fromDate = d);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event, color: AppTheme.primary),
                title: Text(toDate == null
                    ? 'Bitiş tarihi'
                    : AppDateUtils.formatDate(toDate!.toIso8601String())),
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: toDate ?? DateTime.now(),
                    firstDate: fromDate ?? DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (d != null) set(() => toDate = d);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                if (fromDate == null || toDate == null) return;
                Navigator.pop(ctx);
                final token = context.read<AuthProvider>().token!;
                try {
                  final result = await context
                      .read<DutyProvider>()
                      .rebalance(token, fromDate!, toDate!);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${result['assignedCount']} nöbet yeniden atandı, '
                        '${result['alreadyFilledCount']} manuel atama korundu, '
                        '${result['skippedCount']} gün atlandı',
                      ),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
                  );
                }
              },
              child: const Text('Güncelle'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final duties = context.watch<DutyProvider>().duties;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _autoAssign(context),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Otomatik Ata'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rebalance(context),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Nöbeti Güncelle'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: duties.length,
            itemBuilder: (ctx, i) {
              final d = duties[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  leading: const Icon(Icons.calendar_month, color: AppTheme.primary),
                  title: Text(AppDateUtils.formatDate(d.date)),
                  subtitle: Text(d.userName),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: AppTheme.error, size: 20),
                    onPressed: () async {
                      final token = context.read<AuthProvider>().token!;
                      await context.read<DutyProvider>().delete(token, d.id);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LeaveTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pending = context.watch<LeaveProvider>().pending;
    final token = context.read<AuthProvider>().token!;

    if (pending.isEmpty) {
      return const Center(child: Text('Bekleyen izin talebi yok.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: pending.length,
      itemBuilder: (ctx, i) {
        final leave = pending[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(leave.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                    '${AppDateUtils.formatDate(leave.startDate)} - ${AppDateUtils.formatDate(leave.endDate)}'),
                Text(leave.reason, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        await context.read<LeaveProvider>().review(token, leave.id, false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Red edildi'), backgroundColor: AppTheme.error),
                        );
                      },
                      icon: const Icon(Icons.close, color: AppTheme.error),
                      label: const Text('Reddet', style: TextStyle(color: AppTheme.error)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await context.read<LeaveProvider>().review(token, leave.id, true);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Onaylandı'), backgroundColor: AppTheme.success),
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Onayla'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SwapTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pending = context.watch<SwapProvider>().pending;
    final token = context.read<AuthProvider>().token!;

    if (pending.isEmpty) {
      return const Center(child: Text('Bekleyen değişim talebi yok.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: pending.length,
      itemBuilder: (ctx, i) {
        final swap = pending[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${swap.requesterName} → ${swap.targetUserName}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Nöbet: ${AppDateUtils.formatDate(swap.requesterDutyDate)}'),
                if (swap.reason.isNotEmpty) Text(swap.reason, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        await context.read<SwapProvider>().review(token, swap.id, false);
                      },
                      icon: const Icon(Icons.close, color: AppTheme.error),
                      label: const Text('Reddet', style: TextStyle(color: AppTheme.error)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await context.read<SwapProvider>().review(token, swap.id, true);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Onayla'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UserTab extends StatelessWidget {
  Future<void> _startVote(
    BuildContext context,
    String token,
    String groupId,
    String candidateUserId,
    String candidateName,
  ) async {
    try {
      await context.read<GroupProvider>().startAdminVote(token, groupId, candidateUserId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$candidateName için admin oylaması başlatıldı')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _cast(BuildContext context, String token, String groupId, String voteId, bool approve) async {
    try {
      await context.read<GroupProvider>().castAdminVote(token, groupId, voteId, approve);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    }
  }

  Widget _voteBanner(BuildContext context, String token, String groupId) {
    final vote = context.watch<GroupProvider>().activeVote;
    if (vote == null) return const SizedBox.shrink();

    final auth = context.read<AuthProvider>();
    final myId = auth.user?.id;
    final canCancel = vote.isPending &&
        (vote.initiatedById == myId ||
            context.read<GroupProvider>().currentGroup?.isAdmin == true);

    Color color;
    String statusText;
    switch (vote.status) {
      case 'Passed':
        color = AppTheme.success;
        statusText = '${vote.candidateName} admin oldu!';
        break;
      case 'Rejected':
        color = AppTheme.error;
        statusText = 'Oylama reddedildi.';
        break;
      default:
        color = AppTheme.primary;
        statusText = '${vote.candidateName} için admin oylaması sürüyor';
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      color: color.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.how_to_vote, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(statusText,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Evet: ${vote.yesCount} / Hayır: ${vote.noCount} '
                '(gerekli: ${vote.requiredYesCount} / ${vote.activeMemberCount} aktif üye)'),
            const SizedBox(height: 8),
            if (vote.isPending)
              Row(
                children: [
                  if (vote.myVote == null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _cast(context, token, groupId, vote.id, false),
                        icon: const Icon(Icons.close, color: AppTheme.error),
                        label: const Text('Hayır', style: TextStyle(color: AppTheme.error)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _cast(context, token, groupId, vote.id, true),
                        icon: const Icon(Icons.check),
                        label: const Text('Evet'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                      ),
                    ),
                  ] else
                    Expanded(
                      child: Text(
                        vote.myVote == true ? 'Oyunuz: Evet' : 'Oyunuz: Hayır',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  if (canCancel)
                    TextButton(
                      onPressed: () =>
                          context.read<GroupProvider>().cancelAdminVote(token, groupId, vote.id),
                      child: const Text('İptal'),
                    ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.read<GroupProvider>().dismissVote(),
                  child: const Text('Tamam'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActive(
    BuildContext context,
    String token,
    String groupId,
    String userId,
    bool current,
  ) {
    return context
        .read<GroupProvider>()
        .updateMember(token, groupId, userId, isActive: !current);
  }

  Future<void> _toggleRole(
    BuildContext context,
    String token,
    String groupId,
    String userId,
    bool isAdmin,
  ) {
    return context
        .read<GroupProvider>()
        .updateMember(token, groupId, userId, role: isAdmin ? 'Member' : 'Admin');
  }

  Future<void> _confirmRemove(
    BuildContext context,
    String token,
    String groupId,
    String userId,
    String name,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Üyeyi Çıkar'),
        content: Text('$name kullanıcısını gruptan çıkarmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Çıkar', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<GroupProvider>().removeMember(token, groupId, userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = context.watch<GroupProvider>().members;
    final groupId = context.watch<GroupProvider>().currentGroup?.id ?? '';
    final token = context.read<AuthProvider>().token!;
    final hasActiveVote = context.watch<GroupProvider>().activeVote?.isPending == true;

    if (members.isEmpty) {
      return const Center(child: Text('Üye bulunamadı.'));
    }

    return Column(
      children: [
        _voteBanner(context, token, groupId),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: members.length,
            itemBuilder: (ctx, i) {
              final member = members[i];
              return Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: member.isActive ? AppTheme.primary : Colors.grey,
              child: Text(
                member.userName.isNotEmpty ? member.userName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(member.userName),
            subtitle: Text('${member.userEmail} • Puan: ${member.score}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusBadge(member.isActive ? 'Approved' : 'Rejected'),
                if (!member.isAdmin && member.isActive)
                  IconButton(
                    icon: const Icon(Icons.how_to_vote, size: 20, color: AppTheme.textSecondary),
                    tooltip: 'Admin olması için oylama başlat',
                    onPressed: hasActiveVote
                        ? null
                        : () => _startVote(context, token, groupId, member.userId, member.userName),
                  ),
                IconButton(
                  icon: Icon(
                    member.isAdmin ? Icons.shield : Icons.shield_outlined,
                    size: 20,
                    color: member.isAdmin ? AppTheme.primary : AppTheme.textSecondary,
                  ),
                  tooltip: member.isAdmin ? 'Yöneticiliği kaldır' : 'Yönetici yap',
                  onPressed: () =>
                      _toggleRole(context, token, groupId, member.userId, member.isAdmin),
                ),
                Switch(
                  value: member.isActive,
                  onChanged: (v) =>
                      _toggleActive(context, token, groupId, member.userId, member.isActive),
                ),
                IconButton(
                  icon: const Icon(Icons.person_remove, color: AppTheme.error, size: 20),
                  tooltip: 'Gruptan Çıkar',
                  onPressed: () =>
                      _confirmRemove(context, token, groupId, member.userId, member.userName),
                ),
              ],
            ),
          ),
              );
            },
          ),
        ),
      ],
    );
  }
}
