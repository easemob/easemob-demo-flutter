import 'dart:async';

import 'package:chat_uikit_demo/demo_localizations.dart';
import 'package:chat_uikit_demo/tool/app_server_helper.dart';
import 'package:chat_uikit_demo/widgets/verify_code_widget.dart';
import 'package:em_chat_uikit/chat_uikit.dart';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:url_launcher/url_launcher.dart';

class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({super.key});

  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage>
    with ChatUIKitThemeMixin {
  int timer = 0;
  Timer? _timer;
  final String serviceAgreementURL = 'https://www.easemob.com/agreement';
  final String privacyPolicyURL = 'https://www.easemob.com/protocol';

  TextEditingController phoneController = TextEditingController();
  TextEditingController codeController = TextEditingController();

  bool agreeServiceAgreement = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    phoneController.dispose();
    codeController.dispose();
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
    Widget content = Scaffold(
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
                const SizedBox(height: 30),
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
                    controller: phoneController,
                    keyboardAppearance:
                        theme.color.isDark ? Brightness.dark : Brightness.light,
                    style: TextStyle(
                        fontWeight: theme.font.bodyLarge.fontWeight,
                        fontSize: theme.font.bodyLarge.fontSize,
                        color: theme.color.neutralColor1),
                    scrollPadding: EdgeInsets.zero,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: DemoLocalizations.loginInputPhoneHint
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
                    controller: codeController,
                    keyboardAppearance:
                        theme.color.isDark ? Brightness.dark : Brightness.light,
                    style: TextStyle(
                        fontWeight: theme.font.bodyLarge.fontWeight,
                        fontSize: theme.font.bodyLarge.fontSize,
                        color: theme.color.neutralColor1),
                    scrollPadding: EdgeInsets.zero,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: DemoLocalizations.loginInputSmsHint
                          .localString(context),
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      hintStyle: TextStyle(
                        color: theme.color.neutralColor6,
                      ),
                      suffixIconConstraints:
                          BoxConstraints.loose(const Size(100, 40)),
                      suffixIcon: InkWell(
                        onTap: () {
                          fetchSmsCode();
                        },
                        enableFeedback: false,
                        child: Text(
                          timer == 0
                              ? DemoLocalizations.loginSendSms
                                  .localString(context)
                              : '${DemoLocalizations.loginResendSms.localString(context)}(${timer}s)',
                          style: TextStyle(
                            color: timer == 0
                                ? theme.color.primaryColor5
                                : theme.color.neutralColor7,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () => setState(() {
                        agreeServiceAgreement = !agreeServiceAgreement;
                      }),
                      child: () {
                        return agreeServiceAgreement
                            ? Icon(
                                Icons.check_box,
                                size: 22,
                                color: theme.color.primaryColor5,
                              )
                            : Icon(
                                Icons.check_box_outline_blank,
                                size: 22,
                                color: theme.color.primaryColor5,
                              );
                      }(),
                    ),
                    Text(DemoLocalizations.loginCheck.localString(context)),
                    InkWell(
                      onTap: serviceAgreement,
                      child: Text(
                        DemoLocalizations.loginTermsOfService
                            .localString(context),
                        style: linkStyle,
                      ),
                    ),
                    Text(DemoLocalizations.loginAnd.localString(context)),
                    InkWell(
                      onTap: privacyPolicy,
                      child: Text(
                        DemoLocalizations.loginPrivacyPolicy
                            .localString(context),
                        style: linkStyle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    content = GestureDetector(
      child: content,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
    );

    return content;
  }

  bool checkout() {
    if (agreeServiceAgreement == false) {
      EasyLoading.showInfo(DemoLocalizations
          .loginPleaseAgreeTermsOfServicePrivacyPolicy
          .localString(context));
      return false;
    }

    if (phoneController.text.isEmpty) {
      EasyLoading.showInfo(
          DemoLocalizations.loginPleaseInputPhone.localString(context));
      return false;
    }

    return true;
  }

  void fetchSmsCode() async {
    if (timer > 0) {
      EasyLoading.showInfo(DemoLocalizations.sendSmsWait.localString(context));
      return;
    }

    if (!checkout()) return;

    final result = await showVerifyCode(
      context,
      phoneController.text,
    );
    if (result == null) return;
    if (!mounted) return;
    if (result == true) {
      EasyLoading.showSuccess(
          DemoLocalizations.sendSmsSuccess.localString(context));
      timer = 60;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          this.timer--;
          if (this.timer == 0) {
            timer.cancel();
          }
        });
      });
    } else {
      EasyLoading.showError(
          DemoLocalizations.sendSmsFailed.localString(context));
    }
    return;
  }

  void login() async {
    if (!checkout()) return;

    if (codeController.text.isEmpty) {
      EasyLoading.showInfo(
          DemoLocalizations.loginPleaseInputSms.localString(context));
      return;
    }

    EasyLoading.show(status: DemoLocalizations.loggingIn.localString(context));
    Future(() async {
      try {
        LoginUserData data = await AppServerHelper.login(
          phoneController.text,
          codeController.text,
        );

        await ChatUIKit.instance.loginWithToken(
          userId: data.userId,
          token: data.token,
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
