import 'package:fitcourse/models/exercise_models.dart';
import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'dart:ui';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:fitcourse/screens/home.dart';
import 'package:fitcourse/screens/exercise.dart';
import 'package:fitcourse/screens/settings.dart';

class NavigatorScreen extends StatefulWidget {
  const NavigatorScreen({super.key});

  @override
  _NavigatorScreenState createState() => _NavigatorScreenState();
}

class _NavigatorScreenState extends State<NavigatorScreen> {
  int _selectedIndex = 0;
  bool _isExerciseLightMode = false; // Track exercise screen theme

  void _onExerciseThemeChanged(bool isLightMode) {
    setState(() {
      _isExerciseLightMode = isLightMode;
    });
  }

  List<Widget> get _widgetOptions => <Widget>[
    const HomeScreen(),
    ExerciseScreen(onThemeChanged: _onExerciseThemeChanged),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  BottomNavigationBarItem _buildTabItem(
    IconData unselectedIcon,
    selectedIcon,
    int index,
    Color iconColor,
  ) {
    final bool isSelected = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? selectedIcon : unselectedIcon,
            size: isSelected ? 28.0 : 24.0,
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4.0),
              height: 6.0,
              width: 6.0,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      label: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine nav bar colors based on current screen and theme
    final bool shouldUseBlackIcons = _selectedIndex == 1 && _isExerciseLightMode; // Exercise screen (index 1) in light mode
    final Color iconColor = shouldUseBlackIcons ? Colors.black : Colors.white;
    
    return Scaffold(
      body: Stack(
        children: [
          Center(child: _widgetOptions.elementAt(_selectedIndex)),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 0.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ClipRRect(
                    borderRadius: _selectedIndex == 0
                              ? const BorderRadius.only(
                                  topRight: Radius.circular(20.0),
                                  topLeft: Radius.circular(90.0),
                                  bottomLeft: Radius.circular(90.0),
                                  bottomRight: Radius.circular(90.0),
                                )
                              : BorderRadius.circular(90.0),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(90.0),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                          ),
                          child: BottomNavigationBar(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            items: <BottomNavigationBarItem>[
                              _buildTabItem(
                                FluentIcons.home_24_regular,
                                FluentIcons.home_24_filled,
                                0,
                                iconColor,
                              ),
                              _buildTabItem(
                                MingCuteIcons.mgc_performance_line,
                                MingCuteIcons.mgc_performance_fill,
                                1,
                                iconColor,
                              ),
                              _buildTabItem(
                                MingCuteIcons.mgc_settings_3_line,
                                MingCuteIcons.mgc_settings_3_fill,
                                2,
                                iconColor,
                              ),
                            ],
                            currentIndex: _selectedIndex,
                            selectedItemColor: iconColor,
                            unselectedItemColor: iconColor,
                            type: BottomNavigationBarType.fixed,
                            showSelectedLabels: false,
                            showUnselectedLabels: false,
                            enableFeedback: false,
                            onTap: _onItemTapped,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
