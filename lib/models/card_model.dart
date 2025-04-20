class CardModel {
  final String id;
  final String userId;
  final String cardNumber;
  final String cardHolderName;
  final String? cardType;
  final String? lastFourDigits;
  final String? expiryMonth;
  final String? expiryYear;
  final String cvv;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;

  CardModel({
    required this.id,
    required this.userId,
    required this.cardNumber,
    required this.cardHolderName,
    this.cardType,
    this.lastFourDigits,
    this.expiryMonth,
    this.expiryYear,
    required this.cvv,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    // Xử lý ngày hết hạn
    String expiryDate = json['expiryDate'] ?? '';
    String? month;
    String? year;
    if (expiryDate.contains('/')) {
      final parts = expiryDate.split('/');
      month = parts[0];
      year = parts[1];
    }

    // Xử lý số thẻ
    String cardNum = json['cardNumber'] ?? '';
    String? lastFour = cardNum.length >= 4 ? cardNum.substring(cardNum.length - 4) : null;

    return CardModel(
      id: json['_id'] ?? '',
      userId: json['user_id'] ?? '',
      cardNumber: cardNum,
      cardHolderName: json['cardHolderName'] ?? '',
      cardType: json['cardType'],
      lastFourDigits: lastFour,
      expiryMonth: month,
      expiryYear: year,
      cvv: json['cvv'] ?? '',
      isDefault: json['isDefault'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      v: json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user_id': userId,
      'cardNumber': cardNumber,
      'cardHolderName': cardHolderName,
      'cardType': cardType,
      'expiryDate': expiryMonth != null && expiryYear != null 
          ? '$expiryMonth/$expiryYear' 
          : null,
      'cvv': cvv,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': v,
    };
  }
} 