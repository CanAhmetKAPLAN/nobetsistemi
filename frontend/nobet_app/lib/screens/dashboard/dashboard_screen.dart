import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../models/group_membership.dart';
import '../../models/notification.dart';
import '../../models/swap_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/duty_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/swap_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/app_drawer.dart';

/// Bildirim başlığına göre uygulama içinde açılacak sayfa — "Gelişmeler"
/// akışında ve bildirim listesinde ortak kullanılır.
String? routeForNotificationTitle(String title) {
  if (title.contains('Değişim')) return '/swaps';
  if (title.contains('Nöbet Atandı')) return '/monthly-calendar';
  if (title.contains('İzin')) return '/leaves';
  return null;
}

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
      context.read<SwapProvider>().fetchMy(token),
      context.read<SwapProvider>().fetchIncoming(token),
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
    final swap  = context.watch<SwapProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
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

    final myPendingSwap = swap.swaps
        .where((s) => s.requesterId == userId && s.status == 'Pending')
        .firstOrNull;
    final incomingCount = swap.incoming.where((s) => s.status == 'Pending').length;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bg : const Color(0xFFF8FAFC),
      appBar: _buildAppBar(notif, isDark),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        color: isDark ? AppTheme.primaryLight : const Color(0xFF0D9488),
        backgroundColor: isDark ? AppTheme.panel : Colors.white,
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: isDark
              ? _buildDarkBody(auth, todayDuty, isAdmin, myScore, nextDuty, weeklyAll, userId, notif)
              : _buildLightBody(auth, isAdmin, myScore, nextDuty, weeklyAll, userId, notif, group,
                  myPendingSwap, incomingCount),
        ),
      ),
    );
  }

  // ─── Dark mod içeriği (mevcut tasarım — değişmedi) ───────────────────────────

  Widget _buildDarkBody(
    dynamic auth,
    dynamic todayDuty,
    bool isAdmin,
    double myScore,
    dynamic nextDuty,
    List<dynamic> weeklyAll,
    String userId,
    NotificationProvider notif,
  ) {
    return Column(
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
              _sectionLabel('HAFTALIK TAKVİM', true),
              const SizedBox(height: 10),
              _WeeklyGrid(weeklyDuties: weeklyAll, userId: userId),
              const SizedBox(height: 20),
              _sectionLabel('HIZLI İŞLEMLER', true),
              const SizedBox(height: 10),
              _QuickActions(),
              const SizedBox(height: 20),
              _sectionLabel('GELİŞMELER', true),
              const SizedBox(height: 10),
              _ActivityFeed(notifications: notif.notifications.take(8).toList()),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Açık (Light) mod içeriği — yeni tasarım ─────────────────────────────────

  Widget _buildLightBody(
    dynamic auth,
    bool isAdmin,
    double myScore,
    dynamic nextDuty,
    List<dynamic> weeklyAll,
    String userId,
    NotificationProvider notif,
    GroupProvider group,
    SwapRequest? myPendingSwap,
    int incomingCount,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LightUserCard(user: auth.user, isAdmin: isAdmin, score: myScore),
          const SizedBox(height: 16),
          _LightNextDutyHero(nextDuty: nextDuty, remaining: _remaining),
          const SizedBox(height: 20),
          _sectionLabel(
            'HAFTALIK ÇİZELGE',
            false,
            trailing: InkWell(
              onTap: () => Navigator.pushNamed(context, '/monthly-calendar'),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Tüm Ay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0D9488))),
                  Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF0D9488)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _LightWeeklyGrid(weeklyDuties: weeklyAll, userId: userId),
          const SizedBox(height: 20),
          _sectionLabel('HIZLI İŞLEMLER', false),
          const SizedBox(height: 10),
          _LightQuickActions(pendingSwapCount: incomingCount),
          if (myPendingSwap != null) ...[
            const SizedBox(height: 16),
            _LightPendingExchangeBanner(
              swap: myPendingSwap,
              onCancel: () => context.read<SwapProvider>().cancel(
                    context.read<AuthProvider>().token!,
                    myPendingSwap.id,
                  ),
            ),
          ],
          const SizedBox(height: 16),
          _LightLeaderboardPreview(members: group.members, currentUserId: userId),
          const SizedBox(height: 20),
          _sectionLabel('SON GELİŞMELER', false),
          const SizedBox(height: 10),
          _LightActivityFeed(notifications: notif.notifications.take(8).toList()),
        ],
      ),
    );
  }

  AppBar _buildAppBar(NotificationProvider notif, bool isDark) {
    final barColor    = isDark ? AppTheme.panel : Colors.white;
    final borderColor = isDark ? AppTheme.border : const Color(0xFFF1F5F9);
    final titleColor  = isDark ? AppTheme.textPrimary : const Color(0xFF0F172A);
    final subColor    = isDark ? AppTheme.primaryLight : const Color(0xFF0F766E);
    final iconColor   = isDark ? AppTheme.textSecondary : const Color(0xFF334155);
    final shieldBg    = isDark ? AppTheme.primary : const Color(0xFF0D9488);

    return AppBar(
      backgroundColor: barColor,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      iconTheme: IconThemeData(color: iconColor),
      title: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: shieldBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NÖBET SİSTEMİ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    color: titleColor,
                  ),
                ),
                Text(
                  'KOMUTA MERKEZİ',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.8,
                    color: subColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        _ThemeToggle(isDark: isDark, onTap: () => context.read<ThemeProvider>().toggle()),
        const SizedBox(width: 6),
        Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: iconColor),
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
        child: Container(height: 1, color: borderColor),
      ),
    );
  }

  Widget _sectionLabel(String text, bool isDark, {Widget? trailing}) => Row(
    children: [
      Container(
        width: 3, height: 14,
        color: isDark ? AppTheme.primary : const Color(0xFF0D9488),
        margin: const EdgeInsets.only(right: 8),
      ),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: isDark ? AppTheme.textSecondary : const Color(0xFF334155),
          ),
        ),
      ),
      if (trailing != null) trailing,
    ],
  );

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─── Açık/Koyu mod anahtarı (köşe switch) ─────────────────────────────────────

