import 'dart:async';

import 'package:chat_uikit_demo/demo_localizations.dart';
import 'package:em_chat_uikit/chat_uikit.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:url_launcher/url_launcher.dart';

class UserIdLoginPage extends StatefulWidget {
  const UserIdLoginPage({super.key});

  @override
  State<UserIdLoginPage> createState() => _UserIdLoginPageState();
}

class _UserIdLoginPageState extends State<UserIdLoginPage>
    with ChatUIKitThemeMixin {
  int timer = 0;
  Timer? _timer;
  final String serviceAgreementURL = 'https://www.easemob.com/agreement';
  final String privacyPolicyURL = 'https://www.easemob.com/protocol';

  TextEditingController userIdController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  bool agreeServiceAgreement = false;

  @override
  void dispose() {
    _timer?.cancel();
    userIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget themeBuilder(BuildContext context, ChatUIKitTheme theme) {
    TextStyle linkStyle = TextStyle(
      color: Colors.blue,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w500,
      decorationColor: theme.color.primaryColor5,
    );
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: theme.color.primaryColor95,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: ListView(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      DemoLocalizations.loginEaseMob.localString(context),
                      style: TextStyle(
                        color: theme.color.primaryColor5,
                        fontWeight: FontWeight.w500,
                        fontSize: 24,
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                  child: TextField(
                    controller: userIdController,
                    keyboardAppearance:
                        theme.color.isDark ? Brightness.dark : Brightness.light,
                    autofocus: true,
                    style: TextStyle(
                        fontWeight: theme.font.bodyLarge.fontWeight,
                        fontSize: theme.font.bodyLarge.fontSize,
                        color: theme.color.neutralColor1),
                    scrollPadding: EdgeInsets.zero,
                    decoration: InputDecoration(
                      hintText: DemoLocalizations.loginUserIdHint
                          .localString(context),
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      hintStyle: TextStyle(
                        color: theme.color.neutralColor6,
                      ),
                      border:
                          const OutlineInputBorder(borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                  child: TextField(
                    controller: passwordController,
                    keyboardAppearance:
                        theme.color.isDark ? Brightness.dark : Brightness.light,
                    autofocus: true,
                    style: TextStyle(
                        fontWeight: theme.font.bodyLarge.fontWeight,
                        fontSize: theme.font.bodyLarge.fontSize,
                        color: theme.color.neutralColor1),
                    // controller: searchController,
                    scrollPadding: EdgeInsets.zero,
                    decoration: InputDecoration(
                      hintText: DemoLocalizations.loginPasswordHint
                          .localString(context),
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      hintStyle: TextStyle(
                        color: theme.color.neutralColor6,
                      ),
                      suffixIconConstraints:
                          BoxConstraints.loose(const Size(100, 40)),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: () {
                      login();
                    },
                    child: Text(
                      DemoLocalizations.login.localString(context),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(
                        child: InkWell(
                          onTap: () => setState(() {
                            agreeServiceAgreement = !agreeServiceAgreement;
                          }),
                          child: () {
                            return agreeServiceAgreement
                                ? Icon(
                                    Icons.check_box,
                                    size: 20,
                                    color: theme.color.primaryColor5,
                                  )
                                : Icon(
                                    Icons.check_box_outline_blank,
                                    size: 20,
                                    color: theme.color.primaryColor5,
                                  );
                          }(),
                        ),
                      ),
                      TextSpan(
                          text: DemoLocalizations.loginCheck
                              .localString(context)),
                      TextSpan(
                          text: DemoLocalizations.loginTermsOfService
                              .localString(context),
                          style: linkStyle,
                          recognizer: TapGestureRecognizer()
                            ..onTap = serviceAgreement),
                      TextSpan(
                          text:
                              DemoLocalizations.loginAnd.localString(context)),
                      TextSpan(
                          text: DemoLocalizations.loginPrivacyPolicy
                              .localString(context),
                          style: linkStyle,
                          recognizer: TapGestureRecognizer()
                            ..onTap = privacyPolicy),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  bool checkout() {
    if (agreeServiceAgreement == false) {
      EasyLoading.showInfo(DemoLocalizations
          .loginPleaseAgreeTermsOfServicePrivacyPolicy
          .localString(context));
      return false;
    }

    return true;
  }

  void login() async {
    if (!checkout()) return;

    if (passwordController.text.isEmpty || userIdController.text.isEmpty) {
      EasyLoading.showInfo(
          DemoLocalizations.loginPleaseInput.localString(context));
      return;
    }

    EasyLoading.show(status: DemoLocalizations.loggingIn.localString(context));

    Future(() async {
      try {
        await ChatUIKit.instance.loginWithPassword(
          userId: userIdController.text,
          password: passwordController.text,
        );
      } catch (e) {
        debugPrint(e.toString());
        rethrow;
      }
    }).then((value) {
      EasyLoading.dismiss();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }).catchError((e) {
      if (mounted) {
        EasyLoading.showError(
            DemoLocalizations.loginFailed.localString(context));
      }
    });
  }

  void serviceAgreement() async {
    if (!await launchUrl(Uri.parse(serviceAgreementURL))) {
      throw Exception('Could not launch $serviceAgreementURL');
    }
  }

  void privacyPolicy() async {
    if (!await launchUrl(Uri.parse(privacyPolicyURL))) {
      throw Exception('Could not launch $privacyPolicyURL');
    }
  }
}
