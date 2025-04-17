class LoginResponseModel {
  final String accesstoken;
  final String email;
  final String userId;

  LoginResponseModel({
    required this.accesstoken,
    required this.email,
    required this.userId,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      accesstoken: json['token'] ?? '',
      email: json['email'] ?? '',
      userId: json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': accesstoken,
      'email': email,
      'userId': userId,
    };
  }
} 