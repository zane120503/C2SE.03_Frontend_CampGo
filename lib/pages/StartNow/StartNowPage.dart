import 'package:flutter/material.dart';

class StartNowPage extends StatelessWidget {
  const StartNowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/StartNow.jpg'),
                fit: BoxFit.cover,
                alignment: Alignment(1, 0),
              ),
            ),
          ),
          Positioned(
            bottom: 90,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 215, 159, 54),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Start Now',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
