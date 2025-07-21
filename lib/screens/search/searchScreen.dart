import 'package:fixibot_app/screens/homeScreen.dart';
import 'package:fixibot_app/screens/search/search_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SearchModel> _filteredModules = [];

  @override
  void initState() {
    super.initState();
    _filteredModules = [];
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredModules = [];
      } else {
        _filteredModules = SearchModel.modules
            .where((module) =>
                module.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      appBar: AppBar(
      backgroundColor: AppColors.secondaryColor,
        leading: IconButton(
          onPressed: () {
            Get.to(const HomeScreen());
          },
          icon: Image.asset('assets/icons/back.png', width: 30, height: 30),
        ),
        title: Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: 'Search Here',
              suffixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.textColor3,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: _searchController.text.isEmpty
                  ? const Center(
                      child: Text("...",
                          style: TextStyle(color: AppColors.textColor2)),
                    )
                  : _filteredModules.isEmpty
                      ? const Center(
                          child: Text("No results found",
                              style: TextStyle(color: AppColors.textColor2)),
                        )
                      : ListView.builder(
                          itemCount: _filteredModules.length,
                          itemBuilder: (context, index) {
                            final module = _filteredModules[index];
                            return Card(
                              color: AppColors.textColor3,
                              child: ListTile(
                                title: Text(
                                  module.name,
                                  style: const TextStyle(
                                      color: AppColors.textColor4,
                                      fontSize: 14),
                                ),
                                onTap: () {
                                  Get.to(module.screen);
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
