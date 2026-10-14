import 'package:chat_uikit_demo/demo_localizations.dart';
import 'package:chat_uikit_demo/tool/login_data_store.dart';
import 'package:em_chat_uikit/chat_uikit.dart';

import 'package:flutter/material.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with ChatUIKitThemeMixin {
  @override
  void initState() {
    super.initState();
    startShowTimer();
  }

  void startShowTimer() async {
    await Future.delayed(const Duration(seconds: 2));
    final credential = await LoginDataStore.load();
    var loginSucceeded = false;
    if (credential != null) {
      try {
        await ChatUIKit.instance.loginWithToken(
          userId: credential.userId,
          token: credential.token,
        );
        loginSucceeded = true;
      } catch (e) {
        debugPrint('Restore login failed: $e');
      }
    }
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacementNamed(loginSucceeded ? '/home' : '/login');
  }

  @override
  Widget themeBuilder(BuildContext context, ChatUIKitTheme theme) {
    return Scaffold(
      backgroundColor: theme.color.primaryColor95,
      body: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Image.asset('assets/images/icon.png'),
              ),
              const SizedBox(height: 38),
              Text(
                DemoLocalizations.welcome.localString(context),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                  color: theme.color.primaryColor5,
                ),
              ),
              const SizedBox(height: 180),
            ],
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Text(
              'Powered by Easemob',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.color.neutralColor5),
            ),
          )
        ],
      ),
    );
  }
}
