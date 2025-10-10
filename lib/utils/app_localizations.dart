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

      // Privacy Policy Content
      'pp_title': 'Privacy Policy',
      'pp_effective_date': 'Effective Date',
      'pp_last_updated': 'Last Updated',
      'pp_introduction_title': 'Introduction',
      'pp_introduction_content': 'This Privacy Policy explains how BCA Scholar Hub collects, uses, and discloses your information when you use our application. By using our services, you agree to the collection and use of information in accordance with this policy.',
      'pp_information_title': 'Information Collection and Use',
      'pp_information_content': 'We collect several different types of information for various purposes to provide and improve our service to you. While using our app, we may ask you to provide us with certain personally identifiable information that can be used to contact or identify you.',
      'pp_personal_data_title': 'Personal Data',
      'pp_personal_data_content': 'We may collect personal information that you provide to us such as name, email address, and other contact details.',
      'pp_usage_data_title': 'Usage Data',
      'pp_usage_data_content': 'We may also collect information on how the app is accessed and used. This data may include information such as your device\'s IP address, browser type, pages visited, time spent on those pages, and other diagnostic data.',
      'pp_data_security_title': 'Data Security',
      'pp_data_security_content': 'The security of your data is important to us, but remember that no method of transmission over the Internet, or method of electronic storage is 100% secure. While we strive to use commercially acceptable means to protect your personal data, we cannot guarantee its absolute security.',
      'pp_changes_title': 'Changes to This Privacy Policy',
      'pp_changes_content': 'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "effective date" at the top of this Privacy Policy.',
      'pp_contact_title': 'Contact Us',
      'pp_contact_content': 'If you have any questions about this Privacy Policy, please contact us at:\\n\\n• Email: contact@bcascholar.com\\n• Website: www.bcascholar.com',

      // Terms of Service Content
      'tos_title': 'Terms of Service',
      'tos_agreement_title': 'Agreement to Terms',
      'tos_agreement_content': 'By accessing or using the BCA Scholar Hub application, you agree to be bound by these Terms of Service and all applicable laws and regulations. If you do not agree with any of these terms, you are prohibited from using or accessing this app.',
      'tos_license_title': 'Use License',
      'tos_license_content': 'Permission is granted to temporarily use the application for personal, non-commercial purposes only. This is the grant of a license, not a transfer of title, and under this license you may not:\\n\\n• Modify or copy the materials\\n• Use the materials for any commercial purpose\\n• Attempt to decompile or reverse engineer any software contained in the app\\n• Remove any copyright or other proprietary notations from the materials\\n• Transfer the materials to another person or "mirror" the materials on any other server',
      'tos_accounts_title': 'User Accounts',
      'tos_accounts_content': 'Some features of the app may require you to register for an account. You are responsible for maintaining the confidentiality of your account and password and for restricting access to your device, and you agree to accept responsibility for all activities that occur under your account.',
      'tos_content_title': 'Content',
      'tos_content_content': 'Our app allows you to access educational materials, PDFs, and courses. All content provided on this app is for informational and educational purposes only. We make no warranties about the accuracy or reliability of such content.',
      'tos_limitations_title': 'Limitations',
      'tos_limitations_content': 'In no event shall BCA Scholar Hub or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on the app, even if BCA Scholar Hub or an authorized representative has been notified orally or in writing of the possibility of such damage.',
      'tos_revisions_title': 'Revisions and Errata',
      'tos_revisions_content': 'BCA Scholar Hub may revise these terms of service for its app at any time without notice. By using this app you are agreeing to be bound by the then current version of these terms of service.',
      'tos_governing_title': 'Governing Law',
      'tos_governing_content': 'These terms and conditions are governed by and construed in accordance with the laws and you irrevocably submit to the exclusive jurisdiction of the courts in that location.',
      'tos_contact_title': 'Contact Information',
      'tos_contact_content': 'If you have any questions about these Terms of Service, please contact us at:\\n\\n• Email: terms@bcascholar.com\\n• Website: www.bcascholar.com',
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

      // Privacy Policy Content
      'pp_title': 'गोपनीयता नीति',
      'pp_effective_date': 'प्रभावी मिति',
      'pp_last_updated': 'अन्तिम अपडेट',
      'pp_introduction_title': 'परिचय',
      'pp_introduction_content': 'यो गोपनीयता नीतिले बीसीए स्कोलर हबले तपाईंको जानकारी कसरी सङ्कलन, प्रयोग र सार्वजनिक गर्छ भन्ने कुरा वर्णन गर्दछ। हाम्रो सेवा प्रयोग गरेर, तपाईं यस नीति अनुसार जानकारी सङ्कलन र प्रयोगमा सहमत हुनुहुन्छ।',
      'pp_information_title': 'जानकारी सङ्कलन र प्रयोग',
      'pp_information_content': 'हामीले तपाईंलाई हाम्रो सेवा प्रदान गर्न र सुधार गर्नका लागि विभिन्न उद्देश्यका लागि विभिन्न प्रकारका जानकारी सङ्कलन गर्छौं। हाम्रो एप प्रयोग गर्दा, हामीले तपाईंलाई व्यक्तिगत पहिचान योग्य जानकारी प्रदान गर्न भन्न सक्छौं।',
      'pp_personal_data_title': 'व्यक्तिगत डेटा',
      'pp_personal_data_content': 'हामीले तपाईंले हामीलाई प्रदान गर्ने व्यक्तिगत जानकारी जस्तै नाम, इमेल ठेगाना र अन्य सम्पर्क विवरणहरू सङ्कलन गर्न सक्छौं।',
      'pp_usage_data_title': 'प्रयोग डेटा',
      'pp_usage_data_content': 'एप कसरी पहुँच र प्रयोग गरिन्छ भन्ने बारेमा पनि हामीले जानकारी सङ्कलन गर्न सक्छौं। यो डेटामा तपाईंको उपकरणको आईपी ठेगाना, ब्राउजर प्रकार, भ्रमण गरेका पृष्ठहरू र अन्य निदान डेटा समावेश हुन सक्छ।',
      'pp_data_security_title': 'डेटा सुरक्षा',
      'pp_data_security_content': 'तपाईंको डेटाको सुरक्षा हाम्रो लागि महत्वपूर्ण छ, तर इन्टरनेटमा प्रसारण वा इलेक्ट्रोनिक भण्डारणको कुनै पनि विधि १००% सुरक्षित छैन भन्ने कुरा याद राख्नुहोस्। हामी तपाईंको व्यक्तिगत डेटा सुरक्षित राख्न व्यावसायिक रूपमा स्वीकार्य माध्यमहरू प्रयोग गर्न प्रयास गर्छौं।',
      'pp_changes_title': 'यस गोपनीयता नीतिमा परिवर्तन',
      'pp_changes_content': 'हामीले समय-समयमा हाम्रो गोपनीयता नीति अपडेट गर्न सक्छौं। हामीले यस पृष्ठमा नयाँ गोपनीयता नीति पोस्ट गरेर र "प्रभावी मिति" अपडेट गरेर कुनै पनि परिवर्तनहरूको बारेमा तपाईंलाई सूचित गर्नेछौं।',
      'pp_contact_title': 'हामीलाई सम्पर्क गर्नुहोस्',
      'pp_contact_content': 'यदि तपाईंसँग यस गोपनीयता नीतिको बारेमा कुनै प्रश्नहरू छन् भने, कृपया हामीलाई सम्पर्क गर्नुहोस्:\\n\\n• इमेल: contact@bcascholar.com\\n• वेबसाइट: www.bcascholar.com',

      // Terms of Service Content
      'tos_title': 'सेवाका सर्तहरू',
      'tos_agreement_title': 'सर्तहरूमा सहमति',
      'tos_agreement_content': 'बीसीए स्कोलर हब एप्लिकेसन पहुँच वा प्रयोग गरेर, तपाईं यी सेवाका सर्तहरू र सबै लागू कानून र नियमहरूमा बाध्य हुन सहमत हुनुहुन्छ। यदि तपाईं यी सर्तहरूमध्ये कुनै पनि कुरामा सहमत हुनुहुन्न भने, तपाईंलाई यो एप प्रयोग गर्न वा पहुँच गर्न निषेध गरिएको छ।',
      'tos_license_title': 'प्रयोग इजाजतपत्र',
      'tos_license_content': 'व्यक्तिगत, गैर-व्यावसायिक उद्देश्यका लागि मात्र एप्लिकेसन अस्थायी रूपमा प्रयोग गर्ने अनुमति दिइएको छ। यो इजाजतपत्रको अनुदान हो, स्वामित्व स्थानान्तरण होइन:\\n\\n• सामग्री परिमार्जन वा प्रतिलिपि नगर्नुहोस्\\n• व्यावसायिक उद्देश्यका लागि सामग्री प्रयोग नगर्नुहोस्\\n• एपमा भएको कुनै पनि सफ्टवेयर डिकम्पाइल वा रिभर्स इन्जिनियर गर्ने प्रयास नगर्नुहोस्\\n• सामग्रीबाट कुनै पनि प्रतिलिपि अधिकार वा अन्य स्वामित्व संकेतहरू हटाउनुहोस्\\n• सामग्री अर्को व्यक्तिलाई स्थानान्तरण नगर्नुहोस्',
      'tos_accounts_title': 'प्रयोगकर्ता खाताहरू',
      'tos_accounts_content': 'एपका केही सुविधाहरूको लागि तपाईंले खाताको लागि दर्ता गर्नुपर्ने हुन सक्छ। तपाईं आफ्नो खाता र पासवर्डको गोपनीयता कायम राख्न र आफ्नो उपकरणमा पहुँच प्रतिबन्धित गर्न जिम्मेवार हुनुहुन्छ।',
      'tos_content_title': 'सामग्री',
      'tos_content_content': 'हाम्रो एपले तपाईंलाई शैक्षिक सामग्री, पीडीएफ र पाठ्यक्रमहरूमा पहुँच गर्न अनुमति दिन्छ। यस एपमा प्रदान गरिएको सबै सामग्री केवल जानकारीमूलक र शैक्षिक उद्देश्यका लागि हो।',
      'tos_limitations_title': 'सीमाहरू',
      'tos_limitations_content': 'कुनै पनि घटनामा बीसीए स्कोलर हब वा यसका आपूर्तिकर्ताहरू एपमा सामग्रीको प्रयोग वा प्रयोग गर्न असमर्थताबाट उत्पन्न कुनै पनि क्षतिको लागि उत्तरदायी हुनेछैनन्।',
      'tos_revisions_title': 'संशोधन र त्रुटिहरू',
      'tos_revisions_content': 'बीसीए स्कोलर हबले बिना सूचना आफ्नो एपको लागि यी सेवाका सर्तहरू संशोधन गर्न सक्छ। यो एप प्रयोग गरेर तपाईं सेवाका सर्तहरूको वर्तमान संस्करणमा बाध्य हुन सहमत हुनुहुन्छ।',
      'tos_governing_title': 'शासकीय कानून',
      'tos_governing_content': 'यी नियम र सर्तहरू कानून अनुसार शासित र व्याख्या गरिन्छ र तपाईं त्यस स्थानको अदालतहरूको विशेष क्षेत्राधिकारमा अपरिवर्तनीय रूपमा पेश गर्नुहुन्छ।',
      'tos_contact_title': 'सम्पर्क जानकारी',
      'tos_contact_content': 'यदि तपाईंसँग यी सेवाका सर्तहरूको बारेमा कुनै प्रश्नहरू छन् भने, कृपया हामीलाई सम्पर्क गर्नुहोस्:\\n\\n• इमेल: terms@bcascholar.com\\n• वेबसाइट: www.bcascholar.com',
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

      // Privacy Policy Content
      'pp_title': 'गोपनीयता नीति',
      'pp_effective_date': 'प्रभावी तिथि',
      'pp_last_updated': 'अंतिम अपडेट',
      'pp_introduction_title': 'परिचय',
      'pp_introduction_content': 'यह गोपनीयता नीति बताती है कि बीसीए स्कॉलर हब आपकी जानकारी कैसे एकत्र, उपयोग और प्रकट करता है। हमारी सेवाओं का उपयोग करके, आप इस नीति के अनुसार जानकारी के संग्रह और उपयोग से सहमत होते हैं।',
      'pp_information_title': 'जानकारी संग्रह और उपयोग',
      'pp_information_content': 'हम आपको हमारी सेवा प्रदान करने और बेहतर बनाने के लिए विभिन्न उद्देश्यों के लिए कई प्रकार की जानकारी एकत्र करते हैं। हमारे ऐप का उपयोग करते समय, हम आपसे व्यक्तिगत पहचान योग्य जानकारी प्रदान करने को कह सकते हैं।',
      'pp_personal_data_title': 'व्यक्तिगत डेटा',
      'pp_personal_data_content': 'हम आपके द्वारा हमें प्रदान की गई व्यक्तिगत जानकारी जैसे नाम, ईमेल पता और अन्य संपर्क विवरण एकत्र कर सकते हैं।',
      'pp_usage_data_title': 'उपयोग डेटा',
      'pp_usage_data_content': 'हम यह भी जानकारी एकत्र कर सकते हैं कि ऐप कैसे एक्सेस और उपयोग किया जाता है। इस डेटा में आपके डिवाइस का आईपी पता, ब्राउज़र प्रकार, देखे गए पृष्ठ और अन्य निदान डेटा शामिल हो सकता है।',
      'pp_data_security_title': 'डेटा सुरक्षा',
      'pp_data_security_content': 'आपके डेटा की सुरक्षा हमारे लिए महत्वपूर्ण है, लेकिन याद रखें कि इंटरनेट पर ट्रांसमिशन या इलेक्ट्रॉनिक स्टोरेज की कोई भी विधि 100% सुरक्षित नहीं है। हम आपके व्यक्तिगत डेटा की सुरक्षा के लिए व्यावसायिक रूप से स्वीकार्य साधनों का उपयोग करने का प्रयास करते हैं।',
      'pp_changes_title': 'इस गोपनीयता नीति में बदलाव',
      'pp_changes_content': 'हम समय-समय पर अपनी गोपनीयता नीति को अपडेट कर सकते हैं। हम इस पृष्ठ पर नई गोपनीयता नीति पोस्ट करके और "प्रभावी तिथि" को अपडेट करके किसी भी बदलाव के बारे में आपको सूचित करेंगे।',
      'pp_contact_title': 'हमसे संपर्क करें',
      'pp_contact_content': 'यदि आपके पास इस गोपनीयता नीति के बारे में कोई प्रश्न हैं, तो कृपया हमसे संपर्क करें:\\n\\n• ईमेल: contact@bcascholar.com\\n• वेबसाइट: www.bcascholar.com',

      // Terms of Service Content
      'tos_title': 'सेवा की शर्तें',
      'tos_agreement_title': 'शर्तों से सहमति',
      'tos_agreement_content': 'बीसीए स्कॉलर हब एप्लिकेशन तक पहुंचने या उपयोग करने से, आप इन सेवा की शर्तों और सभी लागू कानूनों और नियमों से बंधे होने के लिए सहमत हैं। यदि आप इनमें से किसी भी शर्त से सहमत नहीं हैं, तो आपको इस ऐप का उपयोग करने या इसे एक्सेस करने से प्रतिबंधित किया गया है।',
      'tos_license_title': 'उपयोग लाइसेंस',
      'tos_license_content': 'केवल व्यक्तिगत, गैर-व्यावसायिक उद्देश्यों के लिए एप्लिकेशन का अस्थायी उपयोग करने की अनुमति दी गई है। यह लाइसेंस का अनुदान है, स्वामित्व का स्थानांतरण नहीं:\\n\\n• सामग्री को संशोधित या कॉपी न करें\\n• व्यावसायिक उद्देश्य के लिए सामग्री का उपयोग न करें\\n• ऐप में शामिल किसी भी सॉफ्टवेयर को डीकंपाइल या रिवर्स इंजीनियर करने का प्रयास न करें\\n• सामग्री से कोई भी कॉपीराइट या अन्य स्वामित्व संकेत न हटाएं\\n• सामग्री को किसी अन्य व्यक्ति को स्थानांतरित न करें',
      'tos_accounts_title': 'उपयोगकर्ता खाते',
      'tos_accounts_content': 'ऐप की कुछ सुविधाओं के लिए आपको एक खाते के लिए पंजीकरण करना पड़ सकता है। आप अपने खाते और पासवर्ड की गोपनीयता बनाए रखने और अपने डिवाइस तक पहुंच को प्रतिबंधित करने के लिए जिम्मेदार हैं।',
      'tos_content_title': 'सामग्री',
      'tos_content_content': 'हमारा ऐप आपको शैक्षिक सामग्री, पीडीएफ और पाठ्यक्रमों तक पहुंचने की अनुमति देता है। इस ऐप पर प्रदान की गई सभी सामग्री केवल सूचनात्मक और शैक्षिक उद्देश्यों के लिए है।',
      'tos_limitations_title': 'सीमाएं',
      'tos_limitations_content': 'किसी भी स्थिति में बीसीए स्कॉलर हब या इसके आपूर्तिकर्ता ऐप पर सामग्री के उपयोग या उपयोग करने में असमर्थता से उत्पन्न किसी भी नुकसान के लिए उत्तरदायी नहीं होंगे।',
      'tos_revisions_title': 'संशोधन और त्रुटियां',
      'tos_revisions_content': 'बीसीए स्कॉलर हब बिना सूचना के अपने ऐप के लिए इन सेवा की शर्तों को संशोधित कर सकता है। इस ऐप का उपयोग करके आप सेवा की शर्तों के वर्तमान संस्करण से बंधे होने के लिए सहमत हैं।',
      'tos_governing_title': 'शासी कानून',
      'tos_governing_content': 'ये नियम और शर्तें कानून के अनुसार शासित और व्याख्या की जाती हैं और आप उस स्थान की अदालतों के विशेष न्यायाधिकार के लिए अपरिवर्तनीय रूप से प्रस्तुत करते हैं।',
      'tos_contact_title': 'संपर्क जानकारी',
      'tos_contact_content': 'यदि आपके पास इन सेवा की शर्तों के बारे में कोई प्रश्न हैं, तो कृपया हमसे संपर्क करें:\\n\\n• ईमेल: terms@bcascholar.com\\n• वेबसाइट: www.bcascholar.com',
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
