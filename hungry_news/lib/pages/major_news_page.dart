import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MajorNewsPage extends StatelessWidget {
  const MajorNewsPage({super.key});

  String getFormattedDate() {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd MMM yyyy, EEEE, HHmm\'HRS\'').format(now);
    int weekNumber = ((now.day - now.weekday + 10) / 7).floor();
    int totalWeeks = DateTime(now.year, now.month + 1, 0).day ~/ 7;

    return '$formattedDate\nDisplaying news from Week $weekNumber of $totalWeeks\n(${DateFormat('dd MMM yyyy').format(DateTime(now.year, now.month, (weekNumber - 1) * 7 + 1))} - ${DateFormat('dd MMM yyyy').format(DateTime(now.year, now.month, weekNumber * 7))})';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Major News'),
        backgroundColor: Colors.red[800],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0, bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Latest Updates',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              getFormattedDate(),
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[800],
                fontWeight: FontWeight.w500,
              ),
            ),
            Divider(color: Colors.grey[400]),
            const SizedBox(height: 20),
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  'Sample news',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black,
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
