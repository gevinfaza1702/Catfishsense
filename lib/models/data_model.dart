import 'package:cloud_firestore/cloud_firestore.dart';

class DataModel {
  DateTime tanggal;
  double ph;
  double ketinggianAir;
  double kadarOksigen;
  double ketinggianIkan;

  DataModel({
    required this.tanggal,
    required this.ph,
    required this.ketinggianAir,
    required this.kadarOksigen,
    required this.ketinggianIkan,
  });

  // Convert from Firestore document
  factory DataModel.fromDocument(DocumentSnapshot doc) {
    return DataModel(
      tanggal: (doc['tanggal'] as Timestamp).toDate(),
      ph: doc['ph'],
      ketinggianAir: doc['ketinggian_air'],
      kadarOksigen: doc['kadar_oksigen'],
      ketinggianIkan: doc['ketinggian_ikan'],
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'tanggal': Timestamp.fromDate(tanggal),
      'ph': ph,
      'ketinggian_air': ketinggianAir,
      'kadar_oksigen': kadarOksigen,
      'ketinggian_ikan': ketinggianIkan,
    };
  }
}
