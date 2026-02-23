import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:sms_forwarder/l10n/locale/en.dart';
import 'package:sms_forwarder/l10n/locale/zh_CN.dart';
import 'package:sms_forwarder/l10n/locale/zh_HK.dart';
import 'package:sms_forwarder/l10n/locale/de.dart';
import 'package:sms_forwarder/l10n/locale/uk.dart';
import 'package:sms_forwarder/l10n/locale/ja.dart';
import 'package:sms_forwarder/l10n/locale/ko.dart';
import 'package:sms_forwarder/l10n/locale/id.dart';
import 'package:sms_forwarder/l10n/locale/hi.dart';
import 'package:sms_forwarder/l10n/locale/ru.dart';
import 'package:sms_forwarder/l10n/locale/ar.dart';
import 'package:sms_forwarder/l10n/locale/fr.dart';
import 'package:sms_forwarder/l10n/locale/es.dart';
import 'package:sms_forwarder/l10n/locale/bn.dart';

extension Transs on String {

  String get xtr {
    String that = trim(), ttr = tr.trim();
    if (that==ttr && ttr.contains(":")) {
      int trIndexOf = ttr.indexOf(":");
      return ttr.substring(trIndexOf+1);
    }
    return ttr;
  }

  String xtrFormat(Map<String, String?> params) {
    String xtt = xtr;
    if (params.isNotEmpty) {
      params.forEach((key, value) {
        if (value!=null) {
          xtt = xtt.replaceAll('@$key', value);
        }
      });
    }
    return xtt;
  }

  String strFormat(Map<String, String?> params) {
    String ttr = tr.trim();
    if (params.isNotEmpty) {
      params.forEach((key, value) {
        if (value!=null) {
          ttr = ttr.replaceAll('@$key', value);
        }
      });
    }
    return ttr;
  }
}

class TranslationService extends Translations {

  static Locale? get locale => Get.deviceLocale;

  static const fallbackLocale = Locale("en", "US");

  @override
  Map<String, Map<String, String>> get keys => {
    'en': enLang,
    'zh_CN': zhCNLang,
    'zh_Hans': zhCNLang,
    'zh_Hans_US': zhCNLang,
    'zh_Hant': zhHKLang,
    'zh_Hant_US': zhHKLang,
    'zh_TW': zhHKLang,
    'zh_HK': zhHKLang,
    'de': deLang,
    'fr': frLang,
    'es': esLang,
    'ja': jaLang,
    'ko': koLang,
    'ru': ruLang,
    'ar': arLang,
    'hi': hiLang,
    'id': idLang,
    'bn': bnLang,
    'uk': ukLang,
  };

  static String supportLocaleCode() {
    Locale? currentLocale = Get.locale;
    // String? countryCode = currentLocale?.countryCode;
    String? languageCode = currentLocale?.languageCode;
    String? scriptCode = currentLocale?.scriptCode;
    String? localeCode = languageCode=="zh" ? "${languageCode}_$scriptCode" : languageCode;
    // logger.i(">>> $currentLocale $scriptCode $countryCode $languageCode $localeCode");
    localeCode = ['en', 'zh_CN', 'zh_Hans', 'zh_Hant', 'zh_TW', 'zh_HK', 'de', 'fr', 'es', 'ja', 'ko', 'uk', 'ru', 'ar', 'hi', 'id', 'bn']
      .contains(localeCode) ? localeCode : "en";
    return localeCode??"en";
  }
}