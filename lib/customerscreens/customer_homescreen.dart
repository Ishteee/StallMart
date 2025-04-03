// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_super_parameters

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:xaviers_market/customerscreens/customer_pending_orders.dart';
import 'package:xaviers_market/customerscreens/customer_settings.dart';
import 'package:xaviers_market/customerscreens/merch_details_screen.dart';
import 'package:xaviers_market/customerscreens/merch_products_screen.dart';
import 'package:xaviers_market/customerscreens/merchs_screen.dart';
import 'package:xaviers_market/customerscreens/products_screen.dart';
import 'package:xaviers_market/customerscreens/customer_bookings_tab.dart';
import 'notification.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'NewsScreen.dart';
import 'stalls_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  final String userId;
  
  const CustomerHomeScreen(this.userId);

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  String? _customerName;

  @override
  void initState() {
    super.initState();
    _fetchCustomerName();
  }

  Future<void> _fetchCustomerName() async {
    var nameSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    setState(() {
      _customerName = nameSnapshot['name'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 242, 233, 226),
        appBar: AppBar(
          toolbarHeight: 100,
          backgroundColor: const Color.fromARGB(255, 242, 233, 226),
          title: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'Hi, ',
                      style: TextStyle(
                          fontSize: 20,
                          color: const Color.fromARGB(255, 126, 70, 62),
                          fontWeight: FontWeight.bold),
                      children: <TextSpan>[
                        TextSpan(
                          text: _customerName,
                          style: TextStyle(
                              fontSize: 20,
                              color: Color.fromARGB(255, 77, 43, 38),
                              fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Welcome',
                    style: TextStyle(
                      fontSize: 25,
                      color: const Color.fromARGB(255, 126, 70, 62),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Spacer(),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 500),
                      pageBuilder: (_, __, ___) => NotificationScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, -1.0);
                        const end = Offset.zero;
                        var curve = Curves.easeInOut;

                        var tween = Tween(begin: begin, end: end).chain(
                          CurveTween(curve: curve),
                        );

                        var offsetAnimation = animation.drive(tween);

                        return SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        );
                      },
                    ),
                  );
                },
                child: Hero(
                  tag: 'notificationBell',
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: const Icon(
                      Icons.notifications,
                      size: 30,
                      color: const Color.fromARGB(255, 126, 70, 62),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                iconSize: 30,
                color: Colors.blueGrey,
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const CustomerSettingsScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset(0.0, 0.0);
                        var tween = Tween(begin: begin, end: end);
                        var offsetAnimation = animation.drive(tween);

                        return SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 400),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
            child: Align(
          alignment: Alignment.topLeft,
          child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(children: [
                StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('stalls')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return const Center(child: Text('Error'));
                      }

                      final stallDocs = snapshot.data!.docs;
                      DateTime currentTime = DateTime.now();
                                          List<DocumentSnapshot> activeStalls = stallDocs.where((stall) {
              DateTime startDateTime = (stall.get('startDateTime') as Timestamp).toDate();
              DateTime endDateTime = (stall.get('endDateTime') as Timestamp).toDate();
              return currentTime.isAfter(startDateTime) && currentTime.isBefore(endDateTime);
            }).toList();
                      final stalls = activeStalls
                          .map((doc) => {
                                'id': doc.id,
                                'name': doc['name'],
                                'imageUrl': doc['imageUrl'],
                                'createdAt': doc[
                                    'createdAt'], // Assuming you have a field called 'createdAt' in your document
                              })
                          .toList();

                      // Sort the stalls by createdAt to get the latest stall
                      stalls.sort(
                          (a, b) => b['createdAt'].compareTo(a['createdAt']));

                      // Get the image URL of the latest stall
                      final latestStallImageUrl =
                          stalls.isNotEmpty ? stalls.first['imageUrl'] : '';
                      final latestStallName =
                          stalls.isNotEmpty ? stalls.first['name'] : '';

                      return Column(
                        children: [
                          Text(
                            'Latest Stall',
                            style: GoogleFonts.raleway(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 126, 70, 62),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 10.0),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ProductsScreen(
                                            widget.userId, stalls.first['id'])),
                                  );
                                },
                                child: Hero(
                                  tag: 'stallImage',
                                  child: Container(
                                    height: 350,
                                    width: 300,
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image:
                                            NetworkImage(latestStallImageUrl),
                                        fit: BoxFit.cover,
                                      ),
                                      borderRadius: BorderRadius.circular(10.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.7),
                                          spreadRadius: 4,
                                          blurRadius: 5,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10.0),
                              Center(
                                child: Text(
                                  "$latestStallName",
                                  style: GoogleFonts.raleway(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 104, 54, 46),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10.0),
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Stalls',
                                          style: GoogleFonts.raleway(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromARGB(
                                                255, 126, 70, 62),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              PageRouteBuilder(
                                                pageBuilder: (context,
                                                        animation,
                                                        secondaryAnimation) =>
                                                    StallsScreen(widget.userId),
                                                transitionsBuilder: (context,
                                                    animation,
                                                    secondaryAnimation,
                                                    child) {
                                                  var begin =
                                                      const Offset(1.0, 0.0);
                                                  var end = Offset.zero;
                                                  var curve = Curves.ease;
                                                  var tween = Tween(
                                                          begin: begin,
                                                          end: end)
                                                      .chain(CurveTween(
                                                          curve: curve));
                                                  var offsetAnimation =
                                                      animation.drive(tween);
                                                  return SlideTransition(
                                                    position: offsetAnimation,
                                                    child: child,
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'See all >',
                                            style: GoogleFonts.raleway(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromARGB(
                                                  255, 126, 70, 62),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('stalls')
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Center(
                                                child:
                                                    CircularProgressIndicator());
                                          }

                                          if (snapshot.hasError) {
                                            return const Center(
                                                child: Text('Error'));
                                          }

                                          final stallDocs = snapshot.data!.docs;
                                          DateTime currentTime = DateTime.now();
                                          List<DocumentSnapshot> activeStalls = stallDocs.where((stall) {
              DateTime startDateTime = (stall.get('startDateTime') as Timestamp).toDate();
              DateTime endDateTime = (stall.get('endDateTime') as Timestamp).toDate();
              return currentTime.isAfter(startDateTime) && currentTime.isBefore(endDateTime);
            }).toList();
                                          final stalls = activeStalls
                                              .map((doc) => {
                                                    'id': doc.id,
                                                    'name': doc['name'],
                                                    'imageUrl': doc['imageUrl'],
                                                  })
                                              .toList();

                                          return Row(
                                            children: [
                                              ...stalls.take(3).map((stall) {
                                                return GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            ProductsScreen(
                                                                widget.userId,
                                                                stall['id']),
                                                      ),
                                                    );
                                                  },
                                                  child: Column(
                                                    children: [
                                                      Container(
                                                        margin: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 8.0),
                                                        width: 150,
                                                        height: 200,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.grey
                                                                  .withOpacity(
                                                                      0.5),
                                                              spreadRadius: 2,
                                                              blurRadius: 5,
                                                              offset:
                                                                  const Offset(
                                                                      0, 3),
                                                            ),
                                                          ],
                                                          image:
                                                              DecorationImage(
                                                            fit: BoxFit.cover,
                                                            image: NetworkImage(
                                                                stall[
                                                                    'imageUrl']),
                                                          ),
                                                        ),
                                                      ),
                                                      //const SizedBox(height: 8.0),
                                                      Text(
                                                        stall['name'],
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                              GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    PageRouteBuilder(
                                                      pageBuilder: (context,
                                                              animation,
                                                              secondaryAnimation) =>
                                                          StallsScreen(
                                                              widget.userId),
                                                      transitionsBuilder:
                                                          (context,
                                                              animation,
                                                              secondaryAnimation,
                                                              child) {
                                                        var begin =
                                                            const Offset(
                                                                1.0, 0.0);
                                                        var end = Offset.zero;
                                                        var curve = Curves.ease;
                                                        var tween = Tween(
                                                                begin: begin,
                                                                end: end)
                                                            .chain(CurveTween(
                                                                curve: curve));
                                                        var offsetAnimation =
                                                            animation
                                                                .drive(tween);
                                                        return SlideTransition(
                                                          position:
                                                              offsetAnimation,
                                                          child: child,
                                                        );
                                                      },
                                                    ),
                                                  );
                                                },
                                                child: Column(
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8.0),
                                                      width: 150,
                                                      height: 200,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.grey
                                                                .withOpacity(
                                                                    0.5),
                                                            spreadRadius: 2,
                                                            blurRadius: 5,
                                                            offset:
                                                                const Offset(
                                                                    0, 3),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          'See all',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 16,
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      "",
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Merchandise',
                                          style: GoogleFonts.raleway(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromARGB(
                                                255, 126, 70, 62),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              PageRouteBuilder(
                                                pageBuilder: (context,
                                                        animation,
                                                        secondaryAnimation) =>
                                                    MerchsScreen(widget.userId),
                                                transitionsBuilder: (context,
                                                    animation,
                                                    secondaryAnimation,
                                                    child) {
                                                  var begin =
                                                      const Offset(1.0, 0.0);
                                                  var end = Offset.zero;
                                                  var curve = Curves.ease;
                                                  var tween = Tween(
                                                          begin: begin,
                                                          end: end)
                                                      .chain(CurveTween(
                                                          curve: curve));
                                                  var offsetAnimation =
                                                      animation.drive(tween);
                                                  return SlideTransition(
                                                    position: offsetAnimation,
                                                    child: child,
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'See all >',
                                            style: GoogleFonts.raleway(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromARGB(
                                                  255, 126, 70, 62),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('merchandise')
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Center(
                                                child:
                                                    CircularProgressIndicator());
                                          }

                                          if (snapshot.hasError) {
                                            return const Center(
                                                child: Text('Error'));
                                          }

                                          final merchDocs = snapshot.data!.docs;
                                          final merchs = merchDocs
                                              .map((doc) => {
                                                    'id': doc.id,
                                                    'name': doc['name'],
                                                    'imageUrl': doc['imageUrl'],
                                                  })
                                              .toList();

                                          return Row(
                                            children: [
                                              ...merchs.take(3).map((merch) {
                                                return GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            MerchProductsScreen(
                                                                widget.userId,
                                                                merch['id'],
                                                                merch['name']),
                                                      ),
                                                    );
                                                  },
                                                  child: Column(
                                                    children: [
                                                      Container(
                                                        margin: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 8.0),
                                                        width: 150,
                                                        height: 200,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.grey
                                                                  .withOpacity(
                                                                      0.5),
                                                              spreadRadius: 2,
                                                              blurRadius: 5,
                                                              offset:
                                                                  const Offset(
                                                                      0, 3),
                                                            ),
                                                          ],
                                                          image:
                                                              DecorationImage(
                                                            fit: BoxFit.cover,
                                                            image: NetworkImage(
                                                                merch[
                                                                    'imageUrl']),
                                                          ),
                                                        ),
                                                      ),
                                                      //const SizedBox(height: 8.0),
                                                      Text(
                                                        merch['name'],
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                              GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    PageRouteBuilder(
                                                      pageBuilder: (context,
                                                              animation,
                                                              secondaryAnimation) =>
                                                          MerchsScreen(
                                                              widget.userId),
                                                      transitionsBuilder:
                                                          (context,
                                                              animation,
                                                              secondaryAnimation,
                                                              child) {
                                                        var begin =
                                                            const Offset(
                                                                1.0, 0.0);
                                                        var end = Offset.zero;
                                                        var curve = Curves.ease;
                                                        var tween = Tween(
                                                                begin: begin,
                                                                end: end)
                                                            .chain(CurveTween(
                                                                curve: curve));
                                                        var offsetAnimation =
                                                            animation
                                                                .drive(tween);
                                                        return SlideTransition(
                                                          position:
                                                              offsetAnimation,
                                                          child: child,
                                                        );
                                                      },
                                                    ),
                                                  );
                                                },
                                                child: Column(
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8.0),
                                                      width: 150,
                                                      height: 200,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.grey
                                                                .withOpacity(
                                                                    0.5),
                                                            spreadRadius: 2,
                                                            blurRadius: 5,
                                                            offset:
                                                                const Offset(
                                                                    0, 3),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          'See all',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 16,
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      "",
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'University News',
                                      style: GoogleFonts.raleway(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 126, 70, 62),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    CarouselSlider(
                                      options: CarouselOptions(
                                        height: 250.0,
                                        enableInfiniteScroll: true,
                                        enlargeCenterPage: true,
                                        autoPlay: true,
                                        viewportFraction:
                                            0.7, // Set the fraction of the viewport width
                                      ),
                                      items: [
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    NewsDetailsScreen(
                                                  title: 'Project Submission Comes Close',
                                                  imagePath:
                                                      'assets/images/studying.jpeg',
                                                  content:
                                                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua..',
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            height: double.infinity,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(
                                                  spreadRadius: 3,
                                                  blurRadius: 5,
                                                  color: Colors.black,
                                                  offset: Offset(0, 3),
                                                )
                                              ],
                                            ),
                                            child: Image(
                                              image: AssetImage(
                                                  'assets/images/studying.jpeg'),
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    NewsDetailsScreen(
                                                  title: 'Our Biggest Event',
                                                  imagePath:
                                                      'assets/images/college_fest.jpeg',
                                                  content:
                                                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua..',

                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            height: double.infinity,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(
                                                  spreadRadius: 3,
                                                  blurRadius: 5,
                                                  color: Colors.black,
                                                  offset: Offset(0, 3),
                                                )
                                              ],
                                            ),
                                            child: Image(
                                              image: AssetImage(
                                                  'assets/images/college_fest.jpeg'),
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    NewsDetailsScreen(
                                                  title: 'Sports Day this Week',
                                                  imagePath:
                                                      'assets/images/sports.jpeg',
                                                  content:
                                                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua..',
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            height: double.infinity,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(
                                                  spreadRadius: 3,
                                                  blurRadius: 5,
                                                  color: Colors.black,
                                                  offset: Offset(0, 3),
                                                )
                                              ],
                                            ),
                                            child: Image(
                                              image: AssetImage(
                                                  'assets/images/sports.jpeg'),
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                        ),
                                        // Add more carousel items as needed...
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    })
              ])),
        )));
  }
}
