import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/main/main_screen.dart';
import 'services/auth_service.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.loadTheme();
  runApp(const MBTICareerApp());
}

class MBTICareerApp extends StatelessWidget {
  const MBTICareerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'MBTI Career',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: AppColors.lightBlue,
            textTheme: GoogleFonts.plusJakartaSansTextTheme(),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF000000),
            cardColor: const Color(0xFF111111),
            textTheme: GoogleFonts.plusJakartaSansTextTheme(
              ThemeData.dark().textTheme,
            ),
            useMaterial3: true,
          ),
          home: const AppStartScreen(),
        );
      },
    );
  }
}

class AppStartScreen extends StatefulWidget {
  const AppStartScreen({super.key});

  @override
  State<AppStartScreen> createState() => _AppStartScreenState();
}

class _AppStartScreenState extends State<AppStartScreen> {
  late final Future<bool> _shouldSkipOnboardingFuture;

  @override
  void initState() {
    super.initState();
    _shouldSkipOnboardingFuture = AuthService.shouldSkipOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _shouldSkipOnboardingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final shouldSkipOnboarding = snapshot.data ?? false;

        if (shouldSkipOnboarding) {
          return const MainScreen();
        }

        return const OnboardingScreen();
      },
    );
  }
}
