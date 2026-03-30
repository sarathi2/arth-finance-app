import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arth/local_storage.dart';
import 'package:arth/user_model.dart';
import 'package:arth/api_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;

  // ── Form data ─────────────────────────────────────────────────────────────
  final _nameController = TextEditingController();
  String _familyType = 'individual';
  int _familySize = 1;
  
  final _professionController = TextEditingController();
  final _incomeController = TextEditingController();
  
  double _monthlySavings = 0;
  double _totalAssets = 0;
  double _totalLiabilities = 0;
  String _language = 'english';

  // ── Localization Dictionaries ──────────────────────────────────────────────
  final Map<String, String> _en = {
    'step_1': 'Personal Info', 'step_2': 'Family', 'step_3': 'Work & Income', 'step_4': 'Savings & Assets', 'step_5': 'Almost Done!',
    'call_you': 'What should we call you?', 'name_desc': 'Your name helps Arth personalize your experience', 'full_name': 'Full Name',
    'pref_lang': 'Preferred Language', 'tell_family': 'Tell us about your family', 'family_desc': 'This helps Arth give better budgeting advice',
    'manage_for': 'I am managing finances for:', 'just_me': 'Just Me', 'my_family': 'My Family', 'family_size': 'Number of family members:',
    'work': 'Work & Income', 'work_desc': 'Your primary source of income', 'profession_lbl': 'Profession', 'income': 'Total Monthly Income',
    'savings_net': 'Savings & Net Worth', 'savings_desc': 'Optional — helps AI give better financial advice', 'monthly_target': 'Monthly Savings Target',
    'total_assets': 'Total Assets (property, gold...)', 'total_liabilities': 'Total Liabilities (loans, debts...)', 'net_worth': 'Your Net Worth',
    'looking_good': 'Looking good!', 'reduce_debt': 'Focus on reducing debt',
    'welcome': 'Welcome,', 'summary_desc': 'Here\'s your financial profile summary', 'name': 'Name', 'family': 'Family', 'members': 'members',
    'individual': 'Individual', 'language': 'Language', 'ai_desc': 'Arth AI will use this data to give you personalized financial insights!',
    'continue': 'Continue', 'start_using': 'Start Using Arth!', 'enter_name': 'Please enter your name', 'step_of': 'Step'
  };

  final Map<String, String> _ta = {
    'step_1': 'சுயவிவரம்', 'step_2': 'குடும்பம்', 'step_3': 'வருமானம்', 'step_4': 'சேமிப்பு & சொத்து', 'step_5': 'முடிந்தது!',
    'call_you': 'உங்களை எப்படி அழைக்கலாம்?', 'name_desc': 'உங்கள் பெயர் Arth-ஐ தனிப்பயனாக்க உதவும்', 'full_name': 'முழு பெயர்',
    'pref_lang': 'விருப்பமான மொழி', 'tell_family': 'உங்கள் குடும்பத்தை பற்றி சொல்லுங்கள்', 'family_desc': 'சிறந்த பட்ஜெட் ஆலோசனைகளை வழங்க இது உதவும்',
    'manage_for': 'நான் யாருக்காக நிர்வகிக்கிறேன்:', 'just_me': 'எனக்கு மட்டும்', 'my_family': 'என் குடும்பத்திற்கு', 'family_size': 'குடும்ப உறுப்பினர்களின் எண்ணிக்கை:',
    'work': 'வேலை & வருமானம்', 'work_desc': 'உங்கள் முக்கிய வருமான ஆதாரம்', 'profession_lbl': 'தொழில்', 'income': 'மொத்த மாத வருமானம்',
    'savings_net': 'சேமிப்பு & நிகர மதிப்பு', 'savings_desc': 'விருப்பத்திற்குரியது — AI சிறந்த ஆலோசனை வழங்க உதவும்', 'monthly_target': 'மாதாந்திர சேமிப்பு இலக்கு',
    'total_assets': 'மொத்த சொத்துக்கள் (நிலம், தங்கம்...)', 'total_liabilities': 'மொத்த கடன்கள் (கடன், EMI...)', 'net_worth': 'உங்கள் நிகர மதிப்பு',
    'looking_good': 'நன்றாக உள்ளது!', 'reduce_debt': 'கடனை குறைப்பதில் கவனம் செலுத்துங்கள்',
    'welcome': 'வரவேற்கிறோம்,', 'summary_desc': 'உங்கள் நிதி விவரங்களின் சுருக்கம்', 'name': 'பெயர்', 'family': 'குடும்பம்', 'members': 'உறுப்பினர்கள்',
    'individual': 'தனிநபர்', 'language': 'மொழி', 'ai_desc': 'Arth AI இந்த தரவை கொண்டு தனிப்பயனாக்கப்பட்ட நிதி ஆலோசனைகளை வழங்கும்!',
    'continue': 'தொடரவும்', 'start_using': 'Arth-ஐ தொடங்குங்கள்!', 'enter_name': 'தயவுசெய்து உங்கள் பெயரை உள்ளிடவும்', 'step_of': 'படி'
  };

  String _t(String key) => _language == 'tamil' ? _ta[key] ?? key : _en[key] ?? key;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _professionController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      setState(() => _currentPage++);
    } else {
      _saveProfile();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      setState(() => _currentPage--);
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('enter_name'))));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final totalIncome = double.tryParse(_incomeController.text.trim()) ?? 0.0;
      final profession = _professionController.text.trim().isEmpty ? "Primary Income" : _professionController.text.trim();

      // 1. Local Storage (Keeps app fast without loading from network constantly)
      await LocalStorage.saveUser(UserModel(
        userId: user.uid, name: _nameController.text.trim(), email: user.email ?? '', phone: user.phoneNumber ?? '',
        language: _language, currency: 'INR', monthlyIncome: totalIncome, familyType: _familyType,
        familySize: _familySize, monthlySavings: _monthlySavings, totalAssets: _totalAssets, totalLiabilities: _totalLiabilities,
      ));
      await LocalStorage.setLanguage(_language);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('arth_income_sources', jsonEncode([{'title': profession, 'amount': totalIncome.toString()}]));

      // 2. Python Backend Sync (Mapped EXACTLY to your MongoDB Pydantic Schema)
      try {
        final pythonProfilePayload = {
          "user_id": user.uid, 
          "name": _nameController.text.trim(), 
          "email": user.email ?? "", 
          "phone": user.phoneNumber ?? "",
          "language": _language, 
          "currency": "INR", 
          "family_type": _familyType, 
          "members": [], 
          "monthly_income": totalIncome, 
          "monthly_savings": _monthlySavings,
          "income_sources": [{
            "source": profession, 
            "amount": totalIncome, 
            "frequency": "monthly", 
            "owner": "self"
          }],
          "assets": [{
            "name": "Total Assets", 
            "type": "cash", 
            "value": _totalAssets, 
            "owner": "family", 
            "liquidity": "medium"
          }],
          "liabilities": [{
            "name": "Total Liabilities", 
            "type": "loan", 
            "total_amount": _totalLiabilities, 
            "outstanding_amount": _totalLiabilities, 
            "interest_rate": 0, 
            "monthly_payment": 0, 
            "owner": "family"
          }],
          "financial_behavior": {
            "risk_appetite": "medium",
            "saving_preference": "balanced",
            "spending_pattern": "moderate"
          }
        };
        
        await ApiService.saveUserProfile(pythonProfilePayload);
      } catch (e) {
        debugPrint("Failed to sync profile with Python backend: $e");
      }

      // 3. Navigate home!
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> currentStepTitles = [_t('step_1'), _t('step_2'), _t('step_3'), _t('step_4'), _t('step_5')];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _ProgressHeader(
              currentPage: _currentPage, totalPages: 5, titles: currentStepTitles,
              stepLabel: _t('step_of'), onBack: _currentPage > 0 ? _prevPage : null,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step1PersonalInfo(t: _t, nameController: _nameController, language: _language, onLanguageChanged: (v) => setState(() => _language = v)),
                  _Step2Family(t: _t, familyType: _familyType, familySize: _familySize, onTypeChanged: (v) => setState(() => _familyType = v), onSizeChanged: (v) => setState(() => _familySize = v)),
                  _Step3Income(t: _t, professionController: _professionController, incomeController: _incomeController),
                  _Step4Savings(t: _t, monthlySavings: _monthlySavings, totalAssets: _totalAssets, totalLiabilities: _totalLiabilities, onSavingsChanged: (v) => setState(() => _monthlySavings = v), onAssetsChanged: (v) => setState(() => _totalAssets = v), onLiabilitiesChanged: (v) => setState(() => _totalLiabilities = v)),
                  _Step5Summary(
                    t: _t, name: _nameController.text, familyType: _familyType, familySize: _familySize,
                    profession: _professionController.text.isNotEmpty ? _professionController.text : 'Primary Income',
                    totalIncome: double.tryParse(_incomeController.text.trim()) ?? 0.0,
                    monthlySavings: _monthlySavings, totalAssets: _totalAssets, totalLiabilities: _totalLiabilities, language: _language,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: GestureDetector(
                onTap: _isSaving ? null : _nextPage,
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(color: const Color(0xFF1D9E75), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: const Color(0xFF1D9E75).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))]),
                  child: Center(
                    child: _isSaving
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_currentPage == 4 ? _t('start_using') : _t('continue'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared UI Components ──────────────────────────────────────────────────────
class _ProgressHeader extends StatelessWidget {
  final int currentPage; final int totalPages; final List<String> titles; final String stepLabel; final VoidCallback? onBack;
  const _ProgressHeader({required this.currentPage, required this.totalPages, required this.titles, required this.stepLabel, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onBack != null) IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack) else const SizedBox(width: 48),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$stepLabel ${currentPage + 1} / $totalPages', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                    Text(titles[currentPage], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ),
              Text('${((currentPage + 1) / totalPages * 100).toInt()}%', style: const TextStyle(color: Color(0xFF1D9E75), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: (currentPage + 1) / totalPages, minHeight: 6, backgroundColor: Colors.grey.shade100, valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1D9E75))),
          ),
        ],
      ),
    );
  }
}

