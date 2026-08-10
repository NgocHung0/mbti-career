import 'package:flutter/material.dart';

import '../../core/widgets/app_bottom_nav.dart';
import '../../services/auth_service.dart';

import '../home/home_screen.dart';
import '../courses/courses_screen.dart';
import '../test/test_screen.dart';
import '../majors/majors_screen.dart';
import '../admissions/admissions_screen.dart';
import '../settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  final Widget? admissionsScreen;

  const MainScreen({
    super.key,
    this.initialIndex = 0,
    this.admissionsScreen,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int currentIndex;
  int testRefreshKey = 0;

  @override
  void initState() {
    super.initState();

    currentIndex = widget.initialIndex < 0 || widget.initialIndex > 5
        ? 0
        : widget.initialIndex;
  }

  void changeTab(int index) {
    if (index < 0 || index > 5) return;

    setState(() {
      currentIndex = index;

      // Tab Kiểm tra đang nằm ở index 2
      if (index == 2) {
        testRefreshKey++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<int>(
        valueListenable: AuthService.authVersion,
        builder: (context, authVersion, _) {
          return IndexedStack(
            index: currentIndex,
            children: [
              HomeScreen(key: ValueKey('home_$authVersion')),
              CoursesScreen(key: ValueKey('courses_$authVersion')),
              TestScreen(
                key: ValueKey('test_${authVersion}_$testRefreshKey'),
                refreshKey: testRefreshKey,
              ),
              MajorsScreen(key: ValueKey('majors_$authVersion')),
              widget.admissionsScreen ??
                  AdmissionsScreen(key: ValueKey('admissions_$authVersion')),
              SettingsScreen(key: ValueKey('settings_$authVersion')),
            ],
          );
        },
      ),

      bottomNavigationBar: AppBottomNav(
        currentIndex: currentIndex,
        onTap: changeTab,
      ),
    );
  }
}