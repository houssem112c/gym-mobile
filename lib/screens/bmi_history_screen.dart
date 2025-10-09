import 'package:flutter/material.dart';
import '../models/bmi.dart';
import '../services/bmi_service.dart';

class BmiHistoryScreen extends StatefulWidget {
  final BmiService bmiService;
  const BmiHistoryScreen({Key? key, required this.bmiService}) : super(key: key);

  @override
  State<BmiHistoryScreen> createState() => _BmiHistoryScreenState();
}

class _BmiHistoryScreenState extends State<BmiHistoryScreen> {
  late Future<List<BmiRecord>> _futureRecords;

  @override
  void initState() {
    super.initState();
    _futureRecords = widget.bmiService.getUserBmiRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BMI History')),
      body: FutureBuilder<List<BmiRecord>>(
        future: _futureRecords,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No BMI records found.'));
          }
          final records = snapshot.data!;
          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, i) {
              final r = records[i];
              return Card(
                color: r.status == BmiStatus.ok
                    ? Colors.green[50]
                    : r.status == BmiStatus.caution
                        ? Colors.yellow[50]
                        : Colors.red[50],
                child: ListTile(
                  title: Text('BMI: ${r.bmiValue.toStringAsFixed(2)}'),
                  subtitle: Text('Category: ${r.category}\nDate: ${r.createdAt.toLocal().toString().split(" ")[0]}'),
                  trailing: Text(r.status.name.toUpperCase()),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
