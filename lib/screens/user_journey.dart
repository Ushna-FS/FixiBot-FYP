import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/constants/app_fontStyles.dart';
import 'package:fixibot_app/model/userJourneyModel.dart';
import 'package:fixibot_app/screens/homeScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class UserJourney extends StatefulWidget {
  const UserJourney({super.key});

  @override
  State<UserJourney> createState() => _UserJourneyState();
}

class _UserJourneyState extends State<UserJourney> {
  late UserJourneyModel _model;

  @override
  void initState() {
    super.initState();
    _model = UserJourneyModel();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      body: Stack(
        children: [
          PageView(
            controller: _model.pageViewController ??=
                PageController(initialPage: 0),
            scrollDirection: Axis.horizontal,
            children: [
              Column(
                children: [
                  Container(
                    width: screenSize.height * 0.5,
                    height: screenSize.height * 0.4,
                    decoration: const BoxDecoration(
                        color: AppColors.secondaryColor,
                        image: DecorationImage(
                          image:
                              AssetImage("assets/images/UserJourneyImage1.png"),
                        )),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                        color: AppColors.textColor,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(250),
                        )),
                    width: double.infinity,
                    height: screenSize.height * 0.6,
                    child: Column(children: [
                      const SizedBox(
                        height: 102,
                      ),
                      const Text(
                        "Daignose with AI!",
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColor2),
                      ),
                      const SizedBox(
                        height: 82,
                      ),
                      Text(
                          'Let AI detect issues instantly and keep your car running smoothly.',
                          textAlign: TextAlign.center,
                          style: AppFonts.journeytext),
                      const SizedBox(height: 30),
                    ]),
                  ),
                ],
              ),
              Column(
                children: [
                  Container(
                    width: screenSize.height * 0.5,
                    height: screenSize.height * 0.4,
                    decoration: const BoxDecoration(
                        color: AppColors.secondaryColor,
                        image: DecorationImage(
                          image:
                              AssetImage("assets/images/UserJourneyImage2.png"),
                        )),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                        color: AppColors.textColor,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(250),
                        )),
                    width: double.infinity,
                    height: screenSize.height * 0.6,
                    child: Column(children: [
                      const SizedBox(
                        height: 102,
                      ),
                      const Text(
                        "Fix Smarter, Drive Safer!",
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColor2),
                      ),
                      const SizedBox(
                        height: 82,
                      ),
                      Text(
                          'Get AI-powered repair solutions and avoid costly breakdowns.',
                          textAlign: TextAlign.center,
                          style: AppFonts.journeytext),
                      const SizedBox(height: 30),
                    ]),
                  ),
                ],
              ),
              Column(
                children: [
                  Container(
                    width: screenSize.height * 0.5,
                    height: screenSize.height * 0.4,
                    decoration: const BoxDecoration(
                        color: AppColors.secondaryColor,
                        image: DecorationImage(
                          image:
                              AssetImage("assets/images/UserJourneyImage3.png"),
                        )),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                        color: AppColors.textColor,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(250),
                        )),
                    width: double.infinity,
                    height: screenSize.height * 0.6,
                    child: Column(children: [
                      const SizedBox(
                        height: 102,
                      ),
                      const Text(
                        "Stay Road-Ready!",
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColor2),
                      ),
                      const SizedBox(
                        height: 82,
                      ),
                      Text(
                          'Prevent unexpected issues with real-time AI assistance.',
                          textAlign: TextAlign.center,
                          style: AppFonts.journeytext),
                      const SizedBox(height: 30),
                    ]),
                  ),
                ],
              )
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                          icon: Icon(Icons.arrow_back,
                              color: AppColors.mainColor),
                          onPressed: () =>
                              _model.pageViewController!.previousPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              )),
                      SmoothPageIndicator(
                        controller: _model.pageViewController ??=
                            PageController(initialPage: 0),
                        count: 3,
                        axisDirection: Axis.horizontal,
                        onDotClicked: (index) {
                          _model.pageViewController!.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.ease,
                          );
                          setState(() {}); // Ensure UI updates
                        },
                        effect: const SlideEffect(
                          spacing: 8,
                          radius: 8,
                          dotWidth: 8,
                          dotHeight: 8,
                          dotColor: Colors.grey,
                          activeDotColor: AppColors.mainColor,
                          paintStyle: PaintingStyle.fill,
                        ),
                      ),
                      IconButton(
                          icon: Icon(Icons.arrow_forward,
                              color: AppColors.mainColor),
                          onPressed: () => _model.pageViewController!.nextPage(
                                duration: const Duration(seconds: 1),
                                curve: Curves.easeInOut,
                              )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      Get.to(const HomeScreen());
                    },
                    child: const Text(
                      "Skip",
                      style: TextStyle(
                        color: AppColors.mainColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.mainColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
