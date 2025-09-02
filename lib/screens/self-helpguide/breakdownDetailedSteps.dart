import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_fontStyles.dart';

class BreakdownDetailScreen extends StatelessWidget {
  final String issueName;
  final String vehicleType;
  final Map<String, dynamic> details;

  const BreakdownDetailScreen({
    Key? key,
    required this.issueName,
    required this.vehicleType,
    required this.details,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tools = (details["Tools Required"] != null)
        ? List<String>.from(details["Tools Required"])
        : []; // safe fallback

    final steps = (details["Steps"] != null)
        ? List<String>.from(details["Steps"])
        : [];

    final images = (details["Images"] != null)
        ? Map<String, String>.from(details["Images"])
        : {};

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.mainColor,
        title: Text("$issueName - $vehicleType"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tools
            if (tools.isNotEmpty) ...[
              Text("Tools Required:",
                  style: AppFonts.customTextStyle(
                      fontSize: 18,
                      color: AppColors.mainColor,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...tools.map((t) => ListTile(
                    leading: const Icon(Icons.build),
                    title: Text(t),
                  )),
              const SizedBox(height: 20),
            ],

            // Steps
            if (steps.isNotEmpty) ...[
              Text("Steps:",
                  style: AppFonts.customTextStyle(
                      fontSize: 18,
                      color: AppColors.mainColor,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...steps.asMap().entries.map((e) => ListTile(
                    leading: CircleAvatar(
                      radius: 12,
                      child: Text("${e.key + 1}"),
                    ),
                    title: Text(e.value),
                  )),
              const SizedBox(height: 20),
            ],

            // Images
            if (images.isNotEmpty) ...[
              Text("Illustrations:",
                  style: AppFonts.customTextStyle(
                      fontSize: 18,
                      color: AppColors.mainColor,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              // Wrap(
              //   spacing: 12,
              //   runSpacing: 12,
              //   children: images.values
              //       .map((imgPath) => ClipRRect(
              //             borderRadius: BorderRadius.circular(12),
              //             child: Image.asset(
              //               imgPath,
              //               height: 250,
              //               width: 250,
              //               fit: BoxFit.cover,
              //             ),
              //           ))
              //       .toList(),
              // ),
              Center(
  child: Wrap(
    spacing: 12,
    runSpacing: 12,
    alignment: WrapAlignment.center,
    children: images.values
        .map((imgPath) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imgPath,
                height: 250,
                width: 250,
                fit: BoxFit.cover,
              ),
            ))
        .toList(),
  ),
)

            ],
          ],
        ),
      ),
    );
  }
}