#import "FlutterGtPushPlugin.h"

#import <GTSDK/GeTuiSdk.h>

// iOS10 及以上需导入 UserNotifications.framework
#import <UserNotifications/UserNotifications.h>
#import <PushKit/PushKit.h>

@interface FlutterGtPushPlugin () <GeTuiSdkDelegate, UNUserNotificationCenterDelegate, PKPushRegistryDelegate>
@property (nonatomic, strong) FlutterMethodChannel *channel;
@property (nonatomic, strong) NSDictionary *launchOpions;

@end

@implementation FlutterGtPushPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel
        methodChannelWithName:@"flutter_gt_push_plugin"
              binaryMessenger:[registrar messenger]];
    FlutterGtPushPlugin *instance = [[FlutterGtPushPlugin alloc] init];
    instance.channel = channel;
    [registrar addApplicationDelegate:instance];
    [registrar addMethodCallDelegate:instance
                             channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([@"setup" isEqualToString:call.method]) {
        [GeTuiSdk runBackgroundEnable:YES];
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

- (void)voipRegistration {
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    PKPushRegistry *voipRegistry = [[PKPushRegistry alloc] initWithQueue:mainQueue];
    voipRegistry.delegate = self;
    // Set the push type to VoIP
    voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self registerRemoteNotification];
    [self voipRegistration];
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"deviceToken description = %@", [deviceToken description]);
    NSString *deviceTokenString = [self stringWithDeviceToken:deviceToken];

    BOOL result = [GeTuiSdk registerDeviceTokenData:deviceToken];

    NSString *token = [[[[NSString stringWithFormat:@"%@", deviceToken] stringByReplacingOccurrencesOfString:@"<" withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];

    NSLog(@"token = %@", token);

    NSLog(@"The generated device token string is : %@  result = %d", deviceTokenString, result);
}

- (NSString *)stringWithDeviceToken:(NSData *)deviceToken {
    const char *data = [deviceToken bytes];
    NSMutableString *token = [NSMutableString string];

    for (NSUInteger i = 0; i < [deviceToken length]; i++) {
        [token appendFormat:@"%02.2hhX", data[i]];
    }

    return [token copy];
}

- (BOOL)application:(UIApplication *)application performFetchWithCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler {
    [GeTuiSdk resume];
    completionHandler(UIBackgroundFetchResultNewData);
    return YES;
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(nonnull NSError *)error {
    NSString *errorMsg = [NSString stringWithFormat:@"%@: %@", NSStringFromSelector(_cmd), error.localizedDescription];

    // [ 测试代码 ] 日志打印错误信息
    NSLog(@"[ TestDemo ] %@", errorMsg);
}

#pragma mark - GeTuiSdkDelegate
/** SDK收到透传消息回调 */
- (void)GeTuiSdkDidReceivePayloadData:(NSData *)payloadData andTaskId:(NSString *)taskId andMsgId:(NSString *)msgId andOffLine:(BOOL)offLine fromGtAppId:(NSString *)appId {
    //收到个推消息
    NSString *payloadMsg = nil;
    if (payloadData) {
        payloadMsg = [[NSString alloc] initWithBytes:payloadData.bytes length:payloadData.length encoding:NSUTF8StringEncoding];
    }

    NSString *msg = [NSString stringWithFormat:@"taskId=%@,messageId:%@,payloadMsg:%@%@", taskId, msgId, payloadMsg, offLine ? @"<离线消息>" : @""];
    NSLog(@"\n>>>[GexinSdk ReceivePayload]:%@\n\n", msg);

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

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(nonnull UNNotification *)notification withCompletionHandler:(nonnull void (^)(UNNotificationPresentationOptions))completionHandler {
    NSLog(@"willPresentNotification %@", notification.request.content.userInfo);
    completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert);
}
//  iOS 10: 点击通知进入App时触
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(nonnull UNNotificationResponse *)response withCompletionHandler:(nonnull void (^)(void))completionHandler {
    NSLog(@"didReceiveNotificationResponse %@", response.notification.request.content.userInfo);
    [GeTuiSdk handleRemoteNotification:response.notification.request.content.userInfo];
    completionHandler();
}

- (BOOL)application:(UIApplication *)application didReceiveRemoteNotification:(nonnull NSDictionary *)userInfo fetchCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"didReceiveRemoteNotification %@", userInfo);
    [GeTuiSdk handleRemoteNotification:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);

    return YES;
}

- (void)pushRegistry:(nonnull PKPushRegistry *)registry didUpdatePushCredentials:(nonnull PKPushCredentials *)pushCredentials forType:(nonnull PKPushType)type {
    NSString *token = [[[[NSString stringWithFormat:@"%@", pushCredentials.token] stringByReplacingOccurrencesOfString:@"<" withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];

    // [ 测试代码 ] 日志打印DeviceToken
    NSLog(@"[ TestDemo ] [ VoipToken(NSData) ]: %@\n\n", token);

    //向个推服务器注册 VoipToken 为了方便开发者，建议使用新方法
    [GeTuiSdk registerVoipTokenCredentials:pushCredentials.token];
}

- (void)pushRegistry:(PKPushRegistry *)registry
    didReceiveIncomingPushWithPayload:(nonnull PKPushPayload *)payload
                              forType:(nonnull PKPushType)type {

    NSLog(@"type = %d dictionaryPayload = %@", (int)payload.type, payload.dictionaryPayload);
    if (payload.type == PKPushTypeVoIP && payload.dictionaryPayload != nil) {
        NSString *payloadString = [payload.dictionaryPayload objectForKey:@"payload"];
        
        [self.channel invokeMethod:@"didReceiveIncomingPushWithPayload"
        arguments:payload.dictionaryPayload];
        if (payloadString != nil) {
            NSLog(@"payloadString = %@", payloadString);

            NSData *payloadData = [payloadString dataUsingEncoding:NSUTF8StringEncoding];
            NSError *error = nil;
            NSDictionary *payloadDic = [NSJSONSerialization JSONObjectWithData:payloadData options:NSJSONReadingMutableContainers error:&error];
            NSLog(@"payloadDic = %@", payloadDic);
            if (error != nil) {
                NSLog(@"error = %@", error.description);
            }
            NSString *messageString = [payloadDic objectForKey:@"message"];

            NSData *messageData = [messageString dataUsingEncoding:NSUTF8StringEncoding];
            NSArray *messageArray = [NSJSONSerialization JSONObjectWithData:messageData options:NSJSONReadingMutableContainers error:&error];
            NSLog(@"messageDic = %@", messageArray);

            NSDictionary *messageDic = messageArray[0];
            int type = [[messageDic objectForKey:@"type"] intValue];
            if (type == 200) {
                NSString *contentString = [messageDic objectForKey:@"content"];
                NSData *contentData = [contentString dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *contentDic = [NSJSONSerialization JSONObjectWithData:contentData options:NSJSONReadingMutableContainers error:&error];
                NSLog(@"contentDic = %@", contentDic);
                NSString *content = [contentDic objectForKey:@"content"];
//                [self localPush:content];
            }
        }
    }
}

- (void)localPush:(NSString *)text {
    // 使用 UNUserNotificationCenter 来管理通知
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];

    //需创建一个包含待通知内容的 UNMutableNotificationContent 对象，注意不是 UNNotificationContent ,此对象为不可变对象。
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = [NSString localizedUserNotificationStringForKey:@"Flutter IM" arguments:nil];
    content.body = [NSString localizedUserNotificationStringForKey:text
                                                         arguments:nil];
    content.sound = [UNNotificationSound defaultSound];

    // 在 alertTime 后推送本地推送
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger
        triggerWithTimeInterval:3
                        repeats:NO];

    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"FiveSecond" content:content trigger:trigger];

    //添加推送成功后的处理！
    [center addNotificationRequest:request
             withCompletionHandler:^(NSError *_Nullable error) {
                 UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"本地通知" message:@"成功添加推送" preferredStyle:UIAlertControllerStyleAlert];
                 UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
                 [alert addAction:cancelAction];
                 [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
             }];
}


@end