class _ThemeToggle extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _ThemeToggle({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 52, height: 28,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.panelLight : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppTheme.border : const Color(0xFFE2E8F0)),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppTheme.primary : const Color(0xFF0D9488),
          ),
          child: Icon(
            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            size: 13, color: Colors.white,
          ),
        ),
      ),
    ),
  );
}

// ─── Hero card (dark) ──────────────────────────────────────────────────────────

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

// ─── Next duty countdown card (dark) ──────────────────────────────────────────

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

// ─── Weekly grid (dark) ────────────────────────────────────────────────────────

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

// ─── Quick actions (dark) ──────────────────────────────────────────────────────

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

// ─── Activity feed (dark) ──────────────────────────────────────────────────────

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
        InkWell(
          onTap: () {
            final auth = context.read<AuthProvider>();
            if (!notif.isRead) {
              context.read<NotificationProvider>().markAsRead(auth.token!, notif.id);
            }
            final route = routeForNotificationTitle(notif.title);
            if (route != null) Navigator.pushNamed(context, route);
          },
          child: Padding(
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

// ════════════════════════════════════════════════════════════════════════════
// ─── AÇIK MOD (LIGHT) BİLEŞENLERİ ──────────────────────────────────────────────
// ════════════════════════════════════════════════════════════════════════════

String _fmtScoreLight(dynamic score) {
  if (score == null) return '0';
  final d = (score as num).toDouble();
  return d == d.truncateToDouble() ? d.toInt().toString() : d.toStringAsFixed(2);
}

String _initialsLight(String? name) {
  if (name == null || name.isEmpty) return '?';
  final parts = name.trim().split(' ');
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

class _LightBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final Color border;
  const _LightBadge({required this.icon, required this.label, required this.bg, required this.fg, required this.border});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: fg),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)),
      ],
    ),
  );
}

// ─── Kullanıcı karşılama kartı ─────────────────────────────────────────────────

