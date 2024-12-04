import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DataRecordPage extends StatefulWidget {
  const DataRecordPage({super.key});

  @override
  _DataRecordPageState createState() => _DataRecordPageState();
}

class _DataRecordPageState extends State<DataRecordPage> {
  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;
  List<Map<String, dynamic>> _allData = [];
  List<Map<String, dynamic>> _filteredData = [];

  @override
  void initState() {
    super.initState();
    _fetchDataFromFirestore();
  }

  Future<void> _fetchDataFromFirestore() async {
    var snapshot = await FirebaseFirestore.instance.collection('dataiot').get();

    setState(() {
      _allData = snapshot.docs.map((doc) {
        return {
          'tanggal': (doc['timestamp'] as Timestamp).toDate(),
          'ph': doc['ph'],
          'ketinggian_air': doc['ketinggian_air'],
          'kadar_oksigen': doc['kadar_oksigen'],
          'pakan_ikan': doc['pakan_ikan'],
        };
      }).toList();

      // Mengurutkan data berdasarkan tanggal dari yang paling awal ke paling akhir
      _allData.sort((a, b) => a['tanggal'].compareTo(b['tanggal']));
    });
  }

  void _filterData() {
    if (_selectedFromDate == null || _selectedToDate == null) {
      setState(() {
        _filteredData = [];
      });
    } else {
      setState(() {
        _filteredData = _allData.where((data) {
          DateTime dataDate = data['tanggal'];
          return (dataDate.isAtSameMomentAs(_selectedFromDate!) ||
                  dataDate.isAfter(_selectedFromDate!)) &&
              (dataDate.isAtSameMomentAs(_selectedToDate!) ||
                  dataDate.isBefore(_selectedToDate!));
        }).toList();
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      setState(() {
        if (isFromDate) {
          _selectedFromDate = pickedDate;
        } else {
          _selectedToDate = pickedDate;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Record'),
        backgroundColor: const Color(0xFF6EACDA),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF87CEEB), Color(0xFF4682B4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'From:',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedFromDate != null
                              ? DateFormat('dd-MM-yyyy')
                                  .format(_selectedFromDate!)
                              : '-',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'To:',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedToDate != null
                              ? DateFormat('dd-MM-yyyy')
                                  .format(_selectedToDate!)
                              : '-',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  ElevatedButton(
                    onPressed: _filterData,
                    child: const Text('Filter Data'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_filteredData.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Tidak ada data yang ditampilkan. Silakan pilih tanggal dan tekan "Filter Data".',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        headingRowColor: MaterialStateColor.resolveWith(
                          (states) => const Color.fromARGB(
                              255, 13, 92, 210), // Warna header
                        ),
                        headingTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        dataRowColor: MaterialStateColor.resolveWith(
                          (states) => Colors.white, // Warna baris data
                        ),
                        columns: const [
                          DataColumn(
                            label: Center(child: Text('Tanggal')),
                          ),
                          DataColumn(
                            label: Center(child: Text('pH')),
                          ),
                          DataColumn(
                            label: Center(child: Text('Ketinggian Air')),
                          ),
                          DataColumn(
                            label: Center(child: Text('Kadar Oksigen')),
                          ),
                          DataColumn(
                            label: Center(child: Text('Ketinggian Pakan')),
                          ),
                        ],
                        rows: _filteredData.map((data) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Center(
                                  child: Text(
                                    DateFormat('dd-MM-yyyy')
                                        .format(data['tanggal']),
                                    style: const TextStyle(
                                        color: Colors.black), // Warna teks
                                  ),
                                ),
                              ),
                              DataCell(
                                Center(
                                  child: Text(
                                    data['ph'].toString(),
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                              DataCell(
                                Center(
                                  child: Text(
                                    data['ketinggian_air'].toString(),
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                              DataCell(
                                Center(
                                  child: Text(
                                    data['kadar_oksigen'].toString(),
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                              DataCell(
                                Center(
                                  child: Text(
                                    data['pakan_ikan'].toString(),
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                        dividerThickness: 1.0,
                        dataRowHeight: 36,
                        horizontalMargin: 10,
                        columnSpacing: 15,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
