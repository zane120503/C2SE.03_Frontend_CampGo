import 'package:flutter/material.dart';
import 'package:CampGo/pages/Home/widgets/CategoriesWidget.dart';
import 'package:CampGo/pages/Home/widgets/HomeAppBar.dart';
import 'package:CampGo/pages/Home/widgets/HomeItemsWidget.dart';
import 'package:CampGo/pages/Search/SearchPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? selectedCategoryId;
  double? minPrice;
  double? maxPrice;

  void _handleFiltersApplied(String? categoryId, double? min, double? max) {
    print('HomePage _handleFiltersApplied:');
    print('Category: $categoryId');
    print('Min Price: $min');
    print('Max Price: $max');
    
    setState(() {
      selectedCategoryId = categoryId;
      minPrice = min;
      maxPrice = max;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          HomeAppBar(
            onFiltersApplied: _handleFiltersApplied,
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 15),
              decoration: const BoxDecoration(
                color: Color(0xFFEDECF2),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SearchPage()),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Tìm kiếm sản phẩm...',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.search,
                            size: 27,
                            color: Color(0xFF2B2321),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    alignment: Alignment.centerLeft,
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      "Categories",
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  CategoriesWidget(
                    onCategorySelected: (categoryId) {
                      print('HomePage received categoryId: $categoryId');
                      setState(() {
                        selectedCategoryId = categoryId;
                      });
                    },
                  ),
                  Container(
                    alignment: Alignment.centerLeft,
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      "All Products",
                      style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                    ),
                  ), 
                  Expanded(
                    child: HomeItemsWidget(
                      selectedCategory: selectedCategoryId ?? '',
                      minPrice: minPrice,
                      maxPrice: maxPrice,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
