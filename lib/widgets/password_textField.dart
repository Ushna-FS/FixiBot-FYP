import '../constants/app_colors.dart';
import 'package:flutter/material.dart';

class PasswordTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final bool isPasswordVisible;

  const PasswordTextField({
    super.key,
    this.controller,
    this.hintText = "Password",
    required this.isPasswordVisible,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  late final TextEditingController _effectiveController;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _effectiveController = widget.controller ?? TextEditingController();
    _obscureText = !widget.isPasswordVisible;
  }

  @override
  void didUpdateWidget(PasswordTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _effectiveController = widget.controller ?? TextEditingController();
    }
  }

  @override
  void dispose() {
    // Only dispose if we created it
    if (widget.controller == null) {
      _effectiveController.dispose();
    }
    super.dispose();
  }

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
        controller: _effectiveController,
        obscureText: _obscureText,
        validator: (value) {
          if (value == null || value.isEmpty)
            return 'Please enter your password';
          if (value.length < 6) return 'Password must be at least 6 characters';
          return null;
        },
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          prefixIcon:
              Icon(Icons.lock, color: AppColors.mainColor.withOpacity(0.8)),
          hintText: widget.hintText,
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
            borderSide:
                const BorderSide(color: AppColors.mainColor, width: 2.0),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey.shade300,
            ),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          ),
        ),
      ),
    );
  }
}
