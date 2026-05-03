import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../config/colors.dart';
import '../widgets/animated_gradient_background.dart';
import '../widgets/premium_card.dart';
import '../widgets/premium_section_header.dart';
import '../widgets/category_carousel_3d.dart';
import '../widgets/story_viewer.dart';
import '../services/category_service.dart';
import '../services/course_service.dart';
import '../services/story_service.dart';
import '../models/category.dart' as cat;
import '../models/course.dart';
import '../models/story.dart';
import 'courses_screen.dart';
import 'workout_plans_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onContactTap;
  final VoidCallback? onGetStartedTap;

  const HomeScreen({super.key, this.onContactTap, this.onGetStartedTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CategoryService _categoryService = CategoryService();
  final CourseService _courseService = CourseService();
  final StoryService _storyService = StoryService();

  List<cat.Category> _categories = [];
  List<Course> _courses = [];
  List<StoryGroup> _storyGroups = [];
  
  bool _loadingCategories = true;
  bool _loadingCourses = true;
  bool _loadingStories = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _loadCategories();
    _loadCourses();
    _loadStories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _loadingCategories = false;
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await _courseService.getCourses();
      if (mounted) {
        setState(() {
          _courses = courses.take(3).toList(); // Take top 3
          _loadingCourses = false;
        });
      }
    } catch (e) {
      print('Error loading courses: $e');
      if (mounted) setState(() => _loadingCourses = false);
    }
  }

  Future<void> _loadStories() async {
    try {
      final stories = await _storyService.getStoriesGroupedByCategory();
      if (mounted) {
        setState(() {
          _storyGroups = stories;
          _loadingStories = false;
        });
      }
    } catch (e) {
      print('Error loading stories: $e');
      if (mounted) setState(() => _loadingStories = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface950,
      body: AnimatedGradientBackground(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100), // Space for floating nav
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 30),

                  // Stories Section
                  if (!_loadingStories && _storyGroups.isNotEmpty)
                    _buildStoriesSection(),
                  
                  const SizedBox(height: 10),

                  // Categories Carousel
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: PremiumSectionHeader(
                      title: 'home_find_workout'.tr(),
                      subtitle: 'home_select_muscle'.tr(),
                    ),
                  ),
                  if (_loadingCategories)
                    const SizedBox(
                      height: 400,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_categories.isNotEmpty)
                    CategoryCarousel3D(
                      categories: _categories,
                      onCategoryTap: (category) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WorkoutPlansScreen(
                              initialCategory: category,
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 40),

                  // Featured Courses
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: PremiumSectionHeader(
                      title: 'home_featured'.tr(),
                      subtitle: 'home_premium_courses'.tr(),
                      action: GestureDetector(
                        onTap: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CoursesScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'view_all'.tr(),
                          style: TextStyle(
                            color: AppColors.primary500,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFeaturedCourses(),
                  
                  const SizedBox(height: 40),

                 


                  // Features Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildFeaturesSection(),
                  ),
                  
                  const SizedBox(height: 40),

                  // CTA Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildCTASection(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 40,
            fit: BoxFit.contain,
          ),
          Row(
            children: [
              // Language Selector
              GestureDetector(
                onTap: _showLanguageDialog,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface800.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.language,
                        color: AppColors.primary500,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getCurrentLanguageCode(),
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Notification Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface800.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getCurrentLanguageCode() {
    final locale = context.locale;
    switch (locale.languageCode) {
      case 'en':
        return 'EN';
      case 'fr':
        return 'FR';
      case 'ar':
        return 'AR';
      default:
        return 'EN';
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.gray800,
        title: Row(
          children: [
            Icon(Icons.language, color: AppColors.primary500),
            const SizedBox(width: 8),
            Text(
              'select_language'.tr(),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('English', const Locale('en')),
            const SizedBox(height: 12),
            _buildLanguageOption('Français', const Locale('fr')),
            const SizedBox(height: 12),
            _buildLanguageOption('العربية', const Locale('ar')),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String label, Locale locale) {
    final isSelected = context.locale == locale;
    return GestureDetector(
      onTap: () {
        context.setLocale(locale);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary500 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary500 : AppColors.gray600,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.gray400,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoriesSection() {
    return Container(
      height: 110,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _storyGroups.length,
        itemBuilder: (context, index) {
          final group = _storyGroups[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StoryViewer(
                      stories: group.stories,
                      categoryName: group.category.name,
                    ),
                  ),
                );
              },
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.primary400, AppColors.accent500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary500.withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface900,
                        border: Border.all(color: AppColors.surface950, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          group.category.icon ?? group.category.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 80,
                    child: Text(
                      group.category.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.surface300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedCourses() {
    if (_loadingCourses) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_courses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text('no_courses'.tr(), style: const TextStyle(color: Colors.white54)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _courses.length,
      itemBuilder: (context, index) {
        final course = _courses[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PremiumCard(
            padding: const EdgeInsets.all(12),
            onTap: () {
              // Navigate to course details
            },
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: AppColors.surface800,
                    child: course.thumbnail != null
                        ? Image.network(course.thumbnail!, fit: BoxFit.cover)
                        : Icon(Icons.fitness_center, color: AppColors.primary500),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course.description ?? 'No description',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.gray400,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 14, color: AppColors.primary400),
                          const SizedBox(width: 4),
                          Text(
                            '${course.duration} min',
                            style: TextStyle(fontSize: 12, color: AppColors.primary400),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.signal_cellular_alt, size: 14, color: AppColors.accent500),
                          const SizedBox(width: 4),
                          Text(
                            'All Levels', // Keeping generic or add specific key if needed
                            style: TextStyle(fontSize: 12, color: AppColors.accent500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

 

  Widget _buildFeaturesSection() {
    final features = [
      {
        'icon': Icons.fitness_center_rounded,
        'title': 'feature_training_title'.tr(),
        'description': 'feature_training_desc'.tr(),
      },
      {
        'icon': Icons.schedule_rounded,
        'title': 'feature_schedule_title'.tr(),
        'description': 'feature_schedule_desc'.tr(),
      },
      {
        'icon': Icons.groups_rounded,
        'title': 'feature_community_title'.tr(),
        'description': 'feature_community_desc'.tr(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PremiumSectionHeader(title: 'home_why_choose_us'.tr()),
        const SizedBox(height: 16),
        ...features.map((feature) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PremiumCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary500.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary500.withOpacity(0.3)),
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: AppColors.primary500,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feature['description'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.gray400,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildCTASection(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Text(
            'home_ready_start'.tr(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'home_join_members'.tr(),
            style: TextStyle(
              fontSize: 16,
              color: AppColors.gray300,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onContactTap,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: AppColors.primary500.withOpacity(0.5),
              ),
              child: Text(
                'contact_us_now'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
