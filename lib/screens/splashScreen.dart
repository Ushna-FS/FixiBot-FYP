import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/constants/app_fontStyles.dart';
import 'package:fixibot_app/loaders/loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth/view/login.dart';

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

  @override
  void initState() {
    super.initState();

    
    Future.delayed(const Duration(seconds: 4), () {
      setState(() {
        _hideLoader = true;
      });

      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _showLoader = false;
          _animateText = true;
        });

        
        Future.delayed(const Duration(milliseconds: 700), () {
          setState(() {
            _animateLogo = true;
          });

      
          Future.delayed(const Duration(milliseconds: 1800), () {
            Get.off(() => const Login(), transition: Transition.fadeIn);
          });
        });
      });
    });
  }

  
  @override

Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.secondaryColor,
    body: Center(
      child: _showLoader
          ? AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
              opacity: _hideLoader ? 0.0 : 1.0,
              child: AnimatedScale(
                scale: _hideLoader ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOutBack, // Smooth bounce
                child: const LoaderWidget(),
              ),
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                AnimatedAlign(
                  alignment: _animateText ? Alignment.center : Alignment.centerLeft,
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOutCubic,
                  child: AnimatedOpacity(
                    opacity: _animateText ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    child: Text(
                      'FixiB   t',
                      textAlign: TextAlign.center,
                      style: AppFonts.montserratBold60,
                    ),
                  ),
                ),
                AnimatedAlign(
                  alignment: _animateLogo ? Alignment.center : Alignment.centerLeft,
                  duration: const Duration(milliseconds: 700), // Faster
                  curve: Curves.easeInOutCubic, // Smoother easing
                  child: AnimatedOpacity(
                    opacity: _animateLogo ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeIn,
                    child: Transform.translate(
                      offset: _animateLogo ? const Offset(65, 0) : Offset.zero,
                      child: Image.asset(
                        'assets/icons/APPicon.png',
                        height: 60,
                        width: 50,
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
