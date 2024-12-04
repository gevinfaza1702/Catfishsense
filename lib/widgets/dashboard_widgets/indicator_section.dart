import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:catfishsense1/provider/control_provider.dart';

class IndicatorSection extends StatelessWidget {
  const IndicatorSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ControlProvider>(
      builder: (context, controlProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.lightBlue[100],
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              buildIndicatorColumn('Pompa In', controlProvider.isrelayPin1On,
                  controlProvider.isManualControlEnabled),
              buildIndicatorColumn('Pompa Out', controlProvider.isrelayPin2On,
                  controlProvider.isManualControlEnabled),
              buildIndicatorColumn('Servo', controlProvider.isservoOn,
                  controlProvider.isManualControlEnabled),
              buildIndicatorColumn('Motor DC', controlProvider.isRPWM1On,
                  controlProvider.isManualControlEnabled),
            ],
          ),
        );
      },
    );
  }

  Widget buildIndicatorColumn(
      String label, bool isActive, bool isManualControlEnabled) {
    Color indicatorColor;

    if (!isActive) {
      indicatorColor = Colors.red; // Mati
    } else if (isManualControlEnabled) {
      indicatorColor = Colors.yellow; // Remote menyala
    } else {
      indicatorColor = Colors.green; // Otomatis menyala
    }

    return Column(
      children: [
        Icon(
          Icons.circle,
          color: indicatorColor,
          size: 30,
        ),
        const SizedBox(height: 5),
        Text(label),
      ],
    );
  }
}
