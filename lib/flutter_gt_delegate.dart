//enum SdkStatus {
//  Starting,
//}

abstract class FlutterGtDelegate {
  void GeTuiSdkDidRegisterClient(String clientId);

  void GeTuiSdkDidReceiveMessage(String message);

//  void GeTuiSdkDidReceivePayload(
//      String payload, String taskId, String msgId, bool offLine, String appId);


}
