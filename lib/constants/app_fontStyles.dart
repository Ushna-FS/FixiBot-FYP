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
}
