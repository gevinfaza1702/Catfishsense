import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Library untuk chart
import 'package:cloud_firestore/cloud_firestore.dart'; // Untuk Firestore
import 'package:intl/intl.dart'; // Untuk format waktu
import 'dart:async'; // Untuk Timer

class KadarOksigenPage extends StatefulWidget {
  const KadarOksigenPage({super.key});

  @override
  State<KadarOksigenPage> createState() => _KadarOksigenPageState();
}

class _KadarOksigenPageState extends State<KadarOksigenPage> {
  Timer? dailyTimer;

  @override
  void initState() {
    super.initState();
    _scheduleDailyRecord(); // Penjadwalan untuk penyimpanan data oksigen terakhir setiap hari pada 23:59
  }

  @override
  void dispose() {
    dailyTimer?.cancel();
    super.dispose();
  }

  // Fungsi untuk penjadwalan harian
  void _scheduleDailyRecord() {
    // Timer setiap detik untuk mengecek apakah sudah pukul 23:59
    dailyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (now.hour == 23 && now.minute == 59 && now.second == 50) {
        _saveLastOksigenRecord();
      }
    });
  }

  // Fungsi untuk menyimpan pembacaan oksigen terakhir
  Future<void> _saveLastOksigenRecord() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('record_data')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var lastData = snapshot.docs.first.data();
        var oksigenValue = (lastData['oksigen'] as num).toDouble();

        // Simpan data pembacaan terakhir ke Firestore pada 23:59:50
        await FirebaseFirestore.instance.collection('daily_records').add({
          'oksigen': oksigenValue,
          'timestamp': FieldValue.serverTimestamp(),
          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        });

        print("Pembacaan kadar oksigen terakhir hari ini telah disimpan.");
      }
    } catch (e) {
      print("Error saat menyimpan pembacaan kadar oksigen terakhir: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF87CEEB), // Background biru halaman
      appBar: AppBar(
        title: const Text('Kadar Oksigen'),
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
            // Gambar Oksigen Meter dan nilai oksigen di bawah tulisan
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    flex: 2,
                    child: Image.asset(
                      'assets/images/Pngtreeoxygen_molecule_illustration_design_in_8647358.png',
                      height: 150, // Menyesuaikan tinggi gambar
                    ),
                  ),
                  const SizedBox(width: 20), // Jarak antara gambar dan teks

                  // Kolom untuk tulisan "Kadar Oksigen" dan nilai oksigen di bawahnya
                  Flexible(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kadar Oksigen',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // StreamBuilder untuk menampilkan nilai Kadar Oksigen
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('monitoring')
                              .doc('datamonitoring')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              var data = snapshot.data!.data()
                                  as Map<String, dynamic>?;
                              var oksigenValue = data?['oksigen'] ??
                                  0.00; // Nilai oksigen dari Firestore
                              return Text(
                                oksigenValue.toStringAsFixed(
                                    1), // Tampilkan nilai kadar oksigen
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
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16.0),

            // Grafik Kadar Oksigen
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
                        var oksigenValue = double.tryParse(
                                data['doValue']?.toString() ?? '0.00') ??
                            0.00;
                        return FlSpot(
                            (timestamp.second % 10)
                                .toDouble(), // Menggunakan detik dari timestamp
                            oksigenValue);
                      }).toList();

                      return LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: 10, // Sumbu X dari 0 hingga 10 detik
                          minY: 1,
                          maxY:
                              14, // Sumbu Y dari 1 hingga 14 (sesuaikan dengan kadar oksigen)
                          backgroundColor:
                              Colors.white, // Latar belakang putih pada grafik
                          gridData: const FlGridData(show: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              axisNameWidget: const Text('Kadar Oksigen'),
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