class _StepIcon extends StatelessWidget {
  final IconData icon; final String emoji;
  const _StepIcon({required this.icon, required this.emoji});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64, height: 64, decoration: BoxDecoration(color: const Color(0xFF1D9E75).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 32))),
    );
  }
}

// ── Step 1 ──────────────────────────────────────────────────────────────────
class _Step1PersonalInfo extends StatelessWidget {
  final String Function(String) t; final TextEditingController nameController; final String language; final ValueChanged<String> onLanguageChanged;
  const _Step1PersonalInfo({required this.t, required this.nameController, required this.language, required this.onLanguageChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepIcon(icon: Icons.person, emoji: '👋'), const SizedBox(height: 16),
          Text(t('call_you'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
          Text(t('name_desc'), style: TextStyle(color: Colors.grey.shade500)), const SizedBox(height: 32),
          TextField(
            controller: nameController, textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: t('full_name'), prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF1D9E75)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 2))),
          ),
          const SizedBox(height: 32),
          Text(t('pref_lang'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)), const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildLangCard('English', language == 'english', () => onLanguageChanged('english'))),
              const SizedBox(width: 12),
              Expanded(child: _buildLangCard('தமிழ்', language == 'tamil', () => onLanguageChanged('tamil'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLangCard(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFF1D9E75).withValues(alpha: 0.1) : Colors.grey.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: isSelected ? const Color(0xFF1D9E75) : Colors.grey.shade200, width: isSelected ? 2 : 1)),
        child: Center(child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSelected ? const Color(0xFF1D9E75) : Colors.black87))),
      ),
    );
  }
}

