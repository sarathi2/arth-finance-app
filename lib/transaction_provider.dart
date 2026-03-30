import 'package:flutter/material.dart';
import 'package:arth/expense_service.dart';
import 'package:arth/expense_model.dart';
import 'package:arth/local_storage.dart';

class TransactionProvider extends ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();

  final List<ExpenseModel> _transactions = [];
  bool _isLoading = false;
  String? _error;

  List<ExpenseModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Group transactions by formatted date string
  Map<String, List<ExpenseModel>> get groupedByDate {
    final Map<String, List<ExpenseModel>> grouped = {};
    for (final tx in _transactions) {
      final key = _formatDate(tx.date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    return grouped;
  }

  // Set of date keys that have transactions — used by calendar dots
  Set<String> get daysWithTransactions {
    return _transactions.map((tx) {
      return '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}';
    }).toSet();
  }

  List<ExpenseModel> transactionsForDay(DateTime day) {
    return _transactions.where((tx) {
      return tx.date.year == day.year &&
          tx.date.month == day.month &&
          tx.date.day == day.day;
    }).toList();
  }

  // Monthly summary helpers
  double get totalExpenses {
    final now = DateTime.now();
    return _transactions
        .where((tx) =>
    tx.category.toLowerCase() != 'income' &&
        tx.date.month == now.month &&
        tx.date.year == now.year)
        .fold(0, (sum, tx) => sum + tx.amount);
  }

  double get totalIncome {
    final now = DateTime.now();
    return _transactions
        .where((tx) =>
    tx.category.toLowerCase() == 'income' &&
        tx.date.month == now.month &&
        tx.date.year == now.year)
        .fold(0, (sum, tx) => sum + tx.amount);
  }

  Future<void> loadTransactions() async {
    // Transactions come from AI processing — stored in MongoDB.
    // For now we keep a local in-memory list that gets populated
    // when the user adds transactions manually or via AI chat.
    // A future GET /expense/list endpoint can refresh this.
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTransaction({
    required double amount,
    required String category,
    required String description,
  }) async {
    final userId = await LocalStorage.getUserId();
    if (userId == null) return;

    final expense = ExpenseModel(
      userId: userId,
      amount: amount,
      category: category,
      description: description,
    );

    // Optimistic update — add to local list immediately
    _transactions.insert(0, expense);
    notifyListeners();

    try {
      await _expenseService.addExpense(expense);
    } catch (e) {
      // Roll back on failure
      _transactions.removeAt(0);
      _error = e.toString();
      notifyListeners();
    }
  }

  // Called by AI chat when it successfully saves data —
  // adds the transaction to local list so it shows up immediately
  void onAiTransactionSaved(Map<String, dynamic> details) {
    try {
      final userId = details['user_id'] ?? '';
      final amount = (details['amount'] ?? 0).toDouble();
      final category = details['intent'] ?? 'other';
      final desc = details['description'] ?? '';

      _transactions.insert(
        0,
        ExpenseModel(
          userId: userId,
          amount: amount,
          category: category,
          description: desc,
        ),
      );
      notifyListeners();
    } catch (_) {}
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.day == yesterday.day &&
        dt.month == yesterday.month &&
        dt.year == yesterday.year) {
      return 'Yesterday';
    }
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
}