class _LightUserCard extends StatelessWidget {
  final dynamic user;
  final bool isAdmin;
  final double score;
  const _LightUserCard({required this.user, required this.isAdmin, required this.score});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFF1F5F9)),
      boxShadow: const [BoxShadow(color: Color(0x0A0F172A), blurRadius: 20, offset: Offset(0, 4))],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('HOŞ GELDİN',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: Color(0xFF94A3B8))),
              const SizedBox(height: 3),
              Text(user?.name ?? '',
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              const SizedBox(height: 9),
              Row(
                children: [
                  _LightBadge(
                    icon: Icons.verified_user_rounded,
                    label: isAdmin ? 'Yönetici' : 'Personel',
                    bg: const Color(0xFFF0FDFA), fg: const Color(0xFF0F766E), border: const Color(0x330F766E),
                  ),
                  const SizedBox(width: 8),
                  _LightBadge(
                    icon: Icons.star_rounded,
                    label: '${_fmtScoreLight(score)} Puan',
                    bg: const Color(0xFFFFFBEB), fg: const Color(0xFFB45309), border: const Color(0x33F59E0B),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF334155)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 4),
              ),
              child: Center(
                child: Text(_initialsLight(user?.name),
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                width: 16, height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981), shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// ─── Sıradaki nöbet teal gradyan hero ──────────────────────────────────────────

class _LightNextDutyHero extends StatelessWidget {
  final dynamic nextDuty;
  final Duration remaining;
  const _LightNextDutyHero({required this.nextDuty, required this.remaining});

  @override
  Widget build(BuildContext context) {
    final hasNext = nextDuty != null;
    final dt = hasNext ? DateTime.tryParse(nextDuty.date as String) : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF115E59)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F766E).withValues(alpha: 0.28), blurRadius: 28, offset: const Offset(0, 12)),
        ],
      ),
      child: hasNext && dt != null ? _withDuty(dt) : _noDuty(),
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
            const Icon(Icons.access_time_rounded, color: Color(0xFF99F6E4), size: 15),
            const SizedBox(width: 6),
            const Text('SIRADAKİ NÖBETİNİZ',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.8, color: Color(0xFF99F6E4))),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                isToday ? 'BUGÜN' : 'PLANLANDI',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(_formatDateLight(dt),
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.3)),
        const SizedBox(height: 3),
        Text(_dayNameLight(dt),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF99F6E4), letterSpacing: 0.8)),
        if (!isToday && remaining > Duration.zero) ...[
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0x26FFFFFF))),
            ),
            child: Row(
              children: [
                _LightTimeUnit(value: days,  label: 'GÜN'),
                _lightColon(),
                _LightTimeUnit(value: hours, label: 'SAAT'),
                _lightColon(),
                _LightTimeUnit(value: mins,  label: 'DAKİKA'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _lightColon() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 2),
    child: Text(':', style: TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.w800, fontSize: 18)),
  );

  Widget _noDuty() => Row(
    children: [
      Container(
        width: 42, height: 42,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.event_available_rounded, color: Colors.white),
      ),
      const SizedBox(width: 14),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SIRADAKİ NÖBETİNİZ',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.8, color: Color(0xFF99F6E4))),
            SizedBox(height: 4),
            Text('Yaklaşan nöbet yok', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ],
  );

  String _formatDateLight(DateTime dt) {
    const months = ['', 'OCA', 'ŞUB', 'MAR', 'NİS', 'MAY', 'HAZ',
                        'TEM', 'AĞU', 'EYL', 'EKİ', 'KAS', 'ARA'];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month]} ${dt.year}';
  }

  String _dayNameLight(DateTime dt) {
    const days = ['', 'PAZARTESİ', 'SALI', 'ÇARŞAMBA',
                      'PERŞEMBE', 'CUMA', 'CUMARTESİ', 'PAZAR'];
    return days[dt.weekday];
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _LightTimeUnit extends StatelessWidget {
  final int value;
  final String label;
  const _LightTimeUnit({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 1),
          Text(label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1, color: Color(0xFF99F6E4))),
        ],
      ),
    ),
  );
}

// ─── Haftalık çizelge şeridi ────────────────────────────────────────────────────

