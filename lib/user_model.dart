class UserModel {
  final String userId;
  final String name;
  final String email;
  final String phone; 
  final String language; 
  final String currency;
  final double monthlyIncome;
  final String familyType; 
  final int familySize;
  final double monthlySavings;
  final double totalAssets;
  final double totalLiabilities;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    this.phone = '',
    this.language = 'english',
    this.currency = 'INR',
    this.monthlyIncome = 0.0,
    this.familyType = 'individual',
    this.familySize = 1,
    this.monthlySavings = 0.0,
    this.totalAssets = 0.0,
    this.totalLiabilities = 0.0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      language: json['language'] ?? 'english',
      currency: json['currency'] ?? 'INR',
      monthlyIncome: (json['monthly_income'] ?? 0).toDouble(),
      familyType: json['family_type'] ?? 'individual',
      familySize: json['family_size'] ?? 1,
      monthlySavings: (json['monthly_savings'] ?? 0).toDouble(),
      totalAssets: (json['total_assets'] ?? 0).toDouble(),
      totalLiabilities: (json['total_liabilities'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'name': name,
        'email': email,
        'phone': phone,
        'language': language,
        'currency': currency,
        'monthly_income': monthlyIncome,
        'family_type': familyType,
        'family_size': familySize,
        'monthly_savings': monthlySavings,
        'total_assets': totalAssets,
        'total_liabilities': totalLiabilities,
      };
}