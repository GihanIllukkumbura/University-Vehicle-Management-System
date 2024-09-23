import 'package:flutter/material.dart';

class Spalshscreen extends StatelessWidget {
  const Spalshscreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow,
      appBar: AppBar(
        title: Text('Loading...'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'WAYA Vehicle Management System',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Image.asset(
              'assets/chat.png', // Path to your car image
              width: 100,
              height: 100,
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(), // Add a loading indicator
          ],
        ),
      ),
    );
  }
}
