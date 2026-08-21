import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/monthly_score.dart';
import '../../providers/auth_provider.dart';
import '../../providers/duty_provider.dart';

class ScoreHistoryScreen extends StatefulWidget {
  const ScoreHistoryScreen({super.key});

  @override
  State<ScoreHistoryScreen> createState() => _ScoreHistoryScreenState();
}

class _ScoreHistoryScreenState extends State<ScoreHistoryScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  static const _monthNames = [
    '',
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token!;
      context.read<DutyProvider>().fetchMonthlyScores(token);
    });
  }

  List<MonthlyScore> _filtered(List<MonthlyScore> all) =>
      all
          .where((s) => s.year == _selectedYear && s.month == _selectedMonth)
          .toList()
        ..sort((a, b) => b.score.compareTo(a.score));

  List<int> _availableYears(List<MonthlyScore> all) {
    final years = all.map((s) => s.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    if (!years.contains(_selectedYear)) years.insert(0, _selectedYear);
    return years;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş Puan Tablosu'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<DutyProvider>(
        builder: (_, prov, _) {
          final all = prov.monthlyScores;
          final years = _availableYears(all);
          final filtered = _filtered(all);

          return Column(
            children: [
              _FilterBar(
                selectedYear: _selectedYear,
                selectedMonth: _selectedMonth,
                availableYears: years,
                monthNames: _monthNames,
                onYearChanged: (y) => setState(() => _selectedYear = y),
                onMonthChanged: (m) => setState(() => _selectedMonth = m),
              ),
              Expanded(
                child: all.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Bu ayda nöbet kaydı yok.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) =>
                            _ScoreRow(rank: i + 1, score: filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final int selectedYear, selectedMonth;
  final List<int> availableYears;
  final List<String> monthNames;
  final ValueChanged<int> onYearChanged, onMonthChanged;

  const _FilterBar({
    required this.selectedYear,
    required this.selectedMonth,
    required this.availableYears,
    required this.monthNames,
    required this.onYearChanged,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppTheme.primary.withValues(alpha: 0.06),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: selectedMonth,
                isExpanded: true,
                items: List.generate(12, (i) => i + 1)
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(monthNames[m]),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) onMonthChanged(v);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: selectedYear,
                isExpanded: true,
                items: availableYears
                    .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onYearChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final int rank;
  final MonthlyScore score;

  const _ScoreRow({required this.rank, required this.score});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _medal(rank),
        title: Text(
          score.userName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${score.score} nöbet',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _medal(int rank) {
    if (rank == 1) return const Text('🥇', style: TextStyle(fontSize: 28));
    if (rank == 2) return const Text('🥈', style: TextStyle(fontSize: 28));
    if (rank == 3) return const Text('🥉', style: TextStyle(fontSize: 28));
    return CircleAvatar(
      backgroundColor: Colors.grey.shade200,
      child: Text(
        '$rank',
        style: const TextStyle(color: Colors.black54, fontSize: 13),
      ),
    );
  }
}
