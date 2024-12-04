import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:catfishsense1/models/data_model.dart';

class DataController {
  final CollectionReference _recordCollection =
      FirebaseFirestore.instance.collection('record_data');

  // Get all records from Firestore
  Future<List<DataModel>> getAllRecords() async {
    try {
      QuerySnapshot snapshot = await _recordCollection.get();
      return snapshot.docs.map((doc) => DataModel.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Error fetching records: $e');
    }
  }

  // Add a new record
  Future<void> addRecord(DataModel record) async {
    try {
      await _recordCollection.add(record.toMap());
    } catch (e) {
      throw Exception('Error adding record: $e');
    }
  }

  // Update a record
  Future<void> updateRecord(String docId, DataModel record) async {
    try {
      await _recordCollection.doc(docId).update(record.toMap());
    } catch (e) {
      throw Exception('Error updating record: $e');
    }
  }

  // Delete a record
  Future<void> deleteRecord(String docId) async {
    try {
      await _recordCollection.doc(docId).delete();
    } catch (e) {
      throw Exception('Error deleting record: $e');
    }
  }
}