class _LightWeeklyGrid extends StatelessWidget {
  final List<dynamic> weeklyDuties;
  final String userId;
  const _LightWeeklyGrid({required this.weeklyDuties, required this.userId});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    return SizedBox(
      height: 92,
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

          return _LightDayCell(
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

class _LightDayCell extends StatelessWidget {
  final String dayName;
  final int dayNum;
  final bool isToday, isMyDuty, hasDuty;
  final String? personName;
  const _LightDayCell({
    required this.dayName, required this.dayNum,
    required this.isToday, required this.isMyDuty,
    required this.hasDuty, this.personName,
  });

  @override
  Widget build(BuildContext context) {
    final active = isToday;
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF0D9488) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: active ? const Color(0xFF0D9488) : const Color(0xFFF1F5F9)),
        boxShadow: active
            ? [BoxShadow(color: const Color(0xFF0D9488).withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 5))]
            : const [BoxShadow(color: Color(0x0A0F172A), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(dayName,
            style: TextStyle(
              fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.6,
              color: active ? Colors.white70 : const Color(0xFF94A3B8),
            )),
          const SizedBox(height: 5),
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? Colors.white : (isMyDuty ? const Color(0xFFCCFBF1) : const Color(0xFFF1F5F9)),
            ),
            child: Center(
              child: Text('$dayNum',
                style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w800,
                  color: active ? const Color(0xFF0F766E) : const Color(0xFF0F172A),
                )),
            ),
          ),
          const SizedBox(height: 5),
          if (hasDuty)
            Text(
              _short(personName ?? ''),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8.5, fontWeight: FontWeight.w700,
                color: active ? Colors.white : (isMyDuty ? const Color(0xFF0F766E) : const Color(0xFF64748B)),
              ),
            )
          else
            Container(
              width: 14, height: 2,
              decoration: BoxDecoration(
                color: active ? Colors.white38 : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );
  }

  String _short(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '-';
    return parts.first.length > 6 ? parts.first.substring(0, 6) : parts.first;
  }
}

// ─── Hızlı işlemler ────────────────────────────────────────────────────────────

class _LightQuickActions extends StatelessWidget {
  final int pendingSwapCount;
  const _LightQuickActions({required this.pendingSwapCount});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _LightActionItem(Icons.swap_horiz_rounded, 'Nöbet Değişim', const Color(0xFF0D9488), const Color(0xFFF0FDFA), '/swaps', pendingSwapCount),
      _LightActionItem(Icons.beach_access_rounded, 'İzin Talebi', const Color(0xFFF59E0B), const Color(0xFFFFFBEB), '/leaves', 0),
      _LightActionItem(Icons.calendar_month_rounded, 'Aylık Çizelge', const Color(0xFF0EA5E9), const Color(0xFFF0F9FF), '/monthly-calendar', 0),
      _LightActionItem(Icons.bar_chart_rounded, 'Puanlama', const Color(0xFF6366F1), const Color(0xFFEEF2FF), '/leaderboard', 0),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 0,
      childAspectRatio: 0.78,
      children: actions.map((a) => _LightActionButton(a)).toList(),
    );
  }
}

class _LightActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final Color softBg;
  final String route;
  final int badge;
  const _LightActionItem(this.icon, this.label, this.color, this.softBg, this.route, this.badge);
}

