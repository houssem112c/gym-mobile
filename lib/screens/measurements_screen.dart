import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/progress.dart';
import '../services/progress_service.dart';
import '../services/auth_service.dart';
import '../config/colors.dart';
import '../widgets/gradient_background.dart';

class MeasurementsScreen extends StatefulWidget {
  const MeasurementsScreen({super.key});

  @override
  State<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends State<MeasurementsScreen> {
  final ProgressService _progressService = ProgressService();
  List<UserMeasurement> _measurements = [];
  bool _isLoading = true;

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _bodyFatController = TextEditingController();
  final TextEditingController _waistController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    final token = context.read<AuthService>().accessToken;
    if (token == null) return;
    try {
      final measurements = await _progressService.getMeasurements(token);
      setState(() {
        _measurements = measurements;
        _isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addMeasurement() async {
    final authService = context.read<AuthService>();
    final token = authService.accessToken;

    try {
      await _progressService.addMeasurement(token!, {
        'weight': double.tryParse(_weightController.text),
        'bodyFat': double.tryParse(_bodyFatController.text),
        'waist': double.tryParse(_waistController.text),
      });
      _weightController.clear();
      _bodyFatController.clear();
      _waistController.clear();
      Navigator.pop(context);
      _loadMeasurements();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                  : _buildMeasurementsList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary500,
        child: const Icon(Icons.add_chart, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
          const Text('Body Measurements', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMeasurementsList() {
    if (_measurements.isEmpty) return const Center(child: Text('No records found', style: TextStyle(color: Colors.white)));
    
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _measurements.length,
      itemBuilder: (context, index) {
        final m = _measurements[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.gray800.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gray700.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date: ${m.createdAt.toString().split(' ')[0]}', style: TextStyle(color: AppColors.gray400, fontSize: 12)),
                  const SizedBox(height: 5),
                  Text('${m.weight ?? '-'} kg', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                children: [
                  _buildStatItem('BF', '${m.bodyFat ?? '-'}%'),
                  const SizedBox(width: 20),
                  _buildStatItem('Waist', '${m.waist ?? '-'} cm'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: AppColors.primary400, fontSize: 12, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.gray900,
        title: const Text('Add Measurement', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(_weightController, 'Weight (kg)'),
            _buildTextField(_bodyFatController, 'Body Fat (%)'),
            _buildTextField(_waistController, 'Waist (cm)'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: _addMeasurement, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary500), child: const Text('Save')),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.gray400),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gray700)),
        ),
      ),
    );
  }
}
