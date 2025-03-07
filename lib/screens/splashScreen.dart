import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/constants/app_fontStyles.dart';
import 'package:fixibot_app/loaders/loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth/view/login.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  bool _showLoader = true;
  bool _animateText = false;
  bool _animateLogo = false; 

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        _showLoader = false;
      });

      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _animateText = true;
        });

        Future.delayed(const Duration(milliseconds: 1000), () { 
          setState(() {
            _animateLogo = true;
          });

            //Navigate to the signup screen
          Future.delayed(const Duration(milliseconds: 2000), () {
            Get.off(() => const Login(), transition: Transition.fadeIn);
          });

        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      body: Center(
        child: _showLoader
            ? const LoaderWidget()
            : Stack(
                alignment: Alignment.center, 
                children: [
                  AnimatedAlign(
                    alignment: _animateText
                        ? Alignment.center
                        : Alignment.centerLeft,
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeInOut,
                    child: AnimatedOpacity(
                      opacity: _animateText ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 600),
                      child: Text(
                        'FixiB   t',
                        textAlign: TextAlign.center,
                        style: AppFonts.montserratBold60,
                      ),
                    ),
                  ),
                
                  AnimatedAlign(
                    alignment: _animateLogo
                        ? Alignment.center
                        : Alignment.centerLeft,
                    duration: const Duration(milliseconds: 2000),
                    curve: Curves.easeInOut,
                    child: AnimatedOpacity(
                      opacity: _animateLogo ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 1000),
                      child: Transform.translate( 
                        offset: _animateLogo ? const Offset(65, 0) : Offset.zero, 
                        child: Image.asset(
                          'assets/icons/app-icon.png',
                          height: 60,
                          width: 50,

                        
                        ),
                      ),
                    ),)
                ],
              ),
      ),
    );
  }
}