// ── Step 2 ──────────────────────────────────────────────────────────────────
class _Step2Family extends StatelessWidget {
  final String Function(String) t; final String familyType; final int familySize; final ValueChanged<String> onTypeChanged; final ValueChanged<int> onSizeChanged;
  const _Step2Family({required this.t, required this.familyType, required this.familySize, required this.onTypeChanged, required this.onSizeChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepIcon(icon: Icons.people, emoji: '👨‍👩‍👧‍👦'), const SizedBox(height: 16),
          Text(t('tell_family'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
          Text(t('family_desc'), style: TextStyle(color: Colors.grey.shade500)), const SizedBox(height: 32),
          Text(t('manage_for'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)), const SizedBox(height: 12),
          Row(
            children: [
              _buildTypeCard(Icons.person, t('just_me'), t('individual'), familyType == 'individual', () => onTypeChanged('individual')), const SizedBox(width: 12),
              _buildTypeCard(Icons.people, t('my_family'), t('family'), familyType == 'family', () => onTypeChanged('family')),
            ],
          ),
          if (familyType == 'family') ...[
            const SizedBox(height: 32), Text(t('family_size'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)), const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBtn(Icons.remove, () { if (familySize > 2) onSizeChanged(familySize - 1); }), const SizedBox(width: 24),
                Text('$familySize', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)), const SizedBox(width: 24),
                _buildBtn(Icons.add, () => onSizeChanged(familySize + 1)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeCard(IconData icon, String label, String sub, bool sel, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: sel ? const Color(0xFF1D9E75).withValues(alpha: 0.1) : Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: sel ? const Color(0xFF1D9E75) : Colors.grey.shade200, width: sel ? 2 : 1)),
          child: Column(children: [Icon(icon, size: 36, color: sel ? const Color(0xFF1D9E75) : Colors.grey.shade400), const SizedBox(height: 12), Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: sel ? const Color(0xFF1D9E75) : Colors.black87)), Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey.shade500))]),
        ),
      ),
    );
  }

  Widget _buildBtn(IconData i, VoidCallback onTap) => GestureDetector(onTap: onTap, child: Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF1D9E75).withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF1D9E75))), child: Icon(i, color: const Color(0xFF1D9E75))));
}

