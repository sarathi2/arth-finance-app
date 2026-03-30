import 'package:flutter/material.dart';
import 'package:arth/rich_ai_models.dart';
import 'package:arth/ai_service.dart';
import 'package:arth/local_storage.dart';

class FinancialHealthScreen extends StatefulWidget {
  const FinancialHealthScreen({super.key});

  @override
  State<FinancialHealthScreen> createState() => _FinancialHealthScreenState();
}

class _FinancialHealthScreenState extends State<FinancialHealthScreen> {
  FinancialHealthModel? _health;
  UserProfileSummary? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = await LocalStorage.getUserId();
      if (userId == null) {
        setState(() {
          _error = 'Not logged in. Please log in and try again.';
          _isLoading = false;
        });
        return;
      }

      final prompts = [
        'Show my financial health score and breakdown',
        'What is my financial health score',
        'Give me my financial summary and health score',
      ];

      RichAiResponse? response;
      for (final prompt in prompts) {
        final r = await AiService().processMessage(userId: userId, text: prompt);
        if (r.hasFinancialHealth) {
          response = r;
          break;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (!mounted) return;

      if (response == null || !response.hasFinancialHealth) {
        setState(() {
          _health = null;
          _profile = response?.userProfile;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _health = response!.financialHealth;
        _profile = response.userProfile;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load health data. Pull down to retry.\n(${e.toString()})';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Financial Health', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const _LoadingState()
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : _health == null
                  ? _EmptyState(onRetry: _load)
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: const Color(0xFF1D9E75),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AnimatedScoreHero(health: _health!),
                            const SizedBox(height: 32),
                            if (_profile != null) _PremiumProfileGrid(profile: _profile!),
                            const SizedBox(height: 32),
                            _DetailedBreakdownList(health: _health!),
                          ],
                        ),
                      ),
                    ),
    );
  }
}

// ── Hero Section (Animated Gauge) ───────────────────────────────────────────
class _AnimatedScoreHero extends StatelessWidget {
  final FinancialHealthModel health;
  const _AnimatedScoreHero({required this.health});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: health.statusColor.withValues(alpha: 0.15), blurRadius: 40, offset: const Offset(0, 10))
        ],
        border: Border.all(color: health.statusColor.withValues(alpha: 0.2), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: health.statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(health.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(health.status.toUpperCase(), style: TextStyle(color: health.statusColor, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200, height: 200,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: health.score / 100),
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => CircularProgressIndicator(
                    value: value, strokeWidth: 16, strokeCap: StrokeCap.round,
                    backgroundColor: Colors.grey.shade100, color: health.statusColor,
                  ),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: health.score.toDouble()),
                duration: const Duration(seconds: 2),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Column(
                  children: [
                    Text(value.toInt().toString(), style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, height: 1)),
                    Text('out of 100', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Premium Stat Grid ───────────────────────────────────────────────────────
class _PremiumProfileGrid extends StatelessWidget {
  final UserProfileSummary profile;
  const _PremiumProfileGrid({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Financial Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            _StatCard(title: 'Income', amount: profile.income, icon: Icons.arrow_downward, color: const Color(0xFF1D9E75)),
            const SizedBox(width: 16),
            _StatCard(title: 'Savings', amount: profile.savings, icon: Icons.savings_outlined, color: Colors.blue),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _StatCard(title: 'EMI / Debt', amount: profile.emi, icon: Icons.credit_card, color: Colors.orange),
            const SizedBox(width: 16),
            _StatCard(title: 'Net Worth', amount: profile.netWorth, icon: Icons.account_balance_wallet, color: Colors.purple),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.amount, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ── Detailed Breakdown List ──────────────────────────────────────────────────
class _DetailedBreakdownList extends StatelessWidget {
  final FinancialHealthModel health;
  const _DetailedBreakdownList({required this.health});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Health Diagnostics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _DiagnosticTile(
          title: 'Savings Rate', value: '${health.savingsRate.toStringAsFixed(1)}%',
          isGood: health.savingsRate >= 20,
          description: health.savingsRate >= 20 ? 'Great job saving!' : 'Try to save 20% of income.',
        ),
        _DiagnosticTile(
          title: 'Debt-to-Income', value: '${health.debtRatio.toStringAsFixed(1)}%',
          isGood: health.debtRatio < 30,
          description: health.debtRatio < 30 ? 'Your debt is well managed.' : 'Your debt load is high.',
        ),
        _DiagnosticTile(
          title: 'Asset Health', value: '₹${health.netWorth.toStringAsFixed(0)}',
          isGood: health.netWorth > 0,
          description: health.netWorth > 0 ? 'Positive net worth.' : 'Focus on building assets.',
        ),
      ],
    );
  }
}

class _DiagnosticTile extends StatelessWidget {
  final String title;
  final String value;
  final bool isGood;
  final String description;

  const _DiagnosticTile({required this.title, required this.value, required this.isGood, required this.description});

  @override
  Widget build(BuildContext context) {
    final color = isGood ? const Color(0xFF1D9E75) : Colors.orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(isGood ? Icons.check : Icons.warning_amber, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(description, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ],
            ),
          ),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        ],
      ),
    );
  }
}

// ── Utility States (Loading & Empty) ─────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60, height: 60,
            child: CircularProgressIndicator(color: Color(0xFF1D9E75), strokeWidth: 6),
          ),
          const SizedBox(height: 24),
          Text('Analyzing your finances...', style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1D9E75), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            )
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRetry;
  const _EmptyState({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📊', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('Profile Incomplete', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Please update your income and savings in Profile Setup to generate your score.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, height: 1.5)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Try Again'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1D9E75), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            )
          ],
        ),
      ),
    );
  }
}