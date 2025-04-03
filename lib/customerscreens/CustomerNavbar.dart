// ignore_for_file: file_names, camel_case_types, library_private_types_in_public_api, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:xaviers_market/customerscreens/customer_bookings_tab.dart';
import 'Cart.dart';
import 'my_orders.dart';
import 'Profile.dart';
import 'customer_homescreen.dart';

class customerBottomNavigation extends StatefulWidget {
  final String userId;
  final int page;
  const customerBottomNavigation(this.userId, this.page);
  @override
  _BottomNavigationState createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<customerBottomNavigation> {
  late int _currentIndex; // Declare _currentIndex

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.page; // Initialize _currentIndex with the passed page
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      CustomerHomeScreen(widget.userId),
      TestBookingScreen(widget.userId,0),
      Cart(widget.userId),
      Profile(widget.userId),
    ];

    return MaterialApp(
        title: 'Bottom Navigation Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          canvasColor: const Color.fromARGB(
              255, 242, 233, 226), // Change canvas color here
        ),
        home: Scaffold(
          body: pages[_currentIndex],
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
              selectedItemColor: Color.fromARGB(255, 92, 0, 106),
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
                  icon: Icon(Icons.shopping_cart),
                  label: 'Cart',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ));
  }
}