// ── Step 3 (Simplified!) ───────────────────────────────────────────────────────
class _Step3Income extends StatelessWidget {
  final String Function(String) t; final TextEditingController professionController; final TextEditingController incomeController;

  const _Step3Income({required this.t, required this.professionController, required this.incomeController});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepIcon(icon: Icons.work, emoji: '💼'), const SizedBox(height: 16),
          Text(t('work'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
          Text(t('work_desc'), style: TextStyle(color: Colors.grey.shade500)), const SizedBox(height: 32),
          
          TextField(
            controller: professionController, textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: t('profession'), prefixIcon: const Icon(Icons.business_center_outlined, color: Color(0xFF1D9E75)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 2))),
          ),
          const SizedBox(height: 20),
          
          TextField(
            controller: incomeController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: t('income'), prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF1D9E75)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 2))),
          ),
        ],
      ),
    );
  }
}

// ── Step 4 ──────────────────────────────────────────────────────────────────
class _Step4Savings extends StatelessWidget {
  final String Function(String) t; final double monthlySavings; final double totalAssets; final double totalLiabilities; final ValueChanged<double> onSavingsChanged; final ValueChanged<double> onAssetsChanged; final ValueChanged<double> onLiabilitiesChanged;
  const _Step4Savings({required this.t, required this.monthlySavings, required this.totalAssets, required this.totalLiabilities, required this.onSavingsChanged, required this.onAssetsChanged, required this.onLiabilitiesChanged});

