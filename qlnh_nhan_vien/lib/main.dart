import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:qlnh_nhan_vien/screens/dashboard_screen.dart';
import 'package:qlnh_nhan_vien/screens/login_screen.dart';
import 'package:qlnh_nhan_vien/services/auth_service.dart';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'firebase_background_handler.dart';
import 'package:qlnh_nhan_vien/constants/api.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // local notifications init (Android channel)
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse: (payload) {
    // xử lý tap notification (khi app foreground/local)
    if (payload != null) {

    }
  });

  runApp(MyApp());
}


class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    requestPermission();
    configureListeners();
    getAndRegisterToken();
  }

  void requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    print('User granted permission: ${settings.authorizationStatus}');
  }

  void configureListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // app foreground
      print('onMessage: ${message.notification?.title}');
      showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // user tap notification -> handle navigation
      print('onMessageOpenedApp: ${message.data}');
      // Navigator.of(context).pushNamed('/order', arguments: message.data);
    });
  }

  void showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notification != null) {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'default_channel',
        'Default',
        channelDescription: 'Default channel',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        platformDetails,
        payload: jsonEncode(message.data),
      );
    }
  }

  void getAndRegisterToken() async {
    try {
      String? token = await _messaging.getToken();
      print('FCM token: $token');
      if (token != null) {
        await registerTokenToBackend(token);
      }

      // lắng nghe khi token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        registerTokenToBackend(newToken);
      });
    } catch (e) {
      print('Token error: $e');
    }
  }

  Future<void> registerTokenToBackend(String token) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}/api/fcm-token/');
    // nếu cần auth, gửi Bearer token
    final response = await http.post(uri,
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer <user_jwt>'
        },
        body: jsonEncode({'token': token}));
    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Token registered on backend');
    } else {
      print('Register token failed: ${response.statusCode} ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lý Nhà Hàng - Nhân Viên',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'), // Vietnamese
        Locale('en', 'US'), // English
      ],
      locale: const Locale('vi', 'VN'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        
        // AppBar Theme
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
        
        // Card Theme
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        
        // Elevated Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        
        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color(0xFF2E7D32),
              width: 2,
            ),
          ),
        ),
        
        // Bottom Navigation Bar Theme
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFF2E7D32),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
        
        // FloatingActionButton Theme
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
      ),
      home: const LoginScreen(),
    );
  }

}




class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Hiển thị splash screen trong khi kiểm tra auth
          return const SplashScreen();
        }
        
        if (snapshot.hasData && snapshot.data == true) {
          // User đã đăng nhập, hiển thị dashboard
          return const DashboardScreen();
        } else {
          // User chưa đăng nhập, hiển thị login screen
          return const LoginScreen();
        }
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant,
                color: Color(0xFF2E7D32),
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Quản Lý Nhà Hàng',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ứng dụng nhân viên',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
