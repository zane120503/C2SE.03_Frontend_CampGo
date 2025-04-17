import 'package:CampGo/services/language_manager.dart';
import 'package:CampGo/translate/localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  late LanguageManager _languageManager;
  String _selectedLanguage = 'English';
  bool _hasChanges = false;

  final List<Map<String, String>> _languages = [
    {'name': 'Tiếng Việt', 'code': 'vi'},
    {'name': 'English', 'code': 'en'},
  ];

  @override
  void initState() {
    super.initState();
    _languageManager = Provider.of<LanguageManager>(context, listen: false);
    _selectedLanguage = _languageManager.currentLocale.languageCode == 'en'
        ? 'English'
        : 'Tiếng Việt';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.language,
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: _hasChanges
                ? () async {
                    String code = _selectedLanguage == 'English' ? 'en' : 'vi';
                    await _languageManager.changeLanguage(code);
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  }
                : null,
            child: Text(
              l10n.save,
              style: TextStyle(
                color: _hasChanges ? Colors.pink : Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: Container(
        margin: const EdgeInsets.only(top: 1),
        child: ListView.builder(
          itemCount: _languages.length,
          itemBuilder: (context, index) {
            final language = _languages[index];
            final isSelected = _selectedLanguage == language['name'];

            return Container(
              color: Colors.white,
              child: ListTile(
                title: Text(
                  language['name']!,
                  style: const TextStyle(fontSize: 16),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.black)
                    : null,
                onTap: () {
                  if (!isSelected) {
                    setState(() {
                      _selectedLanguage = language['name']!;
                      _hasChanges = true;
                    });
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
