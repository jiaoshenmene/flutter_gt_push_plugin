import 'dart:async';

import 'package:flutter/services.dart';

typedef Future<dynamic> EventHandler(String event);

class FlutterGtPushPlugin {
  factory FlutterGtPushPlugin() => _instance;
  final MethodChannel _channel;

  EventHandler _onOpenNotification;

  FlutterGtPushPlugin.private(MethodChannel channel) : _channel = channel {
    _channel.setMethodCallHandler(_handleMethod);
  }

  setupWithAppID(String appID) {
    _channel.invokeMethod('setup', appID);
  }

  setOpenNotificationHandler(EventHandler onOpenNotification) {
    _onOpenNotification = onOpenNotification;
  }

  Future<Null> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'onOpenNotification':
        return _onOpenNotification(call.arguments);
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

//  static const MethodChannel _channel =
//      const MethodChannel('flutter_gt_push_plugin');
//
//  static Future<String> get platformVersion async {
//    final String version = await _channel.invokeMethod('getPlatformVersion');
//    return version;
//  }
}
