import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'provider/auth_provider.dart';
import 'provider/control_provider.dart';
import 'view/login_page.dart';
import 'view/register_page.dart';
import 'view/dashboard_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Import local notification

// Inisialisasi untuk notifikasi lokal
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inisialisasi pengaturan untuk notifikasi Android
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  // Inisialisasi plugin notifikasi
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()), // AuthProvider
        ChangeNotifierProvider(
            create: (_) => ControlProvider()), // ControlProvider
      ],
      child: MaterialApp(
        title: 'Catfish Sense',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const AuthChecker(), // Ganti initialRoute dengan AuthChecker
        routes: {
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/dashboard': (context) => const DashboardPage(),
        },
      ),
    );
  }
}

// Tambahkan widget AuthChecker
class AuthChecker extends StatelessWidget {
  const AuthChecker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Provider.of<AuthProvider>(context, listen: false).autoLogin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Tampilkan loading sementara menunggu proses login
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          // Jika sudah ada status login, cek apakah pengguna sudah login atau belum
          final isLoggedIn =
              Provider.of<AuthProvider>(context, listen: false).user != null;
          if (isLoggedIn) {
            return const DashboardPage(); // Arahkan ke dashboard jika sudah login
          } else {
            return const LoginPage(); // Arahkan ke halaman login jika belum login
          }
        }
      },
    );
  }
}

// Fungsi untuk menampilkan notifikasi lokal
Future<void> showNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails('your_channel_id', 'your_channel_name',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker');
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0, // ID notifikasi
    title, // Judul notifikasi
    body, // Isi notifikasi
    platformChannelSpecifics, // Pengaturan notifikasi
  );
}
