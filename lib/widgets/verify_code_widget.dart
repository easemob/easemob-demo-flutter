// ignore_for_file: unused_local_variable

import 'dart:io';

import 'package:chat_uikit_demo/demo_config.dart';
import 'package:em_chat_uikit/chat_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:async';

/// 显示验证码弹窗
Future<bool?> showVerifyCode(
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
  InAppWebViewController? _controller;

  bool isLoaded = false;
  Map<String, dynamic>? verifyResult;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isAndroid = Platform.isAndroid;

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
              child: Stack(
                children: [
                  InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri(
                        "${DemoConfig.verifyCodeURL}?telephone=${widget.phoneNumber}",
                      ),
                    ),
                    initialSettings: InAppWebViewSettings(
                      initialScale: 1,
                      useWideViewPort: true,
                      horizontalScrollBarEnabled: false,
                      verticalScrollBarEnabled: false,
                      // 禁用所有缩放相关功能
                      supportZoom: isAndroid ? false : true,
                      builtInZoomControls: false,
                      displayZoomControls: false,
                      javaScriptEnabled: true,
                      transparentBackground: true,
                      disableVerticalScroll: true,
                      // 禁用长按菜单
                      disableContextMenu: true,
                      disallowOverScroll: true,
                      overScrollMode: OverScrollMode.NEVER,
                    ),
                    onWebViewCreated: onWebViewCreated,
                    onLoadStop: (controller, url) {
                      if (mounted) setState(() => isLoaded = true);
                    },
                    onReceivedError: (controller, request, error) {
                      if (mounted) {
                        Navigator.pop(context, false);
                      }
                    },
                  ),
                  if (!isLoaded)
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void onWebViewCreated(InAppWebViewController controller) {
    _controller = controller;
    controller.addJavaScriptHandler(
      handlerName: 'encryptData',
      callback: encryptData,
    );
    controller.addJavaScriptHandler(
      handlerName: 'getVerifyResult',
      callback: getVerifyResult,
    );
    controller.addJavaScriptHandler(
      handlerName: 'jsErrorChannel',
      callback: (arguments) {
        jsErrorChannel(arguments[0]);
      },
    );
  }

  /// 加密数据并通过 JS 回调 window.encryptCallback 传递结果，生命周期安全
  Future<void> encryptData(List<dynamic> message) async {
    try {
      final base64Key = DemoConfig.verifyCodeSecret!;
      if (message.isNotEmpty) {
        final encryptedData = AESGCMEncryptor.encryptGCM(message[0], base64Key);
        debugPrint('[Dart->JS] 加密数据: $encryptedData');
        if (mounted && _controller != null) {
          await _controller!.callAsyncJavaScript(functionBody: '''
            if (typeof window.encryptCallback === 'function') {
              window.encryptCallback('$encryptedData');
            }
          ''');
        }
        return;
      }
    } catch (e) {
      debugPrint('加密处理失败: $e');
      if (mounted && _controller != null) {
        await _controller!.callAsyncJavaScript(
          functionBody:
              "if (typeof window.encryptCallback === 'function') { window.encryptCallback(''); }",
        );
      }
      return;
    }
    if (mounted && _controller != null) {
      await _controller!.callAsyncJavaScript(
        functionBody:
            "if (typeof window.encryptCallback === 'function') { window.encryptCallback(''); }",
      );
    }
  }

  /// 处理验证码回调
  void getVerifyResult(List<dynamic> info) {
    String message = info[0];
    try {
      Map<String, dynamic> decoded;
      try {
        // 尝试标准JSON解析
        decoded = json.decode(message);
      } catch (_) {
        final fixed = message
            .replaceAllMapped(
                RegExp(r'([{	,])(\w+):'), (m) => '${m[1]}"${m[2]}":')
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

  void jsErrorChannel(List<dynamic> info) {
    String message = info[0];
    debugPrint('[JS->Dart] 处理 JS 错误回调 jsErrorChannel，内容: $message');
    debugPrint('收到 JS 错误: $message');
    // 你可以在这里弹窗、上报日志等
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