class _LightActionButton extends StatelessWidget {
  final _LightActionItem item;
  const _LightActionButton(this.item);

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.pushNamed(context, item.route),
    borderRadius: BorderRadius.circular(16),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [BoxShadow(color: Color(0x0A0F172A), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: item.softBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(item.icon, color: item.color, size: 21),
              ),
              const SizedBox(height: 7),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
            ],
          ),
          if (item.badge > 0)
            Positioned(
              top: 4, right: 4,
              child: Container(
                padding: const EdgeInsets.all(3.5),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
                child: Center(
                  child: Text('${item.badge}',
                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

// ─── Bekleyen değişim talebi çubuğu ─────────────────────────────────────────────

class _LightPendingExchangeBanner extends StatelessWidget {
  final SwapRequest swap;
  final VoidCallback onCancel;
  const _LightPendingExchangeBanner({required this.swap, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final dateLabel = AppDateUtils.formatDate(swap.requesterDutyDate);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFFBEB), Color(0xFFFFF7ED)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$dateLabel → ${swap.targetUserName}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: swap.reason.isEmpty ? 'Gerekçe belirtilmedi' : swap.reason,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      const TextSpan(text: ' • ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      const TextSpan(
                        text: 'Onay Bekliyor',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onCancel,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Colors.white, shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFE11D48)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Puan sıralaması önizlemesi ─────────────────────────────────────────────────

class _LightLeaderboardPreview extends StatelessWidget {
  final List<GroupMembership> members;
  final String currentUserId;
  const _LightLeaderboardPreview({required this.members, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();

    final sorted = [...members]..sort((a, b) => b.score.compareTo(a.score));
    final top = sorted.take(3).toList();
    final myIndex = sorted.indexWhere((m) => m.userId == currentUserId);

    final now = DateTime.now();
    const months = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
                        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    final monthLabel = '${months[now.month]} ${now.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [BoxShadow(color: Color(0x0A0F172A), blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nöbet Sıralaması',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  Text(monthLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                child: const Text('Genel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < top.length; i++) ...[
            _LightLeaderRow(rank: i + 1, name: top[i].userName, score: top[i].score,
              isMe: top[i].userId == currentUserId, medal: true),
            if (i != top.length - 1) const SizedBox(height: 8),
          ],
          if (myIndex >= 3) ...[
            const SizedBox(height: 8),
            _LightLeaderRow(
              rank: myIndex + 1, name: sorted[myIndex].userName, score: sorted[myIndex].score,
              isMe: true, medal: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _LightLeaderRow extends StatelessWidget {
  final int rank;
  final String name;
  final double score;
  final bool isMe;
  final bool medal;
  const _LightLeaderRow({
    required this.rank, required this.name, required this.score,
    required this.isMe, required this.medal,
  });

  static const _medalColors = {1: Color(0xFFF59E0B), 2: Color(0xFF94A3B8), 3: Color(0xFFEA580C)};

  @override
  Widget build(BuildContext context) {
    final medalColor = _medalColors[rank];
    final bg = isMe
        ? const Color(0xFFF0FDFA)
        : (medalColor != null ? medalColor.withValues(alpha: 0.06) : const Color(0xFFF8FAFC));
    final border = isMe ? const Color(0xFF99F6E4) : const Color(0xFFF1F5F9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMe
                  ? const Color(0xFF0D9488)
                  : (medalColor != null ? medalColor.withValues(alpha: 0.15) : const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: medalColor != null && !isMe
                  ? Icon(Icons.emoji_events_rounded, size: 14, color: medalColor)
                  : Text('$rank',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                        color: isMe ? Colors.white : const Color(0xFF475569))),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(name, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                      color: const Color(0xFF0F172A))),
                ),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: const Color(0xFF99F6E4), borderRadius: BorderRadius.circular(4)),
                    child: const Text('SEN',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Color(0xFF115E59))),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF0F766E), borderRadius: BorderRadius.circular(20)),
            child: Text('${_fmtScoreLight(score)} p',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Son gelişmeler akışı ───────────────────────────────────────────────────────

class _LightActivityFeed extends StatelessWidget {
  final List<AppNotification> notifications;
  const _LightActivityFeed({required this.notifications});

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: const Center(
          child: Text('Henüz gelişme yok', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [BoxShadow(color: Color(0x0A0F172A), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Column(
        children: notifications.asMap().entries.map((entry) {
          final i = entry.key;
          final n = entry.value;
          return _LightFeedItem(notif: n, isLast: i == notifications.length - 1);
        }).toList(),
      ),
    );
  }
}

class _LightFeedItem extends StatelessWidget {
  final AppNotification notif;
  final bool isLast;
  const _LightFeedItem({required this.notif, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final icon  = _icon();
    final color = _color();
    final time  = _timeAgo(notif.createdAt);

    return Column(
      children: [
        InkWell(
          onTap: () {
            final auth = context.read<AuthProvider>();
            if (!notif.isRead) {
              context.read<NotificationProvider>().markAsRead(auth.token!, notif.id);
            }
            final route = routeForNotificationTitle(notif.title);
            if (route != null) Navigator.pushNamed(context, route);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Icon(icon, size: 15, color: color),
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
                                fontSize: 13, fontWeight: FontWeight.w700,
                                color: notif.isRead ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                              )),
                          ),
                          Text(time, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                          if (!notif.isRead)
                            Container(
                              width: 6, height: 6,
                              margin: const EdgeInsets.only(left: 6),
                              decoration: const BoxDecoration(color: Color(0xFF0D9488), shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(notif.message,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isLast) Divider(height: 1, color: const Color(0xFFF1F5F9), indent: 58),
      ],
    );
  }

  IconData _icon() {
    final t = notif.title.toLowerCase();
    if (t.contains('izin'))   return Icons.beach_access_rounded;
    if (t.contains('değiş') || t.contains('swap')) return Icons.swap_horiz_rounded;
    if (t.contains('nöbet'))  return Icons.calendar_today_rounded;
    return Icons.notifications_rounded;
  }

  Color _color() {
    final t = notif.title.toLowerCase();
    if (t.contains('red') || t.contains('iptal'))  return const Color(0xFFE11D48);
    if (t.contains('onay'))   return const Color(0xFF10B981);
    if (t.contains('değiş'))  return const Color(0xFF0D9488);
    if (t.contains('izin'))   return const Color(0xFFF59E0B);
    return const Color(0xFF64748B);
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
