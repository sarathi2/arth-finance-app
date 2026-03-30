import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arth/budget_provider.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget & Goals'),
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Net worth card ──────────────────────────────────────
                _NetWorthCard(
                  totalAssets: provider.totalAssets,
                  totalLiabilities: provider.totalLiabilities,
                ),
                const SizedBox(height: 24),

                // ── Monthly budget section ──────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Monthly Budget',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () => _showSetBudgetDialog(context, provider),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Set limit'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...provider.budgetCategories.map(
                  (cat) => _BudgetCategoryCard(category: cat),
                ),

                if (provider.budgetCategories.isEmpty)
                  const _EmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    message: 'No budget limits set yet.\nTap "Set limit" to add one.',
                  ),

                const SizedBox(height: 24),

                // ── Savings goals ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Savings Goals',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () => _showAddGoalDialog(context, provider),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add goal'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...provider.savingsGoals.map(
                  (goal) => _SavingsGoalCard(goal: goal),
                ),

                if (provider.savingsGoals.isEmpty)
                  const _EmptyState(
                    icon: Icons.savings_outlined,
                    message: 'No savings goals yet.\nTap "Add goal" to set one.',
                  ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSetBudgetDialog(BuildContext ctx, BudgetProvider provider) {
    final nameCtrl = TextEditingController();
    final limitCtrl = TextEditingController();

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Set budget limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Category (e.g. Food, Transport)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: limitCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly limit (₹)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final limit = double.tryParse(limitCtrl.text);
              if (nameCtrl.text.isNotEmpty && limit != null) {
                provider.addBudgetCategory(
                    name: nameCtrl.text, limit: limit);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog(BuildContext ctx, BudgetProvider provider) {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final savedCtrl = TextEditingController();
    String type = 'short';

    showDialog(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (ctx2, setState2) => AlertDialog(
          title: const Text('Add savings goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Goal name (e.g. Emergency fund)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target amount (₹)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: savedCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Already saved (₹)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'short', label: Text('Short term')),
                  ButtonSegment(value: 'long', label: Text('Long term')),
                ],
                selected: {type},
                onSelectionChanged: (s) =>
                    setState2(() => type = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final target = double.tryParse(targetCtrl.text);
                final saved = double.tryParse(savedCtrl.text) ?? 0;
                if (nameCtrl.text.isNotEmpty && target != null) {
                  provider.addSavingsGoal(
                    name: nameCtrl.text,
                    target: target,
                    saved: saved,
                    type: type,
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Net worth card ────────────────────────────────────────────────────────────
class _NetWorthCard extends StatelessWidget {
  final double totalAssets;
  final double totalLiabilities;

  const _NetWorthCard(
      {required this.totalAssets, required this.totalLiabilities});

  @override
  Widget build(BuildContext context) {
    final netWorth = totalAssets - totalLiabilities;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('Net Worth',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(
            '₹${netWorth.toStringAsFixed(0)}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NetWorthItem(
                  label: 'Assets',
                  amount: totalAssets,
                  color: Colors.greenAccent.shade100),
              Container(width: 1, height: 40, color: Colors.white24),
              _NetWorthItem(
                  label: 'Liabilities',
                  amount: totalLiabilities,
                  color: Colors.red.shade200),
            ],
          ),
        ],
      ),
    );
  }
}

class _NetWorthItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _NetWorthItem(
      {required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 4),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}

// ── Budget category card ──────────────────────────────────────────────────────
class _BudgetCategoryCard extends StatelessWidget {
  final BudgetCategory category;
  const _BudgetCategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final pct = category.limit > 0 ? category.spent / category.limit : 0.0;
    final isOver = pct >= 1.0;
    final isNear = pct >= 0.8 && !isOver;

    Color barColor = Theme.of(context).colorScheme.primary;
    if (isOver) barColor = Theme.of(context).colorScheme.error;
    if (isNear) barColor = Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(category.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    if (isNear)
                      const Icon(Icons.warning_amber,
                          color: Colors.orange, size: 16),
                    if (isOver)
                      Icon(Icons.error_outline,
                          color: Theme.of(context).colorScheme.error, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '₹${category.spent.toStringAsFixed(0)} / ₹${category.limit.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isOver
                  ? 'Over budget by ₹${(category.spent - category.limit).toStringAsFixed(0)}'
                  : '₹${(category.limit - category.spent).toStringAsFixed(0)} remaining',
              style: TextStyle(
                  fontSize: 12,
                  color: isOver
                      ? Theme.of(context).colorScheme.error
                      : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Savings goal card ─────────────────────────────────────────────────────────
class _SavingsGoalCard extends StatelessWidget {
  final SavingsGoal goal;
  const _SavingsGoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final pct = goal.target > 0 ? goal.saved / goal.target : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(goal.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: goal.type == 'long'
                        ? Theme.of(context).colorScheme.secondaryContainer
                        : Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    goal.type == 'long' ? 'Long term' : 'Short term',
                    style: TextStyle(
                      fontSize: 11,
                      color: goal.type == 'long'
                          ? Theme.of(context).colorScheme.onSecondaryContainer
                          : Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.tertiary),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('₹${goal.saved.toStringAsFixed(0)} saved',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  '${(pct * 100).toStringAsFixed(0)}% of ₹${goal.target.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(icon,
                size: 48,
                color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}