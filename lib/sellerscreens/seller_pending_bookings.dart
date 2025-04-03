import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SellerPendingBookingsScreen extends StatefulWidget {
  final String userId;

  SellerPendingBookingsScreen(this.userId);

  @override
  _SellerPendingBookingsScreenState createState() =>
      _SellerPendingBookingsScreenState();
}

class _SellerPendingBookingsScreenState
    extends State<SellerPendingBookingsScreen> {
  late Stream<QuerySnapshot> _bookingsStream;
  Timer? _timer;
  String? customerName;

  @override
  void initState() {
    super.initState();
    _bookingsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('bookings')
        .snapshots();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  Future<void> fetchCustomerName(String customerId) async {
    try {
      DocumentSnapshot customerSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(customerId)
          .get();
      if (customerSnapshot.exists) {
        customerName = customerSnapshot.get('name');
      }
    } catch (e) {
      print('Error getting customer name: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 233, 226),
      body: StreamBuilder<QuerySnapshot>(
        stream: _bookingsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No bookings found.',
                style: TextStyle(
                    color: const Color.fromARGB(255, 126, 70, 62),
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var booking = snapshot.data!.docs[index];
              var customerId = booking.id;
              fetchCustomerName(customerId).then((_) {});

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(customerId)
                    .collection('carts')
                    .get(),
                builder: (context, cartSnapshot) {
                  if (cartSnapshot.hasError ||
                      !cartSnapshot.hasData ||
                      cartSnapshot.data!.docs.isEmpty) {
                    return SizedBox.shrink(); // Return an empty widget
                  }

                  var cartDocs = cartSnapshot.data!.docs;

                  return ListView(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    children: cartDocs
                        .where((cart) =>
                            cart['isBooked'] == true &&
                            cart['sellerId'] == widget.userId)
                        .map((cart) {
                      _timer?.cancel(); // Cancel the previous timer
                      _timer =
                          Timer.periodic(const Duration(seconds: 1), (timer) {
                        setState(() {});
                      });

                      return FutureBuilder<QuerySnapshot>(
                        future: cart.reference.collection('products').get(),
                        builder: (context, productSnapshot) {
                          if (productSnapshot.hasError ||
                              !productSnapshot.hasData) {
                            return SizedBox.shrink(); // Return an empty widget
                          }
                          var totalAmount = cart['totalAmount'];
                          var products = productSnapshot.data!.docs;
                          var productsText = products
                              .map((product) =>
                                  '${product['name']} x ${product['quantity']}')
                              .join('\n');

                          int checkoutTime = cart['checkoutTime'];
                          var checkoutDateTime =
                              DateTime.fromMillisecondsSinceEpoch(checkoutTime);
                          var date =
                              DateFormat('dd/MM/yyyy').format(checkoutDateTime);
                          var time =
                              DateFormat('h:mm a').format(checkoutDateTime);
                          int fifteenMinutesInMillis = 15 * 60 * 1000;
                          int timeElapsedInMillis =
                              DateTime.now().millisecondsSinceEpoch -
                                  checkoutTime;
                          int remainingTimeInMillis =
                              fifteenMinutesInMillis - timeElapsedInMillis;

                          int remainingMinutes =
                              (remainingTimeInMillis / (60 * 1000)).floor();
                          int remainingSeconds =
                              ((remainingTimeInMillis % (60 * 1000)) / 1000)
                                  .floor();

                          var stallName = cart['stallName'];

                          return Container(
                            margin: EdgeInsets.symmetric(
                                vertical: 5.0, horizontal: 5),
                            child: Card(
                              elevation: 5.0,
                              color: Color.fromARGB(255, 242, 233, 226),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Stall Name",
                                              style: GoogleFonts.raleway(fontSize: 15, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 128, 69, 60),),
                                            ),
                                            Text(
                                              stallName,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 17),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              "Date and Time",
                                              style: GoogleFonts.raleway(fontSize: 15, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 128, 69, 60),),
                                            ),
                                            Text(
                                              "${date} - ${time}",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 17),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 15),
                                    RichText(
                text: TextSpan(
                  style: GoogleFonts.raleway(fontSize: 15, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 128, 69, 60),), // Adjust the style as needed
                  children: [
                    TextSpan(text: 'Customer Name: '),
                    TextSpan(
                        text: customerName,
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
                                    SizedBox(height: 15),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Column(
                                          children: [
                                            Text(
                                              'Products',
                                              style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 128, 69, 60),),
                                            ),
                                            Text(
                                              productsText,
                                              style: TextStyle(
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Total Amount: $totalAmount',
                                      style: TextStyle(fontSize: 18, color: Color.fromARGB(255, 128, 69, 60), fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Booking Auto-Cancel: $remainingMinutes:${remainingSeconds.toString().padLeft(2, '0')}',
                                      style: TextStyle(fontSize: 18, color: Color.fromARGB(255, 128, 69, 60), fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.brown),
                                          onPressed: () async {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title:
                                                      Text('Mark as Collected'),
                                                  content: Text(
                                                      'Are you sure you want to mark this order as collected?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop(); // Close the dialog
                                                      },
                                                      child: Text('No'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        Navigator.of(context)
                                                            .pop(); // Close the dialog
                                                        // Perform the action to mark the order as collected
                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection('users')
                                                            .doc(customerId)
                                                            .collection(
                                                                'orders')
                                                            .add({
                                                          'purchaseTime': DateTime
                                                                  .now()
                                                              .millisecondsSinceEpoch,
                                                          'products':
                                                              productsText,
                                                          'totalAmount':
                                                              totalAmount,
                                                          'stallName': stallName,
                                                          'method': 'cash'
                                                        });

                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection('users')
                                                            .doc(widget.userId)
                                                            .collection(
                                                                'comp_bookings')
                                                            .add({
                                                          'purchaseTime': DateTime
                                                                  .now()
                                                              .millisecondsSinceEpoch,
                                                          'products':
                                                              productsText,
                                                          'totalAmount':
                                                              totalAmount,
                                                          'stallName': stallName,
                                                          'method': 'cash'
                                                        });

                                                        for (var product
                                                            in products) {
                                                          await product
                                                              .reference
                                                              .delete();
                                                        }

                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection('users')
                                                            .doc(customerId)
                                                            .collection('carts')
                                                            .doc(cart.id)
                                                            .delete();

                                                        await FirebaseFirestore.instance
                                                            .collection('users')
                                                            .doc(widget.userId)
                                                            .collection('bookings')
                                                            .doc(customerId)
                                                            .delete();         

                                                      },
                                                      child: Text('Yes'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          child: Text(
                                            "Mark as Collected",
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.brown),
                                          onPressed: () async {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: Text('Cancel Booking'),
                                                  content: Text(
                                                      'Are you sure you want to cancel this booking?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop(); // Close the dialog
                                                      },
                                                      child: Text('No'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        Navigator.of(context)
                                                            .pop(); // Close the dialog
                                                        // Perform the action to cancel the booking
                                                        if (cart['bookNow'] ==
                                                            true) {
                                                          var productsSnapshot =
                                                              await cart
                                                                  .reference
                                                                  .collection(
                                                                      'products')
                                                                  .get();
                                                          if (productsSnapshot
                                                              .docs
                                                              .isNotEmpty) {
                                                            var productDoc =
                                                                productsSnapshot
                                                                    .docs.first;
                                                            await productDoc
                                                                .reference
                                                                .delete();
                                                          }
                                                          await cart.reference
                                                              .delete();
                                                        } else {
                                                          await FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                  'users')
                                                              .doc(customerId)
                                                              .collection(
                                                                  'carts')
                                                              .doc(cart.id)
                                                              .set({
                                                            'bookNow': false,
                                                            'checkoutTime': '',
                                                            'isBooked': false,
                                                            'sellerId':
                                                                widget.userId,
                                                            'stallName':
                                                                stallName,
                                                            'totalAmount': '',
                                                            'isFnB': cart['isFnB']
                                                          });

                                                          await FirebaseFirestore.instance
                                                            .collection('users')
                                                            .doc(widget.userId)
                                                            .collection('bookings')
                                                            .doc(customerId)
                                                            .delete();

                                                        }
                                                      },
                                                      child: Text('Yes'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          child: Text(
                                            "Cancel Booking",
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
