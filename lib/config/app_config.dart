class AppConfig {
  const AppConfig._();

  static const String appName = 'Purchase Request';
  static const String websiteUrl = 'https://naytunlinn.github.io/PurchaseRequest/';
  static const String privacyPolicyUrl =
      'https://naytunlinn.github.io/PurchaseRequest/';

  static const int primaryColorValue = 0xFF145C9E;

  static const List<String> additionalWebViewHosts = <String>[];

  static const List<String> externalSchemes = <String>[
    'tel',
    'mailto',
    'sms',
    'whatsapp',
    'fb',
    'fb-messenger',
    'viber',
    'tg',
    'telegram',
  ];

  static const List<String> externalDomains = <String>[
    'facebook.com',
    'm.facebook.com',
    'messenger.com',
    'm.me',
    'wa.me',
    'whatsapp.com',
    'telegram.me',
    't.me',
    'viber.com',
  ];

  static const List<String> downloadableExtensions = <String>[
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'csv',
    'zip',
    'rar',
    'jpg',
    'jpeg',
    'png',
  ];

  static const List<String> uploadAllowedExtensions = <String>[
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'csv',
    'txt',
  ];

  static Uri get websiteUri => Uri.parse(websiteUrl);
}
