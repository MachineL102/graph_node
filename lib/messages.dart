import 'package:flutter/material.dart';
import 'package:graph_note/local/en.dart' as en;
import 'package:graph_note/local/zh.dart' as zh;

//AppLocalizations 类用于表示应用程序的本地化资源。每个语言环境都有一个对应的 AppLocalizations 实例，用于获取该语言下的翻译文本。
class AppLocalizations {
  final Locale locale;
//构造函数用于创建 AppLocalizations 实例，并传入当前的语言环境。of 方法用于从给定的上下文中获取 AppLocalizations 实例。
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }
//_localizedValues 是一个字典，它保存着不同语言环境下的翻译文本。其中 'en' 和 'zh' 分别对应英文和中文的翻译资源，en.dart 和 zh.dart 文件分别定义了这些翻译文本。
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': en.en,
    'zh': zh.zh,
  };
//operator [] 方法用于获取指定键（key）对应的翻译文本。它通过检索 _localizedValues 字典中当前语言环境的翻译文本，并返回对应的值。
  String operator [](String key) {
    return _localizedValues[locale.languageCode]![key]!;
  }
}
//AppLocalizationsDelegate 类是一个 LocalizationsDelegate 的子类，用于提供本地化资源。
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();
//isSupported 方法用于检查给定的语言环境是否受支持。在这里，我们只支持英文（'en'）和中文（'zh'）两种语言环境。
  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }
//load 方法用于异步加载指定语言环境的本地化资源。在这里，我们使用 Future.delayed 方法模拟异步加载过程，并创建一个 AppLocalizations 实例。
  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }
//shouldReload 方法用于判断是否需要重新加载本地化资源。在这里，我们始终返回 false，表示不需要重新加载。
  @override
  bool shouldReload(AppLocalizationsDelegate old) {
    return false;
  }
}

