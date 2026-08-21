import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/notification.dart';
import '../../providers/auth_provider.dart';
import '../../providers/duty_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/app_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _updateCountdown());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token!;
    final userId = auth.user!.id;
    final groupId = context.read<GroupProvider>().currentGroup?.id;
    await Future.wait([
      context.read<DutyProvider>().fetchByUser(token, userId),
      context.read<DutyProvider>().fetchWeekly(token),
      context.read<NotificationProvider>().fetch(token),
      if (groupId != null) context.read<GroupProvider>().fetchMembers(token, groupId),
    ]);
    _updateCountdown();
  }

  void _updateCountdown() {
    final duties = context.read<DutyProvider>().duties;
    final now = DateTime.now();
    final next = duties
        .map((d) => DateTime.tryParse(d.date))
        .where((dt) => dt != null && dt.isAfter(now))
        .cast<DateTime>()
        .fold<DateTime?>(null, (prev, dt) => prev == null || dt.isBefore(prev) ? dt : prev);

    if (mounted) {
      setState(() {
        _remaining = next != null ? next.difference(now) : Duration.zero;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final duty  = context.watch<DutyProvider>();
    final notif = context.watch<NotificationProvider>();
    final group = context.watch<GroupProvider>();
    final now   = DateTime.now();

    final myDuties    = duty.duties;
    final weeklyAll   = duty.weeklyDuties;
    final userId      = auth.user?.id ?? '';
    final isAdmin     = group.currentGroup?.isAdmin ?? false;
    final myMembership = group.members.where((m) => m.userId == userId).firstOrNull;
    final myScore     = myMembership?.score ?? 0.0;

    final nextDuty = myDuties
        .where((d) {
          final dt = DateTime.tryParse(d.date);
          return dt != null && (dt.isAfter(now) || _isSameDay(dt, now));
        })
        .fold<dynamic>(null, (prev, d) {
          if (prev == null) return d;
          final prevDt = DateTime.tryParse(prev.date)!;
          final thisDt = DateTime.tryParse(d.date)!;
          return thisDt.isBefore(prevDt) ? d : prev;
        });

    final todayDuty = myDuties.where((d) {
      final dt = DateTime.tryParse(d.date);
      return dt != null && _isSameDay(dt, now);
    }).firstOrNull;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: _buildAppBar(notif),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        color: AppTheme.primaryLight,
        backgroundColor: AppTheme.panel,
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroCard(
                user: auth.user,
                todayDuty: todayDuty,
                isAdmin: isAdmin,
                score: myScore,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NextDutyCard(nextDuty: nextDuty, remaining: _remaining),
                    const SizedBox(height: 20),
                    _sectionLabel('HAFTALIK TAKVİM'),
                    const SizedBox(height: 10),
                    _WeeklyGrid(weeklyDuties: weeklyAll, userId: userId),
                    const SizedBox(height: 20),
                    _sectionLabel('HIZLI İŞLEMLER'),
                    const SizedBox(height: 10),
                    _QuickActions(),
                    const SizedBox(height: 20),
                    _sectionLabel('GELİŞMELER'),
                    const SizedBox(height: 10),
                    _ActivityFeed(notifications: notif.notifications.take(8).toList()),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(NotificationProvider notif) {
    return AppBar(
      backgroundColor: AppTheme.panel,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'NÖBET SİSTEMİ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'KOMUTA MERKEZİ',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.8,
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppTheme.textSecondary),
              onPressed: () => Navigator.pushNamed(context, '/notifications'),
            ),
            if (notif.unreadCount > 0)
              Positioned(
                right: 8, top: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppTheme.error, shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${notif.unreadCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppTheme.border),
      ),
    );
  }

  Widget _sectionLabel(String text) => Row(
    children: [
      Container(width: 3, height: 14, color: AppTheme.primary,
        margin: const EdgeInsets.only(right: 8)),
      Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.0,
          color: AppTheme.textSecondary,
        ),
      ),
    ],
  );

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─── Hero card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final dynamic user;
  final dynamic todayDuty;
  final bool isAdmin;
  final double score;
  const _HeroCard({
    required this.user,
    required this.todayDuty,
    required this.isAdmin,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final hasToday = todayDuty != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasToday
              ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
              : [const Color(0xFF1A1F28), AppTheme.panel],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HOŞ GELDİN',
                  style: TextStyle(
                    fontSize: 10, letterSpacing: 2.5,
                    color: hasToday ? Colors.white60 : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.name ?? '',
                  style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: Colors.white, letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Chip(
                      icon: Icons.military_tech,
                      label: isAdmin ? 'YÖNETİCİ' : 'PERSONEL',
                      color: hasToday ? Colors.white38 : AppTheme.border,
                    ),
                    const SizedBox(width: 8),
                    _Chip(
                      icon: Icons.star_outline_rounded,
                      label: 'PUAN ${_fmtScore(score)}',
                      color: hasToday ? Colors.white38 : AppTheme.border,
                    ),
                  ],
                ),
                if (hasToday) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.radio_button_checked, color: Colors.white, size: 12),
                        SizedBox(width: 6),
                        Text('BUGÜN NÖBETTESİNİZ',
                          style: TextStyle(color: Colors.white, fontSize: 11,
                            fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: hasToday ? Colors.white38 : AppTheme.border, width: 2),
              color: hasToday
                  ? Colors.white.withValues(alpha: 0.1)
                  : AppTheme.panelLight,
            ),
            child: Center(
              child: Text(
                _initials(user?.name),
                style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _fmtScore(dynamic score) {
    if (score == null) return '0';
    final d = (score as num).toDouble();
    return d == d.truncateToDouble() ? d.toInt().toString() : d.toStringAsFixed(2);
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(label,
          style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary,
            letterSpacing: 1.2, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

// ─── Next duty countdown card ─────────────────────────────────────────────────

class _NextDutyCard extends StatelessWidget {
  final dynamic nextDuty;
  final Duration remaining;
  const _NextDutyCard({required this.nextDuty, required this.remaining});

  @override
  Widget build(BuildContext context) {
    final hasNext = nextDuty != null;
    final dt = hasNext ? DateTime.tryParse(nextDuty.date as String) : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.panel.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasNext ? AppTheme.primary.withValues(alpha: 0.5) : AppTheme.border,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: hasNext && dt != null
              ? _withDuty(dt)
              : _noDuty(),
        ),
      ),
    );
  }

  Widget _withDuty(DateTime dt) {
    final days  = remaining.inDays;
    final hours = remaining.inHours % 24;
    final mins  = remaining.inMinutes % 60;
    final isToday = _isSameDay(dt, DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.access_time_rounded, color: AppTheme.primaryLight, size: 16),
            const SizedBox(width: 6),
            const Text('SONRAKİ NÖBETİNİZ',
              style: TextStyle(fontSize: 10, letterSpacing: 2, color: AppTheme.textSecondary,
                fontWeight: FontWeight.w700)),
            const Spacer(),
            if (isToday)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.primary),
                ),
                child: const Text('BUGÜN',
                  style: TextStyle(fontSize: 9, color: AppTheme.primaryLight,
                    fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _formatDate(dt),
          style: const TextStyle(
            fontSize: 26, fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary, letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _dayName(dt),
          style: const TextStyle(fontSize: 13, color: AppTheme.primaryLight,
            fontWeight: FontWeight.w600, letterSpacing: 1),
        ),
        if (!isToday && remaining > Duration.zero) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _TimeUnit(value: days,  label: 'GÜN'),
                _Divider(),
                _TimeUnit(value: hours, label: 'SAAT'),
                _Divider(),
                _TimeUnit(value: mins,  label: 'DAK'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _noDuty() => Row(
    children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppTheme.panelLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.event_available_outlined, color: AppTheme.textSecondary),
      ),
      const SizedBox(width: 14),
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SONRAKİ NÖBETİNİZ',
            style: TextStyle(fontSize: 10, letterSpacing: 2, color: AppTheme.textSecondary,
              fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('Yaklaşan nöbet yok', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
        ],
      ),
    ],
  );

  String _formatDate(DateTime dt) {
    const months = ['', 'OCA', 'ŞUB', 'MAR', 'NİS', 'MAY', 'HAZ',
                        'TEM', 'AĞU', 'EYL', 'EKİ', 'KAS', 'ARA'];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month]} ${dt.year}';
  }

  String _dayName(DateTime dt) {
    const days = ['', 'PAZARTESİ', 'SALI', 'ÇARŞAMBA',
                      'PERŞEMBE', 'CUMA', 'CUMARTESİ', 'PAZAR'];
    return days[dt.weekday];
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _TimeUnit extends StatelessWidget {
  final int value;
  final String label;
  const _TimeUnit({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value.toString().padLeft(2, '0'),
        style: const TextStyle(
          fontSize: 28, fontWeight: FontWeight.w900,
          color: AppTheme.primaryLight, letterSpacing: 2,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      Text(label,
        style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary,
          letterSpacing: 1.5, fontWeight: FontWeight.w600)),
    ],
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Text(':',
    style: TextStyle(fontSize: 24, color: AppTheme.border, fontWeight: FontWeight.w900));
}

// ─── Weekly grid ──────────────────────────────────────────────────────────────

class _WeeklyGrid extends StatelessWidget {
  final List<dynamic> weeklyDuties;
  final String userId;
  const _WeeklyGrid({required this.weeklyDuties, required this.userId});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (ctx, i) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final day = now.add(Duration(days: i));
          final isToday = i == 0;

          final duty = weeklyDuties.cast<dynamic>().where((d) {
            final dt = DateTime.tryParse(d.date as String);
            return dt != null && _isSameDay(dt, day);
          }).firstOrNull;

          final isMyDuty = duty != null && (duty.userId as String) == userId;
          final hasDuty  = duty != null;

          return _DayCell(
            dayName: dayNames[day.weekday - 1],
            dayNum: day.day,
            isToday: isToday,
            isMyDuty: isMyDuty,
            hasDuty: hasDuty,
            personName: duty != null ? (duty.userName as String) : null,
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayCell extends StatelessWidget {
  final String dayName;
  final int dayNum;
  final bool isToday, isMyDuty, hasDuty;
  final String? personName;
  const _DayCell({
    required this.dayName, required this.dayNum,
    required this.isToday, required this.isMyDuty,
    required this.hasDuty, this.personName,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    if (isMyDuty) {
      bgColor     = AppTheme.primary.withValues(alpha: 0.25);
      borderColor = AppTheme.primary;
    } else if (isToday) {
      bgColor     = AppTheme.panelLight;
      borderColor = AppTheme.primaryLight.withValues(alpha: 0.5);
    } else {
      bgColor     = AppTheme.panel;
      borderColor = AppTheme.border;
    }

    return Container(
      width: 52,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: isToday || isMyDuty ? 1.5 : 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(dayName,
            style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1,
              color: isToday ? AppTheme.primaryLight : AppTheme.textSecondary,
            )),
          const SizedBox(height: 4),
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isToday ? AppTheme.primary : Colors.transparent,
            ),
            child: Center(
              child: Text('$dayNum',
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800,
                  color: isToday ? Colors.white : AppTheme.textPrimary,
                )),
            ),
          ),
          const SizedBox(height: 4),
          if (hasDuty)
            Text(
              _short(personName ?? ''),
              style: TextStyle(
                fontSize: 8, fontWeight: FontWeight.w700,
                color: isMyDuty ? AppTheme.accent : AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            )
          else
            Container(width: 16, height: 2, color: AppTheme.border),
        ],
      ),
    );
  }

  String _short(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '-';
    return parts.first.length > 5 ? parts.first.substring(0, 5) : parts.first;
  }
}

