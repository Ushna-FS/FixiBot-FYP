import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class CustomSearchBar extends StatefulWidget {
  final String hintText;
  final IconData icon;
  const CustomSearchBar({super.key, required this.hintText, required this.icon});

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  @override
  Widget build(BuildContext context) {
    return TextField(
       decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              prefixIcon: Icon(
                widget.icon,
                color: AppColors.mainColor
                    .withOpacity(0.8), // Lightened icon color
              ),
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: Colors.grey.shade400, // Light grey placeholder text
              ),
              filled: true,
              fillColor: Colors.white, // Background color
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none, // Remove default border
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.grey.shade300), // Subtle border
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.mainColor, width: 2.0),
              ),)
    );
  }
}