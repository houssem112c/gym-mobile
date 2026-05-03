import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/progress.dart';
import '../models/workout.dart';
import '../services/progress_service.dart';
import '../services/workout_service.dart';
import '../services/auth_service.dart';
import '../config/colors.dart';
import '../widgets/gradient_background.dart';

class PersonalRecordsScreen extends StatefulWidget {
  const PersonalRecordsScreen({super.key});

  @override
  State<PersonalRecordsScreen> createState() => _PersonalRecordsScreenState();
}

class _PersonalRecordsScreenState extends State<PersonalRecordsScreen> {
  final ProgressService _progressService = ProgressService();
  final WorkoutService _workoutService = WorkoutService();
  List<UserPR> _prs = [];
  List<Exercise> _exercises = [];
  bool _isLoading = true;

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  String? _selectedExerciseId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final token = context.read<AuthService>().accessToken;
    if (token == null) return;
    try {
      final prs = await _progressService.getPRs(token);
      final exercises = await _workoutService.getExercises();
      setState(() {
        _prs = prs;
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addPR() async {
    if (_selectedExerciseId == null) return;
    final token = context.read<AuthService>().accessToken;

    try {
      await _progressService.addPR(token!, {
        'exerciseId': _selectedExerciseId,
        'weight': double.tryParse(_weightController.text) ?? 0,
        'reps': int.tryParse(_repsController.text) ?? 1,
      });
      Navigator.pop(context);
      _loadData();
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
                  : _buildPRList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary500,
        child: const Icon(Icons.star, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
          const Text('Personal Records', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPRList() {
    if (_prs.isEmpty) return const Center(child: Text('No PRs recorded yet', style: TextStyle(color: Colors.white)));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _prs.length,
      itemBuilder: (context, index) {
        final pr = _prs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.gray800.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gray700.withOpacity(0.5)),
          ),
          child: ListTile(
            leading: const Icon(Icons.emoji_events, color: Colors.amber, size: 30),
            title: Text(pr.exercise?.name ?? 'Exercise', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('Recorded on ${pr.createdAt.toString().split(' ')[0]}', style: TextStyle(color: AppColors.gray400, fontSize: 12)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${pr.weight} kg', style: const TextStyle(color: AppColors.primary500, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${pr.reps} reps', style: TextStyle(color: AppColors.gray400, fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.gray900,
          title: const Text('Add New PR', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: _selectedExerciseId,
                hint: const Text('Select Exercise', style: TextStyle(color: Colors.white)),
                dropdownColor: AppColors.gray800,
                isExpanded: true,
                items: _exercises.map((e) => DropdownMenuItem(
                  value: e.id,
                  child: Text(e.name, style: const TextStyle(color: Colors.white)),
                )).toList(),
                onChanged: (val) => setState(() => _selectedExerciseId = val),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: 'Weight (kg)', labelStyle: TextStyle(color: AppColors.gray400)),
              ),
              TextField(
                controller: _repsController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: 'Reps', labelStyle: TextStyle(color: AppColors.gray400)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(onPressed: _addPR, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary500), child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
