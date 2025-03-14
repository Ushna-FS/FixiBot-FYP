import '../constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType keyboardType; // Define input type

  const CustomTextField({
    Key? key,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    this.controller,
    this.keyboardType = TextInputType.text, // Default to text input
  }) : super(key: key);

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;
  String? _errorText;

  // Validate user input based on keyboardType
  String? _validateInput(String value) {
    if (widget.keyboardType == TextInputType.emailAddress) {
      // Email validation
      final emailRegex =
          RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(value)) return "Enter a valid email";
    } else if (widget.keyboardType == TextInputType.number) {
      // Number validation
      final numberRegex = RegExp(r'^[0-9]+$');
      if (!numberRegex.hasMatch(value)) return "Enter a valid number";
    } else if (widget.keyboardType == TextInputType.name) {
      // Name validation (letters only)
      final nameRegex = RegExp(r"^[a-zA-Z\s]+$");
      if (!nameRegex.hasMatch(value)) return "Enter a valid name";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
          child: TextField(
            controller: widget.controller,
            obscureText: widget.isPassword ? _obscureText : false,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.keyboardType == TextInputType.number
                ? [
                    FilteringTextInputFormatter.digitsOnly
                  ] // Restrict input to numbers
                : null,
            onChanged: (value) {
              setState(() {
                _errorText = _validateInput(value); // Validate input
              });
            },
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
              ),
              errorText: _errorText, // Show error message
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey.shade300,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText; // Toggle obscureText
                        });
                      },
                    )
                  : null, // No suffix for non-password fields
            ),
          ),
        ),
      ],
    );
  }
}
