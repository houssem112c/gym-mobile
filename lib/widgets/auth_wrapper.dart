import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../main.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    return FutureBuilder<void>(
      future: authService.initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Consumer<AuthService>(
          builder: (context, authService, child) {
            return authService.isAuthenticated
                ? const MainScreen()
                : const LoginScreen();
          },
        );
      },
    );
  }
}