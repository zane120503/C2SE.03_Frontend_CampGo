import 'package:flutter/material.dart';
import 'package:CampGo/pages/Home/widgets/CategoriesWidget.dart';
import 'package:CampGo/pages/Home/widgets/HomeAppBar.dart';
import 'package:CampGo/pages/Home/widgets/HomeItemsWidget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const HomeAppBar(),
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
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Search here...',
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
                  CategoriesWidget(),
                  Container(
                    alignment: Alignment.centerLeft,
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      "All Products",
                      style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                    ),
                  ), 
                  Expanded(
                    child: const HomeItemWidget(),
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
