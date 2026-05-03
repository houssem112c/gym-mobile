import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../services/workout_service.dart';
import '../config/colors.dart';
import '../widgets/gradient_background.dart';
import 'package:url_launcher/url_launcher.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final WorkoutService _workoutService = WorkoutService();
  List<Exercise> _exercises = [];
  List<Exercise> _filteredExercises = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedMuscleGroup;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final exercises = await _workoutService.getExercises();
    setState(() {
      _exercises = exercises;
      _filteredExercises = exercises;
      _isLoading = false;
    });
  }

  void _filterExercises() {
    setState(() {
      _filteredExercises = _exercises.where((ex) {
        final matchesSearch = ex.name.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesMuscle = _selectedMuscleGroup == null || ex.muscleGroup == _selectedMuscleGroup;
        return matchesSearch && matchesMuscle;
      }).toList();
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
              _buildFilters(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary500))
                    : _buildExerciseList(),
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
              'Exercise Library',
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

  Widget _buildFilters() {
    final muscleGroups = _exercises
        .map((e) => e.muscleGroup)
        .where((m) => m != null)
        .toSet()
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              _searchQuery = value;
              _filterExercises();
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search exercises...',
              hintStyle: TextStyle(color: AppColors.gray400),
              prefixIcon: Icon(Icons.search, color: AppColors.gray400),
              filled: true,
              fillColor: AppColors.gray800.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedMuscleGroup == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedMuscleGroup = null;
                      _filterExercises();
                    });
                  },
                  backgroundColor: AppColors.gray800,
                  selectedColor: AppColors.primary500,
                  labelStyle: TextStyle(
                    color: _selectedMuscleGroup == null ? Colors.white : AppColors.gray400,
                  ),
                ),
                ...muscleGroups.map((muscle) => Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: FilterChip(
                    label: Text(muscle!),
                    selected: _selectedMuscleGroup == muscle,
                    onSelected: (selected) {
                      setState(() {
                        _selectedMuscleGroup = selected ? muscle : null;
                        _filterExercises();
                      });
                    },
                    backgroundColor: AppColors.gray800,
                    selectedColor: AppColors.primary500,
                    labelStyle: TextStyle(
                      color: _selectedMuscleGroup == muscle ? Colors.white : AppColors.gray400,
                    ),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    if (_filteredExercises.isEmpty) {
      return const Center(child: Text('No exercises found', style: TextStyle(color: Colors.white)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredExercises.length,
      itemBuilder: (context, index) {
        final exercise = _filteredExercises[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: AppColors.gray800.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gray700.withOpacity(0.5)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: exercise.imageUrl != null
                  ? Image.network(exercise.imageUrl!, width: 60, height: 60, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder())
                  : _buildPlaceholder(),
            ),
            title: Text(exercise.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.muscleGroup ?? 'General', style: TextStyle(color: AppColors.gray400, fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(exercise.difficulty).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    exercise.difficulty.name,
                    style: TextStyle(color: _getDifficultyColor(exercise.difficulty), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.info_outline, color: AppColors.primary500),
            onTap: () => _showExerciseDetails(exercise),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: AppColors.gray700,
      child: const Icon(Icons.fitness_center, color: Colors.white),
    );
  }

  Color _getDifficultyColor(Difficulty diff) {
    switch (diff) {
      case Difficulty.BEGINNER: return Colors.green;
      case Difficulty.INTERMEDIATE: return Colors.orange;
      case Difficulty.ADVANCED: return Colors.red;
    }
  }

  void _showExerciseDetails(Exercise exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: AppColors.gray900,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (exercise.imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  child: Image.network(exercise.imageUrl!, width: double.infinity, height: 250, fit: BoxFit.cover),
                ),
              Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildInfoTag(Icons.fitness_center, exercise.muscleGroup ?? 'General'),
                        const SizedBox(width: 15),
                        _buildInfoTag(Icons.speed, exercise.difficulty.name),
                      ],
                    ),
                    const SizedBox(height: 25),
                    const Text('Description', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(exercise.description ?? 'No description available.', style: TextStyle(color: AppColors.gray400, height: 1.5)),
                    if (exercise.equipment != null) ...[
                      const SizedBox(height: 25),
                      const Text('Equipment', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(exercise.equipment!, style: TextStyle(color: AppColors.gray400)),
                    ],
                    if (exercise.videoUrl != null) ...[
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_circle_fill),
                        label: const Text('Watch Tutorial'),
                        onPressed: () async {
                          if (exercise.videoUrl != null) {
                            final url = Uri.parse(exercise.videoUrl!);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not launch video')),
                                );
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary500,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangle_circular(15),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary500),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: AppColors.gray400, fontSize: 14)),
      ],
    );
  }
}

RoundedRectangleBorder RoundedRectangle_circular(double r) => RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));
