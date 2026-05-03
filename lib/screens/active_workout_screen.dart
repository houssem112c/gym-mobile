import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout.dart';
import '../services/workout_service.dart';
import '../services/auth_service.dart';
import '../config/colors.dart';
import '../widgets/gradient_background.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final WorkoutPlan? plan;
  final WorkoutSession? existingSession;

  const ActiveWorkoutScreen({super.key, this.plan, this.existingSession});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  final WorkoutService _workoutService = WorkoutService();
  late WorkoutSession _session;
  bool _isInit = true;
  int _currentExerciseIndex = 0;
  
  // Timer state
  Timer? _restTimer;
  int _secondsRemaining = 0;
  bool _isResting = false;

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      if (widget.existingSession != null) {
        _session = widget.existingSession!;
      }
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    setState(() {
      _secondsRemaining = seconds;
      _isResting = true;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        setState(() => _isResting = false);
        _showRestCompleteNotification();
      }
    });
  }

  void _showRestCompleteNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rest finished! Get to work! 💪'),
        backgroundColor: AppColors.primary500,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _logSet() async {
    if (_weightController.text.isEmpty || _repsController.text.isEmpty) return;
    
    final auth = context.read<AuthService>();
    final exercise = widget.plan!.exercises[_currentExerciseIndex].exercise;
    
    // Calculate set number
    final existingSets = _session.setLogs.where((s) => s.exerciseId == exercise.id).length;

    try {
      await _workoutService.logSet(auth.accessToken!, _session.id, {
        'exerciseId': exercise.id,
        'setNumber': existingSets + 1,
        'weight': double.parse(_weightController.text),
        'reps': int.parse(_repsController.text),
      });

      // Refresh session
      final updated = await _workoutService.getActiveSession(auth.accessToken!);
      if (updated != null) {
        setState(() => _session = updated);
      }

      _weightController.clear();
      _repsController.clear();
      
      _startRestTimer(60); // Default 60s rest
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _finishWorkout() async {
    final auth = context.read<AuthService>();
    try {
      await _workoutService.completeSession(auth.accessToken!, _session.id, 'Great workout!');
      Navigator.pop(context);
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout Saved! 🏆'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error completing: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.plan == null) return const Scaffold(body: Center(child: Text('No plan selected')));
    
    final currentPlanEx = widget.plan!.exercises[_currentExerciseIndex];
    final exerciseSets = _session.setLogs.where((s) => s.exerciseId == currentPlanEx.exerciseId).toList();

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (_isResting) _buildRestTimer(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildExerciseCard(currentPlanEx),
                      const SizedBox(height: 25),
                      _buildLogInput(),
                      const SizedBox(height: 25),
                      const Text('Session Logs', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      _buildSetLogs(exerciseSets),
                    ],
                  ),
                ),
              ),
              _buildFooter(),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
          Column(
            children: [
              Text(widget.plan!.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('Active Session', style: TextStyle(color: AppColors.primary500, fontSize: 12)),
            ],
          ),
          TextButton(
            onPressed: _finishWorkout,
            child: const Text('Finish', style: TextStyle(color: AppColors.primary500, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: AppColors.primary500.withOpacity(0.2),
      child: Center(
        child: Text(
          'REST: $_secondsRemaining s',
          style: const TextStyle(color: AppColors.primary500, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(WorkoutPlanExercise planEx) {
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
          Row(
            children: [
              if (planEx.exercise.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(planEx.exercise.imageUrl!, width: 60, height: 60, fit: BoxFit.cover),
                ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(planEx.exercise.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('${planEx.sets} Sets • ${planEx.reps} Reps', style: TextStyle(color: AppColors.gray400)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogInput() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(_weightController, 'Weight (kg)', Icons.fitness_center),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildTextField(_repsController, 'Reps', Icons.repeat),
        ),
        const SizedBox(width: 15),
        GestureDetector(
          onTap: _logSet,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primary500, borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.add, color: Colors.white, size: 30),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.gray400, size: 20),
        labelText: label,
        labelStyle: TextStyle(color: AppColors.gray400),
        filled: true,
        fillColor: AppColors.gray800.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildSetLogs(List<SetLog> sets) {
    if (sets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Text('No sets logged yet.', style: TextStyle(color: AppColors.gray400))),
      );
    }
    return Column(
      children: sets.map((s) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: AppColors.gray800.withOpacity(0.3), borderRadius: BorderRadius.circular(15)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text('Set ${s.setNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                if (s.isPersonalRecord)
                  Container(
                    margin: const EdgeInsets.only(left: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(5)),
                    child: const Text('PR', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            Text('${s.weight} kg x ${s.reps}', style: const TextStyle(color: AppColors.primary500)),
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildFooter() {
    final isLast = _currentExerciseIndex == widget.plan!.exercises.length - 1;
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentExerciseIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentExerciseIndex--),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 55),
                  side: const BorderSide(color: AppColors.gray700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('Back', style: TextStyle(color: Colors.white)),
              ),
            ),
          if (_currentExerciseIndex > 0) const SizedBox(width: 15),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isLast ? _finishWorkout : () => setState(() => _currentExerciseIndex++),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                minimumSize: const Size(0, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Text(isLast ? 'COMPLETE WORKOUT' : 'NEXT EXERCISE', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
