import 'package:fixibot_app/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFonts {
  static TextStyle montserratBold60 = GoogleFonts.montserrat(
    fontWeight: FontWeight.w700,
    fontSize: 60,
    height: 73.14 / 60,
    color: AppColors.textColor,
  );
  static TextStyle montserratHeading = GoogleFonts.montserrat(
    fontWeight: FontWeight.w500,
    fontSize: 24,
    color: AppColors.textColor,
  );
  static TextStyle montserratBlackHeading = GoogleFonts.montserrat(
    fontWeight: FontWeight.w500,
    fontSize: 20,
    color: AppColors.textColor2,
  );

<<<<<<< HEAD
  static TextStyle journeytext = GoogleFonts.montserrat(
    fontWeight: FontWeight.w500,
    fontSize: 18,
    color: AppColors.textColor3,
  );

  static TextStyle customTextStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.montserrat(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }
=======
  static TextStyle montserratText = GoogleFonts.montserrat(
    fontWeight: FontWeight.w200,
    fontSize: 14,
    color: AppColors.textColor,
  );
  static TextStyle montserratText2 = GoogleFonts.montserrat(
    fontWeight: FontWeight.w500,
    fontSize: 18,
    color: AppColors.textColor2,
  );
  static TextStyle montserratText3 = GoogleFonts.montserrat(
    fontWeight: FontWeight.w300,
    fontSize: 12,
    color: AppColors.textColor2,
  );

  static TextStyle montserratText4 = GoogleFonts.montserrat(
    fontWeight: FontWeight.w300,
    fontSize: 12,
    color: AppColors.mainColor,
  );

  static TextStyle montserratText5 = GoogleFonts.montserrat(
    fontWeight: FontWeight.w500,
    fontSize: 12,
    color: AppColors.textColor2,
  );

  static TextStyle montserratWhiteText = GoogleFonts.montserrat(
    fontWeight: FontWeight.w500,
    fontSize: 16,
    color: AppColors.textColor,
  );

  static TextStyle montserratMainText = GoogleFonts.montserrat(
    fontWeight: FontWeight.w500,
    fontSize: 16,
    color: AppColors.mainColor,
  );
>>>>>>> b09f093bcf9e194c031a0c364bc75545adef8a6b
}

