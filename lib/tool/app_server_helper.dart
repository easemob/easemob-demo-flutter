import 'dart:math';

import 'package:chat_uikit_demo/demo_config.dart';
import 'package:dio/dio.dart';

import 'package:flutter/foundation.dart';

class AppServerHelper {
  // 发送验证码
  static Future<void> sendSmsCodeRequest(String phone) async {
    if (!DemoConfig.isValid) {
      throw Exception('DemoConfig is not valid');
    }
    String url = '${DemoConfig.serverUrl!}/inside/app/sms/send/$phone';
    Response response = await Dio().post(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to send sms code: ${response.statusCode}');
    }
  }

  // 根据验证码获取登录信息
  static Future<LoginUserData> login(String phone, String smsCode) async {
    if (!DemoConfig.isValid) {
      throw Exception('DemoConfig is not valid');
    }
    String url = '${DemoConfig.serverUrl!}/inside/app/user/login/V2';
    Response response = await Dio().post(url, data: {
      'phoneNumber': phone,
      'smsCode': smsCode,
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to login: ${response.statusCode}');
    }
    return LoginUserData.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // 上传头像
  static Future<String> uploadAvatar(
      String currentUserId, String avatarPath) async {
    if (!DemoConfig.isValid) {
      throw Exception('DemoConfig is not valid');
    }
    debugPrint('uploadAvatar: $currentUserId, $avatarPath');
    String url =
        '${DemoConfig.serverUrl!}/inside/app/user/$currentUserId/avatar/upload';
    Map<String, dynamic> entry = {
      'file': await MultipartFile.fromFile(avatarPath)
    };
    Response response = await Dio().post(url, data: FormData.fromMap(entry));
    if (response.statusCode != 200) {
      throw Exception('Failed to uploadAvatar: ${response.statusCode}');
    } else {
      return response.data['avatarUrl'];
    }
  }

  // 获取群组头像
  static Future<String> fetchGroupAvatar(String groupId) async {
    if (!DemoConfig.isValid) {
      throw Exception('DemoConfig is not valid');
    }
    String url = '${DemoConfig.serverUrl!}/inside/app/group/$groupId/avatarurl';
    Response response = await Dio().get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetchGroupAvatar: ${response.statusCode}');
    } else {
      return response.data['avatarUrl'];
    }
  }

  // 自动解散群组
  static Future<void> autoDestroyGroup(String groupId) async {
    if (!DemoConfig.isValid) {
      throw Exception('DemoConfig is not valid');
    }
    String url = '${DemoConfig.serverUrl!}/inside/app/group/$groupId';
    Response response =
        await Dio().post(url, queryParameters: {'appkey': DemoConfig.appKey});
    if (response.statusCode != 200) {
      throw Exception('Failed to auto destroy: ${response.statusCode}');
    }
  }

  // 获取呼叫信息
  static Future<AgoraInfo> fetchAgoraInfo(String userId,
      {String? channelName}) async {
    if (!DemoConfig.isValid) {
      throw Exception('DemoConfig is not valid');
    }
    String url =
        '${DemoConfig.serverUrl!}/inside/token/rtc/channel/${channelName ?? Random().nextInt(99999999)}/user/$userId';
    Response response = await Dio().get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch agora info: ${response.statusCode}');
    }
    AgoraInfo agoraInfo =
        AgoraInfo.fromJson(response.data as Map<String, dynamic>);
    agoraInfo.channelName = channelName;
    return agoraInfo;
  }

  // 获取agora uid 和 user id 的映射信息
  static Future<Map<String, String>> fetchAgoraUidMap(
      String channelName) async {
    if (!DemoConfig.isValid) {
      throw Exception('DemoConfig is not valid');
    }
    String url = '${DemoConfig.serverUrl!}/inside/agora/channel/mapper';
    Response response =
        await Dio().get(url, queryParameters: {'channelName': channelName});
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch agora uid map: ${response.statusCode}');
    }
    /*
    "result": {
        "121006940": "tom",
        "1138437225": "jack"
    }
    */
    Map<String, dynamic> map = response.data['result'];
    Map<String, String> resultMap = {};
    map.forEach((key, value) {
      resultMap[key] = value as String;
    });
    return resultMap;
  }
}

class AgoraInfo {
  AgoraInfo.fromJson(Map<String, dynamic> json)
      : agoraToken = json['accessToken'],
        agoraUid = json['agoraUid'];

  final String agoraToken;
  final String agoraUid;
  String? channelName;
}

// 登录用户信息
class LoginUserData {
  LoginUserData.fromJson(Map<String, dynamic> json)
      : token = json['token'],
        userId = json['chatUserName'],
        avatarUrl = json['avatarUrl'];

  LoginUserData({
    required this.token,
    required this.userId,
    this.avatarUrl,
  });
  final String token;
  final String userId;
  final String? avatarUrl;
}
