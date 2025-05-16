import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/screens/chatbot/chatView.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  _CustomNavBarState createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  int hoveredIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        ClipPath(
          clipper: NavBarClipper(),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(iconPath: 'assets/icons/nav-icons/home.png', index: 0),
                _buildNavItem(iconPath: 'assets/icons/nav-icons/search.png', index: 1),
                const SizedBox(width: 60), 
                _buildNavItem(iconPath: 'assets/icons/nav-icons/mechanic.png', index: 2),
                _buildNavItem(iconPath: 'assets/icons/nav-icons/user.png', index: 3),
              ],
            ),
          ),
        ),

        Positioned(
          top: -35, 
          child: Transform.translate(
            offset: const Offset(0, -5),
            child: GestureDetector(
              onTap: () => widget.onTap(1),
              child: Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.mainColor,
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromARGB(255, 224, 133, 105),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => Get.to(const ChatScreen()),
                  icon: Image.asset(
                    'assets/icons/nav-icons/chat.png',
                    color: Colors.white,
                    width: 30,
                    height: 30,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem({required String iconPath, required int index}) {
    bool isSelected = widget.currentIndex == index;
    bool isHovered = hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => hoveredIndex = index),
      onExit: (_) => setState(() => hoveredIndex = -1),
      child: GestureDetector(
        onTap: () => widget.onTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              iconPath,
              
              color: isSelected || isHovered ? AppColors.mainColor : Colors.grey,
            ),
            if (isHovered || isSelected) 
              Text(
                _getNavLabel(index),
                style: const TextStyle(fontSize: 12, color: AppColors.mainColor),
              ),
          ],
        ),
      ),
    );
  }

  String _getNavLabel(int index) {
    switch (index) {
      case 0: return "Home";
      case 1: return "Search";
      case 2: return "Find Mechanic";
      case 3: return "Profile";
      default: return "";
    }
  }
}

class NavBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    double width = size.width;
    double height = size.height;

    path.lineTo(width * 0.35, 0);
    path.quadraticBezierTo(width * 0.5, height * 0.985, width * 0.65, 0);
    path.lineTo(width, 0);
    path.lineTo(width, height);
    path.lineTo(0, height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}


