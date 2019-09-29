import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_gt_push_plugin/flutter_gt_push_plugin.dart';
import 'package:flutter_gt_push_plugin/flutter_gt_delegate.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  GtPushServer _server = GtPushServer();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
      ),
    );
  }
}

class GtPushServer implements FlutterGtDelegate {
  FlutterGtPushPlugin push = FlutterGtPushPlugin();

  GtPushServer() {
    push.setupWithAppID(
        appId: 'pakNhnuVra897u9TQOz7G6',
        appKey: 'bFQzHgCBA17GlCzyEyEy76',
        appSecret: 'U35S7Mh2uL99zhJAh9G4F3');
    push.delegate = this;
  }

  @override
  void GeTuiSdkDidReceiveMessage(String message) {
    print('收到个推消息');
  }

  @override
  void GeTuiSdkDidRegisterClient(String clientId) {
    print('注册个推ID $clientId');
  }
}
