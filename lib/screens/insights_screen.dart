import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/colors.dart';
import '../widgets/gradient_background.dart';
import '../services/progress_service.dart';
import '../services/auth_service.dart';
import '../models/progress.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final ProgressService _progressService = ProgressService();
  bool _isLoading = true;
  List<UserMeasurement> _measurements = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthService>();
    try {
      final data = await _progressService.getMeasurements(auth.accessToken!);
      setState(() {
        _measurements = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary500))
                    : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Training Insights',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_measurements.isEmpty) {
      return Center(
        child: Text('Add measurements to see charts!', style: TextStyle(color: AppColors.gray400)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChartCard(
            'Weight Trend',
            'Progress over time (kg)',
            _getWeightSpots(),
          ),
          const SizedBox(height: 20),
          _buildChartCard(
            'Body Fat Trend',
            'Estimated percentage (%)',
            _getBodyFatSpots(),
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  List<FlSpot> _getWeightSpots() {
    final sorted = List<UserMeasurement>.from(_measurements)..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value.weight ?? 0).toDouble());
    }).toList();
  }

  List<FlSpot> _getBodyFatSpots() {
     final sorted = List<UserMeasurement>.from(_measurements)..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value.bodyFat ?? 0).toDouble());
    }).toList();
  }

  Widget _buildChartCard(String title, String subtitle, List<FlSpot> spots, {Color color = AppColors.primary500}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.gray800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.gray700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(subtitle, style: TextStyle(color: AppColors.gray400, fontSize: 12)),
          const SizedBox(height: 30),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 4,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
