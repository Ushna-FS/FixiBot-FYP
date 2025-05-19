import '../constants/app_colors.dart';
import 'package:flutter/material.dart';

class EmailTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const EmailTextField({
    super.key,
    required this.controller,
    this.hintText = "Email",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(255, 129, 126, 126),
            blurRadius: 5,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
          if (value == null || value.isEmpty) return 'Please enter your email';
          if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
          return null;
        },
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          prefixIcon: Icon(Icons.email, color: AppColors.mainColor.withOpacity(0.8)),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.mainColor, width: 2.0),
          ),
        ),
      ),
    );
  }
}