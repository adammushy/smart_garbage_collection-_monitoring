import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class AppConstants {
  static const String appName = 'Demo App';
  static const double appVersion = 1.0;

  // Shared Preference Key
  static const String token = 'token';
  static const String user = 'user';
  static const String isLogin = 'is_login';

  static String apiBaseUrl = "${dotenv.env['url']}/";
  static String mediaBaseUrl = '${dotenv.env['url']}';

  static const String registerUrl = 'user-management/register-user';
  static const String loginUrl = 'user-management/login-user';
  static const String trashcan = 'trash-management/trashbin-view';
  static const String reportComplain = 'trash-management/complain-view';
  static const String reportBreakdown = 'trash-management/report-view';

  // static const String getCreateAccountUrl =
  // static List<LanguageModel> languages = [
  //   LanguageModel(imageUrl: Images.unitedKingdom, languageName: 'English', countryCode: 'US', languageCode: 'en'),
  //   LanguageModel(imageUrl: Images.arabic, languageName: 'Arabic', countryCode: 'SA', languageCode: 'ar'),
  // ];
}
