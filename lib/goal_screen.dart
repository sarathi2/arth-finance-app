import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arth/goal_provider.dart';
import 'package:arth/auth_provider.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.uid;
      if (userId != null) {
        context.read<GoalProvider>().loadDashboard(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().user?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('My Goals'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1D9E75),
        onPressed: () => _showCreateGoalDialog(context, userId),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Goal', style: TextStyle(color: Colors.white)),
      ),
      body: Consumer<GoalProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1D9E75)));
          }

          if (provider.goals.isEmpty) {
            return const Center(
              child: Text('No goals yet! Tap "New Goal" to start saving.',
                  style: TextStyle(color: Colors.grey)),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadDashboard(userId),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Alerts Section ──
                if (provider.alerts.isNotEmpty) ...[
                  ...provider.alerts.map((alert) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(alert,
                                  style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),
                ],

                // ── Goals List ──
                ...provider.goals.map((goal) => _GoalCard(goal: goal, userId: userId)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Dialog to Create a New Goal ──
  void _showCreateGoalDialog(BuildContext context, String userId) {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final deadlineCtrl = TextEditingController(); // Format: YYYY-MM

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create New Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Goal Name (e.g. Laptop)')),
            TextField(controller: targetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target Amount (₹)')),
            TextField(controller: deadlineCtrl, decoration: const InputDecoration(labelText: 'Deadline (YYYY-MM)', hintText: '2026-12')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1D9E75)),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && targetCtrl.text.isNotEmpty && deadlineCtrl.text.isNotEmpty) {
                context.read<GoalProvider>().createNewGoal(
                  userId, 
                  nameCtrl.text, 
                  double.parse(targetCtrl.text), 
                  deadlineCtrl.text
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

// ── Individual Goal Card UI ──
class _GoalCard extends StatelessWidget {
  final Map<String, dynamic> goal;
  final String userId;

  const _GoalCard({required this.goal, required this.userId});

  @override
  Widget build(BuildContext context) {
    final double progress = (goal['progress_percent'] ?? 0).toDouble() / 100.0;
    final String status = goal['status'] ?? 'Unknown';
    final bool isAtRisk = status == 'At Risk';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name + Status Chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  goal['goal_name'] ?? 'Goal',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAtRisk ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isAtRisk ? Colors.red.shade200 : Colors.green.shade200),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isAtRisk ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Amounts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('₹${goal['saved_amount']} saved', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                Text('of ₹${goal['target_amount']}', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 8),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isAtRisk ? Colors.orange : const Color(0xFF1D9E75),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // AI Insights Footer + Add Money Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Deadline: ${goal['deadline']}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text('Needs ₹${goal['monthly_required']}/mo', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () => _showAddMoneyDialog(context, userId, goal['goal_name']),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Add Money'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1D9E75),
                    side: const BorderSide(color: Color(0xFF1D9E75)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialog to Add Money to this specific Goal ──
  void _showAddMoneyDialog(BuildContext context, String userId, String goalName) {
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Money to $goalName'),
        content: TextField(
          controller: amountCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount (₹)',
            prefixIcon: Icon(Icons.currency_rupee),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1D9E75)),
            onPressed: () {
              if (amountCtrl.text.isNotEmpty) {
                context.read<GoalProvider>().addMoney(
                  userId, 
                  goalName, 
                  double.parse(amountCtrl.text)
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}