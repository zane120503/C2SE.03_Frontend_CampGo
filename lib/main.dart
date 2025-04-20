import 'package:CampGo/pages/Home/HomePage.dart';
import 'package:CampGo/pages/Home/widgets/HomeMainNavigationBar.dart';
import 'package:CampGo/pages/Login/LoginPage.dart';
import 'package:CampGo/pages/Notification/NotificationPage.dart';
import 'package:CampGo/pages/Product/ProductPage.dart';
import 'package:CampGo/pages/Search/SearchPage.dart';
import 'package:CampGo/pages/SignUp/SignUpPage.dart';
import 'package:CampGo/pages/StartNow/StartNowPage.dart';
import 'package:CampGo/pages/Checkout/CheckOutPage.dart';
import 'package:CampGo/pages/Cart/CartPage.dart';
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
      ),
      navigatorKey: navigatorKey,
      routes: {
        "/": (context) => const StartNowPage(),
        "/login": (context) => const LoginPage(),
        "/register": (context) => const SignUpPage(),
        "/home": (context) => const HomePage(),
        "/main": (context) => const HomeMainNavigationBar(),
        "/cart": (context) => const CartPage(),
        
        // "/search": (context) => SearchPage(), 
        "/product": (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return ProductPage(
            productId: args?['productId']?.toString() ?? '',
          );
        },
        // "/notifications": (context) => NotificationPage(),
      },
      initialRoute: "/",
    );
  }
}
