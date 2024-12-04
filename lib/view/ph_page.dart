import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Library untuk chart
import 'package:cloud_firestore/cloud_firestore.dart'; // Untuk Firestore
import 'package:intl/intl.dart'; // Untuk format waktu
import 'dart:async'; // Untuk Timer
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Import notifikasi lokal

class PhPage extends StatefulWidget {
  const PhPage({super.key});

  @override
  State<PhPage> createState() => _PhPageState();
}

class _PhPageState extends State<PhPage> {
  Timer? dailyTimer;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin(); // Plugin notifikasi

  @override
  void initState() {
    super.initState();
    _initializeNotifications(); // Inisialisasi notifikasi
    _scheduleDailyRecord(); // Penjadwalan untuk penyimpanan data PH terakhir setiap hari pada 23:59
  }

  @override
  void dispose() {
    dailyTimer?.cancel();
    super.dispose();
  }

  // Inisialisasi notifikasi
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
            '@mipmap/ic_launcher'); // Icon notifikasi Android

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Fungsi untuk menampilkan notifikasi
  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description', // Named argument fix
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0, // ID notifikasi
      title, // Judul notifikasi
      body, // Isi notifikasi
      platformChannelSpecifics,
    );
  }

  // Fungsi untuk menampilkan notifikasi jika PH di luar batas
  void _checkPhAndShowNotification(double phValue) {
    if (phValue < 6.5) {
      _showNotification('PH di Bawah Batas Minimal',
          'PH kurang dari batas minimal: ${phValue.toStringAsFixed(1)}');
    } else if (phValue > 8.5) {
      _showNotification('PH Melebihi Batas Maksimal',
          'PH melebihi batas maksimal: ${phValue.toStringAsFixed(1)}');
    }
  }

  // Fungsi untuk penjadwalan harian
  void _scheduleDailyRecord() {
    // Timer setiap detik untuk mengecek apakah sudah pukul 23:59
    dailyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (now.hour == 23 && now.minute == 59 && now.second == 50) {
        _saveLastPhRecord();
      }
    });
  }

  // Fungsi untuk menyimpan pembacaan PH terakhir
  Future<void> _saveLastPhRecord() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('record_data')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var lastData = snapshot.docs.first.data();
        var phValue = (lastData['pH'] as num).toDouble();

        // Simpan data pembacaan terakhir ke Firestore pada 23:59:50
        await FirebaseFirestore.instance.collection('daily_records').add({
          'pH': phValue,
          'timestamp': FieldValue.serverTimestamp(),
          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        });

        print("Pembacaan PH terakhir hari ini telah disimpan.");
      }
    } catch (e) {
      print("Error saat menyimpan pembacaan PH terakhir: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF87CEEB), // Background biru halaman
      appBar: AppBar(
        title: const Text('PH'),
        backgroundColor: Colors.blue, // Mengatur warna AppBar
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Kembali ke halaman sebelumnya
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Gambar PH Meter dan nilai PH di sampingnya
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/PH-Meter-PNG-Image.png',
                    height: 150, // Menyesuaikan tinggi gambar
                  ),
                  const SizedBox(width: 20), // Jarak antara gambar dan teks

                  // Expanded untuk menghindari overflow
                  Expanded(
                      child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('monitoring')
                        .doc('datamonitoring')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        var data =
                            snapshot.data!.data() as Map<String, dynamic>?;

                        // Menggunakan nilai default jika `pH` adalah null
                        var phValue = double.tryParse(
                                data?['pH']?.toString() ?? '0.00') ??
                            0.00;

                        // Mengecek apakah PH di bawah 6.5 atau di atas 8.5
                        _checkPhAndShowNotification(phValue);

                        return Text(
                          'PH ${phValue.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      } else {
                        return const Text(
                          'Memuat...',
                          style: TextStyle(fontSize: 24),
                        );
                      }
                    },
                  ))
                ],
              ),
            ),

            const SizedBox(height: 16.0),

            // Grafik PH
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                width: double.infinity,
                height: 200, // Sesuaikan tinggi grafik
                decoration: BoxDecoration(
                  color: Colors.white, // Latar belakang putih di dalam grafik
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3), // Shadow position
                    ),
                  ],
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('record_data')
                      .orderBy('timestamp', descending: true)
                      .limit(10)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      var dataDocs = snapshot.data!.docs;
                      List<FlSpot> spots = dataDocs.map((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        var timestamp =
                            (data['timestamp'] as Timestamp).toDate();

                        // Konversi nilai pH dari string ke double jika diperlukan
                        var phValue =
                            double.tryParse(data['pH']?.toString() ?? '0.00') ??
                                0.00;

                        // Tambahkan log untuk debugging
                        print(
                            "pH Value: $phValue, Timestamp: ${timestamp.second}");

                        return FlSpot(
                            (timestamp.second % 10)
                                .toDouble(), // Menggunakan detik dari timestamp
                            phValue);
                      }).toList();

                      return LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: 10, // Sumbu X dari 0 hingga 10 detik
                          minY: 1,
                          maxY: 14, // Sumbu Y dari 1 hingga 14
                          backgroundColor:
                              Colors.white, // Latar belakang putih pada grafik
                          gridData: const FlGridData(show: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              axisNameWidget: const Text('PH'),
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              axisNameWidget: const Text('Waktu (detik)'),
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${value.toInt()} detik',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: const Border(
                              left: BorderSide(color: Colors.black, width: 2),
                              bottom: BorderSide(color: Colors.black, width: 2),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: Colors.blue,
                              dotData: const FlDotData(show: true),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
