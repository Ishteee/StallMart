import 'package:flutter/material.dart';
import 'package:xaviers_market/customerscreens/customer_cash_orders.dart';
import 'package:xaviers_market/customerscreens/customer_online_orders.dart';
import 'package:xaviers_market/customerscreens/customer_pending_orders.dart';

class TestBookingScreen extends StatefulWidget {
  final String userId;
  final int index;

  TestBookingScreen(this.userId,this.index);

  @override
  _TestBookingScreenState createState() => _TestBookingScreenState();
}

class _TestBookingScreenState extends State<TestBookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.index = 0; // Set default tab index to 0 (first page)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 233, 226),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 242, 233, 226),
        title: Text(
          'Orders',
          style: TextStyle(
              color: const Color.fromARGB(255, 126, 70, 62),
              fontWeight: FontWeight.bold,
              fontSize: 22),
        ),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Online Orders'),
              Tab(text: 'Cash Orders'),
              Tab(text: 'Pending Orders'),
            ],
            labelColor: const Color.fromARGB(255, 126, 70, 62),
            unselectedLabelColor: const Color.fromARGB(255, 126, 70, 62),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                CompletedOnlineOrdersScreen(widget.userId),
                CompletedCashOrdersScreen(widget.userId),
                PendingBookingsScreen(widget.userId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
