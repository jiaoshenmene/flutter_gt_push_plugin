import 'dart:async';

import 'package:flutter/services.dart';

import 'flutter_gt_delegate.dart';

typedef Future<dynamic> EventHandler(Map event);

class FlutterGtPushPlugin {
  factory FlutterGtPushPlugin() => _instance;
  final MethodChannel _channel;

  FlutterGtDelegate delegate;

  EventHandler _onOpenNotification;

  FlutterGtPushPlugin.private(MethodChannel channel) : _channel = channel {
    _channel.setMethodCallHandler(_handleMethod);
  }

  setupWithAppID({String appId, String appKey, String appSecret}) {
    _channel.invokeMethod(
        'setup', {'appId': appId, 'appKey': appKey, 'appSecret': appSecret});
  }

  setOpenNotificationHandler(EventHandler onOpenNotification) {
    _onOpenNotification = onOpenNotification;
  }

  Future<Null> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'GeTuiSdkDidRegisterClient':
        delegate.GeTuiSdkDidRegisterClient(call.arguments);
        break;
      case 'GeTuiSdkDidReceivePayload':
        delegate.GeTuiSdkDidReceiveMessage(call.arguments);
        break;
      default:
        throw UnsupportedError('Unrecognized Event');
    }
  }

  static final FlutterGtPushPlugin _instance = FlutterGtPushPlugin.private(
      const MethodChannel('flutter_gt_push_plugin'));

  Future<String> get registrationID async {
    final String regID = await _channel.invokeMethod('getRegistrationID');
    return regID;
  }
}
