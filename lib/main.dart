import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/colors.dart';
import 'screens/home_screen.dart';
import 'screens/courses_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/videos_screen.dart';
import 'screens/locations_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/bmi_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/bmi_service.dart';
import 'widgets/auth_wrapper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
        ProxyProvider<AuthService, BmiService>(
          update: (context, authService, _) => BmiService(authService),
        ),
      ],
      child: MaterialApp(
        title: 'GYM',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
    HomeScreen(
      onContactTap: () => setState(() => _currentIndex = 6),
      onGetStartedTap: () => setState(() => _currentIndex = 1),
    ),
    const CoursesScreen(),
    const CalendarScreen(),
    const VideosScreen(),
    const LocationsScreen(),
    Consumer<AuthService>(
      builder: (context, authService, _) => Consumer<BmiService>(
        builder: (context, bmiService, _) => BmiScreen(
          authService: authService,
          bmiService: bmiService,
        ),
      ),
    ),
    const ContactScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;
    
    if (isDesktop) {
      // Desktop layout with side navigation
      return Scaffold(
        body: Row(
          children: [
            // Side Navigation
            Container(
              width: 250,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.gray900,
                    AppColors.gray800,
                  ],
                ),
                border: Border(
                  right: BorderSide(color: AppColors.gray700, width: 1),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // Logo/Title
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'GYM',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Navigation items
                  Expanded(
                    child: ListView(
                      children: [
                        _buildNavItem(0, Icons.home_rounded, 'Home'),
                        _buildNavItem(1, Icons.fitness_center_rounded, 'Courses'),
                        _buildNavItem(2, Icons.calendar_month_rounded, 'Calendar'),
                        _buildNavItem(3, Icons.play_circle_rounded, 'Videos'),
                        _buildNavItem(4, Icons.location_on_rounded, 'Locations'),
                        _buildNavItem(5, Icons.calculate_rounded, 'BMI Calculator'),
                        _buildNavItem(6, Icons.contact_page_rounded, 'Contact'),
                      ],
                    ),
                  ),
                  // Logout button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Consumer<AuthService>(
                      builder: (context, authService, child) {
                        return ListTile(
                          leading: Icon(
                            Icons.logout_rounded,
                            color: AppColors.red500,
                          ),
                          title: Text(
                            'Logout',
                            style: TextStyle(
                              color: AppColors.red500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onTap: () => authService.logout(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: _screens[_currentIndex],
            ),
          ],
        ),
      );
    }
    
    // Mobile and Tablet layout with bottom navigation
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.gray900,
        elevation: 0,
        title: Text(
          'GYM',
          style: TextStyle(
            color: AppColors.primary400,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Consumer<AuthService>(
            builder: (context, authService, child) {
              return IconButton(
                icon: Icon(
                  Icons.logout_rounded,
                  color: AppColors.red500,
                ),
                onPressed: () => authService.logout(),
                tooltip: 'Logout',
              );
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.gray900,
              AppColors.gray800,
              AppColors.gray900,
            ],
          ),
          border: Border(
            top: BorderSide(color: AppColors.gray700, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.primary400,
          unselectedItemColor: AppColors.gray300,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 14 : 12,
          ),
          unselectedLabelStyle: TextStyle(fontSize: isTablet ? 12 : 10),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_rounded),
              label: 'Courses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.play_circle_outline_rounded),
              label: 'Videos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_rounded),
              label: 'Locations',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calculate_rounded),
              label: 'BMI',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.contact_page_rounded),
              label: 'Contact',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _currentIndex = index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected ? AppColors.primary500.withOpacity(0.2) : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppColors.primary500.withOpacity(0.3) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primary400 : AppColors.gray300,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary400 : AppColors.gray300,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
