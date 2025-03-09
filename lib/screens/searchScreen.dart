import '../constants/app_colors.dart';
import 'homeScreen.dart';
import '../widgets/custom_searchBar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  @override
  Widget build(BuildContext context) {
    return  SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.secondaryColor,
        body:  Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
             Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Get.to(HomeScreen());
                    }, 
                    icon: Image.asset('assets/icons/back.png',
                    width: 30,
                    height:30),
                    ),
                  SizedBox( width: 10),
                  Expanded(
                    child: CustomSearchBar(
                      hintText: 'Search Here', 
                      icon: Icons.search),
                  )
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Recent searches", 
                  style: TextStyle(
                    color: AppColors.textColor4,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),),
                    TextButton(
                    onPressed: () {},
                    child: const Text("Clear All", 
                    style: TextStyle(
                      color: AppColors.textColor4,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),))
                ],
              ),
             Divider(thickness: 1),
             ListTile(
              tileColor: AppColors.textColor3,
              title: Text("Feature1",
              style: TextStyle(
                color: AppColors.textColor4,
                fontSize: 14,
              )),
              trailing: IconButton(onPressed: () {}, icon: Icon(Icons.cancel), color: AppColors.textColor4,),
             )
            ],
          ),
        ),
      ),
    );
  }
}