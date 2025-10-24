import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/constants/app_fontStyles.dart';
import 'package:fixibot_app/loaders/loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth/controller/shared_pref_helper.dart';
import 'auth/view/login.dart';
import 'homeScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showLoader = true;
  bool _animateText = false;
  bool _animateLogo = false;
  bool _hideLoader = false;
  final SharedPrefsHelper _sharedPrefsHelper = SharedPrefsHelper();
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _initializeApp();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 4));
    if (!_isMounted) return;

    _safeSetState(() => _hideLoader = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!_isMounted) return;

    _safeSetState(() => _showLoader = false);
    _safeSetState(() => _animateText = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!_isMounted) return;

    _safeSetState(() => _animateLogo = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!_isMounted) return;

    final bool isLoggedIn = await _sharedPrefsHelper.isUserLoggedIn();
    final bool rememberUser = await _sharedPrefsHelper.rememberUser();

    if (!_isMounted) return;

    if (isLoggedIn && rememberUser) {
      Get.off(() => const HomeScreen(), transition: Transition.fadeIn);
    } else {
      Get.off(() => Login(), transition: Transition.fadeIn);
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (_isMounted) {
      setState(fn);
    }
  }

  // Get responsive font size based on screen width
  double _getFontSize(Size screenSize) {
    final double width = screenSize.width;
    
    if (width < 320) return width * 0.16;      // Very small phones
    if (width < 360) return width * 0.15;      // Small phones
    if (width < 414) return width * 0.14;      // Medium phones
    if (width < 600) return width * 0.13;      // Large phones
    if (width < 768) return width * 0.10;      // Small tablets
    if (width < 1024) return width * 0.08;     // Tablets
    if (width < 1440) return width * 0.06;     // Laptops
    return width * 0.04;                       // Large screens/PCs
  }

  // Get responsive icon size based on screen width
  double _getIconSize(Size screenSize) {
    final double width = screenSize.width;
    
    if (width < 320) return width * 0.12;      // Very small phones
    if (width < 360) return width * 0.11;      // Small phones
    if (width < 414) return width * 0.10;      // Medium phones
    if (width < 600) return width * 0.09;      // Large phones
    if (width < 768) return width * 0.08;      // Small tablets
    if (width < 1024) return width * 0.07;     // Tablets
    if (width < 1440) return width * 0.05;     // Laptops
    return width * 0.035;                      // Large screens/PCs
  }

  double _calculateIconPosition(Size screenSize, double fontSize, double iconSize) {
    final double fixibWidth = fontSize * 3.0; // Adjusted for proper spacing
    
    final double iconSpacing = fontSize * 0.4;
    
    final double totalWidth = fixibWidth + iconSize + (iconSpacing * 2) + fontSize * 0.5;
    final double startX = (screenSize.width - totalWidth) / 2;
    
    return startX + fixibWidth + iconSpacing;
  }

  double _getIconVerticalOffset(double fontSize, double iconSize) {
    return fontSize * 0.09; // Slight downward adjustment to match text baseline
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double fontSize = _getFontSize(screenSize);
    final double iconSize = _getIconSize(screenSize);
    final double iconPosition = _calculateIconPosition(screenSize, fontSize, iconSize);
    final double iconVerticalOffset = _getIconVerticalOffset(fontSize, iconSize);
    final double iconSpacing = fontSize * 0.1; 

    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      body: Center(
        child: _showLoader
            ? AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: _hideLoader ? 0.0 : 1.0,
                child: AnimatedScale(
                  scale: _hideLoader ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 500),
                  child: const LoaderWidget(),
                ),
              )
            : Stack(
                children: [
                  // "FixiB" text part
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 800),
                    left: _animateText 
                        ? iconPosition - fontSize * 2.6 - iconSpacing 
                        : -screenSize.width,
                    top: screenSize.height / 2 - fontSize / 2,
                    child: AnimatedOpacity(
                      opacity: _animateText ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 600),
                      child: Text(
                        'FixiB',
                        style: AppFonts.montserratBold60.copyWith(
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                  ),

                  // Icon acting as 'o'
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 700),
                    left: _animateLogo ? iconPosition : -iconSize,
                    top: screenSize.height / 2 - iconSize / 2 + iconVerticalOffset,
                    child: AnimatedOpacity(
                      opacity: _animateLogo ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 400),
                      child: Image.asset(
                        'assets/icons/APPicon.png',
                        height: iconSize,
                        width: iconSize,
                      ),
                    ),
                  ),

                  // "t" text part
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 800),
                    left: _animateText 
                        ? iconPosition + iconSize + iconSpacing 
                        : screenSize.width, 
                    top: screenSize.height / 2 - fontSize / 2,
                    child: AnimatedOpacity(
                      opacity: _animateText ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 600),
                      child: Text(
                        't',
                        style: AppFonts.montserratBold60.copyWith(
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
