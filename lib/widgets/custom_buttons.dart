import 'package:flutter/material.dart';
import 'package:fixibot_app/constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final Color textColor;
  final bool isOutlined;
  final Widget? icon;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.color = AppColors.mainColor,
    this.textColor = AppColors.textColor,
    this.isOutlined = false,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: isOutlined
          ? OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: BorderSide(color: AppColors.mainColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onPressed,
              child: _buildContent(),
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onPressed,
              child: _buildContent(),
            ),
    );
  }

  Widget _buildContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          icon!,
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isOutlined ? AppColors.mainColor : textColor,
          ),
        ),
      ],
    );
  }
}

class CustomHomeButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final Color textColor;
  final bool isOutlined;
  final Widget? icon;

  const CustomHomeButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.color = const Color(0xFFFFAFA4), 
    this.textColor = Colors.white,
    this.isOutlined = false,
    this.icon,
  }) : super(key: key);

  

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 175,
      height: 35,
      child: isOutlined
          ? OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: BorderSide(color: color, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              onPressed: onPressed,
              child: _buildContent(),
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onPressed,
              child: _buildContent(),
            ),
    );
  }

  Widget _buildContent() {
    return Row(
      mainAxisSize: MainAxisSize.min, 
      children: [
        Text(
          text,
          style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.bold),
        ),
        if (icon != null) ...[
          SizedBox(width: 5), 
          icon!, 
        ],
      ],
    );
  }


}
