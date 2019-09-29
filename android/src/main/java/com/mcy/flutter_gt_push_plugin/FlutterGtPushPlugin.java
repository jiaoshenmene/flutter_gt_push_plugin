package com.mcy.flutter_gt_push_plugin;

import android.app.NotificationManager;

import com.igexin.sdk.PushManager;

import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * FlutterGtPushPlugin
 */
public class FlutterGtPushPlugin implements MethodCallHandler {
    public final Registrar registrar;
    private final MethodChannel channel;
    public static FlutterGtPushPlugin instance;

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
   
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_gt_push_plugin");
        instance = new FlutterGtPushPlugin(registrar, channel);
        channel.setMethodCallHandler(instance);

        PushManager.getInstance().initialize(registrar.activity().getApplicationContext(),
                AppPushService.class);
        PushManager.getInstance().registerPushIntentService(registrar.activity().getApplicationContext(),
                AppMessageReceiverService.class);
    }

    public FlutterGtPushPlugin(Registrar registrar, MethodChannel channel) {
        this.registrar = registrar;
        this.channel = channel;
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {

        if (call.method.equals("setup")) {
            result.success(0);
        } else if (call.method.equals("getRegistrationID")) {
        } else {
            result.notImplemented();
        }
    }

    public void callbackNotificationOpened(String method, Object data) {
        channel.invokeMethod(method, data);
    }
}
