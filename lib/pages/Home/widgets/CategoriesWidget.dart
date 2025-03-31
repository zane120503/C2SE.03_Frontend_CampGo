import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class CategoriesWidget extends StatefulWidget {
  final Function(String)? onCategorySelected;
  
  const CategoriesWidget({
    super.key,
    this.onCategorySelected,
  });

  @override
  State<CategoriesWidget> createState() => _CategoriesWidgetState();
}

class _CategoriesWidgetState extends State<CategoriesWidget> {
  List<Map<String, dynamic>> categories = [];
  int selectedIndex = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      final String response = await rootBundle.loadString('assets/data/Categories.json');
      final data = await json.decode(response);
      
      setState(() {
        categories = List<Map<String, dynamic>>.from(data['categories']);
        isLoading = false;
      });
    } catch (e) {
      print('Lỗi khi tải danh mục: $e');
    }
  }

  void _onCategoryTap(int index) {
    setState(() {
      selectedIndex = index;
    });
    
    if (widget.onCategorySelected != null) {
      widget.onCategorySelected!(categories[index]['title']);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: List.generate(
          categories.length,
          (index) => GestureDetector(
            onTap: () => _onCategoryTap(index),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
              decoration: BoxDecoration(
                color: selectedIndex == index ? const Color(0xFF2B2321) : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (categories[index]["imagePath"] != null)
                    Image.asset(
                      categories[index]["imagePath"],
                      width: 30,
                      height: 30,
                      color: selectedIndex == index ? Colors.white : const Color(0xFF2B2321),
                    ),
                  if (categories[index]["imagePath"] != null)
                    const SizedBox(width: 5),
                  Text(
                    categories[index]["title"],
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: selectedIndex == index ? Colors.white : const Color(0xFF2B2321),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}