// ─── Quick actions ────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(Icons.beach_access_outlined, 'İZİN TALEBİ',   AppTheme.warning,      '/leaves'),
      _ActionItem(Icons.swap_horiz_rounded,    'NÖBET DEĞİŞİM', AppTheme.primaryLight,  '/swaps'),
      _ActionItem(Icons.calendar_month_outlined,'AYLIK TAKVİM',  AppTheme.accent,       '/monthly-calendar'),
      _ActionItem(Icons.leaderboard_outlined,  'PUAN TABLOSU',  AppTheme.textSecondary, '/leaderboard'),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 0,
      childAspectRatio: 0.75,
      children: actions.map((a) => _ActionButton(a)).toList(),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  const _ActionItem(this.icon, this.label, this.color, this.route);
}

class _ActionButton extends StatelessWidget {
  final _ActionItem item;
  const _ActionButton(this.item);

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.pushNamed(context, item.route),
    borderRadius: BorderRadius.circular(12),
    child: Container(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 8, fontWeight: FontWeight.w700,
              letterSpacing: 0.8, color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    ),
  );
}

// ─── Activity feed ────────────────────────────────────────────────────────────

class _ActivityFeed extends StatelessWidget {
  final List<AppNotification> notifications;
  const _ActivityFeed({required this.notifications});

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Center(
          child: Text('Henüz gelişme yok',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: notifications.asMap().entries.map((entry) {
          final i    = entry.key;
          final notif = entry.value;
          final isLast = i == notifications.length - 1;
          return _FeedItem(notif: notif, isLast: isLast);
        }).toList(),
      ),
    );
  }
}

