import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _db = DatabaseHelper();
  int _periodIndex = 0; // 0=today, 1=week, 2=month

  double _revenue = 0;
  double _cost = 0;
  List<Map<String, dynamic>> _dailyData = [];
  List<Map<String, dynamic>> _topItems = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  (DateTime, DateTime) _getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_periodIndex) {
      case 1: // week
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return (weekStart, now);
      case 2: // month
        final monthStart = DateTime(now.year, now.month, 1);
        return (monthStart, now);
      default: // today
        return (today, now);
    }
  }

  Future<void> _loadData() async {
    final (from, to) = _getDateRange();
    final profitData = await _db.getProfitForRange(from, to);
    final chartDays = _periodIndex == 0 ? 1 : (_periodIndex == 1 ? 7 : 30);
    final daily = await _db.getDailyRevenue(chartDays);
    final top = await _db.getTopSellingItems(from: from, to: to, limit: 5);
    setState(() {
      _revenue = profitData['revenue']!;
      _cost = profitData['cost']!;
      _dailyData = daily;
      _topItems = top;
    });
  }

  double get _profit => _revenue - _cost;

  void _setPeriod(int index) {
    setState(() => _periodIndex = index);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporo'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PeriodChip(label: 'Uyu munsi', selected: _periodIndex == 0, onTap: () => _setPeriod(0)),
                const SizedBox(width: 8),
                _PeriodChip(label: 'Iki cyumweru', selected: _periodIndex == 1, onTap: () => _setPeriod(1)),
                const SizedBox(width: 8),
                _PeriodChip(label: 'Uku kwezi', selected: _periodIndex == 2, onTap: () => _setPeriod(2)),
              ],
            ),
            const SizedBox(height: 20),

            // Profit + Revenue cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: _profit >= 0 ? Colors.green : Colors.red,
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            _profit >= 0 ? 'Inyungu' : 'Igihombo',
                            style: const TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_profit.abs().toStringAsFixed(0)} Frw',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    color: Colors.blue,
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Ibyacurujwe',
                            style: TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_revenue.toStringAsFixed(0)} Frw',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bar chart
            if (_periodIndex > 0) ...[
              const Text(
                'Ibyacurujwe ku munsi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: _dailyData.isEmpty
                    ? const Center(
                        child: Text('Nta byacurujwe', style: TextStyle(color: Colors.grey)),
                      )
                    : BarChart(
                        BarChartData(
                          barGroups: _dailyData.asMap().entries.map((e) {
                            return BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: (e.value['revenue'] as num).toDouble(),
                                  color: Colors.green,
                                  width: _periodIndex == 1 ? 24 : 8,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ],
                            );
                          }).toList(),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= _dailyData.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final dateStr = _dailyData[idx]['date'] as String;
                                  final parts = dateStr.split('-');
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      '${parts[2]}/${parts[1]}',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  '${rod.toY.toStringAsFixed(0)} Frw',
                                  const TextStyle(color: Colors.white, fontSize: 12),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 24),
            ],

            // Top selling items
            const Text(
              'Ibicuruzwa bikundwa',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_topItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('Nta byacurujwe', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...List.generate(_topItems.length, (i) {
                final item = _topItems[i];
                final name = item['name'] as String;
                final qty = (item['total_qty'] as num).toDouble();
                final revenue = (item['total_revenue'] as num).toDouble();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.teal,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'x${qty.toStringAsFixed(qty == qty.roundToDouble() ? 0 : 1)}',
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                              Text(
                                '${revenue.toStringAsFixed(0)} Frw',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.teal : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
