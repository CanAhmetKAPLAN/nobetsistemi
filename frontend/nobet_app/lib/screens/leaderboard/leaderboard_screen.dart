import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/app_drawer.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    final token = context.read<AuthProvider>().token!;
    final groupId = context.read<GroupProvider>().currentGroup?.id;
    if (groupId == null) return;
    await context.read<GroupProvider>().fetchMembers(token, groupId);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final provider = context.watch<GroupProvider>();
    final currentUserId = context.read<AuthProvider>().user?.id;

    final sorted = [...provider.members]
      ..sort((a, b) => b.score.compareTo(a.score));

    return Scaffold(
      appBar: AppBar(title: const Text('Puan Tablosu')),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: sorted.length,
                itemBuilder: (ctx, i) {
                  final member = sorted[i];
                  final isMe = member.userId == currentUserId;
                  final rank = i + 1;

                  Color rankColor = Colors.grey;
                  if (rank == 1) rankColor = const Color(0xFFFFD700);
                  if (rank == 2) rankColor = const Color(0xFFC0C0C0);
                  if (rank == 3) rankColor = const Color(0xFFCD7F32);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isMe
                        ? AppTheme.primary.withValues(alpha: 0.08)
                        : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: rankColor,
                        child: Text(
                          '$rank',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            member.userName,
                            style: TextStyle(
                              fontWeight: isMe
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Siz',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        member.isAdmin ? 'Yönetici' : 'Personel',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${member.score}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: rankColor == Colors.grey
                                  ? AppTheme.primary
                                  : rankColor,
                            ),
                          ),
                          const Text(
                            'puan',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
