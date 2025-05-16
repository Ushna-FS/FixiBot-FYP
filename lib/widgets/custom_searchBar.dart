import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomSearchBar extends StatefulWidget {
  final String hintText;
  final IconData icon;
  final TextEditingController? controller; // Optional controller from parent

  const CustomSearchBar({
    super.key,
    required this.hintText,
    required this.icon,
    this.controller, // Allow parent to pass a controller
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Use the provided controller or create a new one
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    // Only dispose the controller if we created it ourselves
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller, // Use our managed controller
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        prefixIcon: Icon(
          widget.icon,
          color: AppColors.mainColor.withOpacity(0.8),
        ),
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
        ),
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
    );
  }
}
