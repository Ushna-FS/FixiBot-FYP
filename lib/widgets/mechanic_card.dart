import '../constants/app_colors.dart';
import '../constants/app_fontStyles.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MechanicCard extends StatelessWidget {
  final String mechanic;
  final String expertise;
  final String phNum;
  final String distance;
  final String imageSource;
  final String? rating;

  const MechanicCard({
    super.key,
    required this.mechanic,
    required this.expertise,
    required this.phNum,
    required this.distance,
    required this.imageSource,
    this.rating,
  });

  // Check if the image source is a network URL
  bool get isNetworkImage => imageSource.startsWith('http') || 
                           imageSource.startsWith('https');

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.textColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Stack(
                children: [
                  Container(
                    width: isSmallScreen ? 70 : 80,
                    height: isSmallScreen ? 70 : 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.secondaryColor,
                    ),
                    child: _buildMechanicImage(),
                  ),
                  if (rating != null && rating!.isNotEmpty)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.textColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              "assets/icons/rating.png",
                              width: 12,
                              height: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              rating!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.mainColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(width: 16),
              
              // Details Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Mechanic Name
                    Text(
                      mechanic,
                      style: AppFonts.montserratText2.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Expertise
                    Text(
                      expertise,
                      style: AppFonts.montserratText4,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Contact Number
                    Row(
                      children: [
                        Text(
                          "Contact: ",
                          style: AppFonts.montserratText3.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            phNum,
                            style: AppFonts.montserratText4,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Distance
                    Row(
                      children: [
                        Image.asset(
                          "assets/icons/locationIcon.png",
                          width: 14,
                          height: 14,
                          color: AppColors.mainColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            distance,
                            style: AppFonts.montserratText5,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMechanicImage() {
    if (imageSource.isEmpty) {
      // Fallback to default asset if no image is provided
      return Image.asset(
        'assets/icons/mechanicShop.png',
        fit: BoxFit.cover,
      );
    } else if (isNetworkImage) {
      // Use CachedNetworkImage for network URLs
      return CachedNetworkImage(
        imageUrl: imageSource,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.mainColor,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Image.asset(
          'assets/icons/mechanicShop.png',
          fit: BoxFit.cover,
        ),
      );
    } else {
      // Use AssetImage for local assets
      return Image.asset(
        imageSource,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/icons/mechanicShop.png',
          fit: BoxFit.cover,
        ),
      );
    }
  }
}