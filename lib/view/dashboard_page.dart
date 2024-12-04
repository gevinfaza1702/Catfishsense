import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:catfishsense1/provider/control_provider.dart';
import 'profile_page.dart';
import 'datarecord_page.dart';
import '../widgets/dashboard_widgets/dashboard_header.dart';
import '../widgets/dashboard_widgets/monitoring_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  // Tambahan: inisialisasi plugin notifikasi
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications(); // Inisialisasi notifikasi
  }

  // Fungsi untuk inisialisasi notifikasi
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Fungsi untuk menampilkan notifikasi
  Future<void> _showNotification(int id, String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'dashboard_channel_id',
      'Dashboard Alerts',
      channelDescription: 'Notifications for Dashboard Alerts',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  // Fungsi untuk memeriksa kondisi pH dan menampilkan notifikasi
  void _checkPhCondition(double phValue) {
    if (phValue < 6.5) {
      _showNotification(
          1, 'PH di Bawah Batas', 'PH: ${phValue.toStringAsFixed(1)}');
    } else if (phValue > 8.5) {
      _showNotification(
          1, 'PH Melebihi Batas', 'PH: ${phValue.toStringAsFixed(1)}');
    }
  }

  // Fungsi untuk memeriksa kondisi Ketinggian Pakan di bawah 18 cm
  void _checkKetinggianPakanCondition(double ketinggianPakan) {
    if (ketinggianPakan < 18) {
      _showNotification(2, 'Ketinggian Pakan di Bawah Batas',
          'Ketinggian Pakan: ${ketinggianPakan.toStringAsFixed(1)} cm');
    }
  }

  // Fungsi untuk memeriksa kondisi Ketinggian Air dan menampilkan notifikasi
  void _checkKetinggianAirCondition(double ketinggianAir) {
    if (ketinggianAir < 20) {
      _showNotification(3, 'Ketinggian Air di Bawah Batas',
          'Ketinggian Air: ${ketinggianAir.toStringAsFixed(1)}');
    } else if (ketinggianAir > 22) {
      _showNotification(3, 'Ketinggian Air Melebihi Batas',
          'Ketinggian Air: ${ketinggianAir.toStringAsFixed(1)}');
    }
  }

  // Fungsi untuk memeriksa kondisi Kadar Oksigen dan menampilkan notifikasi
  void _checkKadarOksigenCondition(double kadarOksigen) {
    if (kadarOksigen < 5) {
      _showNotification(4, 'Kadar Oksigen di Bawah Batas',
          'Kadar Oksigen: ${kadarOksigen.toStringAsFixed(1)}');
    } else if (kadarOksigen > 10) {
      _showNotification(4, 'Kadar Oksigen Melebihi Batas',
          'Kadar Oksigen: ${kadarOksigen.toStringAsFixed(1)}');
    }
  }

  // Fungsi untuk handle perubahan halaman pada navbar
  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF87CEEB),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildDashboardContent(context),
            const ProfilePage(),
            const DataRecordPage(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Data Record',
          ),
        ],
      ),
    );
  }

  // Dashboard content builder
  Widget _buildDashboardContent(BuildContext context) {
    return Container(
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF87CEEB), Color(0xFF4682B4)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DashboardHeader(),
            const SizedBox(height: 20),
            const Text(
              'Monitoring',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Card untuk PH
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('monitoring')
                      .doc('datamonitoring')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      var data = snapshot.data!.data() as Map<String, dynamic>?;
                      var phValue =
                          double.tryParse(data?['pH']?.toString() ?? '0.00') ??
                              0.00;
                      _checkPhCondition(phValue);

                      return MonitoringCard(
                        title: 'PH',
                        width: MediaQuery.of(context).size.width * 0.4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              phValue.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return MonitoringCard(
                        title: 'Loading...',
                        width: MediaQuery.of(context).size.width * 0.4,
                      );
                    }
                  },
                ),

                // Card untuk Ketinggian Pakan
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('monitoring')
                      .doc('datamonitoring2')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      var data = snapshot.data!.data() as Map<String, dynamic>?;
                      var ketinggianPakanValue = double.tryParse(
                              data?['ketinggianPakan']?.toString() ?? '0.00') ??
                          0.00;
                      _checkKetinggianPakanCondition(ketinggianPakanValue);

                      return MonitoringCard(
                        title: 'Ketinggian Pakan',
                        width: MediaQuery.of(context).size.width * 0.4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${ketinggianPakanValue.toStringAsFixed(2)} cm',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return MonitoringCard(
                        title: 'Loading...',
                        width: MediaQuery.of(context).size.width * 0.4,
                      );
                    }
                  },
                ),

                // Card untuk Ketinggian Air
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('monitoring')
                      .doc('datamonitoring')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      var data = snapshot.data!.data() as Map<String, dynamic>?;
                      var ketinggianAirValue = double.tryParse(
                              data?['level']?.toString() ?? '0.00') ??
                          0.00;
                      _checkKetinggianAirCondition(ketinggianAirValue);

                      return MonitoringCard(
                        title: 'Ketinggian Air',
                        width: MediaQuery.of(context).size.width * 0.4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${ketinggianAirValue.toStringAsFixed(2)} cm',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return MonitoringCard(
                        title: 'Loading...',
                        width: MediaQuery.of(context).size.width * 0.4,
                      );
                    }
                  },
                ),

                // Card untuk Kadar Oksigen
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('monitoring')
                      .doc('datamonitoring')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      var data = snapshot.data!.data() as Map<String, dynamic>?;
                      var oksigenValue = double.tryParse(
                              data?['doValue']?.toString() ?? '0.00') ??
                          0.00;
                      _checkKadarOksigenCondition(oksigenValue);

                      return MonitoringCard(
                        title: 'Kadar Oksigen',
                        width: MediaQuery.of(context).size.width * 0.4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${oksigenValue.toStringAsFixed(2)} mg/L',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return MonitoringCard(
                        title: 'Loading...',
                        width: MediaQuery.of(context).size.width * 0.4,
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Kontrol Remote',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Aktifkan Panel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Consumer<ControlProvider>(
                  builder: (context, controlProvider, child) {
                    return Switch(
                      value: controlProvider.isStarted,
                      onChanged: (value) {
                        value
                            ? controlProvider.toggleStart()
                            : controlProvider.toggleStop();
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Aktifkan Kontrol Remote',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Consumer<ControlProvider>(
                  builder: (context, controlProvider, child) {
                    return Switch(
                      value: controlProvider.isManualControlEnabled,
                      onChanged: controlProvider.isStarted
                          ? (value) {
                              controlProvider.toggleManualControl();
                            }
                          : null,
                    );
                  },
                ),
              ],
            ),
            Column(
              children: [
                Consumer<ControlProvider>(
                  builder: (context, controlProvider, child) {
                    return _buildControlCard(
                      context,
                      'Pompa In',
                      'assets/images/water_pump_icon_229881.png',
                      controlProvider.isrelayPin1On,
                      controlProvider.togglePumpIn,
                      false,
                      controlProvider.isManualControlEnabled,
                    );
                  },
                ),
                Consumer<ControlProvider>(
                  builder: (context, controlProvider, child) {
                    return _buildControlCard(
                      context,
                      'Pompa Out',
                      'assets/images/water_pump_icon_229881.png',
                      controlProvider.isrelayPin2On,
                      controlProvider.togglePumpOut,
                      false,
                      controlProvider.isManualControlEnabled,
                    );
                  },
                ),
                Consumer<ControlProvider>(
                  builder: (context, controlProvider, child) {
                    return _buildControlCard(
                      context,
                      'Motor DC',
                      'assets/images/motor_dc.png',
                      controlProvider.isRPWM1On,
                      controlProvider.toggleMotorDC,
                      false,
                      controlProvider.isManualControlEnabled,
                    );
                  },
                ),
                Consumer<ControlProvider>(
                  builder: (context, controlProvider, child) {
                    return _buildControlCard(
                      context,
                      'Servo',
                      'assets/images/servo.png',
                      controlProvider.isservoOn,
                      () async {
                        if (controlProvider.isManualControlEnabled) {
                          controlProvider.toggleServo();
                          await Future.delayed(const Duration(seconds: 5));
                          controlProvider.toggleServo();
                        }
                      },
                      true,
                      controlProvider.isManualControlEnabled,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlCard(BuildContext context, String label, String imagePath,
      bool isActive, Function toggleFunction, bool isButton, bool isEnabled) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isEnabled ? Colors.lightBlue[100] : Colors.grey[400],
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            alignment: const Alignment(-1, 0),
            width: 150,
            height: 150,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                isButton
                    ? ElevatedButton(
                        onPressed: isEnabled ? () => toggleFunction() : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isActive ? Colors.red : Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24.0, vertical: 12.0),
                        ),
                        child: Text(
                          isActive ? 'Nonaktifkan' : 'Aktifkan',
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    : Switch(
                        value: isActive,
                        onChanged:
                            isEnabled ? (value) => toggleFunction() : null,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
