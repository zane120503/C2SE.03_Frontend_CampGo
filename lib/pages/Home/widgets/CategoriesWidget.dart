import 'package:flutter/material.dart';
import 'package:CampGo/services/api_service.dart';

class CategoriesWidget extends StatefulWidget {
  final Function(String?)? onCategorySelected;

  const CategoriesWidget({
    Key? key,
    this.onCategorySelected,
  }) : super(key: key);

  @override
  State<CategoriesWidget> createState() => _CategoriesWidgetState();
}

class _CategoriesWidgetState extends State<CategoriesWidget> {
  List<dynamic> categories = [];
  String? selectedCategoryId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      final response = await APIService.getAllCategories();
      print('Categories response: $response');

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          categories = [
            {'_id': null, 'categoryName': 'All Products'}, 
            ...response['data']
          ];
          isLoading = false;
        });
      } else {
        print('Error loading categories: ${response['message']}');
        setState(() {
          categories = [{'_id': null, 'categoryName': 'All Products'}];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        categories = [{'_id': null, 'categoryName': 'All Products'}];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = selectedCategoryId == category['_id'];
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedCategoryId = category['_id'];
                });
                print('Selected category ID: ${category['_id']}');
                widget.onCategorySelected?.call(category['_id']);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2B2321) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    if (category['imageURL'] != null && category['imageURL'].isNotEmpty)
                      Image.network(
                        category['imageURL'],
                        width: 24,
                        height: 24,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.category, size: 24);
                        },
                      ),
                    if (category['imageURL'] != null && category['imageURL'].isNotEmpty)
                      const SizedBox(width: 8),
                    Text(
                      category['categoryName'] ?? '',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}