import 'package:flutter/material.dart';

/// Visual bar showing power utilization (used/total watts) as a colored progress bar.
/// Green when <90%, red when >=90%. Shows percentage label.
class CapacityGauge extends StatelessWidget {
  final double usedWatts;
  final double totalWatts;

  const CapacityGauge({
    super.key,
    required this.usedWatts,
    required this.totalWatts,
  });

  @override
  Widget build(BuildContext context) {
    final percent = totalWatts > 0 ? (usedWatts / totalWatts) * 100 : 0;
    final isHighUsage = percent >= 90;
    final color = isHighUsage ? Colors.red : Colors.green;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${usedWatts.toStringAsFixed(0)}W / ${totalWatts.toStringAsFixed(0)}W',
              style: const TextStyle(fontSize: 11),
            ),
            Text(
              '${percent.toStringAsFixed(0)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 8,
            backgroundColor: Colors.grey.shade800,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
