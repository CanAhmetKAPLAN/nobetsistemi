import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/group.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/theme_provider.dart';

class GroupSelectScreen extends StatefulWidget {
  const GroupSelectScreen({super.key});

  @override
  State<GroupSelectScreen> createState() => _GroupSelectScreenState();
}

class _GroupSelectScreenState extends State<GroupSelectScreen> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() => _loading = true);
    try {
      await context.read<GroupProvider>().fetchMyGroups(token);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _select(Group group) async {
    final token = context.read<AuthProvider>().token!;
    await context.read<GroupProvider>().selectGroup(token, group);
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final groups = context.watch<GroupProvider>().myGroups;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Nöbet Grubu Seç')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (groups.isEmpty)
                      _EmptyState(onCreate: () => Navigator.pushNamed(context, '/create-group'),
                          onJoin: () => Navigator.pushNamed(context, '/join-group'))
                    else ...[
                      Text(
                        'Gruplarınız',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      ...groups.map((g) => _GroupTile(group: g, onTap: () => _select(g))),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pushNamed(context, '/join-group'),
                              icon: const Icon(Icons.login),
                              label: const Text('Gruba Katıl'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pushNamed(context, '/create-group'),
                              icon: const Icon(Icons.add),
                              label: const Text('Grup Oluştur'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;
  const _GroupTile({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary,
          child: Text(
            group.name.isNotEmpty ? group.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${group.memberCount} üye'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (group.isAdmin ? AppTheme.primary : AppTheme.textSecondary)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: group.isAdmin ? AppTheme.primary : AppTheme.textSecondary,
            ),
          ),
          child: Text(
            group.isAdmin ? 'Yönetici' : 'Üye',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: group.isAdmin ? AppTheme.primary : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  const _EmptyState({required this.onCreate, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.groups_outlined, size: 72, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Henüz bir nöbet grubunuz yok',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppTheme.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni bir grup oluşturun ya da bir katılım kodu ile mevcut bir gruba katılın.',
            style: TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Grup Oluştur'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onJoin,
            icon: const Icon(Icons.login),
            label: const Text('Gruba Katıl'),
          ),
        ],
      ),
    );
  }
}
