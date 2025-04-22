class CardModel {
  final String id;
  final String userId;
  final String cardNumber;
  final String cardHolderName;
  final String cardType;
  final String lastFourDigits;
  final String expiryMonth;
  final String expiryYear;
  final String cvv;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int v;

  CardModel({
    required this.id,
    required this.userId,
    required this.cardNumber,
    required this.cardHolderName,
    required this.cardType,
    required this.lastFourDigits,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
    this.v = 0,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['_id'] ?? '',
      userId: json['user_id'] ?? '',
      cardNumber: json['card_number'] ?? '',
      cardHolderName: json['card_name'] ?? '',
      cardType: json['card_type'] ?? 'VISA',
      lastFourDigits: json['card_number']?.substring(json['card_number'].length - 4) ?? '',
      expiryMonth: json['card_exp_month']?.toString() ?? '',
      expiryYear: json['card_exp_year']?.toString() ?? '',
      cvv: json['card_cvc'] ?? '',
      isDefault: json['is_default'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      v: json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'card_number': cardNumber,
      'card_name': cardHolderName,
      'card_type': cardType,
      'card_exp_month': expiryMonth,
      'card_exp_year': expiryYear,
      'card_cvc': cvv,
      'is_default': isDefault,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      '__v': v,
    };
  }
} 