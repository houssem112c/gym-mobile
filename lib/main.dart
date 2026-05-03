import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/theme.dart';
import 'config/colors.dart';
import 'config/supabase_config.dart';
import 'screens/home_screen.dart';
import 'screens/courses_screen.dart';
import 'screens/community_screen.dart';

import 'screens/calendar_screen.dart';
import 'screens/locations_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/profile_screen.dart' as profile_screen;
import 'screens/bmi_screen.dart';
 import 'screens/stories/stories_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/bmi_service.dart';
import 'services/local_notification_service.dart';
import 'widgets/auth_wrapper.dart';
import 'widgets/premium_bottom_nav.dart';
import 'features/shop/providers/cart_provider.dart';
import 'features/shop/providers/favorites_provider.dart';
import 'features/shop/screens/shop_screen.dart';
import 'providers/gamification_provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    if (details.stack != null) {
      debugPrint(details.stack.toString());
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher error: $error');
    debugPrint(stack.toString());
    return true;
  };

  debugPrint('Startup: entered main()');

  try {
    debugPrint('Startup: EasyLocalization.ensureInitialized()');
    await EasyLocalization.ensureInitialized().timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('Startup: EasyLocalization init failed/timeout: $e');
  }
  
  // Initialize Local Notifications
  try {
    debugPrint('Startup: LocalNotificationService.init()');
    await LocalNotificationService.init().timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint('Startup: Local notifications init failed/timeout: $e');
  }

  // Initialize Stripe
  Stripe.publishableKey = 'pk_test_51S4ivx0hLeYQkXmEBxAexT98uVGZqzoiO3550nN3tV02li3yLtL3OCV4oh8QPjufOQcMsorXy9MagL8pYOEaw3pF00piV3yGyr';
  try {
    debugPrint('Startup: Stripe.instance.applySettings()');
    await Stripe.instance.applySettings().timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('Startup: Stripe applySettings failed/timeout: $e');
  }
  
  // Initialize Supabase only if configured
  if (SupabaseConfig.isConfigured) {
    try {
      debugPrint('Startup: Supabase.initialize()');
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      ).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('Startup: Supabase init failed/timeout: $e');
    }
  } else {
    debugPrint('Startup: Supabase not configured.');
  }

  debugPrint('Startup: runApp()');
  
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
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
        ChangeNotifierProvider<CartProvider>(
          create: (_) => CartProvider(),
        ),
        ChangeNotifierProvider<FavoritesProvider>(
          create: (_) => FavoritesProvider(),
        ),
        ChangeNotifierProxyProvider<AuthService, GamificationProvider>(
          create: (context) => GamificationProvider(Provider.of<AuthService>(context, listen: false)),
          update: (context, authService, previous) => previous ?? GamificationProvider(authService),
        ),
      ],
      child: MaterialApp(
        title: 'GYM',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
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
    const StoriesScreen(),
    const CommunityScreen(),
    const LocationsScreen(),

    Consumer<AuthService>(
      builder: (context, authService, _) => Consumer<BmiService>(
        builder: (context, bmiService, _) => BmiScreen(
          authService: authService,
          bmiService: bmiService,
        ),
      ),
    ),
    ContactScreen(),
    profile_screen.ProfileScreen(),
    ShopScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Set notification context for gamification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GamificationProvider>(context, listen: false).setContext(context);
    });

    final screenWidth = MediaQuery.of(context).size.width;
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
                    child: Container(
                      height: 50,
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 50,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Navigation items
                  Expanded(
                    child: ListView(
                      children: [
                        _buildNavItem(0, Icons.home_rounded, 'nav_home'.tr()),
                        _buildNavItem(1, Icons.fitness_center_rounded, 'nav_courses'.tr()),
                        _buildNavItem(2, Icons.calendar_month_rounded, 'nav_calendar'.tr()),
                        _buildNavItem(3, Icons.auto_stories_rounded, 'nav_stories'.tr()),
                        _buildNavItem(4, Icons.people_rounded, 'nav_community'.tr()),
                        _buildNavItem(5, Icons.location_on_rounded, 'nav_locations'.tr()),

                        _buildNavItem(5, Icons.calculate_rounded, 'nav_bmi'.tr()),
                        _buildNavItem(6, Icons.contact_page_rounded, 'nav_contact'.tr()),
                        _buildNavItem(7, Icons.person_rounded, 'nav_profile'.tr()),
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
                            'logout'.tr(),
                            style: TextStyle(
                              color: AppColors.red500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onTap: () => _showLogoutDialog(context, authService),
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
    
    // Mobile and Tablet layout with premium bottom navigation
    return Scaffold(
      backgroundColor: AppColors.surface950,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Container(
          height: 30,
          child: Image.asset(
            'assets/images/logo.png',
            height: 30,
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          Consumer<AuthService>(
            builder: (context, authService, child) {
              return IconButton(
                icon: Icon(
                  Icons.logout_rounded,
                  color: AppColors.accent500,
                ),
                onPressed: () => _showLogoutDialog(context, authService),
                tooltip: 'Logout',
              );
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: PremiumBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          PremiumNavItem(
            icon: Icons.home_rounded,
            label: 'nav_home'.tr(),
          ),
          PremiumNavItem(
            icon: Icons.fitness_center_rounded,
            label: 'nav_courses'.tr(),
          ),
          PremiumNavItem(
            icon: Icons.calendar_month_rounded,
            label: 'nav_calendar'.tr(),
          ),
          PremiumNavItem(
            icon: Icons.auto_stories_rounded,
            label: 'nav_stories'.tr(),
          ),
          PremiumNavItem(
            icon: Icons.people_rounded,
            label: 'nav_community'.tr(),
          ),
          PremiumNavItem(
            icon: Icons.location_on_rounded,
            label: 'nav_locations'.tr(),
          ),

          PremiumNavItem(
            icon: Icons.calculate_rounded,
            label: 'nav_bmi'.tr(),
          ),
          PremiumNavItem(
            icon: Icons.contact_page_rounded,
            label: 'nav_contact'.tr(),
          ),
          PremiumNavItem(
            icon: Icons.person_rounded,
            label: 'nav_profile'.tr(),
          ),
          PremiumNavItem(
            icon: Icons.shopping_bag_rounded,
            label: 'nav_shop'.tr(),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, AuthService authService) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.gray800,
        title: Text('logout'.tr(), style: TextStyle(color: Colors.white)),
        content: Text(
          'logout_confirmation'.tr(),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'logout'.tr(),
              style: TextStyle(color: AppColors.red500),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await authService.logout();
      // AuthWrapper will handle the redirection
    }
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
