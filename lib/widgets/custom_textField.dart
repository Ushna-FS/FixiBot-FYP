// import '../constants/app_colors.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// class CustomTextField extends StatefulWidget {
//   final String hintText;
//   final IconData icon;
//   final bool isPassword;
//   final TextEditingController? controller;
//   final TextInputType keyboardType;

//   const CustomTextField({
//     super.key,
//     required this.hintText,
//     required this.icon,
//     this.isPassword = false,
//     this.controller,
//     this.keyboardType = TextInputType.text,
//   });

//   @override
//   _CustomTextFieldState createState() => _CustomTextFieldState();
// }

// class _CustomTextFieldState extends State<CustomTextField> {
//   bool _obscureText = true;
//   String? _errorText;
//   late TextEditingController _effectiveController;
//    bool _isExternalController = false;

  

//   @override
//   void didUpdateWidget(CustomTextField oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     // If the external controller changes, update our reference
//     if (widget.controller != oldWidget.controller) {
//       _effectiveController = widget.controller ?? TextEditingController();
//     }
//   }

// @override
//   void initState() {
//     super.initState();
//     _isExternalController = widget.controller != null;
//     _effectiveController = widget.controller ?? TextEditingController();
//   }

//   @override
//   void dispose() {
//     if (!_isExternalController) {
//       _effectiveController.dispose();
//     }
//     super.dispose();
//   }
//   String? _validateInput(String value) {
//     if (widget.keyboardType == TextInputType.emailAddress) {
//       final emailRegex =
//           RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
//       if (!emailRegex.hasMatch(value)) return "Enter a valid email";
//     } else if (widget.keyboardType == TextInputType.number) {
//       final numberRegex = RegExp(r'^[0-9]+$');
//       if (!numberRegex.hasMatch(value)) return "Enter a valid number";
//     } else if (widget.keyboardType == TextInputType.name) {
//       final nameRegex = RegExp(r"^[a-zA-Z\s]+$");
//       if (!nameRegex.hasMatch(value)) return "Enter a valid name";
//     }
//     return null;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: const [
//               BoxShadow(
//                 color: Color.fromARGB(255, 129, 126, 126),
//                 blurRadius: 5,
//                 offset: Offset(2, 2),
//               ),
//             ],
//           ),
//           child: TextField(
//             controller: _effectiveController, // Use the correct controller
//             obscureText: widget.isPassword ? _obscureText : false,
//             keyboardType: widget.keyboardType,
//             inputFormatters: widget.keyboardType == TextInputType.number
//                 ? [FilteringTextInputFormatter.digitsOnly]
//                 : null,
//             onChanged: (value) {
//               setState(() {
//                 _errorText = _validateInput(value);
//               });
//             },
//             decoration: InputDecoration(
//               contentPadding:
//                   const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
//               prefixIcon: Icon(
//                 widget.icon,
//                 color: AppColors.mainColor.withOpacity(0.8),
//               ),
//               hintText: widget.hintText,
//               hintStyle: TextStyle(
//                 color: Colors.grey.shade400,
//               ),
//               filled: true,
//               fillColor: Colors.white,
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide.none,
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide(color: Colors.grey.shade300),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide:
//                     const BorderSide(color: AppColors.mainColor, width: 2.0),
//               ),
//               errorText: _errorText,
//               suffixIcon: widget.isPassword
//                   ? IconButton(
//                       icon: Icon(
//                         _obscureText ? Icons.visibility_off : Icons.visibility,
//                         color: Colors.grey.shade300,
//                       ),
//                       onPressed: () {
//                         setState(() {
//                           _obscureText = !_obscureText;
//                         });
//                       },
//                     )
//                   : null,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }


import '../constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  final String hintText;
  final IconData? icon;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final VoidCallback? onIconPressed; // ✅ optional callback

  const CustomTextField({
    super.key,
    required this.hintText,
    this.icon,
    this.isPassword = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.onIconPressed,
  });

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;
  String? _errorText;
  late TextEditingController _effectiveController;
  bool _isExternalController = false;

  @override
  void initState() {
    super.initState();
    _isExternalController = widget.controller != null;
    _effectiveController = widget.controller ?? TextEditingController();
  }

  @override
  void didUpdateWidget(CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _effectiveController = widget.controller ?? TextEditingController();
    }
  }

  @override
  void dispose() {
    if (!_isExternalController) {
      _effectiveController.dispose();
    }
    super.dispose();
  }

  String? _validateInput(String value) {
    if (widget.keyboardType == TextInputType.emailAddress) {
      final emailRegex =
          RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(value)) return "Enter a valid email";
    } else if (widget.keyboardType == TextInputType.number) {
      final numberRegex = RegExp(r'^[0-9]+$');
      if (!numberRegex.hasMatch(value)) return "Enter a valid number";
    } else if (widget.keyboardType == TextInputType.name) {
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
            controller: _effectiveController,
            obscureText: widget.isPassword ? _obscureText : false,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.keyboardType == TextInputType.number
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
            onChanged: (value) {
              setState(() {
                _errorText = _validateInput(value);
              });
            },
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              prefixIcon: widget.icon != null
                  ? GestureDetector(
                      onTap: widget.onIconPressed,
                      child: Icon(
                        widget.icon,
                        color: AppColors.mainColor.withOpacity(
                            widget.onIconPressed != null ? 0.8 : 0.4),
                      ),
                    )
                  : null,
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
                borderSide:
                    const BorderSide(color: AppColors.mainColor, width: 2.0),
              ),
              errorText: _errorText,
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey.shade300,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
