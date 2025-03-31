import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Account Setup',
      'myAccount': 'My account',
      'accountSecurity': 'Account & Security',
      'address': 'Address',
      'bankAccount': 'Bank Account/Card',
      'notificationSettings': 'Notification settings',
      'language': 'Language',
      'supportCenter': 'Support center',
      'communityStandards': 'Community standards',
      'satisfactionSurvey':
          'Satisfied with FurniFit AR? Let\'s evaluate together.',
      'logOut': 'Log Out',
      'save': 'Save',
      'searchHint': 'Search here...',
      'categories': 'Categories',
      'allProduct': 'All Product',
      'setting': 'Settings', // Note: Usually this is plural in English
    },
    'vi': {
      'appTitle': 'Thiết lập tài khoản',
      'myAccount': 'Tài khoản của tôi',
      'accountSecurity': 'Tài khoản & Bảo mật',
      'address': 'Địa chỉ',
      'bankAccount': 'Tài khoản/Thẻ ngân hàng',
      'notificationSettings': 'Cài đặt thông báo',
      'language': 'Ngôn ngữ',
      'supportCenter': 'Trung tâm hỗ trợ',
      'communityStandards': 'Tiêu chuẩn cộng đồng',
      'satisfactionSurvey': 'Hài lòng với FurniFit AR? Hãy đánh giá cùng nhau.',
      'logOut': 'Đăng xuất',
      'save': 'Lưu',
      'searchHint': 'Tìm kiếm ở đây...',
      'categories': 'Danh mục',
      'allProduct': 'Tất cả sản phẩm',
      'setting': 'Cài đặt',
    },
  };

  String get appTitle => _localizedValues[locale.languageCode]!['appTitle']!;
  String get myAccount => _localizedValues[locale.languageCode]!['myAccount']!;
  String get accountSecurity =>
      _localizedValues[locale.languageCode]!['accountSecurity']!;
  String get address => _localizedValues[locale.languageCode]!['address']!;
  String get bankAccount =>
      _localizedValues[locale.languageCode]!['bankAccount']!;
  String get notificationSettings =>
      _localizedValues[locale.languageCode]!['notificationSettings']!;
  String get language => _localizedValues[locale.languageCode]!['language']!;
  String get supportCenter =>
      _localizedValues[locale.languageCode]!['supportCenter']!;
  String get communityStandards =>
      _localizedValues[locale.languageCode]!['communityStandards']!;
  String get satisfactionSurvey =>
      _localizedValues[locale.languageCode]!['satisfactionSurvey']!;
  String get logOut => _localizedValues[locale.languageCode]!['logOut']!;
  String get save => _localizedValues[locale.languageCode]!['save']!;
  String get searchHint =>
      _localizedValues[locale.languageCode]!['searchHint']!;
  String get categories =>
      _localizedValues[locale.languageCode]!['categories']!;
  String get allProduct =>
      _localizedValues[locale.languageCode]!['allProduct']!;

  String get setting => _localizedValues[locale.languageCode]!['setting']!;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'vi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
