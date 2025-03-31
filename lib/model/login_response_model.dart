import 'dart:convert';

LoginResponseModel loginResponseJson(String str) => LoginResponseModel.fromJson(json.decode(str));

class LoginResponseModel {
  String? message; // Nullable fields
  String? accesstoken;
  String? id;
  String? user_name;
  String? email;
  String? phone_number;
  int? role;

  LoginResponseModel({
    this.message,
    this.accesstoken,
    this.id,
    this.user_name,
    this.email,
    this.phone_number,
    this.role,
  });

  LoginResponseModel.fromJson(Map<String, dynamic> json) {
    message = json['message'] as String?;
    accesstoken = json['accesstoken'] as String?;
    id = json['id'] as String?;
    user_name = json['user_name'] as String?;
    email = json['email'] as String?;
    phone_number = json['phone_number'] as String?;
    role = json['role'] as int?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    data['accesstoken'] = accesstoken;
    data['id'] = id;
    data['user_name'] = user_name;
    data['email'] = email;
    data['phone_number'] = phone_number;
    data['role'] = role;
    return data;
  }
}