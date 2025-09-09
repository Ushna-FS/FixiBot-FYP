import 'package:flutter/material.dart';
import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/constants/app_fontStyles.dart';
import '../screens/auth/controller/shared_pref_helper.dart';

class HomeHeaderBox extends StatefulWidget {
  const HomeHeaderBox({super.key});

  @override
  _HomeHeaderBoxState createState() => _HomeHeaderBoxState();
}

class _HomeHeaderBoxState extends State<HomeHeaderBox> {
  final SharedPrefsHelper _sharedPrefs = SharedPrefsHelper();

  int? selectedIndex;
  String userName = 'Guest';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

 Future<void> _loadUserName() async {
  final name = await _sharedPrefs.getString("full_name");

  if (mounted) {
    setState(() {
      userName = (name != null && name.trim().isNotEmpty) ? name : "User";
    });
  }
  print("Loaded from prefs: full_name=$name");

}


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFF715B),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(110),
          bottomRight: Radius.circular(110),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(35, 10, 0, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hello $userName",
            style: AppFonts.HomeheaderBox,
          ),
          Text(
            "Start Your Smart Journey.",
            style: AppFonts.montserratHomeAppbar,
          ),
          const SizedBox(height: 20),
          Text(
            "Your Vehicles",
            style: AppFonts.HomeheaderBox,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = 0;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedIndex == 0
                            ? AppColors.minorColor
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: selectedIndex == 0
                          ? [
                              BoxShadow(
                                color: Colors.blue.shade800,
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: CircleAvatar(
                      backgroundColor: AppColors.textColor,
                      radius: 25,
                      child: Image.asset('assets/icons/sportbike.png'),
                    ),
                  ),
                ),
                const SizedBox(width: 25),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = 1;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedIndex == 1
                            ? AppColors.minorColor
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: selectedIndex == 1
                          ? [
                              BoxShadow(
                                color: Colors.blue.shade800,
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: CircleAvatar(
                      backgroundColor: AppColors.textColor,
                      radius: 25,
                      child: Image.asset('assets/icons/car.png'),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
