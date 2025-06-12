import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  // Helper method to keep the code in the widgets concise
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // Static member to have a simple access to the delegate from the MaterialApp
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Translation maps
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // General
      'app_name': 'BCA Scholar Hub',
      'welcome': 'Welcome to BCA Scholar Hub',
      'home': 'Home',
      'profile': 'Profile',
      'settings': 'Settings',
      'favorites': 'Favorites',
      'search': 'Search',

      // Navigation
      'youtube': 'YouTube',
      'semester': 'Semester',
      'notes': 'Notes',
      'resources': 'Resources',

      // Search
      'search_hint': 'Search subjects...',
      'no_results_found': 'No results found',

      // AI Assistant
      'ai': 'AI',
      'ask_me': 'Ask me...',
      'clear_chat': 'Clear Chat',

      // Settings
      'dark_mode': 'Dark Mode',
      'theme_description': 'Switch between light and dark theme',
      'text_size': 'Text Size',
      'language': 'Language',
      'notifications': 'Notifications',
      'notification_description':
          'Receive notifications for updates and new content',
      'account_settings': 'Account Settings',
      'appearance': 'Appearance',
      'preferences': 'Preferences',
      'media_settings': 'Media Settings',
      'download_quality': 'Download Quality',
      'download_wifi': 'Download Over Wi-Fi Only',
      'autoplay': 'Auto-play Videos',
      'autoplay_description': 'Automatically play videos when browsing',
      'password_security': 'Password & Security',
      'profile_info': 'Profile Information',
      'reset_settings': 'Reset All Settings',
      'about': 'About',
      'app_version': 'App Version',
      'privacy_policy': 'Privacy Policy',
      'terms_of_service': 'Terms of Service',

      // Placeholders
      'welcome_message':
          'Welcome to BCA Scholar Hub! Access all educational resources in one place.',
      'youtube_description': 'Watch educational videos on various subjects.',
      'search_description': 'Find specific study materials quickly.',
      'favorites_description': 'Access your saved study materials.',
      'coming_soon': 'Coming Soon',

      // BCA Semester
      'bca_semester': 'BCA Semester',
      'subject': 'Subject',
      'tap_for_notes': 'Tap to view notes and resources',

      // Help & Support
      'connect_with_us': 'Connect with me on social media',
      'social_links': 'Social Links',

      // Others
      'contact_us': 'Contact Us',
      'our_website': 'Our Website',
      'facebook': 'Facebook Page',
      'instagram': 'Instagram',
      'bca_entrance': 'BCA ENTRANCE QUESTIONS',
      'logout': 'Logout',
      'save': 'Save',
      'cancel': 'Cancel',
      'reset': 'Reset',
      'confirm_reset':
          'Are you sure you want to reset all settings to default?',
      'reset_title': 'Reset Settings',
      'reset_success': 'All settings have been reset',
      'logout_confirmation': 'Confirm Logout',
      'logout_message': 'Are you sure you want to logout from your account?',
    },

    'ne': {
      // General
      'app_name': 'अनिश लाइब्रेरी',
      'welcome': 'अनिश लाइब्रेरीमा स्वागत छ',
      'home': 'गृहपृष्ठ',
      'profile': 'प्रोफाइल',
      'settings': 'सेटिङहरू',
      'favorites': 'मनपर्ने',
      'search': 'खोज्नुहोस्',

      // Navigation
      'youtube': 'युट्युब',
      'semester': 'सेमेस्टर',
      'notes': 'नोटहरू',
      'resources': 'संसाधनहरू',

      // Search
      'search_hint': 'विषयहरू खोज्नुहोस्...',
      'no_results_found': 'कुनै परिणाम फेला परेन',

      // AI Assistant
      'ai': 'एआई',
      'ask_me': 'मलाई सोध्नुहोस्...',
      'clear_chat': 'च्याट खाली गर्नुहोस्',

      // Settings
      'dark_mode': 'डार्क मोड',
      'theme_description': 'लाइट र डार्क थीम बीच स्विच गर्नुहोस्',
      'text_size': 'पाठ आकार',
      'language': 'भाषा',
      'notifications': 'सूचनाहरू',
      'notification_description':
          'अपडेट र नयाँ सामग्रीको लागि सूचनाहरू प्राप्त गर्नुहोस्',
      'account_settings': 'खाता सेटिङहरू',
      'appearance': 'उपस्थिति',
      'preferences': 'प्राथमिकताहरू',
      'media_settings': 'मिडिया सेटिङहरू',
      'download_quality': 'डाउनलोड गुणस्तर',
      'download_wifi': 'वाई-फाई मार्फत मात्र डाउनलोड गर्नुहोस्',
      'autoplay': 'भिडियो स्वतः प्ले',
      'autoplay_description':
          'ब्राउजिङ गर्दा भिडियोहरू स्वचालित रूपमा प्ले गर्नुहोस्',
      'password_security': 'पासवर्ड र सुरक्षा',
      'profile_info': 'प्रोफाइल जानकारी',
      'reset_settings': 'सबै सेटिङहरू रिसेट गर्नुहोस्',
      'about': 'हाम्रोबारे',
      'app_version': 'एप संस्करण',
      'privacy_policy': 'गोपनीयता नीति',
      'terms_of_service': 'सेवाका सर्तहरू',

      // Placeholders
      'welcome_message':
          'अनिश लाइब्रेरीमा स्वागत छ! सबै शैक्षिक संसाधनहरूमा एकै ठाउँमा पहुँच प्राप्त गर्नुहोस्।',
      'youtube_description':
          'हाम्रो च्यानलबाट शैक्षिक भिडियो र ट्युटोरियलहरू हेर्नुहोस्।',
      'search_description':
          'नोटहरू, PDF, र पाठ्यक्रमहरू हाम्रो डाटाबेसमा खोज्नुहोस्।',
      'favorites_description':
          'तपाईंका मनपर्ने संसाधनहरूमा छिटो पहुँच प्राप्त गर्नुहोस्।',
      'coming_soon': 'छिट्टै आउँदैछ',

      // BCA Semester
      'bca_semester': 'बीसीए सेमेस्टर',
      'subject': 'विषय',
      'tap_for_notes': 'नोटहरू र संसाधनहरू हेर्न ट्याप गर्नुहोस्',

      // Help & Support
      'connect_with_us': 'सामाजिक मिडियामा हामीलाई फलो गर्नुहोस्',
      'social_links': 'सामाजिक लिंकहरू',

      // Others
      'contact_us': 'सम्पर्क गर्नुहोस्',
      'our_website': 'हाम्रो वेबसाइट',
      'facebook': 'फेसबुक पेज',
      'instagram': 'इन्स्टाग्राम',
      'bca_entrance': 'बीसीए प्रवेश प्रश्नहरू',
      'logout': 'लगआउट',
      'save': 'सुरक्षित गर्नुहोस्',
      'cancel': 'रद्द गर्नुहोस्',
      'reset': 'रिसेट',
      'confirm_reset':
          'के तपाईं सबै सेटिङहरू पूर्वनिर्धारित मा रिसेट गर्न निश्चित हुनुहुन्छ?',
      'reset_title': 'सेटिङहरू रिसेट गर्नुहोस्',
      'reset_success': 'सबै सेटिङहरू रिसेट गरिएको छ',
      'logout_confirmation': 'लगआउट पुष्टि गर्नुहोस्',
      'logout_message': 'के तपाईं आफ्नो खाताबाट लगआउट गर्न निश्चित हुनुहुन्छ?',
    },

    'hi': {
      // General
      'app_name': 'अनिश लाइब्रेरी',
      'welcome': 'अनिश लाइब्रेरी में आपका स्वागत है',
      'home': 'होम',
      'profile': 'प्रोफाइल',
      'settings': 'सेटिंग्स',
      'favorites': 'पसंदीदा',
      'search': 'खोज',

      // Navigation
      'youtube': 'यूट्यूब',
      'semester': 'सेमेस्टर',
      'notes': 'नोट्स',
      'resources': 'संसाधन',

      // Search
      'search_hint': 'विषय खोजें...',
      'no_results_found': 'कोई परिणाम नहीं मिला',

      // AI Assistant
      'ai': 'एआई',
      'ask_me': 'मुझसे पूछें...',
      'clear_chat': 'चैट साफ करें',

      // Settings
      'dark_mode': 'डार्क मोड',
      'theme_description': 'लाइट और डार्क थीम के बीच स्विच करें',
      'text_size': 'टेक्स्ट साइज़',
      'language': 'भाषा',
      'notifications': 'सूचनाएं',
      'notification_description':
          'अपडेट और नई सामग्री के लिए सूचनाएं प्राप्त करें',
      'account_settings': 'अकाउंट सेटिंग्स',
      'appearance': 'दिखावट',
      'preferences': 'प्राथमिकताएं',
      'media_settings': 'मीडिया सेटिंग्स',
      'download_quality': 'डाउनलोड क्वालिटी',
      'download_wifi': 'केवल वाई-फाई पर डाउनलोड करें',
      'autoplay': 'ऑटो-प्ले वीडियो',
      'autoplay_description':
          'ब्राउज़िंग करते समय वीडियो स्वचालित रूप से चलाएं',
      'password_security': 'पासवर्ड और सुरक्षा',
      'profile_info': 'प्रोफाइल जानकारी',
      'reset_settings': 'सभी सेटिंग्स रीसेट करें',
      'about': 'के बारे में',
      'app_version': 'ऐप वर्शन',
      'privacy_policy': 'गोपनीयता नीति',
      'terms_of_service': 'सेवा की शर्तें',

      // Placeholders
      'welcome_message':
          'अनिश लाइब्रेरी में आपका स्वागत है! सभी शैक्षिक संसाधनों तक एक ही स्थान पर पहुंचें।',
      'youtube_description':
          'हमारे चैनल से शैक्षिक वीडियो और ट्यूटोरियल देखें।',
      'search_description': 'हमारे डेटाबेस में नोट्स, पीडीएफ और कोर्स खोजें।',
      'favorites_description':
          'अपने बुकमार्क किए गए संसाधनों तक जल्दी से पहुंचें।',
      'coming_soon': 'जल्द आ रहा है',

      // BCA Semester
      'bca_semester': 'बीसीए सेमेस्टर',
      'subject': 'विषय',
      'tap_for_notes': 'नोट्स और संसाधन देखने के लिए टैप करें',

      // Help & Support
      'connect_with_us': 'सोशल मीडिया पर हमसे जुड़ें',
      'social_links': 'सोशल लिंक्स',

      // Others
      'contact_us': 'संपर्क करें',
      'our_website': 'हमारी वेबसाइट',
      'facebook': 'फेसबुक पेज',
      'instagram': 'इंस्टाग्राम',
      'bca_entrance': 'बीसीए प्रवेश प्रश्न',
      'logout': 'लॉगआउट',
      'save': 'सहेजें',
      'cancel': 'रद्द करें',
      'reset': 'रीसेट',
      'confirm_reset':
          'क्या आप वाकई सभी सेटिंग्स को डिफ़ॉल्ट पर रीसेट करना चाहते हैं?',
      'reset_title': 'सेटिंग्स रीसेट करें',
      'reset_success': 'सभी सेटिंग्स रीसेट कर दी गई हैं',
      'logout_confirmation': 'लॉगआउट की पुष्टि करें',
      'logout_message': 'क्या आप अपने अकाउंट से लॉगआउट करना चाहते हैं?',
    },
  };

  // Get a localized value
  String translate(String key) {
    // Get the current language map
    final languageMap = _localizedValues[locale.languageCode];

    if (languageMap == null) {
      // If language not found, fallback to English
      return _localizedValues['en']![key] ?? key;
    }

    // Return the translated value or the key itself if not found
    return languageMap[key] ?? _localizedValues['en']![key] ?? key;
  }
}

// LocalizationsDelegate implementation
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ne', 'hi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
