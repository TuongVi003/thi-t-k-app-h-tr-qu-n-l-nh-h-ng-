import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // xử lý message khi app ở background/terminated
  print('Background message: ${message.messageId}');
  // bạn có thể lưu vào DB local hoặc gửi analytics
}
