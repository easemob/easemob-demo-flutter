import 'package:em_chat_uikit/chat_uikit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

Map<PresenceStatus, String> presenceStatusMap = {
  PresenceStatus.online: '',
  PresenceStatus.offline: 'Offline',
  PresenceStatus.away: 'Away',
  PresenceStatus.busy: 'Busy',
  PresenceStatus.notDisturb: 'Do Not Disturb',
};

enum PresenceStatus {
  none,
  online,
  offline,
  away,
  busy,
  notDisturb,
  custom,
}

extension GetPresenceType on Presence {
  PresenceStatus get presenceType {
    if (statusDetails != null) {
      if (statusDetails!.values.any((element) => element == 1)) {
        switch (statusDescription) {
          case '':
            return PresenceStatus.online;
          case 'Away':
            return PresenceStatus.away;
          case 'Busy':
            return PresenceStatus.busy;
          case 'Do Not Disturb':
            return PresenceStatus.notDisturb;
          default:
            return PresenceStatus.custom;
        }
      }
    }
    return PresenceStatus.offline;
  }

  String presenceStr() {
    if (statusDetails!.values.any((element) => element == 1)) {
      switch (statusDescription) {
        case '':
          return 'Online';
        case 'Away':
          return 'Away';
        case 'Busy':
          return 'Busy';
        case 'Do Not Disturb':
          return 'Do Not Disturb';
        default:
          return statusDescription;
      }
    }
    return 'Offline';
  }
}

class OnlineStatusHelper with ConnectObserver, PresenceObserver {
  static OnlineStatusHelper? _instance;

  factory OnlineStatusHelper() {
    return _instance ??= OnlineStatusHelper._internal();
  }

  /// 自己的初始状态
  ValueNotifier onlineStatus = ValueNotifier(PresenceStatus.none);

  OnlineStatusHelper._internal() {
    ChatUIKit.instance.addObserver(this);
    ChatUIKit.instance.isConnect().then((value) {
      onlineStatus.value =
          value ? PresenceStatus.online : PresenceStatus.offline;
    });
  }

  @override
  void onConnected() {
    onlineStatus.value = PresenceStatus.online;
  }

  @override
  void onDisconnected() {
    onlineStatus.value = PresenceStatus.offline;
  }

  @override
  void onUserDidLoginFromOtherDevice(info) {
    onlineStatus.value = PresenceStatus.offline;
  }

  @override
  void onUserDidRemoveFromServer() {
    onlineStatus.value = PresenceStatus.offline;
  }

  @override
  void onUserDidForbidByServer() {
    onlineStatus.value = PresenceStatus.offline;
  }

  @override
  void onUserDidChangePassword() {
    onlineStatus.value = PresenceStatus.offline;
  }

  @override
  void onUserDidLoginTooManyDevice() {
    onlineStatus.value = PresenceStatus.offline;
  }

  @override
  void onUserKickedByOtherDevice() {
    onlineStatus.value = PresenceStatus.offline;
  }

  @override
  void onUserAuthenticationFailed() {
    onlineStatus.value = PresenceStatus.offline;
  }

  @override
  void onTokenDidExpire() {
    onlineStatus.value = PresenceStatus.offline;
  }

  @override
  void onAppActiveNumberReachLimit() {
    onlineStatus.value = PresenceStatus.offline;
  }

  @override
  void onPresenceStatusChanged(List<Presence> list) {
    for (var element in list) {
      if (element.publisher == ChatUIKit.instance.currentUserId) {
        if (element.statusDescription.isNotEmpty == true) {
          onlineStatus.value = element.presenceType;
        } else if (element.statusDetails != null) {
          element.statusDetails!.values.any((element) => element == 1)
              ? onlineStatus.value = PresenceStatus.online
              : onlineStatus.value = PresenceStatus.offline;
        }
      }
    }
  }

  void changeOnlineStatus(PresenceStatus status, {String? custom}) async {
    EasyLoading.show();
    try {
      await ChatUIKit.instance
          .publishPresence(custom ?? presenceStatusMap[status] ?? '');
      onlineStatus.value = status;
    } catch (e) {
      EasyLoading.showError('changeOnlineStatus error: $e');
    } finally {
      EasyLoading.dismiss();
    }
  }
}
