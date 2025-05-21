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

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isPortrait = screenSize.height > screenSize.width;

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
                alignment: Alignment.center,
                children: [
                  AnimatedAlign(
                    alignment:
                        _animateText ? Alignment.center : Alignment.centerLeft,
                    duration: const Duration(milliseconds: 800),
                    child: AnimatedOpacity(
                      opacity: _animateText ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 600),
                      child: Text(
                        'FixiB   t',
                        style: AppFonts.montserratBold60.copyWith(
                          fontSize: isPortrait
                              ? screenSize.height * 0.08
                              : screenSize.width * 0.08,
                        ),
                      ),
                    ),
                  ),
                  AnimatedAlign(
                    alignment:
                        _animateLogo ? Alignment.center : Alignment.centerLeft,
                    duration: const Duration(milliseconds: 700),
                    child: AnimatedOpacity(
                      opacity: _animateLogo ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 400),
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: isPortrait
                              ? screenSize.width * 0.17
                              : screenSize.height * 0.17,
                        ),
                        child: Transform.translate(
                          offset: _animateLogo
                              ? Offset(
                                  isPortrait
                                      ? screenSize.width * 0.13
                                      : screenSize.height * 0.14,
                                  0)
                              : Offset.zero,
                          child: Image.asset(
                            'assets/icons/APPicon.png',
                            height: isPortrait
                                ? screenSize.height * 0.08
                                : screenSize.width * 0.08,
                            width: isPortrait
                                ? screenSize.height * 0.07
                                : screenSize.width * 0.07,
                          ),
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
