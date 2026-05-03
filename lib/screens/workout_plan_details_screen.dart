import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../config/colors.dart';
import '../widgets/gradient_background.dart';
import '../services/auth_service.dart';
import '../services/workout_service.dart';
import 'package:provider/provider.dart';
import 'active_workout_screen.dart';

class WorkoutPlanDetailsScreen extends StatelessWidget {
  final WorkoutPlan plan;

  const WorkoutPlanDetailsScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                _buildAppBar(context),
                SliverToBoxAdapter(child: _buildPlanInfo()),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildExerciseItem(plan.exercises[index]),
                      childCount: plan.exercises.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
            _buildStartButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.gray900,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          plan.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (plan.imageUrl != null)
              Image.network(plan.imageUrl!, fit: BoxFit.cover)
            else
              Container(color: AppColors.gray800),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.gray900.withOpacity(0.8), AppColors.gray900],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanInfo() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatChip(Icons.calendar_today, '${plan.durationWeeks} Weeks'),
              const SizedBox(width: 15),
              _buildStatChip(Icons.speed, plan.difficulty.name),
              const SizedBox(width: 15),
              _buildStatChip(Icons.flag, plan.goal ?? 'Fitness'),
            ],
          ),
          const SizedBox(height: 25),
          const Text(
            'About the Plan',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            plan.description ?? 'No description provided.',
            style: TextStyle(color: AppColors.gray400, height: 1.5),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Exercises',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${plan.exercises.length} Total',
                style: TextStyle(color: AppColors.primary500, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.gray800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gray700),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primary500),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildExerciseItem(WorkoutPlanExercise planEx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.gray800.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray700.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary500.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${planEx.order + 1}',
                style: const TextStyle(color: AppColors.primary500, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planEx.exercise.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${planEx.sets ?? 3} sets • ${planEx.reps ?? '10-12'} reps',
                  style: TextStyle(color: AppColors.gray400, fontSize: 12),
                ),
              ],
            ),
          ),
          if (planEx.notes != null && planEx.notes!.isNotEmpty)
            const Icon(Icons.note_alt_outlined, color: AppColors.gray500, size: 20),
        ],
      ),
    );
  }

  Future<void> _startWorkout(BuildContext context) async {
    final auth = context.read<AuthService>();
    final workoutService = WorkoutService();

    try {
      // Start session on backend
      final session = await workoutService.startSession(auth.accessToken!, plan.id);

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActiveWorkoutScreen(plan: plan, existingSession: session),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error starting workout: $e')));
      }
    }
  }

  Widget _buildStartButton(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: ElevatedButton(
        onPressed: () => _startWorkout(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary500,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 10,
          shadowColor: AppColors.primary500.withOpacity(0.4),
        ),
        child: const Text(
          'START WORKOUT',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
    );
  }
}
