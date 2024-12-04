import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Library untuk chart
import 'package:cloud_firestore/cloud_firestore.dart'; // Untuk Firestore
import 'package:intl/intl.dart'; // Untuk format waktu
import 'dart:async'; // Untuk Timer
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Import local notification

class KetinggianPakanPage extends StatefulWidget {
  const KetinggianPakanPage({super.key});

  @override
  State<KetinggianPakanPage> createState() => _KetinggianPakanPageState();
}

class _KetinggianPakanPageState extends State<KetinggianPakanPage> {
  Timer? _dailyTimer; // Timer untuk penjadwalan harian
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();

    // Inisialisasi notifikasi lokal
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    _scheduleDailyRecord(); // Jadwalkan penyimpanan pada 23:59
  }

  @override
  void dispose() {
    _dailyTimer?.cancel(); // Hentikan timer ketika widget dihapus
    super.dispose();
  }

  // Fungsi untuk menampilkan notifikasi
  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0, // ID notifikasi
      title, // Judul notifikasi
      body, // Isi notifikasi
      platformChannelSpecifics, // Pengaturan notifikasi
    );
  }

  void _scheduleDailyRecord() {
    // Setiap detik cek apakah sudah pukul 23:59:50
    _dailyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (now.hour == 23 && now.minute == 59 && now.second == 50) {
        _saveLastRecord(); // Simpan pembacaan terakhir pada 23:59:50
      }
    });
  }

  Future<void> _saveLastRecord() async {
    try {
      var lastRecordSnapshot = await FirebaseFirestore.instance
          .collection('record_data')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (lastRecordSnapshot.docs.isNotEmpty) {
        var lastRecord = lastRecordSnapshot.docs.first.data();
        await FirebaseFirestore.instance.collection('daily_records').add({
          'ketinggianPakan': lastRecord['ketinggianPakan'],
          'timestamp': FieldValue.serverTimestamp(), // Simpan waktu saat ini
          'date':
              DateFormat('yyyy-MM-dd').format(DateTime.now()), // Format tanggal
          'isLastOfDay': true, // Menandai bahwa ini adalah pembacaan terakhir
        });

        print("Pembacaan terakhir berhasil disimpan pada 23:59");
      }
    } catch (e) {
      print("Error saat menyimpan pembacaan terakhir: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF87CEEB), // Background biru halaman
      appBar: AppBar(
        title: const Text('Ketinggian Pakan'),
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
            // Menggunakan Flexible agar gambar dan teks bisa menyesuaikan layar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    flex: 2,
                    child: Image.asset(
                      'assets/images/fish-pet-aquarium.png',
                      height: 150, // Menyesuaikan tinggi gambar
                    ),
                  ),
                  const SizedBox(width: 20), // Jarak antara gambar dan teks

                  // StreamBuilder untuk menampilkan nilai Ketinggian Pakan
                  Flexible(
                    flex: 3,
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('monitoring')
                          .doc('datamonitoring')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          var data =
                              snapshot.data!.data() as Map<String, dynamic>?;
                          var ketinggianPakanValue = data?['ketinggianPakan'] ??
                              "0.00"; // Pastikan selalu ada nilai

                          // Coba konversi ketinggianPakanValue menjadi double
                          double? ketinggianPakanValueAsDouble =
                              double.tryParse(ketinggianPakanValue.toString());

                          // Jika berhasil dikonversi, lakukan perbandingan
                          if (ketinggianPakanValueAsDouble != null &&
                              ketinggianPakanValueAsDouble < 18) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              showNotification("Peringatan Pakan Ikan",
                                  "Pakan Ikan Hampir Habis");
                            });
                          }

                          return Text(
                            'Ketinggian Pakan ${ketinggianPakanValueAsDouble?.toStringAsFixed(1) ?? "0.0"}', // Tampilkan nilai Ketinggian Pakan
                            style: const TextStyle(
                              fontSize: 25,
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
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16.0),

            // Grafik Ketinggian Pakan
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
                      .collection(
                          'record_data') // Pastikan koleksi ini menyimpan data ketinggian pakan
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
                        var ketinggianPakanValue =
                            (data['ketinggianPakan'] as num).toDouble();
                        return FlSpot(
                            (timestamp.second % 10)
                                .toDouble(), // Menggunakan detik dari timestamp
                            ketinggianPakanValue);
                      }).toList();

                      return LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: 10, // Sumbu X dari 0 hingga 10 detik
                          minY: 1,
                          maxY:
                              100, // Sesuaikan skala Y dengan ketinggian pakan maksimal
                          backgroundColor:
                              Colors.white, // Latar belakang putih pada grafik
                          gridData: const FlGridData(show: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              axisNameWidget: const Text('Ketinggian Pakan'),
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