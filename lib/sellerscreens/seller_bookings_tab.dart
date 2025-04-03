import 'package:flutter/material.dart';
import 'package:xaviers_market/customerscreens/customer_online_orders.dart';
import 'package:xaviers_market/customerscreens/customer_pending_orders.dart';
import 'package:xaviers_market/sellerscreens/seller_cash_orders.dart';
import 'package:xaviers_market/sellerscreens/seller_online_orders.dart';
import 'package:xaviers_market/sellerscreens/seller_pending_bookings.dart';

class Test2BookingScreen extends StatefulWidget {
  final String userId;
  final int index;

  Test2BookingScreen(this.userId, this.index);

  @override
  _Test2BookingScreenState createState() => _Test2BookingScreenState();
}

class _Test2BookingScreenState extends State<Test2BookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.index =
        widget.index; // Set default tab index to 0 (first page)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 233, 226),
      appBar: AppBar(
        title: Text(
          'Orders',
          style: TextStyle(
              color: const Color.fromARGB(255, 126, 70, 62),
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 242, 233, 226),
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
                SellerOnlineOrdersScreen(widget.userId),
                SellerCashOrdersScreen(widget.userId),
                SellerPendingBookingsScreen(widget.userId)
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
