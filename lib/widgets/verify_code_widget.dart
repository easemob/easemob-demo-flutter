// ignore_for_file: unused_local_variable

import 'package:chat_uikit_demo/demo_config.dart';
import 'package:em_chat_uikit/chat_uikit.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;

/// 显示验证码弹窗
Future<bool> showVerifyCode(
  BuildContext context,
  String phoneNumber,
) async {
  return await showDialog(
    context: context,
    builder: (context) => SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: VerifyCodeWidget(phoneNumber: phoneNumber),
      ),
    ),
  );
}

/// 验证码组件
class VerifyCodeWidget extends StatefulWidget {
  const VerifyCodeWidget({
    super.key,
    required this.phoneNumber,
  });

  final String phoneNumber;

  @override
  State<VerifyCodeWidget> createState() => _VerifyCodeWidgetState();
}

class _VerifyCodeWidgetState extends State<VerifyCodeWidget> {
  late WebViewController controller;
  bool isLoaded = false;
  Map<String, dynamic>? verifyResult;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  /// 初始化WebView控制器
  void _initializeWebView() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(_createNavigationDelegate())
      ..addJavaScriptChannel(
        'encryptData',
        onMessageReceived: (message) => encryptData(message.message),
      )
      ..addJavaScriptChannel(
        'getVerifyResult',
        onMessageReceived: (message) => getVerifyResult(message.message),
      )
      ..addJavaScriptChannel(
        'jsErrorChannel',
        onMessageReceived: (message) => jsErrorChannel(message.message),
      )
      ..loadRequest(
        Uri.parse(
          "${DemoConfig.verifyCodeURL}?telephone=${widget.phoneNumber}",
        ),
      );
  }

  /// 创建导航代理
  NavigationDelegate _createNavigationDelegate() {
    return NavigationDelegate(
      onPageFinished: (url) async {
        if (mounted) {
          setState(() => isLoaded = true);
        }
      },
      onWebResourceError: (error) {
        debugPrint('页面加载错误: ${error.description}');
        if (mounted) setState(() {});
      },
    );
  }

  /// 处理加密数据请求（与安卓端一致：收到JS端encryptData请求后，加密并通过window.encryptCallback回传结果）
  void encryptData(String message) {
    try {
      final base64Key = DemoConfig.verifyCodeSecret!;
      if (message.isNotEmpty) {
        final encryptedData = AESGCMEncryptor.encryptGCM(message, base64Key);
        debugPrint('[Dart->JS] 加密数据: $encryptedData');
        // Flutter端与安卓端一致：加密完成后通过JS回调window.encryptCallback
        controller.runJavaScript('''
          if (typeof window.encryptCallback === 'function') {
            window.encryptCallback('$encryptedData');
          }
        ''');
        debugPrint("加密成功，数据长度: ${encryptedData.length}");
      }
    } catch (e) {
      debugPrint('加密处理失败: $e');
      // 加密失败时，回传空字符串给页面
      controller.runJavaScript("window.encryptCallback('')");
    }
  }

  /// 处理验证码回调
  void getVerifyResult(String message) {
    try {
      debugPrint('[JS->Dart] 处理验证码回调 getVerifyResult，内容: $message');
      debugPrint('收到验证结果: $message');
      Map<String, dynamic> decoded;
      try {
        // 尝试标准JSON解析
        decoded = json.decode(message);
      } catch (_) {
        // 兼容伪JSON格式：{errorInfo: , code: 200.0}
        final fixed = message
            .replaceAllMapped(
                RegExp(r'([{\s,])(\w+):'), (m) => '${m[1]}"${m[2]}":')
            .replaceAllMapped(RegExp(r':\s*([^",}{\\s][^,}{]*)'),
                (m) => ': "${m[1]?.trim()}"')
            .replaceAll("'", '"');
        decoded = json.decode(fixed);
      }

      final code = decoded['code'];
      if (code == 200 || code == '200' || code == '200.0' || code == 200.0) {
        Navigator.pop(context, true);
      } else {
        Navigator.pop(context, false);
      }

      setState(() {
        verifyResult = decoded;
      });
    } catch (e) {
      debugPrint('解析验证码回调失败: $e, message: $message');
    }
  }

  void jsErrorChannel(String message) {
    debugPrint('[JS->Dart] 处理 JS 错误回调 jsErrorChannel，内容: $message');
    debugPrint('收到 JS 错误: $message');
    // 你可以在这里弹窗、上报日志等
  }

  @override
  void dispose() {
    controller.clearCache();
    controller.clearLocalStorage();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChatUIKitTheme.instance;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: InkWell(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
            decoration: BoxDecoration(
              color: theme.color.isDark
                  ? theme.color.neutralColor1
                  : theme.color.neutralColor98,
              borderRadius: BorderRadius.circular(10),
            ),
            height: 150,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: isLoaded
                  ? WebViewWidget(controller: controller)
                  : Center(
                      child: CircularProgressIndicator(
                        color: theme.color.isDark
                            ? theme.color.primaryColor6
                            : theme.color.primaryColor5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// AES/GCM/NoPadding 加密解密工具，与安卓端 AESEncryptor 兼容
class AESGCMEncryptor {
  /// 使用 base64Key 进行 AES/GCM/NoPadding 加密，返回 (IV+密文+tag) 的 base64 字符串
  static String encryptGCM(String plainText, String base64Key) {
    final key = encrypt.Key(base64.decode(base64Key));
    final iv = encrypt.IV.fromSecureRandom(12); // 12字节IV
    final encrypter =
        encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    // 拼接IV和密文（encrypt库的bytes已包含tag）
    final combined = iv.bytes + encrypted.bytes;
    return base64.encode(combined);
  }

  /// 使用 base64Key 进行 AES/GCM/NoPadding 解密，输入为 (IV+密文+tag) 的 base64 字符串
  static String decryptGCM(String base64Cipher, String base64Key) {
    final key = encrypt.Key(base64.decode(base64Key));
    final combined = base64.decode(base64Cipher);
    final iv = encrypt.IV(combined.sublist(0, 12));
    final cipherBytes = combined.sublist(12);
    final encrypter =
        encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
    final encrypted = encrypt.Encrypted(cipherBytes);
    return encrypter.decrypt(encrypted, iv: iv);
  }
}
