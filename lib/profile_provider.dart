import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arth/user_model.dart';
import 'package:arth/local_storage.dart';

class ProfileProvider extends ChangeNotifier {
  UserModel? _user;
  String _language = 'english';
  List<Map<String, String>> _incomeSources = [];
  bool _isLoading = true;

  UserModel? get user => _user;
  String get language => _language;
  List<Map<String, String>> get incomeSources => _incomeSources;
  bool get isLoading => _isLoading;

  static const _keyIncomeSources = 'arth_income_sources';

  Future<void> load() async {
    _user = await LocalStorage.loadUser();
    _language = await LocalStorage.getLanguage();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyIncomeSources);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _incomeSources = list.map((e) => Map<String, String>.from(e)).toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateName(String name) async {
    if (_user == null) return;
    _user = UserModel(
      userId: _user!.userId,
      name: name,
      email: _user!.email,
      language: _user!.language,
      currency: _user!.currency,
      monthlyIncome: _user!.monthlyIncome,
      familyType: _user!.familyType,
    );
    await LocalStorage.saveUser(_user!);
    notifyListeners();
  }

  Future<void> updateIncome(double income) async {
    if (_user == null) return;
    _user = UserModel(
      userId: _user!.userId,
      name: _user!.name,
      email: _user!.email,
      language: _user!.language,
      currency: _user!.currency,
      monthlyIncome: income,
      familyType: _user!.familyType,
    );
    await LocalStorage.saveUser(_user!);
    notifyListeners();
  }

  Future<void> toggleFamilyType() async {
    if (_user == null) return;
    final newType =
    _user!.familyType == 'individual' ? 'family' : 'individual';
    _user = UserModel(
      userId: _user!.userId,
      name: _user!.name,
      email: _user!.email,
      language: _user!.language,
      currency: _user!.currency,
      monthlyIncome: _user!.monthlyIncome,
      familyType: newType,
    );
    await LocalStorage.saveUser(_user!);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    await LocalStorage.setLanguage(lang);
    notifyListeners();
  }

  Future<void> addIncomeSource(
      {required String name, required String amount}) async {
    _incomeSources.add({'name': name, 'amount': amount});
    await _saveIncomeSources();
    notifyListeners();
  }

  Future<void> removeIncomeSource(Map<String, String> source) async {
    _incomeSources.remove(source);
    await _saveIncomeSources();
    notifyListeners();
  }

  Future<void> _saveIncomeSources() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyIncomeSources, jsonEncode(_incomeSources));
  }
}