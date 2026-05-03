import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout.dart';
import '../services/workout_service.dart';
import '../config/colors.dart';
import '../widgets/gradient_background.dart';
import '../services/auth_service.dart';
import 'workout_plan_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout.dart';
import '../services/workout_service.dart';
import '../config/colors.dart';
import '../widgets/gradient_background.dart';
import '../services/auth_service.dart';
import 'workout_plan_details_screen.dart';
import '../models/category.dart' as cat;

class WorkoutPlansScreen extends StatefulWidget {
  final cat.Category? initialCategory;
  const WorkoutPlansScreen({super.key, this.initialCategory});

  @override
  State<WorkoutPlansScreen> createState() => _WorkoutPlansScreenState();
}

class _WorkoutPlansScreenState extends State<WorkoutPlansScreen> {
  final WorkoutService _workoutService = WorkoutService();
  List<WorkoutPlan> _plans = [];
  List<WorkoutPlan> _recommendedPlans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final auth = context.read<AuthService>();
    final plans = await _workoutService.getWorkoutPlans();
    final recommended = await _workoutService.getRecommendedPlans(auth.accessToken!);
    
    setState(() {
      _plans = plans.where((p) => p.isActive).toList();
      
      // Filter by initial category if provided
      if (widget.initialCategory != null) {
        final categoryName = widget.initialCategory!.name.toLowerCase();
        // Try to verify if plan matches category (simple title/goal match as fallback)
        _plans = _plans.where((p) {
          final title = p.title.toLowerCase();
          final goal = (p.goal ?? '').toLowerCase();
          return title.contains(categoryName) || goal.contains(categoryName);
        }).toList();
      }

      _recommendedPlans = recommended.where((p) => p.isActive).toList();
      _isLoading = false;
    });
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
                    : CustomScrollView(
                        slivers: [
                          if (_recommendedPlans.isNotEmpty)
                            SliverToBoxAdapter(child: _buildRecommendedSection()),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: Text('All training plans', style: TextStyle(color: AppColors.gray400, fontSize: 14)),
                            ),
                          ),
                          _buildPlansSliverList(),
                        ],
                      ),
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
          const Expanded(
            child: Text(
              'Training Plans',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            'Recommended for You',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            scrollDirection: Axis.horizontal,
            itemCount: _recommendedPlans.length,
            itemBuilder: (context, index) {
              final plan = _recommendedPlans[index];
              return _buildPlanCard(plan, isHorizontal: true);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlansSliverList() {
    if (_plans.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('No plans available', style: TextStyle(color: Colors.white))),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildPlanCard(_plans[index]),
          childCount: _plans.length,
        ),
      ),
    );
  }

  Widget _buildPlanCard(WorkoutPlan plan, {bool isHorizontal = false}) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WorkoutPlanDetailsScreen(plan: plan)),
      ),
      child: Container(
        width: isHorizontal ? 300 : double.infinity,
        margin: EdgeInsets.only(
          bottom: isHorizontal ? 0 : 20,
          right: isHorizontal ? 15 : 0,
          left: isHorizontal ? 10 : 0,
        ),
        decoration: BoxDecoration(
          color: AppColors.gray800.withOpacity(0.5),
          borderRadius: BorderRadius.circular(25),
          image: plan.imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(plan.imageUrl!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken),
                )
              : null,
          border: Border.all(color: AppColors.gray700.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: isHorizontal ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary500,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      plan.difficulty.name,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '${plan.durationWeeks} Weeks',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              SizedBox(height: isHorizontal ? 40 : 60),
              Text(
                plan.title,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                plan.goal ?? 'Fitness Goal',
                style: TextStyle(color: AppColors.primary400, fontSize: 14),
              ),
              if (!isHorizontal) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.fitness_center, size: 16, color: AppColors.gray400),
                    const SizedBox(width: 5),
                    Text('${plan.exercises.length} Exercises', style: TextStyle(color: AppColors.gray400, fontSize: 12)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