  @override
  Widget build(BuildContext context) {
    final netWorth = totalAssets - totalLiabilities;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepIcon(icon: Icons.savings, emoji: '💰'), const SizedBox(height: 16),
          Text(t('savings_net'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(t('savings_desc'), style: TextStyle(color: Colors.grey.shade500)), const SizedBox(height: 24),
          _AmountField(label: t('monthly_target'), icon: Icons.savings_outlined, val: monthlySavings, onChanged: onSavingsChanged), const SizedBox(height: 16),
          _AmountField(label: t('total_assets'), icon: Icons.account_balance_outlined, val: totalAssets, onChanged: onAssetsChanged), const SizedBox(height: 16),
          _AmountField(label: t('total_liabilities'), icon: Icons.money_off_outlined, val: totalLiabilities, onChanged: onLiabilitiesChanged), const SizedBox(height: 24),
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: netWorth >= 0 ? const Color(0xFF1D9E75).withValues(alpha: 0.1) : Colors.red.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: netWorth >= 0 ? const Color(0xFF1D9E75) : Colors.red.shade200)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t('net_worth'), style: const TextStyle(fontWeight: FontWeight.w500)), Text(netWorth >= 0 ? t('looking_good') : t('reduce_debt'), style: TextStyle(fontSize: 12, color: netWorth >= 0 ? const Color(0xFF1D9E75) : Colors.red))]), Text('₹${netWorth.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: netWorth >= 0 ? const Color(0xFF1D9E75) : Colors.red))])),
        ],
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final String label; final IconData icon; final double val; final ValueChanged<double> onChanged;
  const _AmountField({required this.label, required this.icon, required this.val, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return TextField(keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: const Color(0xFF1D9E75)), prefixText: '₹ ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 2))), onChanged: (v) => onChanged(double.tryParse(v) ?? 0));
  }
}

// ── Step 5 ──────────────────────────────────────────────────────────────────
class _Step5Summary extends StatelessWidget {
  final String Function(String) t; final String name; final String familyType; final int familySize; final String profession; final double totalIncome; final double monthlySavings; final double totalAssets; final double totalLiabilities; final String language;
  const _Step5Summary({required this.t, required this.name, required this.familyType, required this.familySize, required this.profession, required this.totalIncome, required this.monthlySavings, required this.totalAssets, required this.totalLiabilities, required this.language});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepIcon(icon: Icons.check_circle, emoji: '🎉'), const SizedBox(height: 16),
          Text('${t('welcome')} ${name.isNotEmpty ? name.split(' ').first : ''}!', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(t('summary_desc'), style: TextStyle(color: Colors.grey.shade500)), const SizedBox(height: 24),
          _SumTile(Icons.person, t('name'), name.isNotEmpty ? name : '—'), _SumTile(Icons.people, t('family'), familyType == 'family' ? '$familySize ${t('members')}' : t('individual')), _SumTile(Icons.work, t('profession_lbl'), profession), _SumTile(Icons.currency_rupee, t('income'), '₹${totalIncome.toStringAsFixed(0)}'), _SumTile(Icons.savings, t('monthly_target'), '₹${monthlySavings.toStringAsFixed(0)}'), _SumTile(Icons.account_balance, t('net_worth'), '₹${(totalAssets - totalLiabilities).toStringAsFixed(0)}'), _SumTile(Icons.translate, t('language'), language == 'tamil' ? 'தமிழ்' : 'English'), const SizedBox(height: 24),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1D9E75).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)), child: Row(children: [const Icon(Icons.auto_awesome, color: Color(0xFF1D9E75), size: 20), const SizedBox(width: 12), Expanded(child: Text(t('ai_desc'), style: const TextStyle(fontSize: 13, height: 1.5)))]))
        ],
      ),
    );
  }
}

class _SumTile extends StatelessWidget {
  final IconData i; final String l; final String v; const _SumTile(this.i, this.l, this.v);
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF1D9E75).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(i, color: const Color(0xFF1D9E75), size: 18)), const SizedBox(width: 12), Expanded(child: Text(l, style: TextStyle(color: Colors.grey.shade500))), Text(v, style: const TextStyle(fontWeight: FontWeight.w600))]));
  }
}