class _FeedItem extends StatelessWidget {
  final AppNotification notif;
  final bool isLast;
  const _FeedItem({required this.notif, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final icon  = _icon();
    final color = _color();
    final time  = _timeAgo(notif.createdAt);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline dot + line
              Column(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: 0.4)),
                    ),
                    child: Icon(icon, size: 15, color: color),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(notif.title,
                            style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: notif.isRead ? AppTheme.textSecondary : AppTheme.textPrimary,
                            )),
                        ),
                        Text(time,
                          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                        if (!notif.isRead)
                          Container(
                            width: 6, height: 6,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryLight, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(notif.message,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, color: AppTheme.border, indent: 58),
      ],
    );
  }

  IconData _icon() {
    final t = notif.title.toLowerCase();
    if (t.contains('izin'))   return Icons.beach_access_outlined;
    if (t.contains('değiş') || t.contains('swap')) return Icons.swap_horiz_rounded;
    if (t.contains('nöbet'))  return Icons.calendar_today_outlined;
    return Icons.notifications_outlined;
  }

  Color _color() {
    final t = notif.title.toLowerCase();
    if (t.contains('red') || t.contains('iptal'))  return AppTheme.error;
    if (t.contains('onay'))   return AppTheme.success;
    if (t.contains('değiş'))  return AppTheme.primaryLight;
    if (t.contains('izin'))   return AppTheme.warning;
    return AppTheme.textSecondary;
  }

  String _timeAgo(String iso) {
    try {
      final dt   = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1)  return 'şimdi';
      if (diff.inHours < 1)    return '${diff.inMinutes}dk';
      if (diff.inDays < 1)     return '${diff.inHours}sa';
      if (diff.inDays < 30)    return '${diff.inDays}g';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }
}
