// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:xaviers_market/sellerscreens/seller_Profile.dart';
import 'package:xaviers_market/sellerscreens/seller_bookings_tab.dart';
import 'package:xaviers_market/sellerscreens/seller_homescreen.dart';
import 'package:xaviers_market/sellerscreens/transactions.dart';
import 'package:xaviers_market/sellerscreens/transactions.dart';

class BottomNavigation extends StatefulWidget {
  final String userId;
  const BottomNavigation(this.userId, {super.key});
  @override
  // ignore: library_private_types_in_public_api
  _BottomNavigationState createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      SellerHomeScreen(widget.userId),
      Test2BookingScreen(widget.userId, 0),
      Profile(userId:widget.userId),
    ];

    return MaterialApp(
      title: 'Bottom Navigation Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        canvasColor:
            const Color.fromARGB(255, 242, 233, 226), // Change canvas color here
      ),
      home: Scaffold(
        body: _pages[_currentIndex],
        bottomNavigationBar: Container(
          height: 70, // Adjust the height as needed
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 242, 233, 226),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            selectedItemColor: Colors.purple,
            unselectedItemColor: const Color.fromARGB(255, 126, 70, 62),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              
              const BottomNavigationBarItem(
                icon: Icon(Icons.money),
                label: 'Orders',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}