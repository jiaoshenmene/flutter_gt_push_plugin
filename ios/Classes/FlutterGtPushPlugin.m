#import "FlutterGtPushPlugin.h"

#import <GTSDK/GeTuiSdk.h>

// iOS10 及以上需导入 UserNotifications.framework
#import <UserNotifications/UserNotifications.h>

@interface FlutterGtPushPlugin () <GeTuiSdkDelegate, UNUserNotificationCenterDelegate>
@property (nonatomic, strong) FlutterMethodChannel *channel;
@property (nonatomic, strong) NSDictionary *launchOpions;

@end

@implementation FlutterGtPushPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter_gt_push_plugin"
            binaryMessenger:[registrar messenger]];
  FlutterGtPushPlugin* instance = [[FlutterGtPushPlugin alloc] init];
  instance.channel = channel;
  [registrar addApplicationDelegate:instance];
  [registrar addMethodCallDelegate:instance
                           channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"setup" isEqualToString:call.method]) {
      NSString *appId = [call.arguments objectForKey:@"appId"];
      NSString *appKey = [call.arguments objectForKey:@"appKey"];
      NSString *appSecret = [call.arguments objectForKey:@"appSecret"];
      [GeTuiSdk startSdkWithAppId:appId appKey:appKey appSecret:appSecret delegate:self];
      
  } else if ([@"getRegistrationID" isEqualToString:call.method]) {
      
  } else {
    result(FlutterMethodNotImplemented);
  }
}
/** 注册 APNs */
- (void)registerRemoteNotification {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionCarPlay)
                          completionHandler:^(BOOL granted, NSError *_Nullable error) {
                              if (!error) {
                                  NSLog(@"request authorization succeeded!");
                              }
                          }];

    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self registerRemoteNotification];
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [GeTuiSdk registerDeviceTokenData:deviceToken];
}

#pragma mark - GeTuiSdkDelegate
/** SDK收到透传消息回调 */
- (void)GeTuiSdkDidReceivePayloadData:(NSData *)payloadData andTaskId:(NSString *)taskId andMsgId:(NSString *)msgId andOffLine:(BOOL)offLine fromGtAppId:(NSString *)appId {
    //收到个推消息
    NSString *payloadMsg = nil;
    if (payloadData) {
        payloadMsg = [[NSString alloc] initWithBytes:payloadData.bytes length:payloadData.length encoding:NSUTF8StringEncoding];
    }
    
    NSString *msg = [NSString stringWithFormat:@"taskId=%@,messageId:%@,payloadMsg:%@%@",taskId,msgId, payloadMsg,offLine ? @"<离线消息>" : @""];
    NSLog(@"\n>>>[GexinSdk ReceivePayload]:%@\n\n", msg);
//    [self.channel invokeMethod:@"GeTuiSdkDidReceivePayload" arguments:@{ @"payload" : payloadMsg,
//        @"taskId" : taskId,
//        @"msgId" : msgId,
//        @"offLine" : [NSNumber numberWithBool:offLine],
//        @"appId" : appId }];
    [self.channel invokeMethod:@"GeTuiSdkDidReceivePayload"
                     arguments:payloadMsg];
}

/** SDK启动成功返回cid */
- (void)GeTuiSdkDidRegisterClient:(NSString *)clientId {
    //个推SDK已注册，返回clientId
    NSLog(@"\n>>>[GeTuiSdk RegisterClient]:%@\n\n", clientId);
    [self.channel invokeMethod:@"GeTuiSdkDidRegisterClient"
                     arguments:clientId];
}

@end
