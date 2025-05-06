import 'package:CampGo/pages/Home/HomePage.dart';
import 'package:CampGo/pages/Home/widgets/HomeMainNavigationBar.dart';
import 'package:CampGo/pages/Login/LoginPage.dart';
import 'package:CampGo/pages/ChatBot/ChatBotPage.dart';
import 'package:CampGo/pages/Product/ProductPage.dart';
import 'package:CampGo/pages/Search/SearchPage.dart';
import 'package:CampGo/pages/SignUp/SignUpPage.dart';
import 'package:CampGo/pages/StartNow/StartNowPage.dart';
import 'package:CampGo/pages/Checkout/CheckOutPage.dart';
import 'package:CampGo/pages/Cart/CartPage.dart';
import 'package:CampGo/pages/GroupTracking/GroupTrackingPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Cấu hình Firebase Realtime Database với URL đúng
  FirebaseDatabase.instance.databaseURL =
      'https://campgo-project-default-rtdb.asia-southeast1.firebasedatabase.app/';

  // Tạo AuthProvider
  final authProvider = AuthProvider();

  runApp(MyApp(authProvider: authProvider));
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;

  const MyApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: authProvider,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(scaffoldBackgroundColor: Colors.white),
        navigatorKey: navigatorKey,
        routes: {
          "/": (context) => const StartNowPage(),
          "/login": (context) => const LoginPage(),
          "/register": (context) => const SignUpPage(),
          "/home": (context) => const HomePage(),
          "/main": (context) => const HomeMainNavigationBar(),
          "/cart": (context) => const CartPage(),
          "/group-tracking": (context) => const GroupTrackingPage(),
          // "/search": (context) => SearchPage(),
          "/product": (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            return ProductPage(productId: args?['productId']?.toString() ?? '');
          },
          // "/notifications": (context) => NotificationPage(),
        },
        initialRoute: "/",
      ),
    );
  }
}
