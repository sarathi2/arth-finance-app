import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arth/profile_provider.dart';
import 'package:arth/local_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = provider.user;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar + name ──────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          user != null && user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'A',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.name ?? 'Arth User',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Personal info ──────────────────────────────────────
                const _SectionHeader(title: 'Personal info'),
                _InfoTile(
                  icon: Icons.person_outline,
                  label: 'Name',
                  value: user?.name ?? '—',
                  onEdit: () => _editField(context, provider, 'name', user?.name ?? ''),
                ),
                _InfoTile(
                  icon: Icons.people_outline,
                  label: 'Family type',
                  value: user?.familyType == 'family' ? 'Family' : 'Individual',
                  onEdit: () => _toggleFamilyType(context, provider),
                ),
                _InfoTile(
                  icon: Icons.currency_rupee,
                  label: 'Monthly income',
                  value: '₹${user?.monthlyIncome.toStringAsFixed(0) ?? '0'}',
                  onEdit: () => _editField(
                      context, provider, 'income', user?.monthlyIncome.toString() ?? ''),
                ),

                const SizedBox(height: 20),

                // ── Preferences ────────────────────────────────────────
                const _SectionHeader(title: 'Preferences'),
                _PrefTile(
                  icon: Icons.language,
                  label: 'Language',
                  trailing: _LanguageToggle(
                    value: provider.language,
                    onChanged: provider.setLanguage,
                  ),
                ),
                _PrefTile(
                  icon: Icons.dark_mode_outlined,
                  label: 'Currency',
                  trailing: Text('₹ INR',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500)),
                ),

                const SizedBox(height: 20),

                // ── Income sources ─────────────────────────────────────
                const _SectionHeader(title: 'Income sources'),
                ...provider.incomeSources.map(
                      (src) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.attach_money),
                      title: Text(src['name'] ?? ''),
                      subtitle: Text('₹${src['amount']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => provider.removeIncomeSource(src),
                      ),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _addIncomeSource(context, provider),
                  icon: const Icon(Icons.add),
                  label: const Text('Add income source'),
                ),

                const SizedBox(height: 32),

                // ── Logout ─────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(
                          color: Theme.of(context).colorScheme.error),
                    ),
                    onPressed: () => _confirmLogout(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  void _editField(BuildContext ctx, ProfileProvider provider, String field, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text('Edit ${field == 'income' ? 'monthly income' : field}'),
        content: TextField(
          controller: ctrl,
          keyboardType: field == 'income' ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            labelText: field == 'income' ? 'Amount (₹)' : 'Name',
            border: const OutlineInputBorder(),
            prefixIcon: field == 'income'
                ? const Icon(Icons.currency_rupee)
                : const Icon(Icons.person),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (field == 'income') {
                final val = double.tryParse(ctrl.text);
                if (val != null) provider.updateIncome(val);
              } else {
                provider.updateName(ctrl.text);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _toggleFamilyType(BuildContext ctx, ProfileProvider provider) {
    provider.toggleFamilyType();
  }

  void _addIncomeSource(BuildContext ctx, ProfileProvider provider) {
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Add income source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Source (e.g. Salary, Freelance)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amtCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly amount (₹)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && amtCtrl.text.isNotEmpty) {
                provider.addIncomeSource(
                    name: nameCtrl.text, amount: amtCtrl.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () async {
              await LocalStorage.clearUser();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5)),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onEdit;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        subtitle: Text(value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          onPressed: onEdit,
        ),
      ),
    );
  }
}

class _PrefTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;

  const _PrefTile({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label),
        trailing: trailing,
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _LanguageToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'english', label: Text('EN')),
        ButtonSegment(value: 'tamil', label: Text('தமிழ்')),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}