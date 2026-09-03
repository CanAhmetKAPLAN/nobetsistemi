import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/duty_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/swap_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/duty.dart';

class MonthlyCalendarScreen extends StatefulWidget {
  const MonthlyCalendarScreen({super.key});

  @override
  State<MonthlyCalendarScreen> createState() => _MonthlyCalendarScreenState();
}

class _MonthlyCalendarScreenState extends State<MonthlyCalendarScreen> {
  late int _year;
  late int _month;
  bool _filling = false;
  bool _deletingMonth = false;

  static const _monthNames = [
    '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    final auth  = context.read<AuthProvider>();
    final token = auth.token!;
    await Future.wait([
      context.read<DutyProvider>().fetchByMonth(token, _year, _month),
      context.read<DutyProvider>().fetchByUser(token, auth.user!.id),
    ]);
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) { _month = 12; _year--; } else { _month--; }
    });
    _fetch();
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) { _month = 1; _year++; } else { _month++; }
    });
    _fetch();
  }

  Future<void> _autoFill() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ayı Otomatik Doldur'),
        content: Text(
          '$_year ${_monthNames[_month]} ayındaki boş günler adil algoritmayla '
          'otomatik atanacak. Devam edilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Doldur'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _filling = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final result = await context.read<DutyProvider>().autoFillMonth(token, _year, _month);
      if (!mounted) return;
      final assigned = result['assignedCount'] ?? 0;
      final skipped  = result['skippedCount'] ?? 0;
      final already  = result['alreadyFilledCount'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$assigned gün atandı'
            '${already > 0 ? ' · $already zaten doluydu' : ''}'
            '${skipped  > 0 ? ' · $skipped uygun kişi bulunamadı' : ''}',
          ),
          backgroundColor: assigned > 0 ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _filling = false);
    }
  }

  Future<void> _deleteMonth() async {
    final duties = context.read<DutyProvider>().monthlyDuties;
    if (duties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu ayda silinecek nöbet yok.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ayı Sil'),
        content: Text(
          '$_year ${_monthNames[_month]} ayındaki ${duties.length} nöbetin tamamı '
          'silinecek ve ilgili kişilerin puanları buna göre düşülecek. '
          'Bu işlem geri alınamaz. Devam edilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ayı Sil'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _deletingMonth = true);
    final token = context.read<AuthProvider>().token!;
    final dutyProvider = context.read<DutyProvider>();
    var deleted = 0;
    var failed = 0;
    for (final duty in duties) {
      try {
        await dutyProvider.delete(token, duty.id);
        deleted++;
      } catch (_) {
        failed++;
      }
    }
    await dutyProvider.fetchByMonth(token, _year, _month);
    if (!mounted) return;
    setState(() => _deletingMonth = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$deleted nöbet silindi ve puanlar düşüldü'
          '${failed > 0 ? ' · $failed nöbet silinemedi' : ''}',
        ),
        backgroundColor: failed == 0 ? AppTheme.success : AppTheme.warning,
      ),
    );
  }

  Future<void> _showSwapDialog(Duty targetDuty) async {
    final auth        = context.read<AuthProvider>();
    final myDuties    = context.read<DutyProvider>().duties;
    final now         = DateTime.now();

    // Only upcoming duties of the current user can be offered
    final offerableDuties = myDuties.where((d) {
      final dt = DateTime.tryParse(d.date);
      return dt != null && (dt.isAfter(now) || _isSameDay(dt, now));
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    Duty? selectedDuty;
    final reasonCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('Nöbet Değişim Talebi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Target info
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz, color: AppTheme.primaryLight, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${AppDateUtils.formatDate(targetDuty.date)} tarihli nöbet — ${targetDuty.userName}',
                          style: TextStyle(fontSize: 13, color: AppTheme.primaryLight),
                        ),
                      ),
                    ],
                  ),
                ),
                // My duty to offer
                const Text('Teklif edeceğiniz nöbetiniz:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                if (offerableDuties.isEmpty)
                  Text(
                    'Teklif edebileceğiniz yaklaşan nöbetiniz yok.',
                    style: TextStyle(color: AppTheme.error, fontSize: 12),
                  )
                else
                  InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                    child: DropdownButton<Duty>(
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      hint: const Text('Nöbet seçin', style: TextStyle(fontSize: 13)),
                      value: selectedDuty,
                      items: offerableDuties.map((d) => DropdownMenuItem(
                        value: d,
                        child: Text(AppDateUtils.formatDate(d.date), style: const TextStyle(fontSize: 13)),
                      )).toList(),
                      onChanged: (d) => setInner(() => selectedDuty = d),
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Gerekçe (isteğe bağlı)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: offerableDuties.isEmpty || selectedDuty == null
                  ? null
                  : () => Navigator.pop(ctx, true),
              child: const Text('Talep Gönder'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || selectedDuty == null || !mounted) return;

    try {
      await context.read<SwapProvider>().create(
        auth.token!,
        targetDuty.userId,
        selectedDuty!.id,
        targetDuty.id,
        reasonCtrl.text.trim().isEmpty ? 'Takvimden talep' : reasonCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${targetDuty.userName} kullanıcısına değişim talebi gönderildi.',
            ),
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
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final auth    = context.watch<AuthProvider>();
    final isAdmin = context.watch<GroupProvider>().currentGroup?.isAdmin ?? false;
    final userId  = auth.user?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aylık Nöbet Takvimi'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (isAdmin) ...[
            IconButton(
              icon: _filling
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              tooltip: 'Ayı Otomatik Doldur',
              onPressed: _filling || _deletingMonth ? null : _autoFill,
            ),
            IconButton(
              icon: _deletingMonth
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.delete),
              tooltip: 'Ayı Sil',
              onPressed: _filling || _deletingMonth ? null : _deleteMonth,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          _MonthNavigator(
            year: _year,
            month: _month,
            monthName: _monthNames[_month],
            onPrev: _prevMonth,
            onNext: _nextMonth,
          ),
          const _WeekdayHeader(),
          Expanded(
            child: Consumer<DutyProvider>(
              builder: (context, prov, child) {
                if (prov.monthlyLoading || _filling || _deletingMonth) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _CalendarGrid(
                  year: _year,
                  month: _month,
                  duties: prov.monthlyDuties,
                  currentUserId: userId,
                  onSwapRequest: _showSwapDialog,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Month navigator ──────────────────────────────────────────────────────────

class _MonthNavigator extends StatelessWidget {
  final int year, month;
  final String monthName;
  final VoidCallback onPrev, onNext;

  const _MonthNavigator({
    required this.year,
    required this.month,
    required this.monthName,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Container(
      color: AppTheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: onPrev,
          ),
          Text(
            '$monthName $year',
            style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

// ─── Weekday header ───────────────────────────────────────────────────────────

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return Container(
      color: AppTheme.primary.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: days
            .map((d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: d == 'Paz' ? Colors.red : AppTheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ─── Calendar grid ────────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  final int year, month;
  final List<Duty> duties;
  final String currentUserId;
  final void Function(Duty) onSwapRequest;

  const _CalendarGrid({
    required this.year,
    required this.month,
    required this.duties,
    required this.currentUserId,
    required this.onSwapRequest,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay    = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startOffset = firstDay.weekday - 1; // Mon=0 … Sun=6

    final dutyMap = <int, Duty>{};
    for (final d in duties) {
      final date = DateTime.tryParse(d.date);
      if (date != null && date.year == year && date.month == month) {
        dutyMap[date.day] = d;
      }
    }

    final rows = ((startOffset + daysInMonth) / 7).ceil();

    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.9,
      ),
      itemCount: rows * 7,
      itemBuilder: (ctx, i) {
        final dayNum = i - startOffset + 1;
        if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox.shrink();

        final duty    = dutyMap[dayNum];
        final isToday = DateTime.now().year == year &&
            DateTime.now().month == month &&
            DateTime.now().day == dayNum;
        final isSunday = (startOffset + dayNum - 1) % 7 == 6;
        final isMyDuty = duty != null && duty.userId == currentUserId;
        final canSwap  = duty != null && !isMyDuty;
        final d        = duty; // local non-nullable after null check below

        return _DayCell(
          day: dayNum,
          duty: duty,
          isToday: isToday,
          isSunday: isSunday,
          isMyDuty: isMyDuty,
          canSwap: canSwap,
          onSwapTap: d != null && !isMyDuty ? () => onSwapRequest(d) : null,
        );
      },
    );
  }
}

// ─── Day cell ─────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  final int day;
  final Duty? duty;
  final bool isToday, isSunday, isMyDuty, canSwap;
  final VoidCallback? onSwapTap;

  const _DayCell({
    required this.day,
    this.duty,
    required this.isToday,
    required this.isSunday,
    required this.isMyDuty,
    required this.canSwap,
    this.onSwapTap,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    Color bg;
    Color borderColor;

    if (isMyDuty) {
      bg          = AppTheme.primary.withValues(alpha: 0.18);
      borderColor = AppTheme.primary;
    } else if (isToday) {
      bg          = AppTheme.panelLight;
      borderColor = AppTheme.primaryLight.withValues(alpha: 0.6);
    } else if (duty != null) {
      bg          = AppTheme.panel;
      borderColor = AppTheme.border;
    } else {
      bg          = AppTheme.bg;
      borderColor = AppTheme.border.withValues(alpha: 0.5);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSwapTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(
            color: borderColor,
            width: isToday || isMyDuty ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '$day',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isSunday
                    ? Colors.red
                    : isToday
                        ? AppTheme.primaryLight
                        : AppTheme.textPrimary,
              ),
            ),
            if (duty != null) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                decoration: BoxDecoration(
                  color: isMyDuty ? AppTheme.primary : AppTheme.panelLight,
                  borderRadius: BorderRadius.circular(4),
                  border: isMyDuty
                      ? null
                      : Border.all(color: AppTheme.border),
                ),
                child: Text(
                  _shortName(duty!.userName),
                  style: TextStyle(
                    color: isMyDuty ? Colors.white : AppTheme.textSecondary,
                    fontSize: 9,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canSwap) ...[
                const SizedBox(height: 2),
                Icon(Icons.swap_horiz, size: 10, color: AppTheme.accent),
              ],
            ],
          ],
        ),
        ),
      ),
    );
  }

  String _shortName(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return name.length > 8 ? name.substring(0, 8) : name;
    return '${parts.first} ${parts.last[0]}.';
  }
}
