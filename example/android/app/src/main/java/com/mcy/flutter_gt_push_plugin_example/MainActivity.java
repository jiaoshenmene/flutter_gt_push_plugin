package com.mcy.flutter_gt_push_plugin_example;

import android.os.Bundle;

import io.flutter.Log;
import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    Log.i("非","启动");
    GeneratedPluginRegistrant.registerWith(this);
  }
}
