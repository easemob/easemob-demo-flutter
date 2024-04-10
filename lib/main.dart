import 'package:chat_uikit_demo/debug_login_page.dart';
import 'package:chat_uikit_demo/demo_config.dart';
import 'package:chat_uikit_demo/demo_localizations.dart';
import 'package:chat_uikit_demo/home_page.dart';
import 'package:chat_uikit_demo/login_page.dart';
import 'package:chat_uikit_demo/notifications/app_settings_notification.dart';
import 'package:chat_uikit_demo/pages/me/about_page.dart';
import 'package:chat_uikit_demo/pages/me/personal/personal_info_page.dart';
import 'package:chat_uikit_demo/pages/me/settings/general_page.dart';
import 'package:chat_uikit_demo/pages/me/settings/language_page.dart';
import 'package:chat_uikit_demo/pages/me/settings/translate_page.dart';
import 'package:chat_uikit_demo/tool/chat_route_filter.dart';
import 'package:chat_uikit_demo/tool/settings_data_store.dart';
import 'package:chat_uikit_demo/welcome_page.dart';
import 'package:em_chat_uikit/chat_uikit.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'pages/me/settings/advanced_page.dart';

const bool appDebug = false;

void main() async {
  return ChatUIKit.instance
      .init(
    options: Options(
      appKey: appKey,
      deleteMessagesAsExitGroup: false,
    ),
  )
      .then((value) {
    SettingsDataStore().init();
    return SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((value) => runApp(const MyApp()));
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
  Widget build(BuildContext context) {
    return NotificationListener(
      onNotification: (notification) {
        if (notification is AppSettingsNotification) {
          setState(() {});
        }
        return false;
      },
      child: MaterialApp(
        supportedLocales: _localization.supportedLocales,
        localizationsDelegates: _localization.localizationsDelegates,
        localeResolutionCallback: _localization.localeResolutionCallback,
        locale: _localization.currentLocale,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        builder: EasyLoading.init(
          builder: (context, child) {
            return ChatUIKitTheme(
              color: AppSettingsNotification.isLight ? ChatUIKitColor.light() : ChatUIKitColor.dark(),
              child: child!,
            );
          },
        ),
        home: const WelcomePage(),
        onGenerateRoute: (settings) {
          RouteSettings newSettings = ChatRouteFilter.chatRouteSettings(settings);
          return ChatUIKitRoute().generateRoute(newSettings) ??
              MaterialPageRoute(
                builder: (context) {
                  if (settings.name == '/home') {
                    return const HomePage();
                  } else if (settings.name == '/login') {
                    return const LoginPage();
                  } else if (settings.name == '/debug_login') {
                    return const DebugLoginPage();
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
