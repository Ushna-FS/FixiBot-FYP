import '../constants/app_colors.dart';
import '../constants/app_fontStyles.dart';
import 'package:flutter/material.dart';

class MechanicCard extends StatelessWidget {
  final String mechanic;
  final String expertise;
  final String phNum;
  final String distance;
  final String imageSource;
  final String? rating;

  const MechanicCard(
      {super.key,
      required this.mechanic,
      required this.expertise,
      required this.phNum,
      required this.distance,
      required this.imageSource,
      this.rating});

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: const BoxDecoration(
            color: AppColors.textColor,
            borderRadius: BorderRadius.all(Radius.circular(10))),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Stack(children: [
                Image.asset(
                  imageSource,
                ),
                rating!.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Container(
                          decoration: const BoxDecoration(
                              color: AppColors.textColor,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5))),
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 3.0, right: 3.0),
                            child: Row(
                              children: [
                                Image.asset("assets/icons/rating.png"),
                                Text(rating!)
                              ],
                            ),
                          ),
                        ),
                      )
                    : Container()
              ]),
              SizedBox(
                width: screenSize.width * 0.01,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mechanic,
                      style: AppFonts.montserratText2,
                    ),
                    SizedBox(
                      height: screenSize.height * 0.01,
                    ),
                    Text(
                      expertise,
                      style: AppFonts.montserratText4,
                    ),
                    SizedBox(
                      height: screenSize.height * 0.01,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Contact: ",
                          style: AppFonts.montserratText3,
                        ),
                        Text(
                          phNum,
                          style: AppFonts.montserratText4,
                        ),
                      ],
                    ),
                    SizedBox(
                      height: screenSize.height * 0.01,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset("assets/icons/locationIcon.png"),
                        Text(
                          distance,
                          style: AppFonts.montserratText5,
                        )
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
