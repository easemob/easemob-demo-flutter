import 'package:chat_uikit_demo/demo_config.dart';
import 'package:chat_uikit_demo/demo_localizations.dart';
import 'package:chat_uikit_demo/pages/home_page.dart';
import 'package:chat_uikit_demo/pages/phone_login_page.dart';
import 'package:chat_uikit_demo/notifications/app_settings_notification.dart';
import 'package:chat_uikit_demo/pages/me/about_page.dart';
import 'package:chat_uikit_demo/pages/me/personal/personal_info_page.dart';
import 'package:chat_uikit_demo/pages/me/privacy/block_list_page.dart';
import 'package:chat_uikit_demo/pages/me/privacy/privacy_page.dart';
import 'package:chat_uikit_demo/pages/me/settings/general_page.dart';
import 'package:chat_uikit_demo/pages/me/settings/language_page.dart';
import 'package:chat_uikit_demo/pages/me/settings/translate_page.dart';
import 'package:chat_uikit_demo/custom/chat_route_filter.dart';
import 'package:chat_uikit_demo/pages/userid_login_page.dart';
import 'package:chat_uikit_demo/tool/online_status_helper.dart';
import 'package:chat_uikit_demo/tool/settings_data_store.dart';
import 'package:chat_uikit_demo/pages/welcome_page.dart';
import 'package:em_chat_uikit/chat_uikit.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'pages/me/settings/advanced_page.dart';

String appKey = 'easemob#easeim';
String rtcAppId = '';
String serverUrl = '';

void main() async {
  DemoConfig.setConfig(
    appKey: appKey,
    rtcAppId: rtcAppId,
    serverUrl: serverUrl,
  );
  assert(DemoConfig.appKey != null,
      'DemoConfig.appKey must be set, call DemoConfig.setConfig(appKey: "your_app_key") before runApp');
  return ChatUIKit.instance
      .init(
    options: Options.withAppKey(DemoConfig.appKey!),
  )
      .then((value) {
    SettingsDataStore().init();
    OnlineStatusHelper();
    return SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
        .then((value) => runApp(const MyApp()));
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ChatUIKitLocalizations _localization = ChatUIKitLocalizations();

  @override
  void initState() {
    super.initState();

    // 添加 demo 国际化内容
    _localization.defaultLocale = [
      ChatLocal(
        'zh',
        Map.from(ChatUIKitLocal.zh)..addAll(DemoLocalizations.zh),
      ),
      ChatLocal(
        'en',
        Map.from(ChatUIKitLocal.en)..addAll(DemoLocalizations.en),
      )
    ];

    // 添加语言后需要进行resetLocales操作
    _localization.resetLocales();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener(
      onNotification: (notification) {
        if (notification is AppSettingsNotification) {
          setState(() {});
        }
        return false;
      },
      child: MaterialApp(
        // 设置demo国际化支持语言
        supportedLocales: _localization.supportedLocales,
        // 提供语言包内容给demo
        localizationsDelegates: _localization.localizationsDelegates,
        // 当国际化语言不支持时，提供语言默认实现
        localeResolutionCallback: _localization.localeResolutionCallback,
        locale: _localization.currentLocale,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        builder: EasyLoading.init(),
        home: const WelcomePage(),
        onGenerateRoute: (settings) {
          // 设置路由拦截
          RouteSettings newSettings =
              ChatRouteFilter.chatRouteSettings(settings);
          return ChatUIKitRoute().generateRoute(newSettings) ??
              MaterialPageRoute(
                builder: (context) {
                  if (settings.name == '/home') {
                    return const HomePage();
                  } else if (settings.name == '/login') {
                    if (DemoConfig.isValid) {
                      return const PhoneLoginPage();
                    } else {
                      return const UserIdLoginPage();
                    }
                  } else if (settings.name == '/personal_info') {
                    return const PersonalInfoPage();
                  } else if (settings.name == '/general_page') {
                    return const GeneralPage();
                  } else if (settings.name == '/language_page') {
                    return const LanguagePage();
                  } else if (settings.name == '/translate_page') {
                    return const TranslatePage();
                  } else if (settings.name == '/advanced_page') {
                    return const AdvancedPage();
                  } else if (settings.name == '/about_page') {
                    return const AboutPage();
                  } else if (settings.name == '/privacy_page') {
                    return const PrivacyPage();
                  } else if (settings.name == '/block_list_page') {
                    return const BlockListPage();
                  } else {
                    return const SizedBox();
                  }
                },
              );
        },
      ),
    );
  }
}
