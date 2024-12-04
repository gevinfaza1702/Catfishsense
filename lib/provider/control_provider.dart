import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ControlProvider extends ChangeNotifier {
  bool _isrelayPin1On = false;
  bool _isrelayPin2On = false;
  bool _isRPWM1On = false;
  bool _isservoOn = false;
  bool _isManualControlEnabled = true; // Tambahkan state untuk kontrol manual
  bool _isStarted = false; // State for start/stop system

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool get isrelayPin1On => _isrelayPin1On;
  bool get isrelayPin2On => _isrelayPin2On;
  bool get isRPWM1On => _isRPWM1On;
  bool get isservoOn => _isservoOn;
  bool get isManualControlEnabled => _isManualControlEnabled;
  bool get isStarted => _isStarted; // Getter for the start/stop state

  ControlProvider() {
    // Panggil listener saat objek ini dibuat
    _listenToControlData();
  }

  // Fungsi untuk mengaktifkan atau menonaktifkan relayPin1
  void togglePumpIn() {
    if (_isManualControlEnabled) {
      // Hanya jika kontrol manual aktif
      _isrelayPin1On = !_isrelayPin1On;
      _updateFirestore('relayPin1', _isrelayPin1On);
    }
  }

  // Fungsi untuk mengaktifkan atau menonaktifkan relayPin2
  void togglePumpOut() {
    if (_isManualControlEnabled) {
      // Hanya jika kontrol manual aktif
      _isrelayPin2On = !_isrelayPin2On;
      _updateFirestore('relayPin2', _isrelayPin2On);
    }
  }

  // Fungsi untuk mengaktifkan atau menonaktifkan Motor DC
  void toggleMotorDC() {
    if (_isManualControlEnabled) {
      // Hanya jika kontrol manual aktif
      _isRPWM1On = !_isRPWM1On;
      _updateFirestore('RPWM1', _isRPWM1On);
    }
  }

  // Fungsi untuk mengaktifkan atau menonaktifkan Servo
  void toggleServo() {
    if (_isManualControlEnabled) {
      // Hanya jika kontrol manual aktif
      _isservoOn = !_isservoOn;
      _updateFirestore('servo', _isservoOn);
    }
  }

  // Fungsi untuk toggle status kontrol manual
  void toggleManualControl() {
    _isManualControlEnabled = !_isManualControlEnabled;

    if (!_isManualControlEnabled) {
      // Jika kontrol manual dimatikan, matikan semua switch
      _isrelayPin1On = false;
      _isrelayPin2On = false;
      _isRPWM1On = false;
      _isservoOn = false;

      // Update Firestore untuk semua aktuator
      _updateFirestore('relayPin1', _isrelayPin1On);
      _updateFirestore('relayPin2', _isrelayPin2On);
      _updateFirestore('RPWM1', _isRPWM1On);
      _updateFirestore('servo', _isservoOn);
    }

    _updateFirestore('manualControl', _isManualControlEnabled);
    notifyListeners(); // Notify listeners for UI update
  }

  // Fungsi untuk toggle start system
  void toggleStart() {
    _isStarted = true; // Set started to true
    print("Starting system..."); // Logging tambahan
    _updateFirestore('start', _isStarted);
    _updateFirestore('stop', false); // Set stop to OFF when starting
    notifyListeners(); // Notify listeners for UI update
  }

  // Fungsi untuk toggle stop system (mematikan panel)
  void toggleStop() {
    _isStarted = false; // Set started to false
    _isManualControlEnabled = false; // Set manual control to false

    print("Stopping system..."); // Logging tambahan

    // Set all actuators (relay, motor) to OFF
    _isrelayPin1On = false;
    _isrelayPin2On = false;
    _isRPWM1On = false;
    _isservoOn = false;

    // Update Firestore for all actuators
    _updateFirestore('relayPin1', _isrelayPin1On);
    _updateFirestore('relayPin2', _isrelayPin2On);
    _updateFirestore('RPWM1', _isRPWM1On);
    _updateFirestore('servo', _isservoOn);

    // Update Firestore for start/stop status
    _updateFirestore('start', false); // Set start to OFF
    _updateFirestore('stop', true); // Set stop to ON
    _updateFirestore(
        'manualControl', _isManualControlEnabled); // Set manual control to OFF

    notifyListeners(); // Notify UI to update the switches to OFF
    print("System stopped"); // Logging tambahan
  }

  // Fungsi untuk update status ke Firestore
  void _updateFirestore(String controlName, bool status) async {
    // Konversi boolean ke string "ON" atau "OFF"
    String statusString = status ? "ON" : "OFF";

    try {
      await _firestore.collection('Control').doc('ControlManual').set({
        controlName: statusString,
      }, SetOptions(merge: true));
      print("Updated $controlName to Firestore"); // Logging tambahan
    } catch (e) {
      print("Failed to update Firestore: $e"); // Error handling
    }
  }

  // Fungsi untuk mendengarkan perubahan data di Firestore secara real-time
  void _listenToControlData() {
    _firestore.collection('Control').doc('ControlManual').snapshots().listen(
      (snapshot) {
        try {
          if (snapshot.exists) {
            print(
                "Firestore data received: ${snapshot.data()}"); // Logging tambahan

            // Dapatkan data terbaru dari Firestore
            final data = snapshot.data();

            // Konversi nilai string "ON" atau "OFF" menjadi boolean
            _isrelayPin1On = (data?['relayPin1'] ?? "OFF") == "ON";
            _isrelayPin2On = (data?['relayPin2'] ?? "OFF") == "ON";
            _isRPWM1On = (data?['RPWM1'] ?? "OFF") == "ON";
            _isservoOn = (data?['servo'] ?? "OFF") == "ON";

            // Dapatkan status kontrol manual dari Firestore
            _isManualControlEnabled = (data?['manualControl'] ?? "ON") == "ON";

            // Dapatkan status start/stop dari Firestore
            _isStarted = (data?['start'] ?? "OFF") == "ON";

            print(
                "Start: $_isStarted, Stop: ${!_isStarted}"); // Logging tambahan

            // Beritahukan UI untuk memperbarui indikator
            notifyListeners();
          }
        } catch (e) {
          print(
              "Error while listening to Firestore data: $e"); // Error handling
        }
      },
    );
  }
}
