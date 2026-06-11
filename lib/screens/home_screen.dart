import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'items_screen.dart';
import 'sales_screen.dart';
import 'debts_screen.dart';
import 'history_screen.dart';
import 'analytics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseHelper();
  double _todaySales = 0;
  double _totalDebts = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final today = await _db.getTodaySales();
    final debts = await _db.getTotalDebts();
    setState(() {
      _todaySales = today;
      _totalDebts = debts;
    });
  }

  void _navigateTo(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gucuruza'),
        backgroundColor: theme.colorScheme.primaryContainer,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Stats cards
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Uyu munsi',
                    value: '${_todaySales.toStringAsFixed(0)} Frw',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Amadeni yose',
                    value: '${_totalDebts.toStringAsFixed(0)} Frw',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Menu buttons
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MenuButton(
                    icon: Icons.sell,
                    label: 'ANDIKA IBYO UCURUJE',
                    color: Colors.green,
                    onTap: () => _navigateTo(const SalesScreen()),
                  ),
                  const SizedBox(height: 16),
                  _MenuButton(
                    icon: Icons.inventory,
                    label: 'IBICURUZWA',
                    color: Colors.blue,
                    onTap: () => _navigateTo(const ItemsScreen()),
                  ),
                  const SizedBox(height: 16),
                  _MenuButton(
                    icon: Icons.money_off,
                    label: 'AMADENI ATARISHYURWA',
                    color: Colors.orange,
                    onTap: () => _navigateTo(const DebtsScreen()),
                  ),
                  const SizedBox(height: 16),
                  _MenuButton(
                    icon: Icons.history,
                    label: 'IBYACURUJWE',
                    color: Colors.purple,
                    onTap: () => _navigateTo(const HistoryScreen()),
                  ),
                  const SizedBox(height: 16),
                  _MenuButton(
                    icon: Icons.bar_chart,
                    label: 'RAPORO',
                    color: Colors.teal,
                    onTap: () => _navigateTo(const AnalyticsScreen()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 28),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
